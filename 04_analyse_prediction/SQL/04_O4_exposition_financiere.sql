-- ============================================================
-- O4. L'EXPOSITION FINANCIÈRE
-- ============================================================
-- Objectif : quantifier le chiffre d'affaires exposé à une
-- rupture de promesse et sa concentration par vendeur, état et
-- catégorie.
--
-- Source     : mart.orders (96 447 commandes du périmètre)
-- Métriques  : M-06 (CA exposé), M-07 (CA à risque avéré),
--              M-08 (concentration)
-- Constats   : 04_O4_constats.md
--
-- ENJEU : c'est le chiffre que lit la direction générale. Il
-- transforme un taux de retard en montant.
--
-- ANCRAGE : 15 416 546 R$ de CA total sur le périmètre.
--
-- EXPOSITION ≠ PERTE. Ces métriques mesurent l'argent qui
-- TRANSITE par des commandes dont la promesse a été rompue.
-- Avec un réachat de 3,12 % (H1), aucune perte future n'est
-- observable. La distinction doit être maintenue dans tous les
-- livrables.
--
-- MONTANT DE RÉFÉRENCE : payment_total (RG-11 v2) :
-- l'encaissement réel, pas la valeur théorique du panier.


-- ============================================================
-- Q1. QUEL CA TRANSITE PAR DES COMMANDES EN RETARD ? (M-06)
-- ============================================================
-- Un montant seul ne dit rien : il faut le total et la part.
-- Les volumes sont ajoutés pour permettre le calcul des
-- paniers moyens en Q2.
SELECT
    COUNT(order_id)                           AS all_orders,
    COUNT(order_id) FILTER (WHERE is_late)    AS late_orders,
    SUM(payment_total)                        AS total_CA,
    SUM(payment_total) FILTER (WHERE is_late) AS late_CA,
    ROUND(SUM(payment_total) FILTER (WHERE is_late)
          / SUM(payment_total) * 100, 2)      AS late_CA_rate
FROM mart.orders;

-- RÉSULTAT
--
--   Commandes totales          96 447
--   Commandes en retard         6 534   (6,77 %)
--   CA total            15 416 546 R$
--   CA EXPOSÉ            1 150 866 R$
--   PART DU CA EXPOSÉ         7,47 %
--
-- 7,47 % DU CA POUR 6,77 % DES COMMANDES.
-- L'exposition FINANCIÈRE dépasse l'exposition en VOLUME.
-- La question posée en O1, « 6,77 % des commandes ne veut pas
-- dire 6,77 % du CA », trouve ici sa réponse.


-- ============================================================
-- Q2. LES COMMANDES EN RETARD SONT-ELLES PLUS CHÈRES ?
-- ============================================================
-- NE PAS COMPARER UN SOUS-GROUPE À L'ENSEMBLE QUI LE
-- CONTIENT. AVG(payment_total) sur toute la table inclurait
-- les commandes en retard et atténuerait l'écart.
-- Le FILTER (WHERE NOT is_late) isole correctement les
-- commandes à l'heure.
SELECT
    ROUND(AVG(payment_total) FILTER (WHERE NOT is_late), 2) AS avg_orders,
    ROUND(AVG(payment_total) FILTER (WHERE is_late), 2)     AS avg_late_orders
FROM mart.orders;

-- RÉSULTAT
--
--   Panier moyen à l'heure    158,66 R$
--   Panier moyen en retard    176,16 R$   <- +11 %
--
-- L'ÉCART EST RÉEL MAIS MODESTE. Il explique le décalage
-- 7,47 % / 6,77 % constaté en Q1.
--
-- POUR LA RESTITUTION : quand la direction générale lit
-- « 6,77 % de retards », elle SOUS-ESTIME l'enjeu. Le chiffre
-- à communiquer est 7,47 % DU CA.


-- -- Q2 bis. D'où vient ce surcoût ? -------------------------
-- payment_total se décompose en total_price + total_freight.
-- Trois hypothèses à départager : plus d'articles, articles
-- plus chers, ou frais de port plus élevés.
--
-- Le troisième cas serait le plus informatif : des frais
-- élevés signalent une livraison difficile, ce qui expliquerait
-- à la fois le prix ET le retard.
SELECT
    ROUND(AVG(nb_items)      FILTER (WHERE NOT is_late), 2) AS items_a_lheure,
    ROUND(AVG(nb_items)      FILTER (WHERE is_late), 2)     AS items_en_retard,
    ROUND(AVG(total_price)   FILTER (WHERE NOT is_late), 2) AS price_a_lheure,
    ROUND(AVG(total_price)   FILTER (WHERE is_late), 2)     AS price_en_retard,
    ROUND(AVG(total_freight) FILTER (WHERE NOT is_late), 2) AS freight_a_lheure,
    ROUND(AVG(total_freight) FILTER (WHERE is_late), 2)     AS freight_en_retard
