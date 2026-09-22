-- ============================================================
-- O5 — LA TRAJECTOIRE VENDEUR
-- ============================================================
-- Objectif : tester l'existence d'un lien entre la performance
-- de livraison d'un vendeur et l'évolution de son activité.
--
-- Source     : mart.orders + staging.order_items
-- Métriques  : M-09 (taux de retard P1), M-10 (évolution P1→P2)
-- Règles     : RG-08 (seuil), RG-09 (mono-vendeur), RG-10 (fenêtres)
-- Constats   : 06_O5_constats.md
--
-- GRAIN : UNE LIGNE PAR COMMANDE. staging.order_items est au
-- grain ARTICLE ; la CTE order_seller en extrait un couple
-- (commande, vendeur) unique. Sans elle, une commande de 3
-- articles compterait 3 fois dans les effectifs, les taux et le
-- seuil de 10 commandes (8 359 commandes mono-vendeur ont
-- plusieurs articles).
--
-- POURQUOI CET OBJECTIF EXISTE : le projet a perdu son objectif
-- initial en qualification. Avec 3,12 % de réachat (H1), on ne
-- peut pas mesurer si un client déçu revient. O5 est le
-- remplacement — faute d'observer le CLIENT, on observe le
-- VENDEUR, qui lui a un historique.
--
-- ENJEU — deux réponses, deux recommandations opposées :
--   Si l'activité recule  → le marché sanctionne seul, Olist
--                           peut se contenter d'alerter
--   Si elle ne bouge pas  → le marché ne sanctionne pas, Olist
--                           doit intervenir activement
-- UN RÉSULTAT NÉGATIF EST DONC UN RÉSULTAT.


-- ============================================================
-- Q1 — OÙ COUPER LES DEUX FENÊTRES ? (RG-10)
-- ============================================================
SELECT
    purchase_year,
    purchase_month,
    COUNT(*) AS total_orders
FROM mart.orders
GROUP BY purchase_year, purchase_month
ORDER BY purchase_year, purchase_month;

-- RÉSULTAT — la plateforme a TRIPLÉ son activité en un an.
--
-- Cela complique le découpage : si on coupe au milieu, la
-- période 2 aura mécaniquement plus de commandes, et TOUS les
-- vendeurs sembleront progresser — même les mauvais.
--
-- DÉCOUPAGE RETENU — février-août 2017 vs février-août 2018.
-- Mêmes mois d'une année sur l'autre : la SAISONNALITÉ est
-- neutralisée (Black Friday de novembre identifié en O1).
--
-- ET SURTOUT : on ne compare pas les volumes bruts mais la
-- performance RELATIVE AU MARCHÉ.


-- ── Q1 bis. La référence du marché ──────────────────────────
-- Sans ce repère, toute croissance positive serait lue comme un
-- succès. Même filtre RG-09 que pour les vendeurs, sinon la
-- référence ne serait pas comparable.
SELECT
    COUNT(*) FILTER (WHERE purchase_year = 2017
                       AND purchase_month BETWEEN 2 AND 8) AS marche_p1,
    COUNT(*) FILTER (WHERE purchase_year = 2018
                       AND purchase_month BETWEEN 2 AND 8) AS marche_p2,
    ROUND((COUNT(*) FILTER (WHERE purchase_year = 2018 AND purchase_month BETWEEN 2 AND 8)
         - COUNT(*) FILTER (WHERE purchase_year = 2017 AND purchase_month BETWEEN 2 AND 8))
         * 100.0
         / COUNT(*) FILTER (WHERE purchase_year = 2017 AND purchase_month BETWEEN 2 AND 8), 2)
        AS croissance_marche_pct
FROM mart.orders
WHERE nb_sellers = 1;

-- RÉSULTAT : 21 033 → 45 016 commandes, soit +114,03 %
--
-- LE MARCHÉ A PLUS QUE DOUBLÉ. Un vendeur à +50 % a donc PERDU
-- DES PARTS. C'est le repère de lecture de tout O5.


