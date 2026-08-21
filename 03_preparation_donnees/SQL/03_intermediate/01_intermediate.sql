-- ============================================================
-- ÉTAPE 4 — COUCHE INTERMEDIATE
-- ============================================================
-- Rôle : deux transformations décisives.
--   1. CORRIGER LES GRAINS — ramener chaque table satellite à
--      une ligne par commande, pour qu'aucune jointure ne
--      duplique le périmètre.
--   2. APPLIQUER LE PÉRIMÈTRE — traduire les règles de gestion
--      RG-01 et RG-03 en filtres, et produire la table de
--      référence du projet.
--
DROP TABLE IF EXISTS intermediate.order_payments;
DROP TABLE IF EXISTS intermediate.items_order;
DROP TABLE IF EXISTS intermediate.geolocation_pref;
DROP TABLE IF EXISTS intermediate.order_reviews;
DROP TABLE IF EXISTS intermediate.orders;
-- ============================================================
-- 4.1 — CORRECTION DES GRAINS
-- ============================================================


-- ── Q1. Paiements par commande ──────────────────────────────
-- Problème : une commande peut être réglée par plusieurs
-- moyens (carte + bon d'achat, règlement fractionné).
-- staging.order_payments compte 103 886 lignes pour 99 440
-- commandes. Le montant d'une commande est la SOMME de ses
-- lignes, jamais la valeur d'une seule.
-- Sortie : 99 440 lignes.
-- NB : une commande n'a aucune ligne de paiement (99 440 et
-- non 99 441) → prévoir un LEFT JOIN à l'assemblage.
-- Usage : contre-mesure du montant calculé depuis order_items
-- (H9 — concordance vérifiée à 99,75 %).
CREATE TABLE intermediate.order_payments AS
    SELECT
        order_id,
        SUM(payment_value) AS payment_total
    FROM staging.order_payments
    GROUP BY order_id;


-- ── Q2. Articles par commande ───────────────────────────────
-- Problème : une ligne = un article, pas une commande.
-- 112 650 lignes pour 98 666 commandes.
-- Sortie : 98 666 lignes.
--
-- Choix de conception :
--   • nb_items = COUNT(*) et non SUM(order_item_id) :
--     order_item_id est un NUMÉRO d'ordre (1, 2, 3), pas une
--     quantité. Le sommer n'aurait aucun sens.
--   • prix et frais de port conservés SÉPARÉMENT : deux natures
--     de revenu distinctes, à additionner ou non selon RG-11.
--   • nb_sellers : permet d'isoler les commandes multi-vendeurs
--     (1,3 %), exclues de l'analyse au grain vendeur (RG-09).
CREATE TABLE intermediate.items_order AS
    SELECT
        order_id,
        COUNT(*)                  AS nb_items,
        COUNT(DISTINCT seller_id) AS nb_sellers,
        SUM(price)                AS total_price,
        SUM(freight_value)        AS total_freight
    FROM staging.order_items
    GROUP BY order_id;


-- ── Q3. Géolocalisation par code postal ─────────────────────
-- Problème le plus dangereux du jeu de données : un même
-- préfixe apparaît des dizaines de fois avec des coordonnées
-- légèrement différentes. 1 000 163 lignes pour ~19 000
-- préfixes. Une jointure directe multiplierait CHAQUE commande
-- par le nombre de points de sa zone et fausserait tous les
-- totaux.
-- Traitement : un point moyen par préfixe.
-- Sortie : ~19 015 lignes.
-- Usage : calcul de la distance vendeur → client (variable
-- prédictive du délai, O6).
CREATE TABLE intermediate.geolocation_pref AS
    SELECT
        geolocation_zip_code_prefix,
        AVG(geolocation_lat) AS avg_lat,
        AVG(geolocation_lng) AS avg_lng
    FROM staging.geolocation
    GROUP BY geolocation_zip_code_prefix;


