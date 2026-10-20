-- ============================================================
-- ÉTAPE 5 : CONSTRUCTION DES VARIABLES
-- ============================================================
-- Rôle : créer les colonnes calculées dont dépendent les
-- métriques M-00 à M-16 et le modèle prédictif (O6).
--
-- Ces requêtes sont EXPLORATOIRES : elles ne créent aucune
-- table. Les expressions validées ici sont assemblées en une
-- seule table mart.orders à l'étape 6.
--
-- Convention : toutes les soustractions de dates passent par
-- ::DATE. La promesse d'Olist porte sur une DATE, pas sur un
-- horaire : livré le jour promis à 23h = 0 jour de retard.
-- Sans ::DATE, PostgreSQL renvoie un INTERVAL ('-8 days
-- -04:37:12') inexploitable pour des tranches ou une médiane.


-- ============================================================
-- 5.1 : LE RETARD
-- ============================================================

-- -- Q1 + Q2. Écart à la promesse et indicateur de retard ----
-- Sens de la soustraction : RÉELLE − ESTIMÉE.
--   positif = en retard | négatif = en avance
-- L'inverse donnerait « retard = −5 jours », contre-intuitif
-- dans toutes les métriques.
--
-- is_late : une comparaison EST un booléen en SQL, pas besoin
-- de CASE WHEN.
-- Le seuil est > 0 et non >= 0 : livré le jour exact de la
-- promesse, l'engagement est TENU.
--
-- RÉSULTAT (M-00) : 6 534 commandes en retard sur 96 447 = 6,8 %
SELECT
    order_id,
    order_delivered_customer_date::DATE
        - order_estimated_delivery_date::DATE AS gap,
    (order_delivered_customer_date::DATE
        > order_estimated_delivery_date::DATE) AS is_late
FROM intermediate.orders;


-- -- Q3. Tranches de gravité (M-14) --------------------------
-- Bornes choisies sur la DISTRIBUTION OBSERVÉE, pas sur des
-- chiffres ronds arbitraires. Deux ruptures nettes :
-- après 1 jour (de 825 à 545) et après 7-8 jours (de 483 à 336).
--
-- Les commandes NON en retard reçoivent aussi une modalité :
-- sans cela elles seraient NULL et sortiraient des analyses,
-- alors qu'elles constituent le GROUPE DE RÉFÉRENCE de M-01.
--
-- Frontière « à l'heure / en avance » fixée à −4 jours :
-- au-delà de 3 jours d'avance, la livraison n'est plus perçue
-- comme ponctuelle mais comme anticipée : avec un coût réel
-- pour le client (absence, stockage).
--
-- CTE nécessaire : un alias du SELECT (gap) n'est pas
-- réutilisable dans le CASE du même bloc. La CTE le matérialise.
--
-- RÉSULTAT : total 96 447, aucun NULL :
--   Too early     83 878   (87,0 %)
--   At time        6 035   ( 6,3 %)
--   Barely late    3 672   ( 3,8 %)
--   Late           1 637   ( 1,7 %)
--   Too late         880   ( 0,9 %)
--   Very late        345   ( 0,4 %)
--
-- LECTURE MÉTIER : 87 % des commandes arrivent avec 4 jours
-- d'avance ou plus, avec un pic à −14 jours. Olist annonce des
-- délais très conservateurs. C'est la marge de M-16 et le
-- gisement des scénarios d'amélioration (O7).
WITH gap_calcul AS (
    SELECT
        order_id,
        order_delivered_customer_date::DATE
            - order_estimated_delivery_date::DATE AS gap
    FROM intermediate.orders
)
SELECT
    order_id,
    gap,
    CASE
        WHEN gap <= -4              THEN 'Too early'
        WHEN gap BETWEEN -3 AND  0  THEN 'At time'
        WHEN gap BETWEEN  1 AND  7  THEN 'Barely late'
        WHEN gap BETWEEN  8 AND 15  THEN 'Late'
        WHEN gap BETWEEN 16 AND 30  THEN 'Too late'
        WHEN gap >= 31              THEN 'Very late'
    END AS timing
FROM gap_calcul;


-- ============================================================
-- 5.2 : LES TROIS SEGMENTS DU PARCOURS (O2)
-- ============================================================
-- Savoir qu'une commande est en retard ne suffit pas : il faut
-- savoir OÙ le retard est né. Chaque segment a son responsable
-- et donc son levier d'action.
--
--   Validation   : achat -> approbation        (paiement)
--   Préparation  : approbation -> transporteur (LE VENDEUR)
--   Acheminement : transporteur -> livraison   (LE TRANSPORTEUR)
--
-- RG-04 : les 1 350 commandes remises au transporteur AVANT
-- validation du paiement donneraient une préparation NÉGATIVE.
-- Le CASE WHEN la neutralise en NULL.
-- Même principe que les 4 poids à 0 de l'étape 3 : une absence
-- honnête vaut mieux qu'une valeur fausse, qui contaminerait
-- la médiane par segment (M-03).
-- Ces commandes RESTENT au périmètre : seul ce segment est
-- neutralisé (exclusion ciblée, pas exclusion tout court).
SELECT
    order_id,
    order_approved_at::DATE
        - order_purchase_timestamp::DATE AS gap_validation,
    CASE
        WHEN (order_delivered_carrier_date::DATE
              - order_approved_at::DATE) < 0 THEN NULL
        ELSE order_delivered_carrier_date::DATE
             - order_approved_at::DATE
    END AS gap_preparation,
    order_delivered_customer_date::DATE
        - order_delivered_carrier_date::DATE AS gap_shipping
FROM intermediate.orders;


-- ============================================================
-- 5.3 : LES VARIABLES EXPLICATIVES (O6)
-- ============================================================

-- -- Q7. Coordonnées vendeur et client -----------------------
-- geolocation_pref est jointe DEUX FOIS, avec deux alias : une
-- fois côté client (geo_c), une fois côté vendeur (geo_s).
-- Sans alias distincts, PostgreSQL ne saurait pas de quelle
-- instance on parle.
--
-- PAS DE GROUP BY ICI, volontairement. Une commande peut avoir
-- plusieurs vendeurs, donc plusieurs distances. Il faut
-- calculer CHAQUE distance avant de choisir. Agréger les
-- coordonnées (MAX(lat), MAX(lng)) produirait un point
-- inexistant, mêlant la latitude d'un vendeur à la longitude
-- d'un autre.
--
-- DISTINCT : évite qu'un vendeur ayant 3 articles dans la
-- commande n'apparaisse 3 fois avec les mêmes coordonnées.
--
-- DÉCISION : commandes multi-vendeurs (1,3 %) : la distance
-- retenue est la PLUS LONGUE (MAX), appliquée en Python.
-- Justification : le dataset ne fournit qu'UNE date de
-- livraison par commande, même à deux vendeurs. Cette date
-- correspond vraisemblablement au dernier colis arrivé : donc
-- au vendeur le plus éloigné.
-- LIMITE À DOCUMENTER : les expéditions séparées ne sont pas
-- distinguables dans les données.
--
-- Le détail commande × vendeur n'est pas perdu : mart.sellers
-- est construite depuis staging.order_items (étape 6).
--
-- RÉSULTAT DU CONTRÔLE : en INNER JOIN, 95 971 commandes au
-- lieu de 96 447 : 476 perdues, dont un code postal (client ou
-- vendeur) est absent de geolocation.
-- DÉCISION : passage en LEFT JOIN. Une distance manquante ne
-- justifie pas d'exclure une commande des analyses de retard,
-- de satisfaction ou de CA. Exclusion ciblée, comme RG-04 et
-- RG-07.
-- TOUS les JOIN doivent être LEFT : un seul INNER en fin de
-- chaîne annulerait l'effet de tous les précédents.
--
-- SORTIE : 97 607 lignes (couples commande × vendeur),
-- 96 447 order_id distincts.
SELECT DISTINCT
    o.order_id,
    geo_c.avg_lat AS customer_lat,
    geo_c.avg_lng AS customer_lng,
    geo_s.avg_lat AS seller_lat,
    geo_s.avg_lng AS seller_lng
FROM intermediate.orders AS o
LEFT JOIN staging.customers AS c
    ON o.customer_id = c.customer_id
LEFT JOIN intermediate.geolocation_pref AS geo_c
    ON c.customer_zip_code_prefix = geo_c.geolocation_zip_code_prefix
LEFT JOIN staging.order_items AS it
    ON o.order_id = it.order_id
LEFT JOIN staging.sellers AS s
    ON it.seller_id = s.seller_id
LEFT JOIN intermediate.geolocation_pref AS geo_s
    ON s.seller_zip_code_prefix = geo_s.geolocation_zip_code_prefix;

-- La distance elle-même (formule de Haversine) est calculée en
-- PYTHON : la Terre est une sphère, une distance euclidienne
-- sur lat/lng déforme : un degré de longitude rétrécit avec la
-- latitude, et le Brésil s'étend sur ~39 degrés.
-- Le résultat est réinjecté dans intermediate.distances.
-- Le pipeline devient HYBRIDE : le SQL seul ne reconstruit
-- plus la base. Ordre d'exécution à documenter (étape 8).
--
-- DISTRIBUTION OBTENUE :
--   médiane 434 km | moyenne 601 km | max 8 678 km
--   476 commandes sans distance (coordonnées manquantes)


-- -- Q8. Volume du produit -----------------------------------
-- Un produit encombrant est plus complexe à expédier.
-- NULL × valeur = NULL : les 2 produits sans dimensions
-- donnent un volume NULL, ce qui est le comportement voulu.
-- RÉSULTAT : 2 volumes NULL.
-- Dimensions en INT : vérifié, aucune décimale dans la source.
-- À VÉRIFIER : présence de volumes à 0 (ORDER BY ASC) :
-- même piège que les 4 poids à 0 ; un NULLIF serait requis.
SELECT
    product_id,
    (product_length_cm * product_height_cm * product_width_cm)
        AS product_volume_cm3
FROM staging.products;


-- -- Q9. Variables temporelles -------------------------------
-- EXTRACT ne fonctionne QUE sur un type date/timestamp : c'est
-- le typage de l'étape 3 qui rend cette requête possible.
--
--   purchase_month : saisonnalité (Noël, Black Friday, pics
--                    de volume qui saturent la logistique)
--   purchase_dow   : rythme opérationnel, 0 = dimanche à
--                    6 = samedi. Une commande du vendredi soir
--                    attend le lundi pour être traitée.
--   purchase_year  : sert à RG-10 (découpage des deux périodes
--                    d'observation vendeur) et à écarter les
--                    mois incomplets en début/fin de dataset.
--
-- Ces trois variables sont connues AU MOMENT DE LA COMMANDE :
-- c'est le critère d'éligibilité pour O6.
SELECT
    order_id,
    EXTRACT(YEAR  FROM order_purchase_timestamp) AS purchase_year,
    EXTRACT(MONTH FROM order_purchase_timestamp) AS purchase_month,
    EXTRACT(DOW   FROM order_purchase_timestamp) AS purchase_dow
FROM intermediate.orders;


-- ============================================================
-- 5.4 : LES INDICATEURS DÉRIVÉS
-- ============================================================

-- -- Q10. Client insatisfait (M-02) --------------------------
-- Seuil : note ≤ 2, conformément à RG-05.
-- Booléen plutôt que libellé texte : AVG(is_unsatisfied::INT)
-- donne directement un TAUX, ce qu'est M-02. Un libellé
-- imposerait de compter puis diviser.
--
-- NE PAS nommer cette colonne customer_state : ce nom
-- désigne déjà l'ÉTAT BRÉSILIEN (SP, RJ…) dans
-- staging.customers. Collision garantie à l'assemblage.
SELECT
    order_id,
    avg_score,
    (avg_score <= 2) AS is_unsatisfied
FROM intermediate.order_reviews;


-- -- Q11. Montant de la commande (RG-11) ---------------------
-- DÉCISION FINALE : le montant de référence est payment_total,
-- l'ENCAISSEMENT RÉEL du client (somme des payment_value).
-- Le chiffre d'affaires est l'argent qui entre, pas la valeur
-- théorique du panier.
--
-- total_price et total_freight sont conservés séparément :
-- ils permettent de mesurer la part du transport dans le CA
-- exposé au retard (O4).
--
-- CONTRÔLE DE COHÉRENCE (H9) : la somme prix + frais de port
-- calculée depuis order_items a été comparée à payment_total.
-- 299 écarts sur 96 447 (0,31 %), maximum 0,02 R$ : des
-- arrondis. Les deux sources concordent, H9 est revalidé sur
-- le périmètre. La colonne redondante a été supprimée de
-- mart.orders : une seule source de vérité par mesure.
SELECT
    io.order_id,
    ii.total_price,
    ii.total_freight,
    ip.payment_total
FROM intermediate.orders AS io
LEFT JOIN intermediate.items_order    AS ii ON io.order_id = ii.order_id
LEFT JOIN intermediate.order_payments AS ip ON io.order_id = ip.order_id;


-- ------------------------------------------------------------
-- SYNTHÈSE ÉTAPE 5
-- ------------------------------------------------------------
-- Variables construites, à assembler en mart.orders :
--
--   gap, is_late, timing                          -> M-00, M-14, M-15
--   gap_validation, gap_preparation, gap_shipping -> M-03, M-04, M-05
--   customer_lat/lng, seller_lat/lng -> distance_km (O6)
--   product_volume_cm3                            -> O6
--   purchase_year / month / dow                   -> O6
--   avg_score, is_unsatisfied                     -> M-01, M-02
--   total_price, total_freight, payment_total     -> M-06, M-07
--
-- PREMIER RÉSULTAT D'ANALYSE (M-00) :
--   6 534 commandes en retard sur 96 447 = 6,8 %
--   Nuance : 6,8 % des COMMANDES ne signifie pas 6,8 % du CA.
--   Si les retards touchent des commandes plus chères,
--   l'exposition financière est supérieure (O4).
--
-- POINTS OUVERTS :
--   - Vérifier l'absence de volumes à 0 (Q8)
--   - product_volume_cm3 n'est pas encore intégré à mart.orders
--     (grain produit, à rattacher via order_items)
-- ============================================================