-- ============================================================
-- Q2 à Q4 — LES VENDEURS PRÉSENTS DANS LES DEUX FENÊTRES
-- ============================================================
-- TROIS RÈGLES SE CUMULENT :
--   RG-09 — WHERE nb_sellers = 1
--   RG-08 — au moins 10 commandes DANS CHAQUE fenêtre
--   RG-10 — présent dans les deux
--
-- LE TAUX DE RETARD EST MESURÉ EN P1 SEULEMENT : c'est la CAUSE
-- présumée. Mesurer P2 aussi mélangerait cause et conséquence.
--
-- ⚠ order_p1 et order_p2 sont des ENTIERS : sans le * 100.0,
-- la division entière donnerait 0 partout.
WITH order_seller AS (
    -- Une ligne par commande mono-vendeur (voir en-tête)
    SELECT DISTINCT oi.order_id, oi.seller_id
    FROM staging.order_items AS oi
    JOIN mart.orders AS m ON m.order_id = oi.order_id
    WHERE m.nb_sellers = 1
),
calcul AS (
    SELECT
        seller_id,
        COUNT(*) FILTER (WHERE purchase_year = 2017
                           AND purchase_month BETWEEN 2 AND 8) AS order_phase1,
        AVG(is_late::INT) FILTER (WHERE purchase_year = 2017
                           AND purchase_month BETWEEN 2 AND 8) AS rate_late_p1,
        COUNT(*) FILTER (WHERE purchase_year = 2018
                           AND purchase_month BETWEEN 2 AND 8) AS order_phase2,
        AVG(is_late::INT) FILTER (WHERE purchase_year = 2018
                           AND purchase_month BETWEEN 2 AND 8) AS rate_late_p2
    FROM order_seller AS soi
    JOIN mart.orders AS mo ON mo.order_id = soi.order_id
    WHERE nb_sellers = 1
    GROUP BY seller_id
    HAVING COUNT(*) FILTER (WHERE purchase_year = 2017
                              AND purchase_month BETWEEN 2 AND 8) >= 10
       AND COUNT(*) FILTER (WHERE purchase_year = 2018
                              AND purchase_month BETWEEN 2 AND 8) >= 10
)
SELECT
    seller_id,
    order_phase1,
    ROUND(rate_late_p1 * 100, 2) AS taux_retard_p1,
    order_phase2,
    ROUND(rate_late_p2 * 100, 2) AS taux_retard_p2,
    ROUND((order_phase2 - order_phase1) * 100.0 / order_phase1, 2) AS evolution_pct
FROM calcul
ORDER BY evolution_pct;

-- RÉSULTAT — 241 VENDEURS survivent au filtre
--
-- Sur 1 217 vendeurs retenus par RG-08 sur l'ensemble de la
-- période, exiger 10 commandes DANS CHACUNE des deux fenêtres
-- en élimine 80 %. Ces 241 sont les vendeurs ÉTABLIS ET
-- DURABLES — c'est le biais de survie annoncé par RG-10,
-- mesuré en Q6.
--
-- LES PLUS GROS RECULS
--   cca3071e…   363 →  45   −87,60 %   retard P1 : 3,58 %
--   6cd68b3e…    67 →  11   −83,58 %   retard P1 : 0,00 %  ←
--   44073f8b…    66 →  11   −83,33 %   retard P1 : 0,00 %  ←
--
-- LES PLUS FORTES CROISSANCES
--   ea8482cd…    12 → 618  +5 050 %    retard P1 : 0,00 %
--   955fee92…    27 → 845  +3 030 %    retard P1 : 0,00 %
--   1025f0e2…    30 → 602  +1 907 %    retard P1 : 3,33 %
--
-- LES TAUX DE RETARD SONT FAIBLES DES DEUX CÔTÉS. Des vendeurs
-- à 0 % de retard perdent 84 % de leur activité ; d'autres à
-- 0 % en gagnent 5 000 %.
--
-- ⚠ LIRE UN TABLEAU À L'ŒIL N'EST PAS UNE PREUVE. Quantifié
-- en Q5.


