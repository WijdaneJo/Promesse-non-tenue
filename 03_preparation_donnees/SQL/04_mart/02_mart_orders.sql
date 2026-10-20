-- ============================================================
-- ÉTAPE 6. COUCHE MART : mart.orders
-- ============================================================
-- Table analytique finale au grain COMMANDE.
-- Une ligne = une commande du périmètre (96 447), avec toutes
-- les variables nécessaires aux métriques M-00 à M-16 et au
-- modèle prédictif (O6).
--
-- PRÉREQUIS : 01_intermediate.sql puis PYTHON/distances.py.
--
-- TOUS les JOIN sont des LEFT JOIN. intermediate.orders porte
-- le périmètre ; aucune table satellite ne doit pouvoir en
-- retirer une commande :
--   - 646 commandes n'ont aucun avis (RG-07)
--   - 476 n'ont pas de distance calculable
--   - 1 commande n'a aucune ligne de paiement
-- Un seul INNER JOIN les ferait disparaître silencieusement.
--
-- Aucune duplication possible : le contrôle de grain de
-- l'étape 4 a vérifié que chaque table satellite a bien une
-- ligne par commande.
--
-- POURQUOI UNE CTE : is_late et timing dérivent de gap, et un
-- alias du SELECT n'est pas réutilisable dans le même bloc.
-- La CTE « base » matérialise gap ; le SELECT final s'en sert.
-- base.* reprend ses colonnes sans les relister.

DROP TABLE IF EXISTS mart.orders;

