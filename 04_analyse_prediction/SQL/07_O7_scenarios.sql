-- ============================================================
-- O7. LES SCÉNARIOS D'AMÉLIORATION
-- ============================================================
-- Objectif : estimer le gain associé à différents scénarios de
-- réduction des délais RÉELS.
--
-- Source     : mart.orders (96 447 commandes du périmètre)
-- Métrique   : M-13 (CA récupérable)
-- Constats   : 07_O7_constats.md
--
-- LE LIEN AVEC O8 : DEUX LEVIERS OPPOSÉS
--
--             O8                        O7
--   Levier    Raccourcir l'ANNONCÉ      Raccourcir le RÉEL
--   Nature    Commerciale               Opérationnelle
--   Effet     AUGMENTE le retard        RÉDUIT le retard
--
-- Ils se lisent ensemble : si Olist gagne 3 jours en exécution,
-- elle peut resserrer sa promesse de 3 jours sans dégrader son
-- taux de retard.
--
-- ACQUIS DES OBJECTIFS PRÉCÉDENTS
--   O2, 95 % du retard vient de l'ACHEMINEMENT
--   O3, Le seuil critique est à 3 JOURS
--   O4, CA exposé : 1 150 866 R$
--   O1, 56 % des retards sont dans la tranche 1-7 jours
--
-- PRINCIPE DE LA SIMULATION : gagner X jours revient à
-- RETRANCHER X au gap. Les commandes qui passent sous zéro
-- redeviennent à l'heure.


-- ============================================================
-- Q1. COMBIEN DE COMMANDES REVIENNENT À L'HEURE ?
-- ============================================================
-- La première colonne sert de CONTRÔLE : elle doit donner 6 534.
SELECT
    COUNT(*) FILTER (WHERE gap > 0)     AS retard_actuel,
    COUNT(*) FILTER (WHERE gap - 1 > 0) AS retard_si_1j,
    COUNT(*) FILTER (WHERE gap - 2 > 0) AS retard_si_2j,
    COUNT(*) FILTER (WHERE gap - 3 > 0) AS retard_si_3j,
    COUNT(*) FILTER (WHERE gap - 4 > 0) AS retard_si_4j,
    COUNT(*) FILTER (WHERE gap - 5 > 0) AS retard_si_5j,
    COUNT(*) FILTER (WHERE gap - 6 > 0) AS retard_si_6j,
    COUNT(*) FILTER (WHERE gap - 7 > 0) AS retard_si_7j
FROM mart.orders;

-- RÉSULTAT
--
--   Gain   Encore en retard   RÉCUPÉRÉES   Part des retards
--     0        6 534              ,             ,
--     1        5 709             825           12,6 %
--     2        5 164           1 370           21,0 %
--     3        4 664           1 870           28,6 %
--     4        4 211           2 323           35,6 %
--     5        3 764           2 770           42,4 %
--     6        3 345           3 189           48,8 %
--     7        2 862           3 672           56,2 %
--
-- LE RENDEMENT EST PRESQUE LINÉAIRE : chaque jour gagné
-- récupère 450 à 500 commandes.
--
-- 7 JOURS RÉCUPÈRENT 56 % DES RETARDS : cohérent avec O1, qui
-- montrait 3 672 commandes dans la tranche 1-7 jours.
--
-- LE CONTRASTE AVEC O8 EST FRAPPANT
--   O7, gagner 1 jour en exécution  ->  −825 commandes
--   O8, retrancher 1 jour à l'annoncé -> +1 292 commandes
--
-- RESSERRER COÛTE PLUS QUE LIVRER PLUS VITE NE RAPPORTE.


-- ============================================================
-- Q2. QUEL CA EST RÉCUPÉRÉ ? (M-13)
-- ============================================================
-- Le ROUND doit ENVELOPPER le FILTER, pas le précéder :
-- le FILTER appartient à l'agrégation, le ROUND s'applique au
-- résultat.
SELECT
    ROUND(SUM(payment_total) FILTER (WHERE gap > 0), 2)     AS ca_actuel,
    ROUND(SUM(payment_total) FILTER (WHERE gap - 1 > 0), 2) AS ca_si_1j,
    ROUND(SUM(payment_total) FILTER (WHERE gap - 2 > 0), 2) AS ca_si_2j,
    ROUND(SUM(payment_total) FILTER (WHERE gap - 3 > 0), 2) AS ca_si_3j,
    ROUND(SUM(payment_total) FILTER (WHERE gap - 4 > 0), 2) AS ca_si_4j,
    ROUND(SUM(payment_total) FILTER (WHERE gap - 5 > 0), 2) AS ca_si_5j,
    ROUND(SUM(payment_total) FILTER (WHERE gap - 6 > 0), 2) AS ca_si_6j,
    ROUND(SUM(payment_total) FILTER (WHERE gap - 7 > 0), 2) AS ca_si_7j
