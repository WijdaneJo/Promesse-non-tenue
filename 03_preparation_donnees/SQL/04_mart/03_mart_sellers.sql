-- ============================================================
-- ÉTAPE 6 — COUCHE MART : mart.sellers
-- ============================================================
-- Table analytique au grain VENDEUR.
-- Une ligne = un vendeur retenu (1 323), avec son profil de
-- performance de livraison.
--
-- Usage : O5 (lien entre performance de livraison et activité)
-- et classement des vendeurs pour la direction des
-- partenariats.
--
-- PRÉREQUIS : 01_mart_orders.sql.
--
-- DEUX FILTRES, DEUX RÈGLES DISTINCTES :
--
--   WHERE nb_sellers = 1  — RG-09, filtre des COMMANDES.
--     Les commandes multi-vendeurs (1,3 %) sont écartées :
--     le retard ne peut être imputé à un vendeur identifié.
--
--   HAVING COUNT(*) >= 10 — RG-08, filtre des VENDEURS.
--     Un vendeur à 2 commandes dont 1 en retard afficherait
--     50 % de retard, ce qui ne signifie rien.
--     Le WHERE ne peut pas faire ce travail : au moment où il
--     s'applique, le comptage par vendeur n'existe pas encore.
--
-- IMPACT DU SEUIL — mesuré avant de le fixer :
--   1 323 vendeurs retenus sur 2 948   (44,9 %)
--   101 382 commandes sur 107 087      (94,7 %)
--   → on écarte 55 % des vendeurs mais seulement 5,3 % de
--     l'activité. Le bruit statistique part, le phénomène reste.
--
-- late_rate : AVG(is_late::INT). En PostgreSQL, true → 1 et
-- false → 0 ; la moyenne de ces 0/1 EST le taux. C'est pour
-- cela que is_late a été conçu comme booléen et non comme
-- libellé texte.
--
-- seller_state figure dans le GROUP BY : toute colonne du
-- SELECT doit être agrégée ou groupée. PostgreSQL ne sait pas
-- qu'un vendeur n'a qu'un seul état — il faut le lui dire.
-- Le résultat est identique, la contrainte est syntaxique.

DROP TABLE IF EXISTS mart.sellers;

CREATE TABLE mart.sellers AS
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

    FROM mart.orders AS mo
    LEFT JOIN staging.order_items AS si ON mo.order_id = si.order_id
    LEFT JOIN staging.sellers     AS ss ON si.seller_id = ss.seller_id
    WHERE mo.nb_sellers = 1
    GROUP BY si.seller_id, ss.seller_state
    HAVING COUNT(*) >= 10;


-- ── Contrôles ───────────────────────────────────────────────
SELECT COUNT(*) FROM mart.sellers;   -- attendu : 1 323

SELECT seller_id FROM mart.sellers
GROUP BY seller_id HAVING COUNT(*) > 1;   -- attendu : 0 ligne

SELECT * FROM mart.sellers ORDER BY late_rate DESC LIMIT 10;
-- Les 10 vendeurs les plus en difficulté sur la livraison.