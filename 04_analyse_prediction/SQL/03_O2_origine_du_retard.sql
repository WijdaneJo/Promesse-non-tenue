-- ============================================================
-- O2. OÙ NAÎT LE RETARD
-- ============================================================
-- Objectif : décomposer le délai en trois segments et
-- identifier celui où naît le retard.
--
-- Source     : mart.orders (96 447 commandes du périmètre)
-- Métriques  : M-03 (durée par segment), M-04 (par état),
--              M-05 (répartition par segment d'origine)
-- Constats   : 03_O2_constats.md
--
-- ENJEU : deux causes possibles appellent deux directions
-- différentes. Si le retard vient de la préparation, c'est la
-- direction des partenariats vendeurs qui agit. S'il vient de
-- l'acheminement, c'est la logistique.
--
--   Segment       Bornes                        Responsable
--   Validation    achat -> approbation           Paiement
--   Préparation   approbation -> transporteur    LE VENDEUR
--   Acheminement  transporteur -> livraison      LE TRANSPORTEUR
--
-- PÉRIMÈTRE RÉDUIT SUR LA PRÉPARATION : 689 commandes ont un
-- gap_preparation à NULL (RG-04 et dates manquantes). Le
-- dénominateur de ce segment est de 95 758.
--
-- NOTE DE MÉTHODE : il n'existe pas de « retard » par segment.
-- Olist ne promet rien sur chaque étape. On compare donc
-- chaque segment À SA PROPRE NORMALE, établie en Q1.


-- ============================================================
-- Q1. LA DURÉE NORMALE DE CHAQUE SEGMENT (M-03)
-- ============================================================
-- On établit la référence AVANT de chercher l'anormal.
SELECT
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gap_validation)  AS med_validation,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gap_preparation) AS med_preparation,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gap_shipping)    AS med_shipping
FROM mart.orders;

-- RÉSULTAT : 0 / 2 / 7 jours
--
-- L'ACHEMINEMENT REPRÉSENTE 78 % DU DÉLAI TOTAL (7 sur 9).
-- C'est le segment le plus long : donc celui qui a le plus de
-- marge de variation.
-- La validation est instantanée : le paiement n'est jamais en
-- cause.


-- ============================================================
-- Q2. QU'EST-CE QUI CHANGE QUAND UNE COMMANDE EST EN RETARD ?
-- ============================================================
-- La question centrale de O2. Un seul GROUP BY sur is_late
-- suffit à séparer les deux populations : pas besoin de FILTER.
SELECT
    is_late,
    COUNT(*) AS nb,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gap_validation)  AS med_validation,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gap_preparation) AS med_preparation,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gap_shipping)    AS med_shipping
FROM mart.orders
GROUP BY is_late;

-- RÉSULTAT
--
--            Nb       Valid.  Prépa.  ACHEMINEMENT
--   À l'heure  89 913    0       2         7
--   En retard   6 534    0       3        26   <- ×3,7
--
-- SUR LES 20 JOURS D'ÉCART ENTRE UNE COMMANDE À L'HEURE ET UNE
-- COMMANDE EN RETARD, 19 VIENNENT DU TRANSPORT : soit 95 %.
--
-- La préparation ne gagne qu'UN SEUL JOUR. Le vendeur n'est
-- pas le moteur du retard.
--
-- CONFIRME O1 : l'incident de février-mars 2018 avait déjà
-- pointé l'acheminement (de 7 à 11 jours). Ce résultat montre que
-- ce n'était pas un cas particulier : c'est le MÉCANISME
-- STRUCTUREL du retard, hors de toute crise.


-- ============================================================
-- Q3 + Q4 : LA STRUCTURE PAR ÉTAT (M-04)
-- ============================================================
-- Q3 : ce mécanisme varie-t-il géographiquement ?
-- Q4 : POURQUOI RJ DYSFONCTIONNE-T-IL ?, question ouverte
--      laissée par O1, où ni la distance ni la promesse ne
--      l'expliquaient.
--
-- Six grands états + AL (pire taux) et CE (retards les plus
-- longs), identifiés en O1.
-- Croisement avec is_late : c'est la COMPARAISON à l'heure /
-- en retard qui informe, pas la valeur brute.
SELECT
    customer_state,
    is_late,
    COUNT(*) AS nb_total,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gap_validation)  AS med_validation,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gap_preparation) AS med_preparation,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gap_shipping)    AS med_shipping