FROM mart.orders;

-- RÉSULTAT
--
--   Gain   CA encore exposé   CA RÉCUPÉRÉ   Part
--     0       1 150 866 R$         ,        ,
--     1       1 015 984          134 882    11,7 %
--     2         932 499          218 367    19,0 %
--     3         855 882          294 984    25,6 %
--     5         688 444          462 422    40,2 %
--     7         523 247          627 619    54,5 %
--
-- COÏNCIDENCE À NOTER : le scénario 2 jours donne 932 499 R$,
-- exactement le CA exposé au seuil de 3 jours mesuré en O4.
-- Logique : gagner 2 jours ramène sous le seuil critique toutes
-- les commandes qui étaient à 3 jours.
--
-- LE CA PROGRESSE MOINS VITE QUE LE VOLUME
--   1 jour gagné -> 825 commandes (12,6 %) mais 11,7 % du CA
-- LES COMMANDES RÉCUPÉRÉES EN PREMIER SONT LES MOINS CHÈRES.


-- ============================================================
-- Q3. COMBIEN DE CLIENTS MÉCONTENTS ÉVITE-T-ON ?
-- ============================================================
-- CE QU'ON NE PEUT PAS FAIRE : prédire la note qu'un client
-- aurait donnée si sa commande était arrivée à l'heure. Cela
-- n'existe pas dans les données.
--
-- CE QU'ON FAIT À LA PLACE : compter, parmi les commandes qui
-- reviendraient à l'heure, celles dont le client était
-- RÉELLEMENT insatisfait. Ce ne sont pas des notes prédites,
-- ce sont des mécontentements OBSERVÉS qui n'auraient pas eu
-- lieu.
SELECT
    COUNT(*) FILTER (WHERE gap > 0 AND is_unsatisfied) AS mecontents_actuels,
    COUNT(*) FILTER (WHERE gap > 0 AND gap - 1 <= 0 AND is_unsatisfied) AS evites_1j,
    COUNT(*) FILTER (WHERE gap > 0 AND gap - 2 <= 0 AND is_unsatisfied) AS evites_2j,
    COUNT(*) FILTER (WHERE gap > 0 AND gap - 3 <= 0 AND is_unsatisfied) AS evites_3j,
    COUNT(*) FILTER (WHERE gap > 0 AND gap - 5 <= 0 AND is_unsatisfied) AS evites_5j,
    COUNT(*) FILTER (WHERE gap > 0 AND gap - 7 <= 0 AND is_unsatisfied) AS evites_7j
FROM mart.orders;

-- RÉSULTAT
--
--   3 984 CLIENTS MÉCONTENTS parmi les commandes en retard,
--   soit 61 % des 6 534 commandes concernées.
--
--   Gain   Mécontents évités   Part des 3 984
--     1           162              4,1 %
--     2           346              8,7 %
--     3           596             15,0 %
--     5         1 120             28,1 %
--     7         1 777             44,6 %
--
-- PLUS FAIBLE QUE SUR LES COMMANDES
--   7 jours gagnés -> 56 % des commandes récupérées
--                  -> 45 % des mécontents évités
--
-- LES COMMANDES RÉCUPÉRÉES EN PREMIER SONT LES MOINS
-- PROBLÉMATIQUES : cohérent avec O3, où l'insatisfaction ne
-- dépassait 50 % qu'à partir de 3 jours.
--
-- LIMITE : rien ne garantit que ces 3 984 clients auraient été
-- satisfaits à l'heure : leur mécontentement pouvait aussi
-- venir du produit. Mais O3 mesure que le taux d'insatisfaction
-- passe de 49 % à 11,5 % quand on repasse à l'heure : la
-- majorité aurait basculé. ESTIMATION HAUTE.


