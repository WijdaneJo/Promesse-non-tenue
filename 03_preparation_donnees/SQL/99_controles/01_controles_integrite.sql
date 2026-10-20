-- ============================================================
-- CONTRÔLES D'INTÉGRITÉ : COUCHE RAW
-- Projet : La Promesse Non Tenue (Olist)
-- Base   : PostgreSQL 17
-- ============================================================


-- ============================================================
-- BLOC A : UNICITÉ DES CLÉS
-- ============================================================
-- Objectif : vérifier que le grain annoncé dans le dictionnaire
-- de données correspond au grain réel des tables chargées.


-- A1 : customers : unicité de customer_id
-- Résultat : 0 doublon -> conforme
SELECT customer_id, COUNT(*)
FROM raw.customers
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- A2 : orders : unicité de order_id
-- Résultat : 0 doublon -> conforme
SELECT order_id, COUNT(*)
FROM raw.orders
GROUP BY order_id
HAVING COUNT(*) > 1;


-- A3 : sellers : unicité de seller_id
-- Résultat : 0 doublon -> conforme
SELECT seller_id, COUNT(*)
FROM raw.sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;


-- A4 : products : unicité de product_id
-- Résultat : 0 doublon -> conforme
SELECT product_id, COUNT(*)
FROM raw.products
GROUP BY product_id
HAVING COUNT(*) > 1;


-- A5 : order_items : unicité de la clé composite
-- Grain attendu : une ligne = un article dans une commande.
-- order_id seul n'est pas unique (commande multi-articles) ;
-- c'est le couple order_id + order_item_id qui doit l'être.
-- Résultat : 0 doublon -> conforme
-- Conséquence : l'agrégation par order_id (étape 3) est fiable.
SELECT order_id, order_item_id, COUNT(*)
FROM raw.order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;


-- A6 : order_payments : unicité de la clé composite
-- Grain attendu : une ligne = un moyen de paiement pour une commande.
-- Résultat : 0 doublon -> conforme
-- Conséquence : SUM(payment_value) par order_id est fiable.
SELECT order_id, payment_sequential, COUNT(*)
FROM raw.order_payments
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1;


-- A7a, order_reviews : unicité de review_id
-- Résultat : ANOMALIE, 789 review_id apparaissent plusieurs fois.
-- Un même review_id est rattaché à plusieurs order_id,
-- avec note et dates identiques : il s'agit d'une seule
-- enquête couvrant deux commandes livrées ensemble.
-- Impact : NUL, la jointure vers orders se fait sur order_id.
-- Hypothèse à vérifier après les JOINs : même client ?
SELECT review_id, COUNT(*)
FROM raw.order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1;


-- A7a bis : inspection d'un cas de review_id dupliqué
SELECT *
FROM raw.order_reviews
WHERE review_id = '4fea089659b78b233489192ca88d8448';


-- A7b : order_reviews : nombre de commandes à avis multiples
-- Résultat : 547 commandes ont plus d'un avis.
-- Impact : RÉEL, une jointure directe avec orders dupliquerait
-- ces 547 commandes et fausserait périmètre et montants.
-- Décision requise (RG-06) : premier avis / dernier avis / moyenne.
SELECT order_id, COUNT(*)
FROM raw.order_reviews
GROUP BY order_id
HAVING COUNT(*) > 1;


-- ------------------------------------------------------------
-- SYNTHÈSE BLOC A
-- ------------------------------------------------------------
-- 6 clés sur 8 conformes au grain documenté.
-- 2 anomalies, toutes deux dans order_reviews :
--   - review_id non unique          -> sans impact
--   - 547 commandes multi-avis      -> traitement RG-06 requis
-- ============================================================






-- ============================================================
-- BLOC B : VALEURS MANQUANTES
-- ============================================================
-- Objectif : chiffrer les vides sur les colonnes dont dépendent
-- les objectifs O1 à O6.
-- Constat préalable : les vides ont été chargés en NULL,
-- pas en chaîne vide. Le test IS NULL suffit.


-- -- B1. orders : les dates du parcours ----------------------

