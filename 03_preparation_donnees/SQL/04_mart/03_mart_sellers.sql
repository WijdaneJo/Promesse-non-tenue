-- ============================================================
-- ÉTAPE 6. COUCHE MART : mart.sellers
-- ============================================================
-- Table analytique au grain VENDEUR.
-- Une ligne = un vendeur retenu (1 217), avec son profil de
-- performance de livraison.
--
-- Usage : O5 (lien entre performance de livraison et activité)
-- et classement des vendeurs pour la direction des
-- partenariats.
--
-- PRÉREQUIS : 02_mart_orders.sql.
--
-- GRAIN : UNE LIGNE PAR COMMANDE avant agrégation.
-- staging.order_items est au grain ARTICLE ; la CTE order_seller
-- en extrait un couple (commande, vendeur) unique. Sans elle, une
-- commande de 3 articles compterait 3 fois dans nb_orders et les
-- taux, et son payment_total serait additionné 3 fois dans
-- total_revenue.
--
-- DEUX FILTRES, DEUX RÈGLES DISTINCTES :
--
--   WHERE nb_sellers = 1  : RG-09, filtre des COMMANDES.
--     Les commandes multi-vendeurs (1,3 %) sont écartées :
--     le retard ne peut être imputé à un vendeur identifié.
--
--   HAVING COUNT(*) >= 10 : RG-08, filtre des VENDEURS.
--     Un vendeur à 2 commandes dont 1 en retard afficherait
--     50 % de retard, ce qui ne signifie rien.
--     Le WHERE ne peut pas faire ce travail : au moment où il
--     s'applique, le comptage par vendeur n'existe pas encore.
--
-- IMPACT DU SEUIL : mesuré avant de le fixer (contrôle 4) :
--   1 217 vendeurs retenus sur 2 948   (41,3 %)
--   89 250 commandes sur 95 191        (93,8 %)
--   -> on écarte 59 % des vendeurs mais seulement 6,2 % de
--     l'activité. Le bruit statistique part, le phénomène reste.
--
-- late_rate : AVG(is_late::INT). En PostgreSQL, true -> 1 et
-- false -> 0 ; la moyenne de ces 0/1 EST le taux. C'est pour
-- cela que is_late a été conçu comme booléen et non comme
-- libellé texte.
--
-- seller_state figure dans le GROUP BY : toute colonne du
-- SELECT doit être agrégée ou groupée. PostgreSQL ne sait pas
-- qu'un vendeur n'a qu'un seul état : il faut le lui dire.
-- Le résultat est identique, la contrainte est syntaxique.

DROP TABLE IF EXISTS mart.sellers;

CREATE TABLE mart.sellers AS
    WITH order_seller AS (
        -- Une ligne par commande mono-vendeur (voir en-tête)
        SELECT DISTINCT oi.order_id, oi.seller_id
        FROM staging.order_items AS oi
        JOIN mart.orders AS m ON m.order_id = oi.order_id
        WHERE m.nb_sellers = 1
    )
    SELECT
        si.seller_id,
        ss.seller_state,

        -- Volume d'activité
        COUNT(*)                  AS nb_orders,
        SUM(mo.payment_total)     AS total_revenue,

        -- Performance de livraison
        AVG(mo.is_late::INT)      AS late_rate,
        AVG(mo.gap)               AS avg_gap,
        AVG(mo.gap_preparation)   AS avg_preparation_days,

        -- Satisfaction reçue
        AVG(mo.avg_score)         AS avg_score

    FROM order_seller AS si
    JOIN mart.orders              AS mo ON mo.order_id = si.order_id
    LEFT JOIN staging.sellers     AS ss ON si.seller_id = ss.seller_id
    GROUP BY si.seller_id, ss.seller_state
    HAVING COUNT(*) >= 10;


-- -- Contrôles -----------------------------------------------
-- 1. Nombre de vendeurs retenus (attendu : 1 217)
SELECT COUNT(*) FROM mart.sellers;

-- 2. Unicité (attendu : 0 ligne)
SELECT seller_id FROM mart.sellers
GROUP BY seller_id HAVING COUNT(*) > 1;

-- 3. Cohérence du CA : ne peut pas dépasser le CA mono-vendeur
SELECT
    (SELECT SUM(total_revenue) FROM mart.sellers)                AS ca_vendeurs_retenus,
    (SELECT SUM(payment_total) FROM mart.orders
      WHERE nb_sellers = 1)                                      AS ca_mono_vendeur;
-- Résultat : 13 716 463 R$ sur 15 092 034 R$ (90,9 %)

-- 4. Impact du seuil RG-08 (pour l'en-tête)
WITH par_vendeur AS (
    SELECT oi.seller_id, COUNT(DISTINCT oi.order_id) AS nb
    FROM staging.order_items AS oi
    JOIN mart.orders AS mo ON mo.order_id = oi.order_id
    WHERE mo.nb_sellers = 1
    GROUP BY oi.seller_id
)
SELECT
    COUNT(*) FILTER (WHERE nb >= 10)  AS vendeurs_retenus,
    COUNT(*)                          AS vendeurs_total,
    SUM(nb)  FILTER (WHERE nb >= 10)  AS commandes_retenues,
    SUM(nb)                           AS commandes_total
FROM par_vendeur;

-- 5. Les 10 vendeurs les plus en difficulté sur la livraison
SELECT * FROM mart.sellers ORDER BY late_rate DESC LIMIT 10;