-- ── Q4. Avis par commande (RG-06) ───────────────────────────
-- Problème : 547 commandes ont plusieurs avis (99 224 lignes
-- pour 98 673 commandes). Une jointure directe les dupliquerait
-- et gonflerait périmètre comme montants.
--
-- DÉCISION RG-06 : moyenne des notes, TRONQUÉE à l'entier
-- inférieur (FLOOR).
--   • Moyenne plutôt que premier/dernier avis : les avis
--     multiples portent le plus souvent le même score.
--   • FLOOR plutôt que ROUND : principe de prudence. Sur un
--     projet dont l'objet est d'identifier des ruptures de
--     promesse, mieux vaut surestimer légèrement
--     l'insatisfaction que la manquer.
--
-- review_id est ABANDONNÉ : il n'a plus de sens au grain
-- commande une fois les avis fusionnés.
-- Dates en MIN() : la première sollicitation est la plus proche
-- de l'événement livraison.
-- Sortie : 98 673 lignes.
CREATE TABLE intermediate.order_reviews AS
    SELECT
        order_id,
        FLOOR(AVG(review_score))           AS avg_score,
        COUNT(*)                           AS nb_reviews,
        MIN(review_creation_date)          AS review_creation_date,
        MIN(review_answer_timestamp)       AS review_answer_timestamp
    FROM staging.order_reviews
    GROUP BY order_id;


-- ============================================================
-- 4.2 — APPLICATION DU PÉRIMÈTRE
-- ============================================================

-- ── Q5 + Q6. Table de référence du projet ───────────────────
-- RG-01 — Périmètre : commandes au statut 'delivered'
--   disposant d'une date de livraison réelle. Sans elle,
--   l'écart à la promesse n'est pas mesurable.
--   96 478 livrées − 8 sans date = 96 470.
--
-- RG-03 — Chronologie impossible : livraison ANTÉRIEURE à la
--   remise au transporteur. Physiquement absurde, erreur de
--   saisie. 23 commandes exclues → 96 447.
--
-- Piège traité : 2 commandes livrées n'ont pas de date de
-- remise au transporteur. Toute comparaison avec NULL renvoie
-- NULL — ni vrai ni faux — et le WHERE les écarterait
-- silencieusement. La clause IS NULL les conserve
-- explicitement : 23 exclusions et non 25.
--
-- Le >= admet une livraison le jour même de la remise.
--
-- NON exclues ici — RG-04 : 1 350 commandes remises au
-- transporteur AVANT validation du paiement. Improbable mais
-- physiquement possible (contrairement à RG-03). Conservées au
-- périmètre ; leur seul segment « préparation » sera neutralisé
-- à l'étape 5.
CREATE TABLE intermediate.orders AS
    SELECT *
    FROM staging.orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND (order_delivered_carrier_date IS NULL
           OR order_delivered_customer_date >= order_delivered_carrier_date);


-- ============================================================
-- 4.3 — CONTRÔLES ET JOURNAL D'EXCLUSIONS
-- ============================================================

-- Volumétrie attendue
SELECT COUNT(*) FROM intermediate.order_payments;    -- 99 440
SELECT COUNT(*) FROM intermediate.items_order;       -- 98 666
SELECT COUNT(*) FROM intermediate.geolocation_pref;  -- ~19 015
SELECT COUNT(*) FROM intermediate.order_reviews;     -- 98 673
SELECT COUNT(*) FROM intermediate.orders;            -- 96 447

-- Contrôle de grain — doit retourner 0 ligne sur chaque table.
-- C'est LE contrôle de l'étape 4 : il garantit qu'aucune
-- jointure ne dupliquera le périmètre à l'assemblage.
SELECT order_id FROM intermediate.order_payments GROUP BY order_id HAVING COUNT(*) > 1;
SELECT order_id FROM intermediate.items_order    GROUP BY order_id HAVING COUNT(*) > 1;
SELECT order_id FROM intermediate.order_reviews  GROUP BY order_id HAVING COUNT(*) > 1;
SELECT order_id FROM intermediate.orders         GROUP BY order_id HAVING COUNT(*) > 1;


-- ────────────────────────────────────────────────────────────
-- JOURNAL D'EXCLUSIONS
-- ────────────────────────────────────────────────────────────
--   Commandes au statut 'delivered'                    96 478
--   RG-01 : sans date de livraison réelle                  −8
--                                                    ─────────
--                                                      96 470
--   RG-03 : chronologie impossible                       −23
--                                                    ─────────
--   PÉRIMÈTRE D'ANALYSE                                96 447
--
--   Exclusions CIBLÉES (hors périmètre général) :
--   RG-04 : expédition avant validation      1 350
--           → segment « préparation » uniquement
--   RG-06 : commandes multi-avis               547
--           → fusionnées (moyenne tronquée)
--   RG-07 : commandes sans avis                646
--           → analyses de satisfaction uniquement
-- ============================================================