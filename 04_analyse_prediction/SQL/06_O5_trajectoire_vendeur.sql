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
WITH calcul AS (
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
    FROM mart.orders AS mo
    LEFT JOIN staging.order_items AS soi ON soi.order_id = mo.order_id
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

-- RÉSULTAT — 253 VENDEURS survivent au filtre
--
-- Sur 1 323 vendeurs retenus par RG-08 sur l'ensemble de la
-- période, exiger 10 commandes DANS CHACUNE des deux fenêtres
-- en élimine 81 %. Ces 253 sont les vendeurs ÉTABLIS ET
-- DURABLES — c'est le biais de survie annoncé par RG-10,
-- mesuré en Q6.
--
-- LES PLUS GROS RECULS
--   cca3071e…   427 →  49   −88,52 %   retard P1 : 3,51 %
--   6cd68b3e…    71 →  11   −84,51 %   retard P1 : 0,00 %  ←
--   44073f8b…    70 →  11   −84,29 %   retard P1 : 0,00 %  ←
--
-- LES PLUS FORTES CROISSANCES
--   ea8482cd…    12 → 643  +5 258 %    retard P1 : 0,00 %
--   955fee92…    33 → 992  +2 906 %    retard P1 : 0,00 %
--   1025f0e2…    53 → 886  +1 572 %    retard P1 : 1,89 %
--
-- LES TAUX DE RETARD SONT FAIBLES DES DEUX CÔTÉS. Des vendeurs
-- à 0 % de retard perdent 85 % de leur activité ; d'autres à
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
WITH calcul AS (
    SELECT
        seller_id,
        COUNT(*) FILTER (WHERE purchase_year = 2017
                           AND purchase_month BETWEEN 2 AND 8) AS order_p1,
        AVG(is_late::INT) FILTER (WHERE purchase_year = 2017
                           AND purchase_month BETWEEN 2 AND 8) AS retard_p1,
        COUNT(*) FILTER (WHERE purchase_year = 2018
                           AND purchase_month BETWEEN 2 AND 8) AS order_p2
    FROM mart.orders AS mo
    LEFT JOIN staging.order_items AS soi ON soi.order_id = mo.order_id
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
--   Sous-performe            190       3,06 %    −11,05 %
--   Surperforme               63       3,36 %   +419,46 %
--
-- LES DEUX GROUPES ONT UN TAUX DE RETARD IDENTIQUE.
-- 0,3 point d'écart — du bruit. Et dans le sens INVERSE de
-- l'attendu.
--
-- → LE RETARD N'A AUCUN EFFET MESURABLE SUR LA TRAJECTOIRE
--   D'UN VENDEUR.
--
-- À NOTER : 190 vendeurs sur 253, soit 75 %, PERDENT DES PARTS
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
WITH cte AS (
    SELECT
        seller_id,
        COUNT(*) FILTER (WHERE purchase_year = 2017
                           AND purchase_month BETWEEN 2 AND 8) AS order_p1,
        AVG(is_late::INT) FILTER (WHERE purchase_year = 2017
                           AND purchase_month BETWEEN 2 AND 8) AS retard_p1,
        COUNT(*) FILTER (WHERE purchase_year = 2018
                           AND purchase_month BETWEEN 2 AND 8) AS order_p2
    FROM mart.orders AS mo
    LEFT JOIN staging.order_items AS soi ON soi.order_id = mo.order_id
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
--   Disparus          96       5,40 %   ←
--   Survivants       331       3,52 %
--
-- LES DISPARUS AVAIENT 53 % DE RETARD EN PLUS.
-- L'écart est NET — contrairement aux 0,3 point de Q5.
--
-- → LA SANCTION EXISTE, MAIS ELLE EST BINAIRE :
--     Parmi les survivants    → aucun effet (3,06 % vs 3,36 %)
--     Survivants vs disparus  → écart net (3,52 % vs 5,40 %)
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
-- Le CASE WHEN ... THEN 1 ELSE 0 remplace is_late::INT — il
-- n'existe pas de colonne booléenne pour le dépassement, il
-- faut la construire.
WITH activite AS (
    SELECT
        soi.seller_id,
        COUNT(*) FILTER (WHERE mo.purchase_year = 2018
                           AND mo.purchase_month BETWEEN 2 AND 8) AS order_p2,
        AVG(CASE WHEN mo.order_delivered_carrier_date > soi.shipping_limit_date
                 THEN 1 ELSE 0 END)
            FILTER (WHERE mo.purchase_year = 2017
                      AND mo.purchase_month BETWEEN 2 AND 8) AS taux_depassement_p1
    FROM mart.orders AS mo
    JOIN staging.order_items AS soi ON soi.order_id = mo.order_id
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
--   Dépassement ≤ 20 %      360        76         21,11 %            3,87 %
--   Dépassement > 20 %       67        20         29,85 %           37,89 %  ←
--
-- LES VENDEURS QUI NE TIENNENT PAS LEUR ENGAGEMENT
-- CONTRACTUEL DISPARAISSENT 41 % PLUS SOUVENT.
--
-- ET LES DEUX GROUPES NE SE RESSEMBLENT PAS : 37,89 % de
-- dépassement moyen contre 3,87 %. Ce sont deux comportements
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
WITH activite AS (
    SELECT
        soi.seller_id,
        COUNT(*) FILTER (WHERE mo.purchase_year = 2018
                           AND mo.purchase_month BETWEEN 2 AND 8) AS order_p2,
        AVG(CASE WHEN mo.order_delivered_carrier_date > soi.shipping_limit_date
                 THEN 1 ELSE 0 END)
            FILTER (WHERE mo.purchase_year = 2017
                      AND mo.purchase_month BETWEEN 2 AND 4) AS depassement_debut,
        AVG(CASE WHEN mo.order_delivered_carrier_date > soi.shipping_limit_date
                 THEN 1 ELSE 0 END)
            FILTER (WHERE mo.purchase_year = 2017
                      AND mo.purchase_month BETWEEN 6 AND 8) AS depassement_fin
    FROM mart.orders AS mo
    JOIN staging.order_items AS soi ON soi.order_id = mo.order_id
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

-- RÉSULTAT — CONTRE-INTUITIF
--
--   Groupe      Vendeurs  Fév-avr  Juin-août  Évolution
--   Disparus       32      21,84 %   11,92 %   −9,92 pts  ←
--   Survivants    197       7,14 %    7,22 %   +0,09 pt
--
-- LES DISPARUS S'AMÉLIORENT AVANT DE PARTIR. Leur taux de
-- dépassement baisse de moitié, alors que les survivants
-- restent stables.
--
-- CE N'EST PAS UNE DÉGRADATION PROGRESSIVE — C'EST L'INVERSE.
--
-- TROIS LECTURES POSSIBLES
--   A. Ils tentent de se redresser et échouent quand même
--   B. Ils réduisent leur volume et gèrent mieux leurs
--      dernières commandes
--   C. EFFET DE SÉLECTION — seuls 32 disparus sur 96 passent le
--      filtre des 5 commandes par demi-période. Ceux partis
--      brutalement, sans commandes en fin de P1, sont exclus.
--
-- C EST PROBABLEMENT DOMINANT : on passe de 96 disparus à 32.
--
-- CE QU'ON RETIENT MALGRÉ TOUT — LE NIVEAU EST LE VRAI SIGNAL :
-- 21,84 % contre 7,14 % dès février-avril 2017. TROIS FOIS PLUS,
-- six mois avant le départ.
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
--  2. 253 VENDEURS seulement sont présents dans les deux
--     périodes avec au moins 10 commandes (sur 1 323)
--  3. PARMI EUX, LE RETARD N'A AUCUN EFFET : 3,06 % chez ceux
--     qui reculent, 3,36 % chez ceux qui progressent
--  4. 75 % DES VENDEURS ÉTABLIS PERDENT DES PARTS DE MARCHÉ
--  5. MAIS LES DISPARUS AVAIENT 5,40 % DE RETARD contre 3,52 %
--     pour les survivants — 53 % de plus
--  6. LA SANCTION EST BINAIRE : un vendeur qui livre mal ne
--     recule pas, IL DISPARAÎT
--  7. LES VENDEURS DÉPASSANT LEUR DATE LIMITE D'EXPÉDITION
--     DISPARAISSENT 41 % PLUS SOUVENT (29,85 % contre 21,11 %)
--  8. LE SIGNAL EST DANS LE NIVEAU, PAS DANS LA PENTE :
--     21,84 % de dépassement six mois avant le départ, contre
--     7,14 % pour les survivants
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