CREATE TABLE mart.orders AS
WITH limits AS (
    -- -- Date limite d'expédition (découverte 4, V11) --------
    -- Fixée par Olist pour CHAQUE ARTICLE : une commande peut
    -- en avoir plusieurs (336 commandes ont des dates
    -- différentes). On garde la PLUS TÔT (MIN) : si un seul
    -- article dépasse sa date, le vendeur n'a pas tenu son
    -- engagement. Choix conservateur, cohérent avec RG-06.
    SELECT
        order_id,
        MIN(shipping_limit_date) AS shipping_limit_date
    FROM staging.order_items
    GROUP BY order_id
),
base AS (
    SELECT
        -- -- Identifiants ------------------------------------
        io.order_id,
        io.customer_id,
		c.customer_state,
        -- -- Dates du parcours -------------------------------
        -- Les 5 sont conservées : mart doit être AUTOSUFFISANT.
        -- Elles permettent de recalculer n'importe quoi sans
        -- revenir à intermediate, servent d'axe chronologique
        -- en restitution, et de borne pour RG-10.
        io.order_purchase_timestamp,
        io.order_approved_at,
        io.order_delivered_carrier_date,
        io.order_delivered_customer_date,
        io.order_estimated_delivery_date,
        lim.shipping_limit_date,

        -- -- Écart à la promesse -----------------------------
        -- Sens : RÉELLE − ESTIMÉE. Positif = retard.
        -- ::DATE car la promesse porte sur une DATE, pas un
        -- horaire : livré le jour promis à 23h = 0 jour.
        io.order_delivered_customer_date::DATE
            - io.order_estimated_delivery_date::DATE AS gap,

        -- -- Segments du parcours (O2) -----------------------
        -- RG-04 : les 1 350 commandes remises au transporteur
        -- avant validation du paiement donneraient une
        -- préparation négative -> neutralisées en NULL.
        -- Elles restent au périmètre : exclusion ciblée.
        io.order_approved_at::DATE
            - io.order_purchase_timestamp::DATE AS gap_validation,
        CASE
            WHEN (io.order_delivered_carrier_date::DATE
                  - io.order_approved_at::DATE) < 0 THEN NULL
            ELSE io.order_delivered_carrier_date::DATE
                 - io.order_approved_at::DATE
        END AS gap_preparation,
        io.order_delivered_customer_date::DATE
            - io.order_delivered_carrier_date::DATE AS gap_shipping,

        -- -- Variables temporelles (O6) ----------------------
        -- Connues AU MOMENT DE LA COMMANDE : éligibles au
        -- modèle prédictif.
        -- month : saisonnalité | dow : 0=dimanche à 6=samedi
        -- year : RG-10 et exclusion des mois incomplets
        EXTRACT(YEAR  FROM io.order_purchase_timestamp)::INT AS purchase_year,
        EXTRACT(MONTH FROM io.order_purchase_timestamp)::INT AS purchase_month,
        EXTRACT(DOW   FROM io.order_purchase_timestamp)::INT AS purchase_dow,

        -- -- Montants (RG-11, O4) ----------------------------
        -- MONTANT DE RÉFÉRENCE : payment_total, l'encaissement
        -- RÉEL du client (somme des payment_value). Le chiffre
        -- d'affaires est l'argent qui entre, pas la valeur
        -- théorique du panier.
        -- total_price et total_freight sont conservés pour
        -- décomposer la part du transport dans le CA exposé.
        -- Concordance vérifiée avec order_items : 299 écarts
        -- sur 96 447 (0,31 %), maximum 0,02 R$ : arrondis.
        -- H9 revalidé sur le périmètre.
        ii.nb_items,
        ii.nb_sellers,
        ii.total_price,
        ii.total_freight,
        ip.payment_total,

        -- -- Satisfaction (M-01, M-02) -----------------------
        -- avg_score : moyenne tronquée des avis (RG-06)
        -- is_unsatisfied : note ≤ 2 (RG-05). Booléen et non
        -- libellé : AVG(is_unsatisfied::INT) donne le TAUX
        -- directement, ce qu'est M-02.
        ir.avg_score,
        ir.nb_reviews,
        (ir.avg_score <= 2) AS is_unsatisfied,

        -- -- Distance (O6) -----------------------------------
        -- Haversine, calculée en Python. Pour les commandes
        -- multi-vendeurs : la distance la PLUS LONGUE.
        -- Le dataset ne fournit qu'une date de livraison, qui
        -- correspond vraisemblablement au dernier colis arrivé.
        -- LIMITE : les expéditions séparées ne sont pas
        -- distinguables dans les données.
        idi.distance_km

    FROM intermediate.orders              AS io
	LEFT JOIN staging.customers           AS c   ON io.customer_id = c.customer_id  
    LEFT JOIN intermediate.items_order    AS ii  ON io.order_id = ii.order_id
    LEFT JOIN intermediate.order_payments AS ip  ON io.order_id = ip.order_id
    LEFT JOIN intermediate.order_reviews  AS ir  ON io.order_id = ir.order_id
    LEFT JOIN intermediate.distances      AS idi ON io.order_id = idi.order_id
    LEFT JOIN limits                      AS lim ON io.order_id = lim.order_id
)
SELECT
    base.*,

    -- -- Indicateur de retard (M-00) -------------------------
    -- Une comparaison EST un booléen : pas de CASE nécessaire.
    -- Seuil > 0 et non >= 0 : livré le jour exact de la
    -- promesse, l'engagement est TENU.
    (gap > 0) AS is_late,

    -- -- Dépassement de la date limite d'expédition (V11) ----
    -- Vrai si le vendeur a remis le colis au transporteur
    -- APRÈS la date limite. Timestamps complets, pas ::DATE :
    -- la date limite porte une heure précise.
    -- NULL si la date de remise au transporteur manque (1 cas).
    (order_delivered_carrier_date > shipping_limit_date) AS is_limit_exceeded,

    -- -- Tranches de gravité (M-14) --------------------------
    -- Bornes issues de la DISTRIBUTION OBSERVÉE, pas de
    -- chiffres ronds : ruptures nettes après 1 jour
    -- (de 825 à 545) et après 7-8 jours (de 483 à 336).
    -- Les commandes à l'heure reçoivent aussi une modalité :
    -- elles sont le GROUPE DE RÉFÉRENCE de M-01.
    -- Frontière à −4 : au-delà de 3 jours d'avance, la
    -- livraison n'est plus ponctuelle mais anticipée, avec un
    -- coût réel pour le client (absence, stockage).
    CASE
        WHEN gap <= -4              THEN 'Too early'
        WHEN gap BETWEEN -3 AND  0  THEN 'At time'
        WHEN gap BETWEEN  1 AND  7  THEN 'Barely late'
        WHEN gap BETWEEN  8 AND 15  THEN 'Late'
        WHEN gap BETWEEN 16 AND 30  THEN 'Too late'
        WHEN gap >= 31              THEN 'Very late'
    END AS timing
FROM base;


-- -- Contrôles -----------------------------------------------
SELECT COUNT(*) FROM mart.orders;   -- attendu : 96 447

SELECT order_id FROM mart.orders
GROUP BY order_id HAVING COUNT(*) > 1;   -- attendu : 0 ligne

SELECT timing, COUNT(*)
FROM mart.orders
GROUP BY timing
ORDER BY COUNT(*) DESC;
-- Attendu : Too early 83 878 | At time 6 035 | Barely late 3 672
--           Late 1 637 | Too late 880 | Very late 345


-- Dépassement : volume et taux de retard associé
SELECT
    is_limit_exceeded,
    COUNT(*)                                  AS nb_commandes,
    ROUND(AVG(is_late::INT) * 100, 2)         AS taux_retard_pct
FROM mart.orders
GROUP BY is_limit_exceeded;
-- Attendu : ~×4 entre TRUE et FALSE (résultat O2) | 1 NULL

SELECT * FROM mart.orders LIMIT 5;