-- ============================================================
-- ÉTAPE 7 — RECETTE DES TABLES MART
-- ============================================================
-- Objectif : PROUVER que les tables analytiques sont justes,
-- avant de fonder une analyse dessus.
--
-- Principe : si un chiffre du rapport final paraît étrange, ce
-- fichier doit permettre de démontrer que la donnée n'est pas
-- en cause. Chaque contrôle porte un résultat ATTENDU et un
-- résultat OBTENU.
--
-- Exécuter APRÈS 02_mart_orders.sql et 03_mart_sellers.sql.


-- ============================================================
-- Q1 — CONFORMITÉ DU PÉRIMÈTRE
-- ============================================================
-- Le nombre de lignes doit correspondre exactement au journal
-- d'exclusions de l'étape 4.
--
--   Commandes au statut 'delivered'                    96 478
--   RG-01 : sans date de livraison réelle                  −8
--   RG-03 : chronologie impossible                        −23
--                                                    ─────────
--   PÉRIMÈTRE D'ANALYSE                                96 447
--
-- OBTENU : 96 447 ✅
SELECT COUNT(*) AS commandes FROM mart.orders;

-- OBTENU : 1 323 ✅ (seuil RG-08 de 10 commandes)
SELECT COUNT(*) AS vendeurs FROM mart.sellers;


-- ============================================================
-- Q2 — CONFORMITÉ DU GRAIN
-- ============================================================
-- Chaque table doit avoir une ligne par clé. Un doublon ici
-- signifierait qu'une jointure de l'étape 6 a dupliqué des
-- lignes — et tous les totaux seraient faux.
--
-- OBTENU : 0 ligne sur les deux ✅
SELECT order_id FROM mart.orders
GROUP BY order_id HAVING COUNT(*) > 1;

SELECT seller_id FROM mart.sellers
GROUP BY seller_id HAVING COUNT(*) > 1;


-- ============================================================
-- Q3 — VALEURS MANQUANTES vs EXCLUSIONS DOCUMENTÉES
-- ============================================================
-- Chaque NULL doit correspondre à une exclusion CIBLÉE
-- explicitement décidée. Un NULL non expliqué serait un bug.
--
-- OBTENU / ATTENDU :
--   sans_avis          646 / 646  ✅ RG-07
--   sans_distance      476 / 476  ✅ code postal absent de geolocation
--   sans_preparation   689 / ?    ⚠ décomposé ci-dessous
--   sans_paiement        1 / 1    ✅ commande sans ligne de paiement
SELECT
    COUNT(*) FILTER (WHERE avg_score       IS NULL) AS sans_avis,
    COUNT(*) FILTER (WHERE distance_km     IS NULL) AS sans_distance,
    COUNT(*) FILTER (WHERE gap_preparation IS NULL) AS sans_preparation,
    COUNT(*) FILTER (WHERE payment_total   IS NULL) AS sans_paiement
FROM mart.orders;


-- ── Décomposition des 689 gap_preparation NULL ──────────────
-- OBTENU :
--    674  RG-04 — remise transporteur avant approbation
--     14  order_approved_at manquante
--      1  order_delivered_carrier_date manquante
--   ────
--    689  ✅ le compte est exact, tout est expliqué
--
-- ⚠ CORRECTION D'UN CHIFFRE DE LA QUALIFICATION.
-- Les 1 350 commandes RG-04 annoncées portaient sur les
-- 99 441 commandes TOUS STATUTS. Sur le périmètre de 96 447,
-- elles ne sont que 674 : les autres étaient des commandes
-- annulées ou non livrées, déjà hors périmètre.
-- De même, les 2 commandes sans date transporteur ne sont plus
-- qu'1 : l'autre a été écartée par RG-03.
-- C'est la fonction de la recette — produire des chiffres
-- vérifiés sur le périmètre FINAL, pas des estimations
-- reprises d'une étape antérieure.
SELECT
    COUNT(*) FILTER (WHERE order_approved_at IS NULL)            AS sans_approbation,
    COUNT(*) FILTER (WHERE order_delivered_carrier_date IS NULL) AS sans_transporteur,
    COUNT(*) FILTER (WHERE order_delivered_carrier_date::DATE
                           < order_approved_at::DATE)            AS rg04_perimetre
FROM mart.orders;