-- ============================================================
-- Q5 — EXISTE-T-IL UN LIEN ENTRE RETARD ET TRAJECTOIRE ?
-- ============================================================
-- Deux moyennes donnent un chiffre OPPOSABLE, là où la lecture
-- d'un tableau ne donne qu'une impression.
--
-- LE SEUIL EST +114 %, PAS 0 %. Le marché ayant doublé, un
-- vendeur qui croît de 50 % perd des parts. Définir « recul »
-- par une croissance négative serait faux.
WITH order_seller AS (
    -- Une ligne par commande mono-vendeur (voir en-tête)
    SELECT DISTINCT oi.order_id, oi.seller_id
    FROM staging.order_items AS oi
    JOIN mart.orders AS m ON m.order_id = oi.order_id
    WHERE m.nb_sellers = 1
),
calcul AS (
    SELECT
        seller_id,
        COUNT(*) FILTER (WHERE purchase_year = 2017
                           AND purchase_month BETWEEN 2 AND 8) AS order_p1,
        AVG(is_late::INT) FILTER (WHERE purchase_year = 2017
                           AND purchase_month BETWEEN 2 AND 8) AS retard_p1,
        COUNT(*) FILTER (WHERE purchase_year = 2018
                           AND purchase_month BETWEEN 2 AND 8) AS order_p2
    FROM order_seller AS soi
    JOIN mart.orders AS mo ON mo.order_id = soi.order_id
    WHERE nb_sellers = 1
    GROUP BY seller_id
    HAVING COUNT(*) FILTER (WHERE purchase_year = 2017
                              AND purchase_month BETWEEN 2 AND 8) >= 10
       AND COUNT(*) FILTER (WHERE purchase_year = 2018
                              AND purchase_month BETWEEN 2 AND 8) >= 10
),
groupes AS (
    SELECT
        seller_id,
        retard_p1,
        (order_p2 - order_p1) * 100.0 / order_p1 AS evolution,
        CASE
            WHEN (order_p2 - order_p1) * 100.0 / order_p1 >= 114
                THEN 'Surperforme le marche'
            ELSE 'Sous-performe le marche'
        END AS groupe
    FROM calcul
)
SELECT
    groupe,
    COUNT(*)                       AS nb_vendeurs,
    ROUND(AVG(retard_p1) * 100, 2) AS retard_p1_moyen,
    ROUND(AVG(evolution), 2)       AS evolution_moyenne
FROM groupes
GROUP BY groupe;

-- RÉSULTAT
--
--   Groupe                 Vendeurs  Retard P1  Évolution
--   Sous-performe            181       3,11 %    −13,17 %
--   Surperforme               60       2,99 %   +413,78 %
--
-- LES DEUX GROUPES ONT UN TAUX DE RETARD IDENTIQUE.
-- 0,12 point d'écart — du bruit, sans portée.
--
-- → LE RETARD N'A AUCUN EFFET MESURABLE SUR LA TRAJECTOIRE
--   D'UN VENDEUR.
--
-- À NOTER : 181 vendeurs sur 241, soit 75 %, PERDENT DES PARTS
-- DE MARCHÉ. Dans une plateforme qui double, les trois quarts
-- des vendeurs établis reculent relativement.
--
-- CONCLUSION PROVISOIRE : le marché ne sanctionne pas.
-- ⚠ CORRIGÉE PAR Q6.


