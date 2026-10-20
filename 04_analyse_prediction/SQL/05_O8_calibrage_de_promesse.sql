-- ============================================================
-- O8. LE CALIBRAGE DE LA PROMESSE
-- ============================================================
-- Objectif : évaluer si les délais annoncés sont bien calibrés,
-- et simuler l'effet d'un resserrement.
--
-- Source     : mart.orders (96 447 commandes du périmètre)
-- Métriques  : M-16 (marge sur les délais), M-17 (taux simulé)
-- Constats   : 05_O8_constats.md
--
-- ORIGINE DE CET OBJECTIF : il n'était PAS prévu au cadrage
-- initial. Il est né de la qualification (H12), qui a révélé
-- que 91,88 % des commandes sont livrées en avance avec une
-- marge médiane de 13 jours. D'où SQ7 et O8 dans la note v3.1.
--
-- ENJEU : un arbitrage commercial. Une promesse plus courte est
-- plus attractive, mais mécaniquement génératrice de retards.
--
-- ACQUIS DES OBJECTIFS PRÉCÉDENTS
--   O1. La promesse est bien calibrée sur la distance
--        (46 j à 2 700 km, 19 j à 166 km)
--   O3. L'AVANCE N'APPORTE RIEN : la note plafonne à 4,3 de
--        −30 à −5 jours. C'est l'argument central.
--   O1. L'acheminement s'est amélioré : 7 à 5 jours après
--        avril 2018
--
-- TROIS LIMITES À POSER D'EMBLÉE
--   1. LE BÉNÉFICE N'EST PAS MESURABLE. Le dataset ne contient
--      aucune trace des visiteurs n'ayant PAS commandé. M-17
--      mesure le COÛT d'un resserrement, jamais son gain.
--   2. La simulation suppose l'EXÉCUTION INCHANGÉE : on décale
--      la promesse, pas la performance.
--   3. L'effet sur la satisfaction est EXTRAPOLÉ : rien ne
--      garantit qu'un retard créé par un resserrement soit
--      perçu comme un retard subi.


-- ============================================================
-- Q1. QUELLE MARGE OLIST PREND-ELLE AUJOURD'HUI ? (M-16)
-- ============================================================
-- La marge est le temps qu'Olist s'est réservé et qu'elle n'a
-- PAS consommé.
--
-- WHERE gap < 0 OBLIGATOIRE : une commande en retard n'a pas de
-- marge, elle l'a dépassée. Inclure les retards produirait une
-- moyenne entre marge et dépassement : un chiffre qui ne décrit
-- ni l'un ni l'autre.
--
-- MÉDIANE ET NON MOYENNE : le gap descend jusqu'à −147 jours.
--
-- GROUP BY purchase_year : sans découpage, on obtiendrait un
-- chiffre moyen sur deux ans, alors que la promesse a changé
-- entre-temps.
SELECT
    purchase_year,
    COUNT(*)                                         AS nb_commandes,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gap) AS marge_mediane
FROM mart.orders
WHERE gap < 0
GROUP BY purchase_year
ORDER BY purchase_year;

-- RÉSULTAT
--
--   2016      259 commandes    −39 j   NON EXPLOITABLE
--   2017   40 529 commandes    −13 j
--   2018   47 833 commandes    −13 j
--
-- 2016 EST ÉCARTÉ : 259 commandes, dont les mois incomplets de
-- démarrage identifiés en O1 (sept. 2016 : 1 commande,
-- déc. 2016 : 1). Les −39 jours décrivent une plateforme qui
-- démarre sans historique, pas une politique commerciale.
--
-- LA MARGE EST IDENTIQUE EN 2017 ET 2018 : alors que la
-- promesse a été raccourcie sur la période (O1).


-- -- Q1 bis. Rappel : l'évolution de la promesse -------------
-- Requête reprise de O1 (Q2.e), nécessaire pour interpréter
-- Q1 : comment la marge peut-elle rester stable si la promesse
-- se raccourcit ?
SELECT
    purchase_year,
    purchase_month,
    PERCENTILE_CONT(0.5) WITHIN GROUP (
        ORDER BY order_estimated_delivery_date::DATE
                 - order_purchase_timestamp::DATE
    ) AS med_promesse
FROM mart.orders
GROUP BY purchase_year, purchase_month
ORDER BY purchase_year, purchase_month;

