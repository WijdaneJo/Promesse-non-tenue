-- ============================================================
-- ÉTAPE 3 — COUCHE STAGING
-- ============================================================
-- Rôle : copie TYPÉE et CORRIGÉE de raw.
-- Ce qui change  : les types, quelques nettoyages ciblés,
--                  les colonnes hors périmètre écartées.
-- Ce qui ne change PAS : le nombre de lignes. Aucun filtre,
--                  aucune jointure, aucune agrégation ici.
--                  Le périmètre (RG-01) s'applique en intermediate.
--
-- Convention : les identifiants et les codes postaux restent
-- en TEXT. Un code postal converti en INT perdrait son zéro
-- initial ('09790' → 9790) et casserait la jointure vers
-- geolocation — or São Paulo, première région du dataset,
-- est entièrement en 0xxxx.


-- ── 3.1 orders — table de faits centrale ────────────────────
-- 5 dates converties en TIMESTAMP (convertibilité validée en C5).
CREATE TABLE staging.orders AS
    SELECT
        order_id,
        customer_id,
        order_status,
        order_purchase_timestamp::TIMESTAMP      AS order_purchase_timestamp,
        order_approved_at::TIMESTAMP             AS order_approved_at,
        order_delivered_carrier_date::TIMESTAMP  AS order_delivered_carrier_date,
        order_delivered_customer_date::TIMESTAMP AS order_delivered_customer_date,
        order_estimated_delivery_date::TIMESTAMP AS order_estimated_delivery_date
    FROM raw.orders;


-- ── 3.2 order_items ─────────────────────────────────────────
-- order_item_id en INT : c'est un numéro d'ordre, un tri texte
-- donnerait 1, 10, 11, 2, 3…
CREATE TABLE staging.order_items AS
    SELECT
        order_id,
        order_item_id::INT              AS order_item_id,
        product_id,
        seller_id,
        shipping_limit_date::TIMESTAMP  AS shipping_limit_date,
        price::NUMERIC                  AS price,
        freight_value::NUMERIC          AS freight_value
    FROM raw.order_items;


-- ── 3.3 order_payments ──────────────────────────────────────
CREATE TABLE staging.order_payments AS
    SELECT
        order_id,
        payment_sequential::INT    AS payment_sequential,
        payment_type,
        payment_installments::INT  AS payment_installments,
        payment_value::NUMERIC     AS payment_value
    FROM raw.order_payments;


-- ── 3.4 order_reviews ───────────────────────────────────────
-- Colonnes écartées : review_comment_title et
-- review_comment_message (extension NLP, hors v1).
CREATE TABLE staging.order_reviews AS
    SELECT
        review_id,
        order_id,
        review_score::INT                   AS review_score,
        review_creation_date::TIMESTAMP     AS review_creation_date,
        review_answer_timestamp::TIMESTAMP  AS review_answer_timestamp
    FROM raw.order_reviews;


-- ── 3.5 products ────────────────────────────────────────────
-- Colonnes écartées : product_name_lenght,
-- product_description_lenght, product_photos_qty (non retenues
-- au dictionnaire).
-- NETTOYAGE : les 4 poids à 0 identifiés au bloc C sont des
-- valeurs NON RENSEIGNÉES codées en 0, pas des poids réels.
-- NULLIF les convertit en NULL — une absence honnête vaut mieux
-- qu'une valeur fausse qui biaiserait moyennes et modèle (O6).
-- Dimensions en INT : vérifié, aucune décimale dans la source.
CREATE TABLE staging.products AS
    SELECT
        product_id,
        product_category_name,
        NULLIF(product_weight_g::INT, 0) AS product_weight_g,
        product_length_cm::INT           AS product_length_cm,
        product_height_cm::INT           AS product_height_cm,
        product_width_cm::INT            AS product_width_cm
    FROM raw.products;

-- Contrôle : 2 NULL d'origine + 4 zéros convertis = 6 attendus
SELECT COUNT(*) FROM staging.products WHERE product_weight_g IS NULL;


-- ── 3.6 customers ───────────────────────────────────────────
-- customer_city écartée : maille d'analyse = l'état (27 modalités).
-- customer_unique_id conservé : coût nul, permet de tester
-- l'hypothèse des review_id dupliqués (même client ?).
CREATE TABLE staging.customers AS
    SELECT
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_state
    FROM raw.customers;


-- ── 3.7 sellers ─────────────────────────────────────────────
-- seller_zip_code_prefix conservé : clé du calcul de distance
-- vendeur → client, variable prédictive du délai (O6).
CREATE TABLE staging.sellers AS
    SELECT
        seller_id,
        seller_zip_code_prefix,
        seller_state
    FROM raw.sellers;


-- ── 3.8 geolocation ─────────────────────────────────────────
-- ATTENTION : table encore au mauvais grain (~50 points par
-- code postal). Elle sera agrégée par préfixe en intermediate.
-- Ne jamais la joindre en l'état.
CREATE TABLE staging.geolocation AS
    SELECT
        geolocation_zip_code_prefix,
        geolocation_lat::NUMERIC AS geolocation_lat,
        geolocation_lng::NUMERIC AS geolocation_lng
    FROM raw.geolocation;


-- ── 3.9 category_translation ────────────────────────────────
-- Table de correspondance, aucune conversion nécessaire.
-- Rappel : 73 catégories dans products, 71 traduites.
-- Une jointure LEFT laissera 2 valeurs vides — conserver le
-- nom portugais par défaut.
CREATE TABLE staging.category_translation AS
    SELECT
        product_category_name,
        product_category_name_english
    FROM raw.category_name_translation;


-- ── Contrôle de volumétrie ──────────────────────────────────
-- Chaque table staging doit avoir EXACTEMENT le même nombre de
-- lignes que sa source raw. Un écart signale une erreur de CAST
-- ou un filtre involontaire.
SELECT 'orders'        AS table_name, COUNT(*) FROM staging.orders
UNION ALL SELECT 'order_items',        COUNT(*) FROM staging.order_items
UNION ALL SELECT 'order_payments',     COUNT(*) FROM staging.order_payments
UNION ALL SELECT 'order_reviews',      COUNT(*) FROM staging.order_reviews
UNION ALL SELECT 'products',           COUNT(*) FROM staging.products
UNION ALL SELECT 'customers',          COUNT(*) FROM staging.customers
UNION ALL SELECT 'sellers',            COUNT(*) FROM staging.sellers
UNION ALL SELECT 'geolocation',        COUNT(*) FROM staging.geolocation
UNION ALL SELECT 'category_translation', COUNT(*) FROM staging.category_translation;