-- ============================================================
-- Q6 — LE BIAIS DE SURVIE
-- ============================================================
-- Q5 ne porte que sur les vendeurs PRÉSENTS DANS LES DEUX
-- PÉRIODES. Ceux qui ont cessé leur activité en sont absents —
-- et ce sont peut-être les plus affectés.
--
-- ⚠ LE HAVING NE PORTE PLUS QUE SUR P1. Filtrer aussi sur P2
-- éliminerait d'office les disparus — exactement ce qu'on
-- cherche à mesurer.
--
-- DÉFINITION : « disparu » = ZÉRO commande en P2. Un vendeur
-- passé sous 10 commandes n'a pas disparu, il s'est contracté.
WITH order_seller AS (
    -- Une ligne par commande mono-vendeur (voir en-tête)
    SELECT DISTINCT oi.order_id, oi.seller_id
    FROM staging.order_items AS oi
    JOIN mart.orders AS m ON m.order_id = oi.order_id
    WHERE m.nb_sellers = 1
),
cte AS (
    SELECT
        seller_id,
        COUNT(*) FILTER (WHERE purchase_year = 2017
                           AND purchase_month BETWEEN 2 AND 8) AS order_p1,
        AVG(is_late::INT) FILTER (WHERE purchase_year = 2017
                           AND purchase_month BETWEEN 2 AND 8) AS retard_p1,
        COUNT(*) FILTER (WHERE purchase_year = 2018
                           AND purchase_month BETWEEN 2 AND 8) AS order_p2
    FROM order_seller AS soi
    JOIN mart.orders AS mo ON mo.order_id = soi.order_id
    WHERE nb_sellers = 1
    GROUP BY seller_id
    HAVING COUNT(*) FILTER (WHERE purchase_year = 2017
                              AND purchase_month BETWEEN 2 AND 8) >= 10
)
SELECT
    CASE
        WHEN order_p2 = 0 THEN 'disparu'
        ELSE 'survivant'
    END AS etat,
    COUNT(*)                       AS nb_sellers_by_grp,
    ROUND(AVG(retard_p1) * 100, 2) AS avg_retard_p1
FROM cte
GROUP BY etat;

-- RÉSULTAT
--
--   Groupe        Vendeurs   Retard P1
--   Disparus          81       4,76 %   ←
--   Survivants       316       3,38 %
--
-- LES DISPARUS AVAIENT 41 % DE RETARD EN PLUS.
-- L'écart est NET — contrairement aux 0,12 point de Q5.
--
-- → LA SANCTION EXISTE, MAIS ELLE EST BINAIRE :
--     Parmi les survivants    → aucun effet (3,11 % vs 2,99 %)
--     Survivants vs disparus  → écart net (3,38 % vs 4,76 %)
--
--   Un vendeur qui livre mal NE RECULE PAS PROGRESSIVEMENT.
--   IL DISPARAÎT.
--
-- LE BIAIS ANNONCÉ AU CADRAGE ÉTAIT RÉEL. Q5 concluait à
-- l'absence de lien alors que le lien existe — il était
-- invisible parce que les plus touchés avaient déjà quitté
-- l'échantillon.