FROM mart.orders
WHERE customer_state IN ('SP','RJ','MG','RS','PR','SC','AL','CE')
GROUP BY customer_state, is_late
ORDER BY customer_state, is_late;

-- RÉSULTAT : acheminement médian
--
--   État  Distance  À l'heure  En retard  Facteur  Prépa.
--   SP     166 km       4          15      ×3,8     2 à 4
--   RJ     396 km       8          30      ×3,8     2 à 3
--   PR     427 km       7          24      ×3,4     2 à 3
--   MG     491 km       7          22      ×3,1     2 à 3
--   SC     529 km       9          27      ×3,0     2 à 3
--   RS     856 km       9          32      ×3,6     2 à 3
--   AL   1 915 km      16          36      ×2,3     2 à 2
--   CE   2 292 km      14          35      ×2,5     2 à 3
--
-- Q3. LA PRÉPARATION EST STABLE PARTOUT : 2 jours à l'heure,
-- 3 en retard, dans les huit états. Le vendeur n'explique
-- AUCUN écart géographique.
-- -> LE LEVIER EST UNIQUE ET NATIONAL : LE TRANSPORT.
--
-- Q4. RJ : LA QUESTION D'O1 EST RÉSOLUE.
-- RJ met 8 JOURS à livrer normalement, alors que MG (491 km)
-- et PR (427 km), PLUS ÉLOIGNÉS, en mettent 7, et SP 4.
-- Rio est le seul état où la distance ne prédit pas le délai.
-- SON ACHEMINEMENT EST STRUCTURELLEMENT PLUS LENT, même quand
-- tout va bien. Et quand ça dérape : 30 jours, le pire des
-- grands états.
-- Ce n'est ni la distance, ni la promesse : c'est la
-- PERFORMANCE DU TRANSPORT sur cette zone.
--
-- AL ET CE RELÈVENT D'UN AUTRE PROFIL : 16 et 14 jours
-- d'acheminement en régime NORMAL, contre 4 à SP. Quatre fois
-- plus lents en permanence. Leur promesse de 32 jours est déjà
-- tendue : le moindre écart fait basculer, d'où le taux record
-- d'AL (21,41 %) avec des retards courts (7 jours médians).
--
-- DEUX PROBLÈMES DISTINCTS :
--   AL, CE -> lents en PERMANENCE
--   RJ     -> lent ET INSTABLE


-- ============================================================
-- Q5. QUEL SEGMENT EST RESPONSABLE, COMMANDE PAR COMMANDE ?
-- ============================================================
-- M-05, métrique de conclusion de O2. Q2 donne la tendance
-- globale ; Q5 attribue une responsabilité à CHAQUE commande
-- en retard.
--
-- MÉTHODE : pour chaque commande, on mesure l'écart de chaque
-- segment à sa normale (Q1 : préparation 2 j, acheminement
-- 7 j). Le segment dont l'écart est le plus grand est déclaré
-- responsable.
--
-- PIÈGE DES NULL : quand gap_preparation est NULL, la
-- comparaison renvoie NULL (ni vrai ni faux) et la commande
-- tomberait dans le ELSE, comptée à tort comme « Préparation ».
-- Le premier WHEN les isole. Il doit être placé EN PREMIER :
-- un CASE s'arrête à la première condition vraie.
WITH ecarts AS (
    SELECT
        order_id,
        gap_preparation - 2 AS ecart_prep,
        gap_shipping    - 7 AS ecart_ship
    FROM mart.orders
    WHERE is_late
)
SELECT
    CASE
        WHEN ecart_prep IS NULL          THEN 'Indetermine'
        WHEN ecart_ship >= ecart_prep    THEN 'Shipping'
        ELSE 'Preparation'
    END       AS segment_responsable,
    COUNT(*)  AS nb_orders
FROM ecarts
GROUP BY segment_responsable
ORDER BY nb_orders DESC;

-- RÉSULTAT
--
--   Acheminement   5 465   83,6 %
--   Préparation    1 054   16,1 %
--   Indéterminé       15    0,2 %
--
-- ÉCART AVEC Q2 À NOTER : les médianes donnaient 95 % pour le
-- transport, le décompte par commande donne 84 %. Une médiane
-- écrase les cas individuels : 1 054 COMMANDES ONT BIEN UN
-- PROBLÈME VENDEUR, même si globalement le transport domine.
--
-- Le levier principal reste le transport (5 fois plus de
-- commandes), mais un SECOND CHANTIER existe, relevant d'une
-- direction différente (partenariats vendeurs).