-- B1a. Sans date de livraison, tous statuts confondus
-- Résultat : 2 965
-- Lecture : descriptif, correspond aux commandes non livrées
-- (annulées, indisponibles). Hors périmètre RG-01.
SELECT COUNT(*)
FROM raw.orders
WHERE order_delivered_customer_date IS NULL;

-- B1b. Sans date de livraison, parmi les commandes LIVRÉES
-- Résultat : 8  -> conforme à H2
-- Impact : EXCLUSION (RG-01). Retard non calculable.
-- Périmètre : 96 478 − 8 = 96 470 commandes.
SELECT COUNT(*)
FROM raw.orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;

-- B1c. Sans date de remise au transporteur, parmi les LIVRÉES
-- Résultat : 2  -> conforme au cadrage
-- Impact : conservées au périmètre, exclues de la
-- décomposition en segments (O2).
SELECT COUNT(*)
FROM raw.orders
WHERE order_status = 'delivered'
  AND order_delivered_carrier_date IS NULL;

-- B1d. Sans date d'approbation, parmi les LIVRÉES
-- Résultat : 14  -> NOUVEAU, absent de la qualification
-- Impact : segment « validation » incalculable et borne de
-- départ du segment « préparation » manquante.
-- Périmètre de la décomposition O2 : 96 470 − 14 − 2 = 96 454.
SELECT COUNT(*)
FROM raw.orders
WHERE order_status = 'delivered'
  AND order_approved_at IS NULL;


-- -- B2. products : catégorie et encombrement ----------------

-- B2a. Clé produit
-- Résultat : 0 -> conforme
SELECT COUNT(*)
FROM raw.products
WHERE product_id IS NULL;

-- B2b. Catégorie absente
-- Résultat : 610 produits sur 32 951 (1,85 %)
-- Impact : analyse par catégorie (O4).
-- À mesurer après les JOINs : combien de COMMANDES concernées ?
SELECT COUNT(*)
FROM raw.products
WHERE product_category_name IS NULL;

-- B2c. Poids absent
-- Résultat : 2
-- Impact : variable prédictive manquante (O6).
-- Traitement à l'étape 5 : imputation ou exclusion.
SELECT COUNT(*)
FROM raw.products
WHERE product_weight_g IS NULL;


-- -- B3. order_reviews : la satisfaction ---------------------

-- B3. Note de satisfaction absente
-- Résultat : 0
-- Lecture : quand un avis existe, il porte toujours une note.
-- Le vrai sujet n'est pas la valeur manquante mais la LIGNE
-- ABSENTE : ~640 commandes livrées sans aucun avis (RG-07).
-- Détectable uniquement par LEFT JOIN depuis orders.
SELECT COUNT(*)
FROM raw.order_reviews
WHERE review_score IS NULL;


-- -- B4. Montants : base du chiffre d'affaires (O4) ----------

-- B4a. Prix article
-- Résultat : 0
SELECT COUNT(*)
FROM raw.order_items
WHERE price IS NULL;

-- B4b. Frais de port
-- Résultat : 
SELECT COUNT(*)
FROM raw.order_items
WHERE freight_value IS NULL;

-- B4c. Montant payé
-- Résultat : 
SELECT COUNT(*)
FROM raw.order_payments
WHERE payment_value IS NULL;


-- ------------------------------------------------------------
-- SYNTHÈSE BLOC B
-- ------------------------------------------------------------
-- Périmètre confirmé : 96 470 commandes (RG-01 vérifiée).
-- Décomposition O2 limitée à 96 454 commandes (16 dates de segment manquantes).
-- 610 produits sans catégorie, 2 sans poids.
-- Aucun montant manquant dans les lignes existantes.
--
-- QUESTIONS EN ATTENTE DES JOINTURES (bloc D) :
--   - Commandes livrées sans aucune ligne dans order_items
--     (~775 commandes sans montant) -> impact direct sur O4
--   - Commandes livrées sans aucun avis (~640) -> RG-07
--   - Volume de commandes portant un produit sans catégorie
-- ============================================================