-- ============================================================
-- Q4. OÙ LE GAIN RAPPORTE-T-IL LE PLUS ?
-- ============================================================
SELECT
    customer_state,
    COUNT(*) FILTER (WHERE gap > 0)                     AS commandes_en_retard,
    ROUND(SUM(payment_total) FILTER (WHERE gap > 0), 2) AS ca_expose,
    ROUND(SUM(payment_total) FILTER (WHERE gap > 0 AND gap - 3 <= 0), 2) AS ca_recupere_3j,
    ROUND(SUM(payment_total) FILTER (WHERE gap > 0 AND gap - 7 <= 0), 2) AS ca_recupere_7j,
    ROUND(SUM(payment_total) FILTER (WHERE gap > 0 AND gap - 7 <= 0) * 100.0
          / SUM(payment_total) FILTER (WHERE gap > 0), 2)                AS part_recuperable_7j
FROM mart.orders
WHERE customer_state IN ('SP','RJ','MG','RS','PR','SC','BA','ES')
GROUP BY customer_state
ORDER BY ca_recupere_7j DESC;

-- RÉSULTAT : CONTRE-INTUITIF
--
--   État  CA exposé   Récupéré 7j   PART RÉCUPÉRABLE
--   SP     303 157      197 056         65,0 %
--   RJ     251 556      105 797         42,1 %   <-
--   MG      88 243       53 391         60,5 %
--   BA      73 541       35 560         48,4 %
--   SC      45 023       29 588         65,7 %
--   ES      40 333       29 521         73,2 %
--   RS      51 863       25 336         48,9 %
--   PR      34 203       21 379         62,5 %
--
-- UN GAIN DE 7 JOURS RÉCUPÈRE 197 056 R$ À SÃO PAULO CONTRE
-- 105 797 R$ À RIO : presque le double, alors que leur CA
-- exposé est comparable.
--
-- POURQUOI RJ RÉSISTE : 42 % seulement de son CA exposé est
-- récupérable, contre 65 % à SP. C'est exactement ce qu'O1
-- montrait : 58 % DES RETARDS DE RJ DÉPASSENT 8 JOURS.
--
-- -> DEUX ACTIONS DISTINCTES
--   SP, ES, SC, MG  Gain de quelques jours   60-73 % récupérés
--   RJ              CORRECTION DE FOND       42 % seulement


-- ============================================================
-- Q5. VISER ZÉRO OU LE SEUIL DE 3 JOURS ?
-- ============================================================
-- O3 a établi que la bascule se fait à 3 jours : au-delà, plus
-- de la moitié des clients sont mécontents (50,40 %).
--
-- Deux objectifs pour un même effort :
--   « à l'heure »     -> gap - X <= 0
--   « sous 3 jours »  -> gap >= 3 AND gap - X < 3
--
-- Le second ne concerne QUE les commandes actuellement
-- au-dessus du seuil : les petits retards en sont exclus.
SELECT
    COUNT(*) FILTER (WHERE gap > 0) AS retard_actuel,

    COUNT(*) FILTER (WHERE gap > 0 AND gap - 2 <= 0) AS a_lheure_2j,
    COUNT(*) FILTER (WHERE gap > 0 AND gap - 3 <= 0) AS a_lheure_3j,
    COUNT(*) FILTER (WHERE gap > 0 AND gap - 5 <= 0) AS a_lheure_5j,

    COUNT(*) FILTER (WHERE gap >= 3 AND gap - 2 < 3) AS sous_seuil_2j,
    COUNT(*) FILTER (WHERE gap >= 3 AND gap - 3 < 3) AS sous_seuil_3j,
    COUNT(*) FILTER (WHERE gap >= 3 AND gap - 5 < 3) AS sous_seuil_5j
FROM mart.orders;

-- RÉSULTAT : INATTENDU
--
--   Gain   Ramenées à l'heure   Passées sous 3 jours
--     2          1 370                  953
--     3          1 870                1 400
--     5          2 770                2 302
--
-- L'OBJECTIF « À L'HEURE » EST PLUS ATTEIGNABLE QUE L'OBJECTIF
-- « SOUS 3 JOURS ».
--
-- POURQUOI : les deux populations diffèrent.
--   « À l'heure »     vise les commandes à 1, 2, 3 jours :
--                     nombreuses et proches du but
--   « Sous 3 jours »  ne concerne que celles DÉJÀ au-dessus de
--                     3 jours
--
-- -> L'OBJECTIF INTERMÉDIAIRE N'APPORTE RIEN. Plus difficile à
--   atteindre ET moins satisfaisant : une commande à 2 jours de
--   retard produit encore 34 % d'insatisfaction.
--   VISER LE RETOUR À L'HEURE.