FROM mart.orders;

-- RÉSULTAT
--
--                      À l'heure   En retard   Écart
--   Nombre d'articles     1,14        1,11     −3 %   <-
--   Prix des articles   136,03      150,89    +11 %
--   Frais de port        22,60       25,25    +12 %
--
-- HYPOTHÈSE « PLUS COMPLEXE À PRÉPARER » : ÉCARTÉE.
-- Les commandes en retard ont MOINS d'articles, pas plus.
--
-- CE SONT DES COMMANDES PLUS CHÈRES À L'UNITÉ, avec des frais
-- de port proportionnellement plus élevés (+12 % contre +11 %).
--
-- PISTE : la quasi-proportionnalité entre prix et frais de port
-- suggère des produits plus VOLUMINEUX ou plus LOURDS, donc un
-- transport plus contraignant.
-- PISTE, PAS PREUVE. Trancher demanderait le poids et le
-- volume des produits (staging.products), non testé ici.


-- ============================================================
-- Q3. QUELLE PART S'ACCOMPAGNE D'UN MÉCONTENTEMENT ? (M-07)
-- ============================================================
-- M-06 mesure un RISQUE. M-07 mesure une RÉACTION CLIENT
-- CONSTATÉE : donc plus difficile à contester.
--
-- Le dénominateur est le CA EXPOSÉ (1,15 M), pas le CA total :
-- la question est « sur l'argent exposé, combien s'accompagne
-- d'un mécontentement réel ? »
--
-- is_unsatisfied plutôt que avg_score <= 2 : c'est la colonne
-- créée pour appliquer RG-05. Même résultat, mais garantit que
-- la règle est appliquée telle qu'elle est définie.
SELECT
    ROUND(SUM(payment_total) FILTER (WHERE is_late AND is_unsatisfied), 2) AS CA_late_angry,
    ROUND(SUM(payment_total) FILTER (WHERE is_late), 2)                    AS CA_late,
    ROUND(SUM(payment_total) FILTER (WHERE is_late AND is_unsatisfied)
          / SUM(payment_total) FILTER (WHERE is_late) * 100, 2)            AS percent_late_CA_angry
FROM mart.orders;

-- RÉSULTAT
--
--   CA exposé                       1 150 866 R$
--   CA à risque AVÉRÉ                 721 160 R$
--   PART                                62,66 %
--
-- PRESQUE DEUX TIERS DU CA EXPOSÉ S'ACCOMPAGNENT D'UN
-- MÉCONTENTEMENT EXPRIMÉ.
-- Cohérent avec O3, qui mesurait 80 % d'insatisfaction dès
-- 8 jours de retard.
--
-- CE MONTANT EST UN PLANCHER. Les 646 commandes sans avis
-- (RG-07) sont exclues du numérateur. Certaines étaient
-- probablement des clients mécontents n'ayant pas répondu.
--
-- POUR LA DIRECTION GÉNÉRALE : 721 000 R$ de chiffre
-- d'affaires ont généré un client EXPLICITEMENT mécontent.


-- -- Q3 bis. Le CA exposé au seuil critique de 3 jours -------
-- O3 a établi que la bascule se fait à 3 JOURS : la note passe
-- sous 3 et l'insatisfaction dépasse 50 %.
-- Un CA « exposé » au sens strict devrait donc se limiter aux
-- commandes ayant franchi ce seuil.
SELECT
    ROUND(SUM(payment_total) FILTER (WHERE is_late), 2)  AS ca_expose_1j,
    ROUND(SUM(payment_total) FILTER (WHERE gap >= 3), 2) AS ca_expose_3j,
    ROUND(SUM(payment_total) FILTER (WHERE gap >= 3)
          / SUM(payment_total) * 100, 2)                 AS part_3j_pct
FROM mart.orders;

-- RÉSULTAT
--
--   Retard ≥ 1 jour   1 150 866 R$   7,47 % du CA
--   Retard ≥ 3 jours    932 499 R$   6,05 % du CA
--
-- 81 % DU CA EXPOSÉ CONCERNE DES RETARDS DE 3 JOURS OU PLUS :
-- au-delà du seuil où la majorité des clients bascule.
--
-- CHIFFRE PLUS STRICT ET PLUS DÉFENDABLE : 932 K R$ associés à
-- un retard qui produit STATISTIQUEMENT un mécontentement.
-- À retenir pour la restitution comme mesure conservatrice.