-- RÉSULTAT : durée médiane promise
--
--   2017 (mars à nov.)    23-26 jours
--   2018-03               22 jours
--   2018-05               22 jours
--   2018-06               28 jours   <- remonte
--   2018-07               20 jours
--   2018-08               14 jours   <- minimum
--
-- L'EXPLICATION DE Q1 :
--
--     Promesse  −  Exécution  =  Marge
--     2017 :  23  −  10  =  13
--     2018 :  14  −   1  =  13
--
-- Olist a raccourci sa promesse EXACTEMENT AUTANT qu'elle a
-- amélioré son exécution (acheminement 7 à 5 jours, O1). Les
-- deux mouvements se compensent, la marge ne bouge pas.
--
-- -> LE RACCOURCISSEMENT N'A PAS ENTAMÉ LE COUSSIN DE SÉCURITÉ.
--   Les 13 jours de marge sont toujours disponibles.
--
-- PRUDENCE SUR LES 14 JOURS D'AOÛT 2018. Juin était à 28,
-- juillet à 20. Ce n'est pas une tendance régulière mais un
-- MOIS ISOLÉ, et c'est le dernier du dataset. Un seul point ne
-- fait pas une politique.
--
-- PRINCIPE À RETENIR : un écart stable ne signifie pas que rien
-- n'a changé. Il peut cacher deux mouvements qui se compensent.
-- Toujours regarder les composantes, pas seulement le résultat.

-- ============================================================
-- RÉVISÉ PAR O6 ET PAR Q1 TER : CETTE LECTURE NE TIENT PAS À
-- L'ÉCHELLE DU MOIS
-- ============================================================
-- Deux erreurs dans l'interprétation ci-dessus :
--
-- 1. LE CALCUL « 2018 : 14 - 1 = 13 » EST FAUX. En août 2018, le
--    délai réel médian est de 7 jours (Q1 ter). Le bon calcul est
--    14 - 7 = 7 jours de marge, et Q1 ter mesure exactement 7.
--
-- 2. LA MÉDIANE ANNUELLE MASQUE L'ÉTÉ. Les 13 jours de 2018
--    mélangent janvier-juin (promesses de 22 à 28 jours) et août
--    (14 jours). Une politique qui change en cours d'année ne se
--    lit pas dans un chiffre annuel.
--
-- Le principe ci-dessus reste juste (un écart stable peut cacher
-- deux mouvements), mais il vaut à l'échelle de l'année. Au mois
-- près, les deux mouvements ne se compensent plus : le coussin de
-- sécurité a été entamé à l'été 2018. Voir Q1 ter.


-- Q1 ter. La marge mois par mois en 2018
-- Vérifie la révision : la marge médiane des commandes en avance
-- doit se réduire à l'été, en miroir de la hausse du retard.
SELECT
    purchase_month,
    COUNT(*)                                              AS nb_commandes,
    ROUND(100.0 * AVG((gap > 0)::INT), 2)                 AS taux_retard_pct,
    PERCENTILE_CONT(0.5) WITHIN GROUP (
        ORDER BY order_estimated_delivery_date::DATE
                 - order_purchase_timestamp::DATE)        AS med_promesse,
    PERCENTILE_CONT(0.5) WITHIN GROUP (
        ORDER BY order_delivered_customer_date::DATE
                 - order_purchase_timestamp::DATE)        AS med_delai_reel,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gap)
        FILTER (WHERE gap < 0)                            AS marge_mediane
FROM mart.orders
WHERE purchase_year = 2018
GROUP BY purchase_month
ORDER BY purchase_month;

-- RÉSULTAT
--
--   Mois  Commandes  Retard   Promesse  Délai réel  Marge
--     1     7 069    5,70 %    26 j       12 j      -14 j
--     2     6 555   14,13 %    25 j       14 j      -12 j
--     3     7 003   18,96 %    22 j       13 j       -9 j
--     4     6 798    4,50 %    24 j        9 j      -14 j
--     5     6 749    6,56 %    22 j        9 j      -13 j
--     6     6 096    1,16 %    28 j        8 j      -20 j
--     7     6 156    3,38 %    20 j        7 j      -11 j
--     8     6 351    6,19 %    14 j        7 j       -7 j
--
-- LA RÉVISION EST CONFIRMÉE. La marge passe de 20 jours en juin à
-- 7 jours en août, et le taux de retard de 1,16 % à 6,19 %.
--
-- UN CONSTAT DE PLUS : MARS ET AOÛT ONT DEUX CAUSES OPPOSÉES.
--   Mars : délai réel de 13 jours, le plus lent de l'année.
--          L'exécution a craqué (incident d'acheminement, O1).
--   Août : délai réel de 7 jours, le plus rapide de l'année.
--          Le retard vient de la promesse seule.
-- La marge d'août (7 j) est plus faible qu'en mars (9 j), pour un
-- retard trois fois moindre : une exécution régulière tient une
-- marge courte, une exécution qui dérape déborde une marge longue.


-- ============================================================
-- Q2. LA MARGE EST-ELLE UNIFORME PAR ÉTAT ? (M-16)
-- ============================================================
-- Les états à forte marge seraient les candidats naturels au
-- resserrement. Ceux à marge faible n'en auraient pas.
SELECT
    customer_state,
    COUNT(*)                                         AS nb_commandes,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gap) AS marge_mediane