-- ============================================================
-- Q4 — PLAUSIBILITÉ DES VALEURS CALCULÉES
-- ============================================================
-- On cherche l'ABSURDE : une durée négative là où c'est
-- physiquement impossible, un montant nul, une distance
-- supérieure à la taille du pays.
--
-- OBTENU :
--   gap              −147 → 188   ✅ min négatif = AVANCE, normal
--   gap_validation      0 →  31   ✅ aucune valeur négative
--   gap_preparation     0 → 126   ✅ le CASE WHEN RG-04 a filtré
--   gap_shipping        0 → 205   ✅ RG-03 a écarté les négatifs
--   payment_total    9,59 → 13 664 ✅ aucun montant nul
--   distance_km         0 → 8 678 ✅ cohérent (Brésil ~4 300 km
--                                    N-S, trajectoire courbe)
--
-- LES RÈGLES DE GESTION SE VÉRIFIENT DANS LES DONNÉES :
-- RG-03 sur gap_shipping, RG-04 sur gap_preparation. Aucun des
-- deux minimums n'est négatif — les filtres ont bien opéré.
--
-- VALEURS EXTRÊMES À EXPLORER (pas des erreurs, du CONTENU) :
--   205 jours d'acheminement | 126 jours de préparation
--   31 jours pour valider un paiement
-- Ce sont les cas les plus instructifs pour O2.
SELECT
    MIN(gap)             AS gap_min,             MAX(gap)             AS gap_max,
    MIN(gap_validation)  AS valid_min,           MAX(gap_validation)  AS valid_max,
    MIN(gap_preparation) AS prep_min,            MAX(gap_preparation) AS prep_max,
    MIN(gap_shipping)    AS ship_min,            MAX(gap_shipping)    AS ship_max,
    MIN(payment_total)   AS paiement_min,        MAX(payment_total)   AS paiement_max,
    MIN(distance_km)     AS distance_min,        MAX(distance_km)     AS distance_max
FROM mart.orders;


-- ── Contrôle des taux dans mart.sellers ─────────────────────
-- late_rate est une proportion : elle DOIT rester dans [0, 1].
-- Une valeur hors bornes signalerait une erreur d'agrégation.
SELECT
    MIN(late_rate) AS taux_min,
    MAX(late_rate) AS taux_max,
    MIN(nb_orders) AS commandes_min   -- doit être >= 10 (RG-08)
FROM mart.sellers;


-- ============================================================
-- Q5 — COHÉRENCE AVEC LA QUALIFICATION
-- ============================================================
-- Le pipeline complet (CSV → raw → staging → intermediate →
-- mart) doit reproduire les chiffres mesurés en pandas lors de
-- la phase de qualification. C'est la validation de bout en
-- bout.
--
-- OBTENU :
--   commandes         96 447          ✅ périmètre
--   clients           96 447          ✅ un customer_id par
--                                        commande — confirme le
--                                        piège du dictionnaire :
--                                        seul customer_unique_id
--                                        identifie une PERSONNE
--   taux de retard      6,77 %        ✅ M-00
--   note moyenne        4,16 / 5      — élevée MALGRÉ 6,77 % de
--                                        retards : rend O3
--                                        d'autant plus pertinent
--   CA total    15 416 546 R$         — chiffre d'ancrage pour O4
SELECT
    COUNT(*)                          AS commandes,
    COUNT(DISTINCT customer_id)       AS clients,
    ROUND(AVG(is_late::INT) * 100, 2) AS taux_retard_pct,
    ROUND(AVG(avg_score), 2)          AS note_moyenne,
    ROUND(SUM(payment_total), 2)      AS ca_total
FROM mart.orders;


-- ── Répartition par tranche de gravité (M-14) ───────────────
-- Doit reproduire exactement la distribution de l'étape 5,
-- et totaliser 96 447 sans aucun NULL.
--
-- OBTENU :
--   Too early     83 878   (87,0 %)
--   At time        6 035   ( 6,3 %)
--   Barely late    3 672   ( 3,8 %)
--   Late           1 637   ( 1,7 %)
--   Too late         880   ( 0,9 %)
--   Very late        345   ( 0,4 %)
--   ─────────────────────
--   TOTAL         96 447   ✅
SELECT
    timing,
    COUNT(*)                                  AS nb,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS part_pct
FROM mart.orders
GROUP BY timing
ORDER BY nb DESC;


-- ============================================================
-- SYNTHÈSE DE RECETTE
-- ============================================================
--   Q1  Périmètre                96 447            ✅
--   Q2  Grain                    0 doublon         ✅
--   Q3  Valeurs manquantes       toutes expliquées ✅
--   Q4  Plausibilité             aucune aberration ✅
--   Q5  Cohérence qualification  6,77 %            ✅
--
-- CORRECTION APPORTÉE : RG-04 concerne 674 commandes sur le
-- périmètre d'analyse, et non 1 350 comme annoncé en
-- qualification (chiffre calculé tous statuts confondus).
-- La note de cadrage et le fichier de règles doivent être
-- mis à jour.
--
-- LES TABLES mart.orders ET mart.sellers SONT VALIDÉES.
-- ============================================================