-- ============================================================
-- Q6. LES 1 054 RETARDS DE PRÉPARATION SONT-ILS CONCENTRÉS ?
-- ============================================================
-- Si concentrés sur quelques vendeurs -> action ciblée.
-- Si dispersés -> problème structurel du processus d'expédition.
--
-- DEUX CTE ENCHAÎNÉES, séparées par une virgule : la seconde
-- utilise la première.
--
-- COUNT(DISTINCT order_id) : une commande multi-articles serait
-- sinon comptée plusieurs fois.
--
-- JOIN et non LEFT JOIN vers mart.sellers : les vendeurs sous
-- le seuil RG-08 (moins de 10 commandes) disparaissent
-- volontairement : un taux sur 4 commandes ne veut rien dire.
--
-- LE VOLUME SEUL INDUIT EN ERREUR. Un vendeur avec 31
-- retards sur 2 000 commandes n'a pas le même profil qu'un
-- vendeur avec 9 retards sur 14. C'est le TAUX qui informe :
-- même piège que São Paulo en O1.
WITH ecarts AS (
    SELECT
        order_id,
        gap_preparation - 2 AS ecart_prep,
        gap_shipping    - 7 AS ecart_ship
    FROM mart.orders
    WHERE is_late
),
retards_prepa AS (
    SELECT
        oi.seller_id,
        COUNT(DISTINCT e.order_id) AS retards_prepa
    FROM ecarts AS e
    JOIN staging.order_items AS oi ON oi.order_id = e.order_id
    WHERE ecart_prep > ecart_ship
    GROUP BY oi.seller_id
)
SELECT
    rp.seller_id,
    s.nb_orders                                      AS total_commandes,
    rp.retards_prepa,
    ROUND(rp.retards_prepa * 100.0 / s.nb_orders, 2) AS taux_retard_prepa,
    ROUND(s.late_rate * 100, 2)                      AS taux_retard_global
FROM retards_prepa AS rp
JOIN mart.sellers AS s ON rp.seller_id = s.seller_id
WHERE rp.retards_prepa >= 5
ORDER BY rp.retards_prepa DESC;

-- RÉSULTAT : LE VOLUME TROMPE
--
--   Vendeur      Cmdes  Retards  Taux prépa  Taux global
--   7c67e144…    1 342     26      1,94 %       8,94 %
--   1025f0e2…    1 372     26      1,90 %       6,92 %
--   6560211a…    1 960      5      0,26 %       5,15 %
--
-- Ces vendeurs sont en tête du classement par VOLUME parce
-- qu'ils vendent beaucoup, pas parce qu'ils sont mauvais.
--
-- LES VRAIS CAS PROBLÉMATIQUES
--
--   Vendeur      Cmdes  Retards  TAUX PRÉPA  Taux global
--   b1b39487…       14      9     64,29 %     64,29 %  
--   b19f3ca2…       18      5     27,78 %     33,33 %  
--   54965bbe…       80     22     27,50 %     32,50 %  <-
--   ad781527…       33      7     21,21 %     36,36 %
--   835f0f78…       45      9     20,00 %     28,89 %
--   beadbee3…       67     12     17,91 %     22,39 %
--
-- 54965bbe EST LE CAS LE PLUS SÉRIEUX : 80 commandes, volume
-- suffisant pour être fiable, et 27,5 % de retard imputable à
-- sa propre expédition.
--
-- b1b39487 affiche 64 % : mais sur 14 COMMANDES SEULEMENT.
-- Il passe le seuil RG-08 (10) de justesse : deux commandes de
-- moins et le taux bougerait de 15 points. À SURVEILLER, pas à
-- traiter en priorité.
--
-- OBSERVATION : pour ces vendeurs, le taux de préparation
-- représente L'ESSENTIEL de leur taux global. Le premier :
-- 64,29 % dans les deux colonnes : 100 % de ses retards
-- viennent de lui.
-- À l'inverse, da8622b1 a 6,48 % de retard global mais 0,60 %
-- imputable à la préparation : SES RETARDS VIENNENT DU
-- TRANSPORT, PAS DE LUI. La distinction est essentielle avant
-- toute mise en cause d'un partenaire.


