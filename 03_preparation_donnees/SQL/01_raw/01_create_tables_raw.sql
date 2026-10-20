-- ============================================================
-- ÉTAPE 1 : COUCHE RAW
-- ============================================================
-- Rôle : copie fidèle des 9 CSV Olist.
-- Toutes les colonnes en TEXT, sans exception : si une valeur
-- est malformée, le chargement passe quand même et l'anomalie
-- se découvre par requête, pas par un plantage d'import.
-- Le typage se fait au passage vers staging, sous contrôle.
--
-- L'ORDRE DES COLONNES doit être celui du CSV : COPY associe
-- par position, jamais par nom. Une inversion se charge sans
-- erreur et place les données dans la mauvaise colonne.

DROP TABLE IF EXISTS raw.customers;
DROP TABLE IF EXISTS raw.geolocation;
DROP TABLE IF EXISTS raw.order_items;
DROP TABLE IF EXISTS raw.order_payments;
DROP TABLE IF EXISTS raw.order_reviews;
DROP TABLE IF EXISTS raw.orders;
DROP TABLE IF EXISTS raw.products;
DROP TABLE IF EXISTS raw.sellers;
DROP TABLE IF EXISTS raw.category_name_translation;


CREATE TABLE raw.customers (
    customer_id              TEXT,
    customer_unique_id       TEXT,
    customer_zip_code_prefix TEXT,
    customer_city            TEXT,
    customer_state           TEXT
);

CREATE TABLE raw.geolocation (
    geolocation_zip_code_prefix TEXT,
    geolocation_lat             TEXT,
    geolocation_lng             TEXT,
    geolocation_city            TEXT,
    geolocation_state           TEXT
);

CREATE TABLE raw.order_items (
    order_id            TEXT,
    order_item_id       TEXT,
    product_id          TEXT,
    seller_id           TEXT,
    shipping_limit_date TEXT,
    price               TEXT,
    freight_value       TEXT
);

CREATE TABLE raw.order_payments (
    order_id             TEXT,
    payment_sequential   TEXT,
    payment_type         TEXT,
    payment_installments TEXT,
    payment_value        TEXT
);

CREATE TABLE raw.order_reviews (
    review_id               TEXT,
    order_id                TEXT,
    review_score            TEXT,
    review_comment_title    TEXT,
    review_comment_message  TEXT,
    review_creation_date    TEXT,
    review_answer_timestamp TEXT
);

CREATE TABLE raw.orders (
    order_id                      TEXT,
    customer_id                   TEXT,
    order_status                  TEXT,
    order_purchase_timestamp      TEXT,
    order_approved_at             TEXT,
    order_delivered_carrier_date  TEXT,
    order_delivered_customer_date TEXT,
    order_estimated_delivery_date TEXT
);

-- product_name_lenght : faute d'orthographe PRÉSENTE DANS LA
-- SOURCE, reproduite volontairement. raw copie, y compris les
-- fautes. La colonne est écartée en staging.
CREATE TABLE raw.products (
    product_id                 TEXT,
    product_category_name      TEXT,
    product_name_lenght        TEXT,
    product_description_lenght TEXT,
    product_photos_qty         TEXT,
    product_weight_g           TEXT,
    product_length_cm          TEXT,
    product_height_cm          TEXT,
    product_width_cm           TEXT
);

CREATE TABLE raw.sellers (
    seller_id              TEXT,
    seller_zip_code_prefix TEXT,
    seller_city            TEXT,
    seller_state           TEXT
);

CREATE TABLE raw.category_name_translation (
    product_category_name         TEXT,
    product_category_name_english TEXT
);


-- -- Volumétrie attendue après chargement --------------------
--   customers                   99 441
--   geolocation              1 000 163
--   order_items                112 650
--   order_payments             103 886
--   order_reviews               99 224
--   orders                      99 441
--   products                    32 951
--   sellers                      3 095
--   category_name_translation       71