FROM mart.orders
WHERE gap < 0
GROUP BY customer_state
ORDER BY marge_mediane;

-- RÉSULTAT
--
--   État  Commandes   Marge
--   RR         36     −24 j  volume faible
--   AC         77     −22 j  
--   AP         64     −22 j  
--   RO        236     −21 j  
--   AM        139     −19 j  
--   PA        829     −17 j
--   MT        826     −16 j
--   PE      1 421     −15 j
--   RS      4 961     −15 j
--   MG     10 712     −14 j
--   PR      4 677     −14 j
--   RJ     10 685     −14 j
--   BA      2 799     −14 j
--   SC      3 198     −13 j
--   DF      1 933     −13 j
--   SP     38 093     −12 j  <- minimum
--
-- LA MARGE EST REMARQUABLEMENT UNIFORME : de −12 à −17 jours
-- pour tous les états à volume significatif. TROIS JOURS
-- D'ÉCART entre les grands états.
--
-- À COMPARER AU TAUX DE RETARD, qui va de 4,04 % à 17,43 % entre
-- les états de plus de 500 commandes, un RAPPORT DE 1 À 4 (O1).
--
-- Les cinq états amazoniens (RR, AC, AP, RO, AM) dépassent
-- −19 jours mais ont tous moins de 240 commandes. Sous le seuil
-- de fiabilité.
--
-- POURQUOI CETTE UNIFORMITÉ : Olist calibre sa promesse sur la
-- distance (établi en O1). Résultat, le coussin de sécurité
-- restant est le même partout.
--
-- -> UN RESSERREMENT DIFFÉRENCIÉ PAR ÉTAT N'A PAS DE SENS.
--   Une règle uniforme suffit.
--   Ceci répond par avance à Q5.
--
-- CE QUE Q2 NE DIT PAS : de combien resserrer. La médiane
-- décrit le cas CENTRAL, pas les commandes proches de zéro :
-- celles qui basculeraient. C'est l'objet de Q3.