-- ============================================================
-- Q7 — RECOUPEMENT AVEC O2 : L'ENGAGEMENT CONTRACTUEL
-- ============================================================
-- O2 a identifié les vendeurs dépassant leur shipping_limit_date
-- — la date limite d'expédition imposée par Olist.
--
-- POURQUOI CET INDICATEUR PLUTÔT QUE LE TAUX DE RETARD :
--   • il isole la PART DU VENDEUR (segment préparation), sans
--     mélange avec le transport
--   • il est OPPOSABLE : un vendeur peut contester un retard
--     (« c'est le transporteur »), pas un dépassement de sa
--     propre date limite
--   • il est connu DÈS L'EXPÉDITION, pas à la livraison
--
-- QUESTION : ces vendeurs disparaissent-ils davantage ?
--
-- is_limit_exceeded est désormais une colonne de mart.orders
-- (date limite la plus tôt de la commande, MIN).
WITH order_seller AS (
    -- Une ligne par commande mono-vendeur (voir en-tête)
    SELECT DISTINCT oi.order_id, oi.seller_id
    FROM staging.order_items AS oi
    JOIN mart.orders AS m ON m.order_id = oi.order_id
    WHERE m.nb_sellers = 1
),
activite AS (
    SELECT
        soi.seller_id,
        COUNT(*) FILTER (WHERE mo.purchase_year = 2018
                           AND mo.purchase_month BETWEEN 2 AND 8) AS order_p2,
        AVG(mo.is_limit_exceeded::INT)
            FILTER (WHERE mo.purchase_year = 2017
                      AND mo.purchase_month BETWEEN 2 AND 8) AS taux_depassement_p1
    FROM order_seller AS soi
    JOIN mart.orders AS mo ON mo.order_id = soi.order_id
    WHERE mo.nb_sellers = 1
      AND mo.order_delivered_carrier_date IS NOT NULL
    GROUP BY soi.seller_id
    HAVING COUNT(*) FILTER (WHERE mo.purchase_year = 2017
                              AND mo.purchase_month BETWEEN 2 AND 8) >= 10
)
SELECT
    CASE
        WHEN taux_depassement_p1 > 0.20 THEN 'Depassement > 20%'
        ELSE 'Depassement <= 20%'
    END AS profil,
    COUNT(*)                                   AS nb_vendeurs,
    COUNT(*) FILTER (WHERE order_p2 = 0)       AS nb_disparus,
    ROUND(COUNT(*) FILTER (WHERE order_p2 = 0) * 100.0 / COUNT(*), 2)
                                               AS taux_disparition_pct,
    ROUND(AVG(taux_depassement_p1) * 100, 2)   AS depassement_moyen_pct
FROM activite
GROUP BY profil;

-- RÉSULTAT
--
--   Profil                Vendeurs  Disparus  Taux disparition  Dépassement moyen
--   Dépassement ≤ 20 %      340        65         19,12 %            4,13 %
--   Dépassement > 20 %       57        16         28,07 %           36,93 %  ←
--
-- LES VENDEURS QUI NE TIENNENT PAS LEUR ENGAGEMENT
-- CONTRACTUEL DISPARAISSENT 47 % PLUS SOUVENT.
-- Prudence : petits effectifs (57 vendeurs, 16 disparus).
--
-- ET LES DEUX GROUPES NE SE RESSEMBLENT PAS : 36,93 % de
-- dépassement moyen contre 4,13 %. Ce sont deux comportements
-- distincts, pas deux nuances d'un même profil.
--
-- → LE DÉPASSEMENT DE LA DATE LIMITE EST UN SIGNAL D'ALERTE
--   EXPLOITABLE, et meilleur que le taux de retard :
--
--     Taux de retard    → connu à la LIVRAISON, des semaines
--                         plus tard, et mélange les causes
--     Dépassement       → connu DÈS L'EXPÉDITION, et impute
--                         sans ambiguïté


-- ============================================================
-- Q8 — LA DÉGRADATION EST-ELLE PROGRESSIVE OU BRUTALE ?
-- ============================================================
-- Si le taux de dépassement se dégrade AVANT le départ, Olist
-- dispose d'une fenêtre d'intervention.
-- S'il est stable, le départ n'est précédé d'aucun signal.
--
-- P1 est découpée en deux moitiés : février-avril et
-- juin-août. Mai est écarté pour séparer nettement les blocs.
--
-- ⚠ SEUIL ABAISSÉ À 5 COMMANDES par demi-période — sinon trop
-- peu de vendeurs survivraient au découpage.
WITH order_seller AS (
    -- Une ligne par commande mono-vendeur (voir en-tête)
    SELECT DISTINCT oi.order_id, oi.seller_id
    FROM staging.order_items AS oi
    JOIN mart.orders AS m ON m.order_id = oi.order_id
    WHERE m.nb_sellers = 1
),
activite AS (
    SELECT
        soi.seller_id,
        COUNT(*) FILTER (WHERE mo.purchase_year = 2018
                           AND mo.purchase_month BETWEEN 2 AND 8) AS order_p2,
        AVG(mo.is_limit_exceeded::INT)
            FILTER (WHERE mo.purchase_year = 2017
                      AND mo.purchase_month BETWEEN 2 AND 4) AS depassement_debut,
        AVG(mo.is_limit_exceeded::INT)
            FILTER (WHERE mo.purchase_year = 2017
                      AND mo.purchase_month BETWEEN 6 AND 8) AS depassement_fin
    FROM order_seller AS soi
    JOIN mart.orders AS mo ON mo.order_id = soi.order_id
    WHERE mo.nb_sellers = 1
      AND mo.order_delivered_carrier_date IS NOT NULL
    GROUP BY soi.seller_id
    HAVING COUNT(*) FILTER (WHERE mo.purchase_year = 2017
                              AND mo.purchase_month BETWEEN 2 AND 4) >= 5
       AND COUNT(*) FILTER (WHERE mo.purchase_year = 2017
                              AND mo.purchase_month BETWEEN 6 AND 8) >= 5
)
SELECT
    CASE WHEN order_p2 = 0 THEN 'Disparu' ELSE 'Survivant' END AS etat,
    COUNT(*)                                     AS nb_vendeurs,
    ROUND(AVG(depassement_debut) * 100, 2)       AS depassement_fev_avr,
    ROUND(AVG(depassement_fin) * 100, 2)         AS depassement_juin_aout,
    ROUND((AVG(depassement_fin) - AVG(depassement_debut)) * 100, 2) AS evolution_pts
FROM activite
GROUP BY etat;

-- RÉSULTAT
--
--   Groupe      Vendeurs  Fév-avr  Juin-août  Évolution
--   Disparus       27      15,53 %   12,79 %   −2,74 pts  ←
--   Survivants    183       7,29 %    7,08 %   −0,20 pt
--
-- AUCUNE DÉGRADATION N'ANNONCE LE DÉPART. Les deux groupes
-- restent à peu près stables : −2,74 points sur 27 vendeurs ne
-- permettent pas de conclure à une tendance.
--
-- LE NIVEAU, EN REVANCHE, SÉPARE NETTEMENT LES GROUPES :
-- 15,53 % contre 7,29 % dès février-avril 2017. DEUX FOIS PLUS,
-- six mois avant le départ.
--
-- Prudence : seuls 27 disparus sur 81 passent le filtre des 5
-- commandes par demi-période. Ceux partis brutalement, sans
-- commandes en fin de P1, sont exclus de ce test.
--
-- → LA RECOMMANDATION CHANGE DE FORME :
--   ce n'est pas « surveillez la PENTE », c'est
--   « surveillez le NIVEAU ».
--   C'est même préférable pour Olist — un niveau se lit
--   immédiatement, une tendance demande des mois d'observation.


-- ============================================================
-- SYNTHÈSE O5
-- ============================================================
--  1. LE MARCHÉ A DOUBLÉ (+114 %) entre les deux fenêtres —
--     tout vendeur sous ce seuil perd des parts
--  2. 241 VENDEURS seulement sont présents dans les deux
--     périodes avec au moins 10 commandes (sur 1 217)
--  3. PARMI EUX, LE RETARD N'A AUCUN EFFET : 3,11 % chez ceux
--     qui reculent, 2,99 % chez ceux qui progressent
--  4. 75 % DES VENDEURS ÉTABLIS PERDENT DES PARTS DE MARCHÉ
--  5. MAIS LES DISPARUS AVAIENT 4,76 % DE RETARD contre 3,38 %
--     pour les survivants — 41 % de plus
--  6. LA SANCTION EST BINAIRE : un vendeur qui livre mal ne
--     recule pas, IL DISPARAÎT
--  7. LES VENDEURS DÉPASSANT LEUR DATE LIMITE D'EXPÉDITION
--     DISPARAISSENT 47 % PLUS SOUVENT (28,07 % contre 19,12 %)
--  8. LE SIGNAL EST DANS LE NIVEAU, PAS DANS LA PENTE :
--     15,53 % de dépassement six mois avant le départ, contre
--     7,29 % pour les survivants
--
-- CONSÉQUENCE POUR LA RECOMMANDATION
-- Le marché sanctionne, mais tardivement et brutalement —
-- quand le vendeur est déjà perdu. Olist ne peut pas compter
-- sur cette autorégulation : elle doit INTERVENIR EN AMONT.
-- Le dépassement de shipping_limit_date fournit l'indicateur :
-- disponible dès l'expédition, imputable sans ambiguïté, et
-- prédictif du départ.
--
-- ENSEIGNEMENT DE MÉTHODE
-- Q5 seule aurait conclu « aucun lien ». C'est Q6 qui révèle
-- que le lien existait, masqué par la composition de
-- l'échantillon. Une analyse qui ne teste pas ce qu'elle ne
-- voit pas produit une conclusion fausse.
-- ============================================================