-- ============================================================
-- Q7. LES VENDEURS EN DIFFICULTÉ SONT-ILS CONCENTRÉS
--      GÉOGRAPHIQUEMENT ?
-- ============================================================
-- Si oui, ce serait un signal régional plutôt qu'individuel.
--
-- COMPARAISON INDISPENSABLE : un état peut avoir beaucoup de
-- vendeurs à problème simplement parce qu'il a beaucoup de
-- vendeurs. C'est la PART qui informe, pas le nombre.
--
-- Seuil de 20 % : celui identifié en Q6 comme réellement
-- problématique.
-- HAVING COUNT(*) >= 10 : écarte les états à trop peu de
-- vendeurs : même logique que RG-08.
SELECT
    seller_state,
    COUNT(*)                                        AS nb_vendeurs,
    COUNT(*) FILTER (WHERE late_rate > 0.20)        AS vendeurs_en_difficulte,
    ROUND(COUNT(*) FILTER (WHERE late_rate > 0.20)
          * 100.0 / COUNT(*), 2)                    AS part_en_difficulte_pct,
    ROUND(AVG(late_rate) * 100, 2)                  AS taux_retard_moyen,
    SUM(nb_orders)                                  AS volume_total
FROM mart.sellers
GROUP BY seller_state
HAVING COUNT(*) >= 10
ORDER BY part_en_difficulte_pct DESC;

-- RÉSULTAT
--
--   État  Vendeurs  En difficulté  Part      Taux moyen
--   SC       65          9        13,85 %      7,40 %  <-
--   RS       44          3         6,82 %      4,29 %
--   SP      818         37         4,52 %      7,29 %
--   MG      115          5         4,35 %      5,65 %
--   PR      146          3         2,05 %      4,67 %
--   RJ       72          0         0,00 %      6,31 %  <-
--   GO       15          0         0,00 %      2,71 %
--   DF       17          0         0,00 %      5,19 %
--
-- SANTA CATARINA DÉCROCHE : trois fois plus de vendeurs en
-- difficulté que la moyenne.
--
-- ET SURPRISE : RJ N'A AUCUN VENDEUR EN DIFFICULTÉ. Rio est le
-- pire état de DESTINATION mais ses vendeurs vont bien.
-- CONFIRMATION SUPPLÉMENTAIRE : le problème de RJ n'est pas
-- côté vendeur, c'est le transport vers Rio.
--
-- MAIS ATTENTION : late_rate est le taux GLOBAL du vendeur :
-- il inclut les retards dus au transport. Un vendeur de SC
-- expédiant vers des zones lentes aurait un taux élevé sans
-- être responsable. SC pourrait donc être un ARTEFACT.
-- Vérifié en Q7 bis.


-- -- Q7 bis. SC : vrai problème ou artefact du transport ? ---
-- On reprend l'attribution de Q5 et on la ramène au grain
-- ÉTAT DU VENDEUR. Ici on mesure la part des retards
-- IMPUTABLE À LA PRÉPARATION, pas le taux global.
--
-- SELECT DISTINCT sur order_id : une commande multi-articles
-- du même vendeur ne doit être comptée qu'une fois.
WITH ecarts AS (
    SELECT
        order_id,
        gap_preparation - 2 AS ecart_prep,
        gap_shipping    - 7 AS ecart_ship
    FROM mart.orders
    WHERE is_late
),
attribution AS (
    SELECT DISTINCT
        e.order_id,
        s.seller_state,
        (e.ecart_prep > e.ecart_ship) AS prepa_responsable
    FROM ecarts AS e
    JOIN staging.order_items AS oi ON oi.order_id  = e.order_id
    JOIN staging.sellers     AS s  ON s.seller_id  = oi.seller_id
    WHERE e.ecart_prep IS NOT NULL
)
SELECT
    seller_state,
    COUNT(*)                                       AS retards_total,
    COUNT(*) FILTER (WHERE prepa_responsable)      AS retards_prepa,
    ROUND(COUNT(*) FILTER (WHERE prepa_responsable)
          * 100.0 / COUNT(*), 2)                   AS part_prepa_pct
FROM attribution
GROUP BY seller_state
HAVING COUNT(*) >= 50
ORDER BY part_prepa_pct DESC;

