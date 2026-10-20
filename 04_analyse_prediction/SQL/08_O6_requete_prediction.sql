-- ============================================================
-- O6. MODÈLE PRÉDICTIF DU RETARD : PARTIE SQL (Q1 à Q3)
-- ============================================================
-- Objectif : prédire le risque de non-respect du délai à partir
-- des SEULES informations disponibles au moment de la commande.
--
-- Métriques (cadrage) :
--   M-11 = retards détectés ÷ total des retards réels   (détection)
--   M-12 = fausses alertes ÷ total des alertes          (fausses alertes)
--
-- Ce fichier couvre :
--   Q1, l'audit des variables (fuites de données)
--   Q2, la règle de référence à battre
--   Q3 : le découpage entraînement / test
-- La modélisation (Q4 à Q8) est dans PYTHON/O6_modele_predictif.ipynb
--
-- Source : mart.orders, 96 447 commandes, 6 534 retards (6,77 %)
-- ============================================================


-- ============================================================
-- Q1. QUELLES VARIABLES A-T-ON LE DROIT D'UTILISER ?
-- ============================================================
-- Principe : on se place à l'instant du clic « Acheter ».
-- Une variable n'est utilisable que si sa valeur est DÉJÀ connue.
-- Sinon, c'est une FUITE : le modèle paraît excellent à
-- l'entraînement et devient inutile en production.
--
-- Utilisables : customer_state, purchase_year, purchase_month,
--    purchase_dow, nb_items, nb_sellers, total_price,
--    total_freight, payment_total, distance_km
--    + promised_days (à créer, voir ci-dessous)
-- Connues mais inutiles : order_id, customer_id
--    (identifiants uniques : le modèle ne ferait que les mémoriser)
-- Fuites : order_approved_at (arrive après le clic, parfois
--    plusieurs jours après), dates de remise et de livraison,
--    gap, gap_validation, gap_preparation, gap_shipping, timing,
--    avg_score, nb_reviews, is_unsatisfied
--
-- DEUX PIÈGES IDENTIFIÉS
-- 1. order_estimated_delivery_date EST connue à l'achat : le site
--    affiche la date promise avant validation. Elle avait été
--    classée par erreur en « non éligible » au démarrage.
-- 2. Le late_rate de mart.sellers est une FUITE : il est calculé
--    sur toutes les commandes 2016-2018, y compris la commande à
--    prédire et des commandes futures. Version correcte possible :
--    taux calculé sur les commandes STRICTEMENT ANTÉRIEURES du
--    vendeur (fonction fenêtre). Non retenu à ce stade.


-- -- Création de promised_days : le délai promis au client ----
-- ::DATE car une différence de deux DATE donne un ENTIER (jours).
-- Une différence de deux TIMESTAMP donnerait un INTERVAL.
-- Cohérent avec gap : la promesse porte sur une date, pas une heure.

WITH cte AS (
    SELECT
        order_estimated_delivery_date::DATE
            - order_purchase_timestamp::DATE AS promised_days
    FROM mart.orders
)
SELECT
    MIN(promised_days)                                          AS minimum,
    MAX(promised_days)                                          AS maximum,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY promised_days)  AS mediane
FROM cte;
-- Résultat : 3 | 156 | 24
-- Aucune valeur négative ou nulle : la variable est saine.
-- Les 156 jours restent à examiner (question ouverte).


-- -- promised_days distingue-t-il les retards ? ---------------
WITH cte AS (
    SELECT
        is_late,
        order_estimated_delivery_date::DATE
            - order_purchase_timestamp::DATE AS promised_days
    FROM mart.orders
)
SELECT
    is_late,
    COUNT(*)                            AS volume,
    ROUND(AVG(promised_days), 1)        AS promesse_moyenne
FROM cte
GROUP BY is_late;
-- Résultat (arrondi) :
--   false | 89 913 | ≈ 24 jours
--   true  |  6 534 | ≈ 23 jours
-- CONSTAT : seul, le délai promis ne distingue pas les retards.
-- On le GARDE quand même : combiné à la distance, il peut compter
-- (une promesse de 24 jours n'a pas le même sens à 200 km et à
-- 2 500 km). -> Confirmé en Q7 : c'est la variable n° 1 du modèle.


-- ============================================================
-- Q2. QUEL SCORE FAUT-IL BATTRE ?
-- ============================================================
-- Avant tout modèle, on mesure une règle simple issue d'O1 :
-- alerter toutes les commandes vers les états à fort taux.
-- Si le modèle ne fait pas mieux, il ne sert à rien.
-- (Règle naïve n° 0 : « jamais de retard » -> M-11 = 0 %.)