-- ============================================================
-- BLOC C : VALEURS ABERRANTES ET CONVERTIBILITÉ
-- ============================================================
-- Objectif : détecter les valeurs IMPOSSIBLES (erreurs de
-- données), à ne pas confondre avec les valeurs extrêmes mais
-- plausibles, qui relèvent de l'analyse exploratoire.
--
-- Note technique : les colonnes de raw sont en TEXT. Une
-- comparaison numérique directe compare alphabétiquement
-- ("100" < "20"). Le CAST est donc obligatoire avant tout test.


-- -- C1. Note de satisfaction hors échelle -------------------
-- Échelle attendue : 1 à 5.
-- Résultat : 0 -> conforme
SELECT COUNT(*)
FROM raw.order_reviews
WHERE review_score::INT < 1
   OR review_score::INT > 5;


-- -- C2. Prix nul ou négatif ---------------------------------
-- Résultat : 0 -> conforme
-- Conséquence : base saine pour le calcul du CA (O4, RG-11).
SELECT COUNT(*)
FROM raw.order_items
WHERE price::NUMERIC <= 0;


-- -- C3. Frais de port négatifs ------------------------------
-- Le zéro est admis ici (livraison offerte), pas le négatif.
-- Résultat : 0 -> conforme
SELECT COUNT(*)
FROM raw.order_items
WHERE freight_value::NUMERIC < 0;


-- -- C4. Poids produit nul ou négatif ------------------------
-- Résultat : 4 produits
SELECT COUNT(*)
FROM raw.products
WHERE product_weight_g::NUMERIC <= 0;

-- C4 bis : Inspection des 4 cas
-- Constat : 4 déclinaisons d'un même article (catégorie
-- cama_mesa_banho), dimensions et descriptifs renseignés,
-- seul le poids est à 0.
-- Interprétation : le 0 code une valeur NON RENSEIGNÉE,
-- pas un poids réel. Valeur manquante déguisée.
-- Impact : fausse toute moyenne de poids ; information
-- erronée pour le modèle prédictif (O6).
-- Traitement étape 5 : convertir en NULL, puis imputer
-- (médiane de la catégorie) ou exclure.
-- Total produits sans poids exploitable : 4 (zéros) + 2 (NULL) = 6
SELECT *
FROM raw.products
WHERE product_weight_g::NUMERIC = 0;


-- -- C5. Convertibilité des dates en TIMESTAMP ---------------
-- Test implicite : une seule valeur malformée ferait ÉCHOUER
-- la requête. Une exécution sans erreur vaut validation.
-- Résultat : les 5 conversions passent -> typage possible en staging.
--
-- Bonus : COUNT(colonne) ignore les NULL, contrairement à
-- COUNT(*). Ces comptes donnent donc le nombre de valeurs
-- renseignées, sans WHERE.
--
--   order_purchase_timestamp      99 441  ->      0 manquante
--   order_approved_at             99 281  ->    160 manquantes
--   order_delivered_carrier_date  97 658  ->  1 783 manquantes
--   order_delivered_customer_date 96 746  ->  2 695 manquantes
--   order_estimated_delivery_date 99 441  ->      0 manquante
--
-- Recoupement : le 1 783 confirme le bloc B.
SELECT COUNT(order_purchase_timestamp::TIMESTAMP)      FROM raw.orders;
SELECT COUNT(order_approved_at::TIMESTAMP)             FROM raw.orders;
SELECT COUNT(order_delivered_carrier_date::TIMESTAMP)  FROM raw.orders;
SELECT COUNT(order_delivered_customer_date::TIMESTAMP) FROM raw.orders;
SELECT COUNT(order_estimated_delivery_date::TIMESTAMP) FROM raw.orders;


-- ------------------------------------------------------------
-- SYNTHÈSE BLOC C
-- ------------------------------------------------------------
-- Aucune valeur impossible sur les notes ni sur les montants.
-- Une anomalie : 4 poids produit à 0 = valeurs manquantes déguisées.
-- Toutes les dates sont convertibles en TIMESTAMP.
-- ============================================================




-- ============================================================
-- BLOC D : INTÉGRITÉ RÉFÉRENTIELLE (ORPHELINS)
-- ============================================================
-- Objectif : détecter les valeurs sans correspondance dans la
-- table de référence. Un INNER JOIN les ferait disparaître
-- silencieusement, sans erreur ni avertissement.
--
-- Pattern : LEFT JOIN + WHERE <clé de la table B> IS NULL.
-- Le LEFT JOIN conserve toutes les lignes de A et remplit les
-- colonnes de B avec NULL en l'absence de correspondance ;
-- le WHERE isole exactement ces cas.