-- ============================================================
-- Q6. LE GAIN SIMULÉ EST-IL RÉALISTE ?
-- ============================================================
-- Q1 à Q5 supposent un gain de 1 à 7 jours SANS vérifier qu'il
-- soit atteignable.
--
-- MÉTHODE : comparer l'acheminement médian des commandes en
-- retard à celui des commandes à l'heure, DANS LE MÊME ÉTAT.
-- L'écart mesure le gain théoriquement récupérable.
SELECT
    customer_state,
    COUNT(*) FILTER (WHERE NOT is_late) AS nb_a_lheure,
    COUNT(*) FILTER (WHERE is_late)     AS nb_en_retard,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gap_shipping)
        FILTER (WHERE NOT is_late)      AS achem_a_lheure,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gap_shipping)
        FILTER (WHERE is_late)          AS achem_en_retard,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gap_shipping)
        FILTER (WHERE is_late)
    - PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gap_shipping)
        FILTER (WHERE NOT is_late)      AS gain_theorique
FROM mart.orders
WHERE customer_state IN ('SP','RJ','MG','RS','PR','SC','BA','ES')
GROUP BY customer_state
ORDER BY gain_theorique DESC;

-- RÉSULTAT
--
--   État   À l'heure   En retard   GAIN THÉORIQUE
--   RS         9 j        32 j         23 j
--   RJ         8 j        30 j         22 j
--   SC         9 j        27 j         18 j
--   BA        13 j        30 j         17 j
--   ES         9 j        26 j         17 j
--   PR         7 j        24 j         17 j
--   MG         7 j        22 j         15 j
--   SP         4 j        15 j         11 j
--
-- L'ÉCART EST DE 11 À 23 JOURS.
-- -> LE SCÉNARIO DE 7 JOURS EST MODESTE : il ne comble qu'un
--   tiers à deux tiers de l'écart réel.
--   Les simulations ne sont pas ambitieuses, elles sont
--   PRUDENTES. Le gisement est plus large que ce qui a été
--   chiffré.


-- ============================================================
-- Q7. QUI SONT LES COMMANDES IRRÉCUPÉRABLES ?
-- ============================================================
-- Après 7 jours gagnés, 2 862 commandes restent en retard.
SELECT
    customer_state,
    timing,
    COUNT(*)                                         AS nb_commandes,
    ROUND(SUM(payment_total), 2)                     AS ca_residuel,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gap) AS retard_median
FROM mart.orders
WHERE gap - 7 > 0
GROUP BY customer_state, timing
HAVING COUNT(*) >= 30
ORDER BY nb_commandes DESC;

-- RÉSULTAT : CONCENTRÉ SUR RJ
--
--   État  Tranche      Commandes   CA résiduel   Retard médian
--   RJ    Late             423        72 292         11 j
--   SP    Late             345        64 733         10 j
--   RJ    Too late         313        49 959         21 j
--   SP    Too late         145        29 028         20 j
--   RJ    Very late        135        23 508         38 j   <-
--   BA    Late             119        24 655         11 j
--   MG    Late             108        18 466         11 j
--   SP    Very late         65        12 340         52 j
--
-- RJ CUMULE 871 COMMANDES IRRÉCUPÉRABLES POUR 145 759 R$.
-- Ses Very late ont un retard médian de 38 JOURS : aucun gain
-- opérationnel raisonnable ne les rattrapera.
--
-- -> UN GAIN UNIFORME NE RÈGLE PAS RJ. Confirmation de Q4.