-- RÉSULTAT : référence nationale : 16,1 % (cf. Q5)
--
--   État  Retards  Dont prépa  Part
--   MA       74        31     41,89 %  <- ×2,6
--   RS       61        19     31,15 %  <- ×1,9
--   PR      400        85     21,25 %
--   MG      370        69     18,65 %
--   SC      175        29     16,57 %  <- = moyenne nationale
--   SP    5 005       764     15,26 %
--   RJ      301        44     14,62 %  <- sous la moyenne
--
-- SC ÉTAIT BIEN UN ARTEFACT : 16,57 %, soit exactement la
-- moyenne nationale. Ses vendeurs ne sont pas en cause : ils
-- expédient vers des zones difficiles.
--
-- DEUX ÉTATS RESSORTENT VRAIMENT : MA (41,89 %) et RS
-- (31,15 %). Au Maranhão, 4 retards sur 10 viennent de la
-- préparation vendeur contre 1,5 sur 10 en moyenne.
--
-- PRÉCAUTION : MA a 74 retards et RS 61. Le seuil de 50 est
-- bas : ces taux sont INDICATIFS, pas solides. SP, avec
-- 5 005 retards, est le seul chiffre pleinement fiable.
--
-- RJ CONFIRME ENCORE : 14,62 %, sous la moyenne nationale.
-- Les vendeurs basés à Rio préparent bien. Le problème de RJ
-- est EXCLUSIVEMENT dans le transport : établi désormais de
-- trois façons différentes.


-- ============================================================
-- Q8. L'ENGAGEMENT CONTRACTUEL D'EXPÉDITION EST-IL TENU ?
-- ============================================================
-- shipping_limit_date est la DATE LIMITE D'EXPÉDITION imposée
-- au vendeur par Olist.
--
-- POURQUOI CET INDICATEUR EST MEILLEUR QU'UN TAUX DE RETARD :
-- c'est un ENGAGEMENT CONTRACTUEL. Un dépassement est
-- OPPOSABLE au partenaire, contrairement à un taux de retard
-- qui peut venir du transport et qu'il pourrait contester.
--
-- Colonne disponible dans staging.order_items depuis le début
-- du projet, jamais exploitée jusqu'ici.
--
-- Le grain est l'ARTICLE : une commande à plusieurs articles a
-- plusieurs dates limites.
SELECT
    COUNT(*)                                    AS nb_articles,
    COUNT(*) FILTER (
        WHERE o.order_delivered_carrier_date > oi.shipping_limit_date
    )                                           AS depassements,
    ROUND(COUNT(*) FILTER (
        WHERE o.order_delivered_carrier_date > oi.shipping_limit_date
    ) * 100.0 / COUNT(*), 2)                    AS taux_depassement_pct
FROM mart.orders AS o
JOIN staging.order_items AS oi ON oi.order_id = o.order_id
WHERE o.order_delivered_carrier_date IS NOT NULL;

-- RÉSULTAT : 110 138 articles · 10 240 dépassements · 9,30 %
--
-- UN ARTICLE SUR ONZE EST EXPÉDIÉ APRÈS LA DATE LIMITE.
-- Chiffre solide : aucun problème d'effectif.


-- -- Q8.a Un dépassement se traduit-il par un retard ? -------
-- Si oui, l'engagement est bien calibré : le respecter suffit
-- à tenir la promesse.
-- Sinon, il est trop serré et son non-respect est sans
-- conséquence : donc peu utile comme levier.
--
-- BOOL_OR : renvoie true si AU MOINS UNE ligne du groupe
-- satisfait la condition. Une commande est considérée en
-- dépassement dès qu'un de ses articles l'est.
WITH depassement AS (
    SELECT
        o.order_id,
        o.is_late,
        BOOL_OR(o.order_delivered_carrier_date > oi.shipping_limit_date)
            AS a_depasse
    FROM mart.orders AS o
    JOIN staging.order_items AS oi ON oi.order_id = o.order_id
    WHERE o.order_delivered_carrier_date IS NOT NULL
    GROUP BY o.order_id, o.is_late
)
SELECT
    a_depasse,
    COUNT(*)                          AS nb_commandes,
    COUNT(*) FILTER (WHERE is_late)   AS nb_en_retard,
    ROUND(AVG(is_late::INT) * 100, 2) AS taux_retard_pct
FROM depassement
GROUP BY a_depasse;

-- RÉSULTAT
--
--   Date limite respectée   87 739 commandes   -> 5,38 % de retard
--   Date limite dépassée     8 707 commandes   -> 20,83 % de retard
--
-- UN DÉPASSEMENT MULTIPLIE LE RISQUE DE RETARD PAR PRÈS DE 4.
--
-- L'INDICATEUR EST DONC VALIDE : respecter la date limite
-- suffit largement à tenir la promesse. Olist ne l'a pas fixée
-- trop serrée.
-- C'est un levier actionnable ET opposable au vendeur.