-- ============================================================
-- Q3. QUE SE PASSE-T-IL SI ON RETRANCHE X JOURS ? (M-17)
-- ============================================================
-- Le cœur de O8.
--
-- PRINCIPE : resserrer la promesse de X jours revient à AJOUTER
-- X au gap de chaque commande.
--
--   Exemple : commande promise à 20 j, livrée en 12 j :
--     gap actuel        = 12 − 20 = −8  (8 jours d'avance)
--     si promesse 15 j  = 12 − 15 = −3  (soit gap + 5)
--     si promesse 10 j  = 12 − 10 = +2  -> EN RETARD
--
-- Plus le gap monte, plus on s'approche du retard. Au-dessus de
-- zéro, c'est un retard.
--
-- NE PAS FILTRER SUR gap < 0 : les commandes déjà en retard
-- le restent après resserrement. Les exclure sous-estimerait le
-- taux simulé.
--
-- Les deux premières colonnes servent de CONTRÔLE : elles
-- doivent donner 96 447 et 6 534.
SELECT
    COUNT(*)                             AS total,
    COUNT(*) FILTER (WHERE gap > 0)      AS retard_actuel,
    COUNT(*) FILTER (WHERE gap + 3 > 0)  AS retard_si_3j,
    COUNT(*) FILTER (WHERE gap + 5 > 0)  AS retard_si_5j,
    COUNT(*) FILTER (WHERE gap + 7 > 0)  AS retard_si_7j,
    COUNT(*) FILTER (WHERE gap + 10 > 0) AS retard_si_10j
FROM mart.orders;

-- RÉSULTAT
--
--   Scénario     Commandes   Taux
--   Actuel          6 534    6,77 %
--   −3 jours       10 838   11,24 %   <- presque le double
--   −5 jours       14 486   15,02 %
--   −7 jours       20 330   21,08 %   <- le triple
--   −10 jours      34 620   35,90 %   <- plus d'un tiers
--
-- LA MARGE DE 13 JOURS N'EST PAS UN GISEMENT DISPONIBLE.
-- C'est une MÉDIANE : la moitié des commandes ont MOINS de
-- 13 jours d'avance, et ce sont elles qui basculent.
--
-- POURQUOI LA HAUSSE EST SI BRUTALE : la distribution mesurée
-- en O3 l'explique :
--     gap  0  ->  1 280 commandes
--     gap −1  ->  1 450
--     gap −2  ->  1 540
--     gap −3  ->  1 715
-- Beaucoup de commandes sont AU BORD. Retrancher 3 jours fait
-- basculer tout ce qui était entre 0 et −2, soit ~4 300.


-- ============================================================
-- Q4. JUSQU'OÙ ALLER SANS FRANCHIR UN SEUIL ACCEPTABLE ?
-- ============================================================
-- Q3 montre que 3 jours font déjà presque doubler le taux. La
-- zone utile est donc EN DESSOUS : d'où le test de 1 et 2 jours.
SELECT
    COUNT(*)                            AS total,
    COUNT(*) FILTER (WHERE gap > 0)     AS retard_actuel,
    COUNT(*) FILTER (WHERE gap + 1 > 0) AS retard_si_1j,
    ROUND(COUNT(*) FILTER (WHERE gap + 1 > 0) * 100.0 / COUNT(*), 2) AS taux_1j,
    COUNT(*) FILTER (WHERE gap + 2 > 0) AS retard_si_2j,
    ROUND(COUNT(*) FILTER (WHERE gap + 2 > 0) * 100.0 / COUNT(*), 2) AS taux_2j
FROM mart.orders;

-- RÉSULTAT : LE TABLEAU COMPLET
--
--   Resserrement   Commandes   Taux      Coût
--   Actuel            6 534    6,77 %      :
--   −1 jour           7 826    8,11 %   +1,34 pt
--   −2 jours          9 288    9,63 %   +2,86 pt
--   −3 jours         10 838   11,24 %   +4,47 pt
--   −5 jours         14 486   15,02 %   +8,25 pt
--   −7 jours         20 330   21,08 %  +14,31 pt
--   −10 jours        34 620   35,90 %  +29,13 pt
--
-- LE COÛT EST NON LINÉAIRE. Chaque jour retranché coûte environ
-- 1,4 point jusqu'à 3 jours. Au-delà de 7, ça s'emballe.
--
-- LA ZONE DÉFENDABLE EST 1 À 2 JOURS : passer de 6,77 % à
-- 9,63 % est un coût mesurable et assumable. Au-delà, on
-- franchit les 10 %.
--
-- MAIS LE CHIFFRE MANQUANT RESTE LE MÊME. On mesure le COÛT
-- (+2 754 commandes en retard à −2 jours), jamais le BÉNÉFICE.
-- Le dataset ne contient aucune trace des visiteurs ayant
-- renoncé face à un délai trop long.


-- ============================================================
-- Q5. UN RESSERREMENT DIFFÉRENCIÉ FERAIT-IL MIEUX ?
-- ============================================================
-- RÉPONDU PAR Q2 : la marge est uniforme (−12 à −15 jours dans
-- tous les grands états). Aucun état ne dispose d'un gisement
-- supérieur aux autres.
--
-- -> UN RESSERREMENT DIFFÉRENCIÉ N'APPORTERAIT RIEN.
--   Une règle nationale uniforme est suffisante.
--
-- Ceci recoupe O3, qui avait établi que le SEUIL DE TOLÉRANCE
-- est lui aussi national : même point de bascule dans les six
-- grands états. Deux raisons indépendantes de ne pas
-- différencier.


-- ============================================================
-- SYNTHÈSE O8
-- ============================================================
--  1. LA MARGE MÉDIANE ANNUELLE EST DE 13 JOURS en 2017 et
--     en 2018 : un chiffre annuel qui masque l'été (cf. 2)
--  2. Sur l'année, le raccourcissement de la promesse a été
--     compensé par l'amélioration de l'exécution. Mais pas à
--     l'été 2018 (Q1 ter) : la marge passe de 20 jours en juin
--     à 7 jours en août, et le retard de 1,16 % à 6,19 %.
--     Le coussin a été entamé
--  2 bis. Mars et août 2018 ont deux causes opposées :
--     l'exécution en mars, la promesse en août
--  3. LA MARGE EST UNIFORME PAR ÉTAT (−12 à −15 j) : un
--     resserrement différencié n'a pas de sens
--  4. LE COÛT D'UN RESSERREMENT EST NON LINÉAIRE :
--     1,4 pt par jour jusqu'à 3 jours, puis emballement
--  5. LA ZONE DÉFENDABLE EST 1 À 2 JOURS (taux porté de
--     6,77 % à 9,63 %, soit +2 754 commandes en retard)
--  6. LE BÉNÉFICE N'EST PAS MESURABLE : arbitrage à remonter
--     au métier
--
-- L'ARGUMENT CENTRAL : L'ASYMÉTRIE
-- Livrer en avance n'apporte RIEN (note stable à 4,3, O3).
-- Livrer en retard coûte 1,4 point de note dès le premier jour.
-- Le gain et la perte ne sont pas symétriques : la marge
-- protège d'un risque RÉEL contre un bénéfice NUL en
-- satisfaction.
-- C'est ce qui rend le resserrement difficile à défendre
-- au-delà de 2 jours.
-- ============================================================