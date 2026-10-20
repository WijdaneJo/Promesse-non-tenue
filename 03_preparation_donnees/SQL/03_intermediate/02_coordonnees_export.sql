-- ============================================================
-- ÉTAPE 4 bis : EXPORT DES COORDONNÉES POUR CALCUL DE DISTANCE
-- ============================================================
-- Cette requête n'est PAS exécutée directement en SQL : elle
-- est lue par PYTHON/distances.py, qui calcule la distance
-- Haversine et écrit intermediate.distances.
--
-- Le pipeline est HYBRIDE à partir d'ici. Ordre d'exécution :
--   1. 03_intermediate/01_intermediate.sql
--   2. PYTHON/distances.py   (utilise cette requête)
--   3. 04_mart/02_mart_orders.sql
--
-- POURQUOI PYTHON : la formule de Haversine calcule une
-- distance sur une SPHÈRE. Une distance euclidienne sur des
-- lat/lng déforme : un degré de longitude rétrécit à mesure
-- qu'on s'éloigne de l'équateur, et le Brésil s'étend sur
-- ~39 degrés de latitude. L'erreur serait significative.
--
-- geolocation_pref est jointe DEUX FOIS, avec deux alias :
-- geo_c pour le client, geo_s pour le vendeur. Sans alias
-- distincts, PostgreSQL ne saurait pas de quelle instance
-- on parle.
--
-- PAS DE GROUP BY : une commande peut avoir plusieurs vendeurs,
-- donc plusieurs distances. Agréger les COORDONNÉES
-- (MAX(lat), MAX(lng)) produirait un point inexistant, mêlant
-- la latitude d'un vendeur à la longitude d'un autre. Chaque
-- distance doit être calculée AVANT d'être agrégée : c'est
-- Python qui fait le MAX par order_id.
--
-- DISTINCT : évite qu'un vendeur ayant 3 articles dans la
-- même commande n'apparaisse 3 fois.
--
-- LEFT JOIN et non INNER : en INNER, 476 commandes
-- disparaissaient (95 971 au lieu de 96 447) : un code postal
-- client ou vendeur absent de geolocation. Une distance
-- manquante ne justifie pas d'exclure une commande des
-- analyses de retard, de satisfaction ou de CA.
-- Exclusion ciblée, comme RG-04 et RG-07.
--
-- SORTIE ATTENDUE :
--   97 607 lignes  (couples commande × vendeur)
--   96 447 order_id distincts
--   485 lignes sans coordonnées -> 476 commandes sans distance
SELECT DISTINCT
    o.order_id,
    geo_c.avg_lat AS customer_lat,
    geo_c.avg_lng AS customer_lng,
    geo_s.avg_lat AS seller_lat,
    geo_s.avg_lng AS seller_lng
FROM intermediate.orders AS o
LEFT JOIN staging.customers AS c
    ON o.customer_id = c.customer_id
LEFT JOIN intermediate.geolocation_pref AS geo_c
    ON c.customer_zip_code_prefix = geo_c.geolocation_zip_code_prefix
LEFT JOIN staging.order_items AS it
    ON o.order_id = it.order_id
LEFT JOIN staging.sellers AS s
    ON it.seller_id = s.seller_id
LEFT JOIN intermediate.geolocation_pref AS geo_s
    ON s.seller_zip_code_prefix = geo_s.geolocation_zip_code_prefix;


-- -- Contrôle de non-perte -----------------------------------
-- Doit retourner 96 447. Un chiffre inférieur signalerait un
-- INNER JOIN oublié dans la chaîne : un seul suffit à annuler
-- l'effet de tous les LEFT qui précèdent.
SELECT COUNT(DISTINCT o.order_id)
FROM intermediate.orders AS o
LEFT JOIN staging.customers AS c
    ON o.customer_id = c.customer_id
LEFT JOIN intermediate.geolocation_pref AS geo_c
    ON c.customer_zip_code_prefix = geo_c.geolocation_zip_code_prefix
LEFT JOIN staging.order_items AS it
    ON o.order_id = it.order_id
LEFT JOIN staging.sellers AS s
    ON it.seller_id = s.seller_id
LEFT JOIN intermediate.geolocation_pref AS geo_s
    ON s.seller_zip_code_prefix = geo_s.geolocation_zip_code_prefix;


-- -- Contrôle de la table produite par Python ----------------
-- intermediate.distances : 96 447 lignes, dont 476 avec
-- distance_km NULL.
SELECT COUNT(*) FROM intermediate.distances;
SELECT COUNT(*) FROM intermediate.distances WHERE distance_km IS NULL;