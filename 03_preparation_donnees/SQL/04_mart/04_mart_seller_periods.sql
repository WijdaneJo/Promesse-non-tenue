-- ============================================================
-- ÉTAPE 7. COUCHE MART : mart.seller_periods
-- ============================================================
-- Table au grain VENDEUR, sur deux fenêtres (RG-10) :
--   P1 = février-août 2017 | P2 = février-août 2018
-- Mêmes mois d'une année sur l'autre : saisonnalité neutralisée.
--
-- Alimente le visuel V12 du dashboard (phase 05) : le taux de
-- disparition selon le dépassement de la date limite (O5).
--
-- PRÉREQUIS : 02_mart_orders.sql (utilise is_limit_exceeded).
--
-- CORRECTION DE GRAIN par rapport à l'analyse O5 (phase 04) :
-- la jointure mart.orders × staging.order_items donnait UNE
-- LIGNE PAR ARTICLE. Une commande de 3 articles comptait 3 fois
-- dans COUNT(*) et pesait 3 fois dans les taux.
-- 8 359 commandes mono-vendeur ont plusieurs articles.
-- Ici, la CTE order_seller ramène à UNE LIGNE PAR COMMANDE.
--
-- Règles appliquées :
--   RG-09, commandes mono-vendeur uniquement
--   RG-08, au moins 10 COMMANDES en P1 (pas 10 articles)
--   RG-10 : deux fenêtres comparables
-- « Disparu » = zéro commande en P2. Un vendeur passé sous
-- 10 commandes n'a pas disparu, il s'est contracté.

DROP TABLE IF EXISTS mart.seller_periods;

CREATE TABLE mart.seller_periods AS
WITH order_seller AS (
    -- -- Un vendeur par commande -----------------------------
    -- Une commande mono-vendeur n'a qu'un vendeur : le DISTINCT
    -- supprime les lignes répétées par article.
    SELECT DISTINCT
        oi.order_id,
        oi.seller_id
    FROM staging.order_items AS oi
    JOIN mart.orders         AS mo ON mo.order_id = oi.order_id
    WHERE mo.nb_sellers = 1
)
SELECT
    os.seller_id,

    -- -- Période 1 : la CAUSE présumée -----------------------
    COUNT(*) FILTER (WHERE mo.purchase_year = 2017
                       AND mo.purchase_month BETWEEN 2 AND 8)  AS orders_p1,
    AVG(mo.is_late::INT) FILTER (WHERE mo.purchase_year = 2017
                       AND mo.purchase_month BETWEEN 2 AND 8)  AS late_rate_p1,
    -- AVG ignore le NULL de la commande sans date transporteur
    AVG(mo.is_limit_exceeded::INT) FILTER (WHERE mo.purchase_year = 2017
                       AND mo.purchase_month BETWEEN 2 AND 8)  AS limit_exceeded_rate_p1,

    -- -- Période 2 : la CONSÉQUENCE --------------------------
    COUNT(*) FILTER (WHERE mo.purchase_year = 2018
                       AND mo.purchase_month BETWEEN 2 AND 8)  AS orders_p2,

    -- -- Indicateurs dérivés ---------------------------------
    -- Calculés ici et non dans Power BI : la règle métier ne
    -- vit qu'à un seul endroit.
    (COUNT(*) FILTER (WHERE mo.purchase_year = 2018
                        AND mo.purchase_month BETWEEN 2 AND 8) = 0)
                                                               AS is_disappeared,
    (AVG(mo.is_limit_exceeded::INT) FILTER (WHERE mo.purchase_year = 2017
                        AND mo.purchase_month BETWEEN 2 AND 8) > 0.20)
                                                               AS is_high_exceeder

FROM order_seller AS os
JOIN mart.orders  AS mo ON mo.order_id = os.order_id
GROUP BY os.seller_id
HAVING COUNT(*) FILTER (WHERE mo.purchase_year = 2017
                          AND mo.purchase_month BETWEEN 2 AND 8) >= 10;


-- -- Contrôles -----------------------------------------------

-- 1. Nombre de vendeurs (phase 04, au grain article : 427)
SELECT COUNT(*) FROM mart.seller_periods;

-- 2. Unicité (attendu : 0 ligne)
SELECT seller_id FROM mart.seller_periods
GROUP BY seller_id HAVING COUNT(*) > 1;

-- 3. Recalcul de Q6 : disparus vs survivants
-- Phase 04 : disparus 96 vendeurs à 5,40 % | survivants 331 à 3,52 %
-- Même méthode qu'en phase 04 : moyenne simple des taux vendeurs.
SELECT
    is_disappeared,
    COUNT(*)                          AS nb_vendeurs,
    ROUND(AVG(late_rate_p1) * 100, 2) AS retard_p1_moyen_pct
FROM mart.seller_periods
GROUP BY is_disappeared;

-- 4. Recalcul de Q7 : disparition selon le dépassement
-- Phase 04 : ≤ 20 % à 21,11 % de disparus | > 20 % à 29,85 % (+41 %)
SELECT
    is_high_exceeder,
    COUNT(*)                                            AS nb_vendeurs,
    COUNT(*) FILTER (WHERE is_disappeared)              AS nb_disparus,
    ROUND(COUNT(*) FILTER (WHERE is_disappeared) * 100.0
          / COUNT(*), 2)                                AS taux_disparition_pct,
    ROUND(AVG(limit_exceeded_rate_p1) * 100, 2)         AS depassement_moyen_pct
FROM mart.seller_periods
GROUP BY is_high_exceeder;