-- -- Taux de retard national : le seuil de référence ----------
SELECT ROUND(AVG(is_late::INT) * 100, 2) AS taux_retard
FROM mart.orders;
-- Résultat : 6.77
-- Pourquoi ce seuil : c'est le risque d'une commande prise au
-- hasard. Un état au-dessus est « plus risqué que la normale ».
-- Rejeté : le milieu entre min et max (12,09 %), qui ne dépend
-- que des deux états extrêmes (AM 145 commandes, AL 397).


-- -- Taux de retard par état ---------------------------------
-- AVG(is_late::INT) : true = 1, false = 0 -> la moyenne est le taux.
SELECT
    customer_state,
    COUNT(*)                            AS nb_orders,
    ROUND(AVG(is_late::INT) * 100, 2)   AS late_rate
FROM mart.orders
GROUP BY customer_state
ORDER BY late_rate DESC;
-- Résultat :
--   AL 397 21.41 | MA 717 17.43 | SE 335 15.22 | PI 476 13.87
--   CE 1 279 13.76 | RR 41 12.20 | BA 3 256 12.16 | RJ 12 349 12.11
--   PA 946 11.21 | ES 1 995 10.73 | PB 517 10.44 | TO 274 9.85
--   MS 701 9.70 | PE 1 593 9.60 | RN 474 9.28 | SC 3 544 8.21
--   ------------ seuil 6,77 % ------------
--   GO 1 957 6.54 | RS 5 343 6.08 | MT 886 5.98 | DF 2 080 5.67
--   MG 11 349 4.57 | SP 40 480 4.50 | PR 4 923 4.04 | AC 80 3.75
--   AP 67 2.99 | RO 243 2.88 | AM 145 2.76
-- -> 16 états en alerte (AL -> SC).
-- PIÈGE ÉVITÉ : SP a le plus gros VOLUME de retards mais l'un des
-- meilleurs TAUX. L'alerter reviendrait à signaler 42 % des
-- commandes, pour la plupart à l'heure.


-- -- M-11 et M-12 de la règle (seuil 6,77 %, toute la période) -
WITH cte AS (
    SELECT
        is_late,
        customer_state IN ('AL', 'MA', 'SE', 'PI', 'CE', 'RR', 'BA', 'RJ',
                           'PA', 'ES', 'PB', 'TO', 'MS', 'PE', 'RN', 'SC') AS alerte
    FROM mart.orders
)
SELECT
    COUNT(*) FILTER (WHERE alerte AND is_late)      AS vraies_alertes,
    COUNT(*) FILTER (WHERE alerte AND NOT is_late)  AS fausses_alertes,
    COUNT(*) FILTER (WHERE is_late)                 AS nb_retards,
    ROUND(100.0 * COUNT(*) FILTER (WHERE alerte AND is_late)
          / COUNT(*) FILTER (WHERE is_late), 1)     AS m11_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE alerte AND NOT is_late)
          / COUNT(*) FILTER (WHERE alerte), 1)      AS m12_pct
FROM cte;
-- Résultat : 3 356 | 25 538 | 6 534 | 51.4 | 88.4
-- 28 894 alertes = 30 % des commandes.
-- Taux de retard dans les alertes : 11,6 % (× 1,7 le hasard).


-- -- Variante : seuil à 10 % (11 états, AL -> PB) --------------
WITH cte AS (
    SELECT
        is_late,
        customer_state IN ('AL', 'MA', 'SE', 'PI', 'CE', 'RR', 'BA', 'RJ',
                           'PA', 'ES', 'PB') AS alerte
    FROM mart.orders
)
SELECT
    COUNT(*) FILTER (WHERE alerte AND is_late)      AS vraies_alertes,
    COUNT(*) FILTER (WHERE alerte AND NOT is_late)  AS fausses_alertes,
    ROUND(100.0 * COUNT(*) FILTER (WHERE alerte AND is_late)
          / COUNT(*) FILTER (WHERE is_late), 1)     AS m11_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE alerte AND NOT is_late)
          / COUNT(*) FILTER (WHERE alerte), 1)      AS m12_pct
FROM cte;
-- Résultat : 2 773 | 19 535 | 42.4 | 87.6
-- CONSTAT : monter le seuil fait perdre 9 points de détection
-- pour gagner moins d'1 point sur les fausses alertes.
-- Limite structurelle : même en n'alertant que AL (21,41 %),
-- 78,6 % des alertes seraient fausses. Une règle par état donne
-- la même alerte à toutes les commandes d'un état.


-- ============================================================
-- Q3. COMMENT SÉPARER ENTRAÎNEMENT ET TEST ?
-- ============================================================
-- Choix : découpage DANS LE TEMPS, pas au hasard.
-- Usage réel : apprendre sur le passé pour prédire le futur.
-- Un tirage au hasard laisserait le modèle apprendre avec des
-- commandes « du futur » : score trop optimiste.


-- -- Répartition des commandes et du retard par mois ----------
SELECT
    purchase_year,
    purchase_month,
    COUNT(*)                            AS nb_orders,
    ROUND(AVG(is_late::INT) * 100, 2)   AS late_rate