-- -- D1. orders -> customers ----------------------------------
-- Des commandes rattachées à un client inexistant ?
-- Résultat : 0 -> conforme
SELECT COUNT(*)
FROM raw.orders AS ord
LEFT JOIN raw.customers AS cus
    ON ord.customer_id = cus.customer_id
WHERE cus.customer_id IS NULL;


-- -- D2. order_items -> orders --------------------------------
-- Des articles rattachés à une commande inexistante ?
-- Résultat : 0 -> conforme
SELECT COUNT(*)
FROM raw.order_items AS it
LEFT JOIN raw.orders AS ord
    ON it.order_id = ord.order_id
WHERE ord.order_id IS NULL;


-- -- D3. order_items -> products ------------------------------
-- Des articles rattachés à un produit inexistant ?
-- Résultat : 0 -> conforme
SELECT COUNT(*)
FROM raw.order_items AS it
LEFT JOIN raw.products AS prod
    ON it.product_id = prod.product_id
WHERE prod.product_id IS NULL;


-- -- D4. order_items -> sellers -------------------------------
-- Des articles rattachés à un vendeur inexistant ?
-- Résultat : 0 -> conforme
-- Conséquence : l'imputation du retard au vendeur (O2, RG-09)
-- est possible sur l'ensemble du périmètre.
SELECT COUNT(*)
FROM raw.order_items AS it
LEFT JOIN raw.sellers AS sell
    ON it.seller_id = sell.seller_id
WHERE sell.seller_id IS NULL;


-- -- D5. Commandes LIVRÉES sans aucun article ----------------
-- Enjeu : une commande sans ligne dans order_items n'a pas de
-- montant, donc échappe au calcul du CA exposé (O4).
-- Résultat : 0
-- Lecture : le CA est calculable sur 100 % du périmètre.
-- L'écart de volume entre orders (99 441) et order_items
-- (98 666 commandes) provient des commandes annulées ou
-- indisponibles, hors périmètre RG-01.
SELECT COUNT(*)
FROM raw.orders AS ord
LEFT JOIN raw.order_items AS it
    ON ord.order_id = it.order_id
WHERE ord.order_status = 'delivered'
  AND it.order_id IS NULL;


-- -- D6. Commandes LIVRÉES sans aucun avis -------------------
-- Enjeu : ces commandes sont ABSENTES de order_reviews, elles
-- n'y figurent pas avec une note vide. Seul un LEFT JOIN
-- depuis orders permet de les détecter.
-- Résultat : 646 -> conforme à RG-07 (≈640 annoncées)
-- Impact : exclusion CIBLÉE des analyses de satisfaction (O3),
-- pas du périmètre général.
SELECT COUNT(*)
FROM raw.orders AS ord
LEFT JOIN raw.order_reviews AS rev
    ON ord.order_id = rev.order_id
WHERE ord.order_status = 'delivered'
  AND rev.order_id IS NULL;


-- -- D7. Commandes LIVRÉES portant un produit sans catégorie -
-- Enjeu : le bloc B a dénombré 610 produits sans catégorie.
-- La question utile n'est pas combien de PRODUITS, mais combien
-- de COMMANDES en sont affectées (O4 : analyse par catégorie).
-- Résultat : 
SELECT *
FROM raw.orders AS ord
JOIN raw.order_items AS it
    ON ord.order_id = it.order_id
JOIN raw.products AS prod
    ON it.product_id = prod.product_id
WHERE ord.order_status = 'delivered'
  AND prod.product_category_name IS NULL;


-- ------------------------------------------------------------
-- SYNTHÈSE BLOC D
-- ------------------------------------------------------------
-- Modèle relationnel sain : aucun orphelin (D1 à D4).
-- CA calculable sur 100 % du périmètre (D5 = 0).
-- 646 commandes livrées sans avis -> exclusion ciblée (RG-07).
-- ============================================================