-- -- Q8.b Quels vendeurs ne tiennent pas leur engagement ? ---
-- Recoupement avec la liste de Q6 : les vendeurs identifiés
-- par l'analyse des segments sont-ils les mêmes que ceux qui
-- dépassent leur date limite contractuelle ?
SELECT
    oi.seller_id,
    s.nb_orders                                 AS total_commandes,
    COUNT(*)                                    AS nb_articles,
    COUNT(*) FILTER (
        WHERE o.order_delivered_carrier_date > oi.shipping_limit_date
    )                                           AS depassements,
    ROUND(COUNT(*) FILTER (
        WHERE o.order_delivered_carrier_date > oi.shipping_limit_date
    ) * 100.0 / COUNT(*), 2)                    AS taux_depassement_pct,
    ROUND(s.late_rate * 100, 2)                 AS taux_retard_global
FROM mart.orders AS o
JOIN staging.order_items AS oi ON oi.order_id  = o.order_id
JOIN mart.sellers        AS s  ON s.seller_id  = oi.seller_id
WHERE o.order_delivered_carrier_date IS NOT NULL
GROUP BY oi.seller_id, s.nb_orders, s.late_rate
HAVING COUNT(*) >= 30
ORDER BY taux_depassement_pct DESC
LIMIT 20;

-- RÉSULTAT : DEUX PROFILS OPPOSÉS
--
-- A) DÉPASSENT SANS CONSÉQUENCE : la marge absorbe
--
--   Vendeur      Cmdes  Dépassement  Retard
--   48efc9d9…      34     82,35 %     0,00 %   
--   a7f13822…      84     59,52 %     3,57 %
--   1da366ca…      47     55,32 %     6,38 %
--   f4aba7c0…     114     45,22 %     6,14 %
--
-- LE PREMIER DÉPASSE SA DATE LIMITE 8 FOIS SUR 10 ET N'A AUCUN
-- RETARD. La marge d'Olist (13 jours médians, cf. O8) est si
-- large qu'un vendeur peut expédier en retard et le colis
-- arriver quand même à temps.
--
-- B) DÉPASSENT ET GÉNÈRENT DU RETARD : cible prioritaire
--
--   Vendeur      Cmdes  Dépassement  Retard
--   835f0f78…      45     72,92 %    28,89 %  <-
--   a49928bc…     101     55,77 %    21,78 %  <-
--   54965bbe…      80     54,32 %    32,50 %  <-
--   ad781527…      33     47,37 %    36,36 %  <-
--   bbad7e51…      80     46,43 %    23,75 %
--
-- CE SONT LES MÊMES QUE LA LISTE DE Q6. Les deux méthodes :
-- analyse des segments et respect de l'engagement : CONVERGENT.
-- Ces vendeurs ont un vrai problème d'expédition, et il se
-- traduit en retards clients.


-- ============================================================
-- SYNTHÈSE O2
-- ============================================================
--  1. Durée normale : 0 / 2 / 7 jours. L'acheminement
--     représente 78 % du délai total
--  2. LE RETARD NAÎT DE L'ACHEMINEMENT : 7 à 26 jours, soit
--     95 % de l'écart. La préparation ne gagne qu'un jour
--  3. La structure est IDENTIQUE DANS TOUS LES ÉTATS : le
--     levier est unique et national
--  4. RJ RÉSOLU : son acheminement est structurellement lent
--     (8 j contre 7 pour des états plus éloignés). Établi de
--     trois façons : durée, vendeurs sortants, vendeurs locaux
--  5. AL et CE relèvent d'un autre profil : lents en
--     PERMANENCE (16 et 14 j), pas instables
--  6. Attribution par commande : 84 % acheminement,
--     16 % préparation
--  7. SC était un ARTEFACT : ses vendeurs expédient vers des
--     zones lentes. MA (41,89 %) et RS (31,15 %) ressortent
--     réellement, sous réserve d'effectifs limités
--  8. LE RESPECT DE LA DATE LIMITE DIVISE LE TAUX DE RETARD
--     PAR 4 (5,38 % contre 20,83 %) : levier actionnable et
--     opposable
--  9. Quatre vendeurs cumulent dépassement contractuel ET
--     retard client : liste courte, cible prioritaire
-- ============================================================