-- ============================================================
-- Q8. COMBIEN RAPPORTE UN JOUR GAGNÉ ?
-- ============================================================
-- LE PROBLÈME : améliorer l'acheminement COÛTE de l'argent :
-- transporteurs supplémentaires, entrepôts régionaux,
-- partenaire premium. Aucune donnée de coût logistique
-- n'existe dans le dataset.
--
-- CE QU'ON PEUT FAIRE : calculer le BÉNÉFICE par jour gagné.
-- Il devient alors un SEUIL DE DÉCISION : tout investissement
-- inférieur à ce montant est rentable sur ce seul critère.
--
-- Chaque colonne isole le gain MARGINAL du jour concerné, pas
-- le cumul : la double condition encadre les commandes
-- récupérées par ce jour-là précisément.
SELECT
    ROUND(SUM(payment_total) FILTER (WHERE gap > 0 AND gap - 1 <= 0), 2)     AS gain_jour_1,
    ROUND(SUM(payment_total) FILTER (WHERE gap - 1 > 0 AND gap - 2 <= 0), 2) AS gain_jour_2,
    ROUND(SUM(payment_total) FILTER (WHERE gap - 2 > 0 AND gap - 3 <= 0), 2) AS gain_jour_3,
    ROUND(SUM(payment_total) FILTER (WHERE gap - 4 > 0 AND gap - 5 <= 0), 2) AS gain_jour_5,
    ROUND(SUM(payment_total) FILTER (WHERE gap - 6 > 0 AND gap - 7 <= 0), 2) AS gain_jour_7,
    ROUND(SUM(payment_total) FILTER (WHERE gap > 0 AND gap - 7 <= 0) / 7, 2) AS gain_moyen_par_jour
FROM mart.orders;

-- RÉSULTAT
--
--   Jour        Gain marginal
--   1er          134 881,50 R$   <- +60 % vs les suivants
--   2e            83 485,53
--   3e            76 616,89
--   5e            86 625,04
--   7e            84 265,28
--   MOYENNE       ~89 660 R$
--
-- LE PREMIER JOUR RAPPORTE 60 % DE PLUS QUE LES SUIVANTS :
-- il récupère les commandes à exactement 1 jour de retard, les
-- plus nombreuses.
--
-- ENSUITE LE RENDEMENT SE STABILISE autour de 80 000 à
-- 87 000 R$ par jour. Pas de décroissance marquée :
-- encourageant pour un investissement progressif.
--
-- -> LE CRITÈRE DE DÉCISION
--   « Un jour gagné sur l'acheminement rapporte environ
--     90 000 R$ de CA récupéré. Tout investissement
--     permettant de gagner un jour pour moins de 90 000 R$
--     est rentable sur ce seul critère : sans compter les
--     ~250 clients mécontents évités. »
--
-- DEUX NUANCES À POSER
--   1. Ces 90 000 R$ sont du CA EXPOSÉ RÉCUPÉRÉ, pas du profit
--   2. Le gain est calculé sur la période du dataset : à
--      rapporter à une base annuelle pour comparer à un
--      investissement


-- ============================================================
-- SYNTHÈSE O7
-- ============================================================
--  1. LE RENDEMENT EST LINÉAIRE : 450 à 500 commandes par jour
--     gagné
--  2. 7 JOURS RÉCUPÈRENT 3 672 COMMANDES (56 %) et
--     627 619 R$ (54,5 %)
--  3. LE CA PROGRESSE MOINS VITE QUE LE VOLUME
--  4. 3 984 CLIENTS MÉCONTENTS concernés ; 7 jours en
--     éviteraient 1 777 (44,6 %)
--  5. LE GAIN RAPPORTE PLUS À SÃO PAULO (197 056 R$, 65 %)
--     QU'À RIO (105 797 R$, 42 %)
--  6. VISER LE RETOUR À L'HEURE, PAS UN SEUIL INTERMÉDIAIRE
--  7. LE GAIN THÉORIQUE EST DE 11 À 23 JOURS : le scénario de
--     7 jours est PRUDENT
--  8. 871 COMMANDES IRRÉCUPÉRABLES À RJ, dont 135 à 38 jours
--  9. UN JOUR GAGNÉ RAPPORTE ~90 000 R$ : seuil de décision
--     pour tout investissement logistique
--
-- LA RECOMMANDATION EN DEUX VOLETS
--   Partout sauf RJ  -> un gain de quelques jours récupère
--                      60-73 % du CA exposé
--   RJ               -> correction de fond de l'acheminement
--
-- LE LIEN AVEC O8
-- Gagner 1 jour en exécution récupère 825 commandes ;
-- retrancher 1 jour à la promesse en coûte 1 292.
-- MIEUX VAUT GAGNER EN EXÉCUTION QUE RACCOURCIR LA PROMESSE.
-- ============================================================