FROM mart.orders
GROUP BY purchase_year, purchase_month
ORDER BY purchase_year, purchase_month;
-- Résultat :
--   2016 : 09 1 (100.00) | 10 261 (0.77) | 12 1 (0.00)
--   2017 : 01 749 (2.94) | 02 1 651 (2.97) | 03 2 545 (4.56)
--          04 2 303 (6.56) | 05 3 544 (2.99) | 06 3 134 (3.03)
--          07 3 861 (2.80) | 08 4 191 (2.91) | 09 4 150 (4.39)
--          10 4 478 (4.18) | 11 7 288 (12.40) | 12 5 513 (7.46)
--   2018 : 01 7 069 (5.70) | 02 6 555 (14.13) | 03 7 003 (18.96)
--          04 6 798 (4.50) | 05 6 749 (6.56) | 06 6 096 (1.16)
--          07 6 156 (3.38) | 08 6 351 (6.19)
-- Coupure retenue : test = juin-août 2018 (18 603 commandes, 19,3 %).
-- 2016 pèse trop peu pour gêner : conservé.


-- -- Taux de retard de la période d'entraînement --------------
-- Inégalité STRICTE : le 1er juin appartient au test.
SELECT ROUND(AVG(is_late::INT) * 100, 2) AS late_rate
FROM mart.orders
WHERE order_purchase_timestamp::DATE < '2018-06-01';
-- Résultat : 7.53
-- Entraînement : 77 844 commandes, 7,53 % de retard
-- Test         : 18 603 commandes, ≈ 3,6 % de retard (672 retards)
-- -> Le test est deux fois moins exposé : il mesure la capacité
--   du modèle à fonctionner quand le contexte change.


-- -- Liste d'alerte recalculée sur l'entraînement seulement ---
-- Rigueur : la règle ne doit pas être choisie avec les données
-- de test. Seuil = taux de l'entraînement (7,53 %).
SELECT
    customer_state,
    COUNT(*)                            AS nb_orders,
    ROUND(AVG(is_late::INT) * 100, 2)   AS late_rate
FROM mart.orders
WHERE order_purchase_timestamp::DATE < '2018-06-01'
GROUP BY customer_state
ORDER BY late_rate DESC;
-- Résultat :
--   AL 335 24.18 | SE 261 18.77 | MA 608 18.26 | CE 1 068 16.39
--   RR 31 16.13 | RJ 10 223 13.96 | PI 395 13.92 | BA 2 654 13.90
--   PA 792 13.01 | ES 1 647 12.14 | PB 410 11.95 | RN 390 11.28
--   TO 221 10.86 | PE 1 283 10.83 | MS 568 9.68 | SC 2 943 9.55
--   ------------ seuil 7,53 % ------------
--   GO 1 623 7.33 | MT 742 7.01 | RS 4 438 6.92 | DF 1 625 6.46
--   MG 9 291 5.36 | PR 3 976 4.60 | SP 31 869 4.44 | AC 70 4.29
--   AP 57 3.51 | AM 116 3.45 | RO 208 3.37
-- -> Les MÊMES 16 états : le choix de la liste était robuste.


-- -- La règle notée sur la période de test --------------------
-- Même examen que le modèle : juin-août 2018.
WITH cte AS (
    SELECT
        is_late,
        order_purchase_timestamp,
        customer_state IN ('AL', 'MA', 'SE', 'PI', 'CE', 'RR', 'BA', 'RJ',
                           'PA', 'ES', 'PB', 'TO', 'MS', 'PE', 'RN', 'SC') AS alerte
    FROM mart.orders
)
SELECT
    COUNT(*) FILTER (WHERE alerte AND is_late)      AS nb_orders_true_alerts,
    COUNT(*) FILTER (WHERE alerte AND NOT is_late)  AS nb_false_alerts,
    COUNT(*) FILTER (WHERE is_late)                 AS nb_orders_late
FROM cte
WHERE order_purchase_timestamp::DATE >= '2018-06-01';
-- Résultat : 189 | 4 876 | 672
-- M-11 = 189 ÷ 672            = 28,1 %
-- M-12 = 4 876 ÷ 5 065        = 96,3 %
-- Taux de retard dans les alertes : 3,7 %, contre 3,6 % sur tout
-- le test -> la règle ne fait quasiment pas mieux que le hasard.
--
-- CONSTAT Q3 : la règle qui détectait la moitié des retards sur
-- l'historique n'en détecte plus que 28 % sur l'été 2018.
-- La géographie du retard a changé (expliqué en Q8 : inversion
-- RJ / SP liée au raccourcissement des promesses).
--
-- SCORE À BATTRE PAR LE MODÈLE (même test, 5 065 alertes) :
--   M-11 = 28,1 %  |  M-12 = 96,3 %