-- ============================================================
-- Q4. CONCENTRATION PAR ÉTAT (M-08)
-- ============================================================
-- Transformer un constat national en cible opérationnelle.
--
-- LE PIÈGE DU VOLUME, POUR LA TROISIÈME FOIS. São Paulo aura
-- le plus gros montant exposé parce qu'il pèse 42 % du
-- périmètre : pas parce qu'il est mauvais. Il faut le montant
-- ET la part.
SELECT
    customer_state,
    SUM(payment_total)                        AS total_CA,
    SUM(payment_total) FILTER (WHERE is_late) AS late_CA,
    ROUND(SUM(payment_total) FILTER (WHERE is_late)
          / SUM(payment_total) * 100, 2)      AS late_CA_rate
FROM mart.orders
GROUP BY customer_state
ORDER BY late_CA_rate DESC;

-- RÉSULTAT : par TAUX décroissant
--
--   État   CA total      CA exposé    Taux
--   AL        94 196        20 964   22,26 %  <- maximum
--   MA       147 807        29 031   19,64 %
--   SE        70 289        12 726   18,10 %
--   RR         9 040         1 454   16,09 %  volume faible
--   CE       266 464        36 919   13,85 %
--   PI       105 272        14 015   13,31 %
--   ES       317 683        40 333   12,70 %
--   BA       591 271        73 541   12,44 %
--   RJ     2 055 579       251 556   12,24 %  <-
--   ...
--   SP     5 766 546       303 157    5,26 %  <-
--   MG     1 818 183        88 243    4,85 %
--   PR       781 920        34 203    4,37 %
--   RO        56 976         1 216    2,13 %  <- minimum
--
-- DEUX LECTURES, DEUX CIBLES
--
-- PAR INTENSITÉ : AL (22,26 %), MA, SE. Plus d'un cinquième du
-- CA d'Alagoas transite par des commandes en retard : MAIS les
-- montants sont faibles (21 K, 29 K, 13 K).
--
-- PAR MONTANT : SP (303 157 R$) et RJ (251 556 R$).
--
-- RJ CUMULE LES DEUX : deuxième montant du pays AVEC un taux
-- de 12,24 %, soit DEUX FOIS ET DEMIE celui de São Paulo.
-- SP expose plus en valeur absolue, mais c'est mécanique : son
-- CA est presque trois fois supérieur, et son taux reste parmi
-- les meilleurs du pays.
--
-- -> RJ EST LA CIBLE PRIORITAIRE EN VOLUME (O1) ET EN MONTANT
--   (O4). L'arbitrage tient sur les deux dimensions.
--
-- CONCENTRATION : SP + RJ = 554 713 R$, soit 48 % DU CA EXPOSÉ.
-- Deux états sur vingt-sept concentrent la moitié de l'enjeu.
--
-- NOTE DE MÉTHODE : la comparaison se fait À L'INTÉRIEUR de
-- chaque état, ce qui neutralise l'effet distance : deux
-- commandes du même état ont des frais de port comparables.
-- Cette requête HIÉRARCHISE, elle n'explique pas.


-- ============================================================
-- Q5. CONCENTRATION PAR VENDEUR (M-08)
-- ============================================================
-- Quelques vendeurs concentrent-ils l'enjeu, ou est-ce
-- dispersé ? C'est le livrable attendu par la direction des
-- partenariats.
--
-- RG-09 OBLIGATOIRE (WHERE nb_sellers = 1) : sans ce filtre,
-- une commande à 150 R$ servie par deux vendeurs serait
-- comptée 150 R$ CHEZ CHACUN. Le CA serait compté en double et
-- la somme des vendeurs dépasserait le CA réel.
--
-- COALESCE(..., 0) : quand un vendeur n'a AUCUNE commande en
-- retard, SUM(...) FILTER porte sur un ensemble VIDE et renvoie
-- NULL : pas 0. Sans COALESCE, la colonne reste vide au lieu
-- d'afficher zéro.
--
-- COUNT(DISTINCT oi.order_id) et non COUNT(oi.order_id) :
-- ce dernier compterait les ARTICLES, pas les commandes. Un
-- vendeur avec 5 commandes de 2 articles passerait le seuil.
SELECT
    seller_id,
    SUM(payment_total)                                        AS total_CA,
    COALESCE(SUM(payment_total) FILTER (WHERE is_late), 0)    AS late_CA,
    ROUND(COALESCE(SUM(payment_total) FILTER (WHERE is_late), 0)
          / SUM(payment_total) * 100, 2)                      AS late_CA_rate
FROM mart.orders AS mo
LEFT JOIN staging.order_items AS oi ON mo.order_id = oi.order_id
WHERE mo.nb_sellers = 1
GROUP BY seller_id
HAVING COUNT(DISTINCT oi.order_id) >= 10
ORDER BY total_CA DESC;

-- RÉSULTAT : AUCUNE CONCENTRATION
--
-- Le plus gros vendeur pèse 497 775 R$ de CA total mais
-- seulement 40 065 R$ exposés : soit 3,5 % du CA exposé
-- national. AUCUN VENDEUR NE DÉPASSE 4 % DE L'ENJEU.
--
-- CONTRASTE AVEC Q4 :
--   Par état    -> SP + RJ = 48 % du CA exposé
--   Par vendeur -> aucun ne dépasse 4 %
--
-- -> LE PROBLÈME EST GÉOGRAPHIQUE, PAS VENDEUR.
--   Cohérent avec O2 : le retard vient du transport, et le
--   transport dépend de la DESTINATION, pas de qui expédie.
--
-- CAS INDIVIDUELS EXTRÊMES
--
--   Vendeur      CA total   CA exposé   Taux
--   b1b39487…      21 924     18 308   83,51 %  <-
--   2709af95…       5 796      4 206   72,57 %
--   0d85bbda…      11 374      6 211   54,61 %
--
-- b1b39487 RÉAPPARAÎT POUR LA TROISIÈME FOIS : déjà identifié
-- en O2 sur la préparation (64 %) et sur le dépassement
-- contractuel. Trois angles indépendants convergent.
-- MAIS son enjeu financier reste faible : 18 308 R$, soit
-- 1,6 % du CA exposé national.
--
-- DISTINCTION À MAINTENIR :
--   Au niveau du VENDEUR  -> l'impact est massif (83 % de son CA)
--   Au niveau NATIONAL    -> négligeable (1,6 % de l'enjeu)
-- Régler totalement son cas ne ferait pas bouger le global.


-- ============================================================
-- Q6. CONCENTRATION PAR CATÉGORIE (M-08)
-- ============================================================
-- Certaines catégories sont-elles plus touchées ? Si oui, par
-- exemple les produits volumineux, cela donnerait un levier
-- logistique concret, et recouperait la piste ouverte en Q2 bis.
--
-- La catégorie est au grain PRODUIT : double jointure via
-- order_items puis products.
--
-- DEUX COALESCE, DEUX RÔLES DIFFÉRENTS :
--   sur la catégorie -> nommer les valeurs manquantes plutôt
--     que les perdre (1 392 commandes sans catégorie)
--   sur le montant   -> remplacer NULL par 0
-- Ne pas confondre : on ne remplace pas un montant par du
-- texte.
SELECT
    COALESCE(product_category_name, 'Non renseigne')          AS category,
    SUM(payment_total)                                        AS total_CA,
    COALESCE(SUM(payment_total) FILTER (WHERE is_late), 0)    AS late_CA,
    ROUND(COALESCE(SUM(payment_total) FILTER (WHERE is_late), 0)
          / SUM(payment_total) * 100, 2)                      AS late_CA_rate
FROM mart.orders AS mo
LEFT JOIN staging.order_items AS soi ON mo.order_id  = soi.order_id
LEFT JOIN staging.products    AS sp  ON sp.product_id = soi.product_id
WHERE mo.nb_sellers = 1
GROUP BY product_category_name
ORDER BY total_CA DESC;

-- RÉSULTAT : LES GRANDES CATÉGORIES SONT TOUTES À 6-9 %
--
--   Catégorie              CA total    CA exposé   Taux
--   beleza_saude          1 591 475      122 158   7,68 %
--   cama_mesa_banho       1 511 495      114 432   7,57 %
--   informatica_acess.    1 453 179      107 538   7,40 %
--   relogios_presentes    1 348 112      103 453   7,67 %
--   esporte_lazer         1 294 756       90 043   6,95 %
--   moveis_decoracao      1 274 822      107 806   8,46 %
--   utilidades_domest.    1 019 928       56 711   5,56 %
--   automotivo              816 969       78 052   9,55 %
--   Non renseigne           226 825       20 958   9,24 %
--
-- L'ÉCART ENTRE LA MEILLEURE ET LA PIRE DES GRANDES CATÉGORIES
-- EST DE 3 POINTS.
-- À comparer aux états de plus de 500 commandes : de 4,38 % à
-- 19,64 %, soit PLUS DE 15 POINTS.
--
-- -> LA CATÉGORIE N'EXPLIQUE PAS LE RETARD. Confirme O2 : le
--   problème est le transport, qui dépend de la destination,
--   pas du produit.
--
-- Les taux extrêmes (0,00 % ou 34 %) concernent tous des
-- catégories à moins de 20 000 R$ de CA. Trop peu de commandes
-- pour être fiables : même logique que le seuil RG-08.


-- -- Q6 bis. Le cas « artigos_de_natal » ---------------------
-- Les articles de Noël affichent 34,57 % de CA exposé, trois
-- fois la moyenne. Explication saisonnière : vente concentrée
-- en fin d'année, donc pendant le Black Friday et le pic de
-- décembre identifiés en O1 ?
SELECT
    mo.purchase_year,
    mo.purchase_month,
    COUNT(DISTINCT mo.order_id)                           AS nb_commandes,
    COUNT(DISTINCT mo.order_id) FILTER (WHERE mo.is_late) AS nb_late,
    ROUND(AVG(mo.is_late::INT) * 100, 2)                  AS late_rate
FROM mart.orders AS mo
JOIN staging.order_items AS soi ON mo.order_id  = soi.order_id
JOIN staging.products    AS sp  ON sp.product_id = soi.product_id
WHERE sp.product_category_name = 'artigos_de_natal'
GROUP BY mo.purchase_year, mo.purchase_month
ORDER BY mo.purchase_year, mo.purchase_month;

-- RÉSULTAT : L'HYPOTHÈSE DE NOËL EST ÉCARTÉE
--
--   Mois       Commandes  En retard  Taux
--   2017-10        7          0       0,00 %
--   2017-11       18          2       9,09 %
--   2017-12       14          0       0,00 %  <- Noël : AUCUN retard
--   2018-01        9          0       0,00 %
--   2018-02       17          4      37,50 %  <- incident O1
--   2018-03       12          3      25,00 %  <- incident O1
--   2018-07        8          1      12,50 %
--
-- DÉCEMBRE 2017 : 14 COMMANDES, ZÉRO RETARD. La période de
-- Noël est parfaitement servie.
--
-- LES RETARDS SE CONCENTRENT EN FÉVRIER-MARS 2018 : c'est
-- L'INCIDENT NATIONAL identifié en O1, pas un effet de la
-- catégorie.
--
-- ET SURTOUT : 7 commandes en retard sur 125 au total. Le taux
-- de 34,57 % en CA venait de QUELQUES COMMANDES CHÈRES, pas
-- d'un phénomène. Piège classique du petit effectif.


-- ============================================================
-- SYNTHÈSE O4
-- ============================================================
--  1. CA EXPOSÉ : 1 150 866 R$, soit 7,47 % du CA total
--  2. L'exposition FINANCIÈRE dépasse l'exposition en VOLUME
--     (7,47 % contre 6,77 %) : les commandes en retard sont
--     11 % plus chères
--  3. L'origine du surcoût : ni le nombre d'articles (qui
--     BAISSE de 3 %) ni la complexité, mais des produits plus
--     chers avec des frais de port plus élevés (+12 %)
--  4. CA À RISQUE AVÉRÉ : 721 160 R$, soit 62,66 % du CA
--     exposé, s'accompagne d'un mécontentement exprimé.
--     Ce montant est un PLANCHER
--  5. AU SEUIL CRITIQUE DE 3 JOURS (O3) : 932 499 R$, soit
--     81 % du CA exposé : mesure conservatrice
--  6. RJ EST LA CIBLE PRIORITAIRE EN MONTANT comme en volume :
--     251 556 R$ exposés, taux de 12,24 % : deux fois et demie
--     celui de SP
--  7. SP + RJ = 48 % DU CA EXPOSÉ. Deux états concentrent la
--     moitié de l'enjeu
--  8. AUCUNE CONCENTRATION PAR VENDEUR, aucun ne dépasse 4 %
--  9. AUCUN EFFET DE CATÉGORIE, 3 points d'écart entre les
--     grandes catégories, contre plus de 15 entre les grands états
--
-- CONCLUSION TRANSVERSALE : l'enjeu financier est
-- GÉOGRAPHIQUE. Ni le vendeur ni le produit ne le structurent.
-- L'action doit porter sur l'acheminement, en ciblant RJ.
-- ============================================================