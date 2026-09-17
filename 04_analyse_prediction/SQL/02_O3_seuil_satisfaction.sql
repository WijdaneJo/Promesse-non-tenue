-- ============================================================
-- O3 — LE SEUIL DE TOLÉRANCE
-- ============================================================
-- Objectif : établir le lien entre l'ampleur du retard et la
-- dégradation de la satisfaction, et en déduire un seuil
-- critique.
--
-- Source     : mart.orders (96 447 commandes du périmètre)
-- Métriques  : M-01 (note moyenne), M-02 (taux d'insatisfaction)
-- Constats   : resultats/02_O3_constats.md
--
-- ENJEU : ce seuil conditionne O4 (quel CA est réellement
-- exposé) et O7 (combien de jours faut-il gagner).
--
-- PÉRIMÈTRE — les 646 commandes sans avis (RG-07) sortent de
-- ces analyses. Le dénominateur est donc de 95 801 et non
-- 96 447. AVG() ignore automatiquement les NULL ;
-- COUNT(avg_score) donne le vrai nombre d'avis pris en compte,
-- là où COUNT(*) compterait aussi les commandes non évaluées.
--
-- SENS DU REGROUPEMENT — on groupe par RETARD (la cause
-- présumée) et on observe la NOTE (l'effet). L'inverse ne
-- permettrait pas d'identifier un seuil.


-- ============================================================
-- Q1 — LA NOTE PAR TRANCHE DE GRAVITÉ (M-01)
-- ============================================================
SELECT
    timing,
    ROUND(AVG(avg_score), 2) AS avg_score,
    COUNT(avg_score)         AS nb_avis
FROM mart.orders
GROUP BY timing
ORDER BY nb_avis DESC;

-- RÉSULTAT
--
--   Too early    4,30   83 435
--   At time      4,11    5 985
--   Barely late  2,72    3 600   ← −1,39 point
--   Late         1,67    1 601
--   Too late     1,60      851
--   Very late    2,05      329   ⚠ remonte — anomalie
--
-- LA CHUTE EST BRUTALE, PAS PROGRESSIVE.
-- Passer de « à l'heure » à « 1-7 jours de retard » coûte
-- 1,39 point. C'est SEPT FOIS l'écart entre « en avance » et
-- « à l'heure » (0,19 point).
--
-- ANOMALIE : Very late (2,05) est mieux noté que Too late
-- (1,60) et Late (1,67). Contre-intuitif — investigué en Q6.


-- ============================================================
-- Q2 — LE TAUX D'INSATISFACTION PAR TRANCHE (M-02)
-- ============================================================
-- COMPLÉMENT INDISPENSABLE À Q1 : une moyenne qui passe de
-- 4,11 à 2,72 peut cacher deux réalités très différentes —
-- tout le monde baisse un peu, ou une partie des clients
-- bascule violemment. Le taux rend la bascule visible.
--
-- AVG(is_unsatisfied::INT) : true → 1, false → 0. La moyenne
-- de ces 0/1 EST le taux. Le * 100 se place APRÈS l'AVG :
-- multiplier à l'intérieur donnerait le même résultat, mais
-- c'est une écriture qui induit en erreur dès que la formule
-- se complique.
SELECT
    timing,
    ROUND(AVG(is_unsatisfied::INT) * 100, 2) AS unsatisfied_rate,
    COUNT(avg_score)                         AS nb_avis
FROM mart.orders
GROUP BY timing
ORDER BY nb_avis DESC;

-- RÉSULTAT
--
--   Too early     9,09 %   83 435
--   At time      11,51 %    5 985
--   Barely late  49,36 %    3 600   ← ×4,3
--   Late         80,07 %    1 601
--   Too late     82,37 %      851
--   Very late    68,09 %      329   ⚠ anomalie
--
-- UN SEUL JOUR DE RETARD FAIT PASSER L'INSATISFACTION DE
-- 11 % À 49 %. IL N'Y A PAS DE SEUIL DE TOLÉRANCE — le client
-- ne pardonne pas quelques jours, il bascule immédiatement.
--
-- À 8 jours : 80 %. Quatre clients sur cinq.


-- ============================================================
-- Q3 — LA BASCULE, JOUR PAR JOUR (M-01 fine)
-- ============================================================
-- Q1 et Q2 localisent la bascule entre 0 et 1 jour. Cette
-- requête la mesure précisément.
--
-- POURQUOI COMMENCER À −3 ET NON À 1 : un chiffre seul ne dit
-- rien, il faut sa référence. Sans les valeurs négatives et le
-- zéro, impossible de mesurer l'ampleur de la chute.
SELECT
    gap,
    ROUND(AVG(avg_score), 2)                 AS avg_score,
    ROUND(AVG(is_unsatisfied::INT) * 100, 2) AS unsatisfied_rate,
    COUNT(avg_score)                         AS nb_avis
FROM mart.orders
WHERE gap BETWEEN -3 AND 10
GROUP BY gap
ORDER BY gap ASC;

-- RÉSULTAT
--
--   Gap   Note   Insatisfaction   Avis
--   -3    4,12       10,96 %      1 715
--   -2    4,12       11,75 %      1 540
--   -1    4,16       11,17 %      1 450
--    0    4,03       12,34 %      1 280   ← référence
--    1    3,73       19,76 %        820   ← +60 %
--    2    3,18       34,33 %        536   ← ×2,8
--    3    2,68       50,40 %        496   ← SEUIL CRITIQUE
--    4    2,50       55,96 %        436
--    5    2,19       64,52 %        434
--    6    1,81       76,66 %        407
--    7    1,92       73,25 %        471
--    8    1,71       78,48 %        330
--    9    1,67       80,82 %        219
--   10    1,58       83,09 %        207
--
-- TROIS LECTURES :
--
-- 1. DÈS LE PREMIER JOUR, l'insatisfaction augmente de 60 %.
--    Ce n'est pas de la tolérance, c'est une dégradation
--    immédiate — simplement moins spectaculaire que la suite.
--
-- 2. LE SEUIL CRITIQUE EST À 3 JOURS. Deux basculements s'y
--    produisent : la note passe SOUS 3 (2,68) et
--    l'insatisfaction dépasse 50 % — un client sur deux.
--
-- 3. PLATEAU APRÈS 6 JOURS. Ça monte encore, mais lentement
--    (77 % à 6 j, 83 % à 10 j). LE MAL EST DÉJÀ FAIT.
--
-- CONSÉQUENCE POUR M-13 : le simulateur doit viser le passage
-- SOUS 3 JOURS, pas le retour à zéro. Gagner 4 jours sur un
-- retard de 6 fait passer l'insatisfaction de 77 % à 56 %.
-- Gagner 4 jours de plus n'apporte presque rien.


-- ============================================================
-- Q4 — L'AVANCE APPORTE-T-ELLE QUELQUE CHOSE ? (M-01)
-- ============================================================
-- 87 % des commandes arrivent avec 4 jours d'avance ou plus,
-- avec un pic à −14 jours. Cette marge produit-elle de la
-- satisfaction supplémentaire ?
--
-- ENJEU POUR O8 : si l'avance n'apporte rien, Olist peut
-- resserrer ses délais annoncés sans risque commercial.
SELECT
    gap,
    ROUND(AVG(avg_score), 2)                 AS avg_score,
    ROUND(AVG(is_unsatisfied::INT) * 100, 2) AS unsatisfied_rate,
    COUNT(avg_score)                         AS nb_avis
FROM mart.orders
WHERE gap BETWEEN -30 AND 0
GROUP BY gap
ORDER BY gap ASC;

-- RÉSULTAT — extraits
--
--   Gap    Note   Insatisfaction   Avis
--   -30    4,27       10,13 %        375
--   -25    4,27       10,35 %        908
--   -20    4,37        7,84 %      2 947
--   -15    4,35        8,34 %      5 314
--   -14    4,33        9,11 %      7 090   ← pic de volume
--   -10    4,33        8,08 %      4 618
--    -7    4,26        9,30 %      4 815
--    -5    4,20       10,78 %      2 208
--    -3    4,12       10,96 %      1 715
--    -1    4,16       11,17 %      1 450
--     0    4,03       12,34 %      1 280
--
-- LA NOTE PLAFONNE À ~4,3 QUELLE QUE SOIT L'AVANCE.
-- De −30 à −5 jours, elle ne bouge pas : l'écart entre 30
-- jours d'avance et 5 jours d'avance est de 0,07 point — du
-- bruit.
--
-- INTERPRÉTATION : ce plafond de 4,3 est le niveau de
-- satisfaction lié au PRODUIT, pas à la livraison. Quand la
-- promesse est tenue, le client note le produit ; quand elle
-- est rompue, il note le retard.
-- Cohérent avec le cadrage : l'enquête est envoyée à la
-- réception OU à l'échéance de la date promise — le dispositif
-- capte spécifiquement l'effet du délai.
--
-- CONSÉQUENCE MAJEURE POUR O8 : livrer très en avance
-- n'apporte AUCUN bénéfice mesurable en satisfaction. Un
-- resserrement des délais annoncés a donc un COÛT NUL côté
-- client, tant que la promesse reste tenue.


-- ============================================================
-- Q5 — LE SEUIL EST-IL LE MÊME PARTOUT ?
-- ============================================================
-- Un client de São Paulo (19 jours promis) et un client
-- d'Amazonie (46 jours promis) ont-ils la même tolérance ?
--
-- ENJEU : une politique nationale ou différenciée par région.
--
-- POURQUOI timing ET NON gap : croiser 27 états × 14 valeurs
-- de gap produirait 378 lignes à 20 commandes chacune —
-- illisible et non fiable. Les 6 modalités de timing donnent
-- des effectifs solides.
--
-- POURQUOI SEULEMENT 6 ÉTATS : les plus gros volumes, seuls à
-- permettre une comparaison fiable une fois croisés avec les
-- tranches.
SELECT
    customer_state,
    timing,
    ROUND(AVG(avg_score), 2)                 AS avg_score,
    ROUND(AVG(is_unsatisfied::INT) * 100, 2) AS unsatisfied_rate,
    COUNT(avg_score)                         AS nb_avis
FROM mart.orders
WHERE customer_state IN ('SP','RJ','MG','RS','PR','SC')
GROUP BY customer_state, timing
ORDER BY customer_state, timing;

-- RÉSULTAT — taux d'insatisfaction
--
--   État   Too early   At time   Barely late   Late
--   SP        8,48 %   10,52 %     45,10 %    81,07 %
--   RJ       10,63 %   14,72 %     58,10 %    82,04 %
--   MG        9,31 %   13,31 %     48,63 %    75,96 %
--   PR        9,04 %   11,49 %     41,13 %    75,00 %
--   RS        8,51 %    8,53 %     52,73 %    79,61 %
--   SC        8,63 %   12,22 %     46,89 %    82,61 %
--
-- LE SEUIL EST LE MÊME PARTOUT. Dans les six états, la bascule
-- se produit au premier jour de retard. Aucun état ne tolère
-- plus que les autres.
-- → UNE RÈGLE NATIONALE SUFFIT. Pas de seuil différencié.
--
-- RJ EST PLUS SÉVÈRE, MAIS PAS SUR LE SEUIL : 58 % contre
-- 41-53 % ailleurs sur Barely late. C'est l'INTENSITÉ qui
-- diffère, pas le point de bascule.
-- ⚠ RJ a pourtant une promesse COURTE (25 j), comme PR.
-- L'hypothèse « promesse longue = moins de tolérance » ne
-- tient donc pas. RJ reste un cas particulier — cf. O1 et O2.
--
-- ⚠ Very late : effectifs trop faibles hors RJ et SP
-- (PR : 8 · RS : 8 · SC : 4). Non interprétable.


-- ============================================================
-- Q6 — L'ANOMALIE « VERY LATE » : INVESTIGATION
-- ============================================================
-- Q1 et Q2 ont montré que Very late est mieux noté que Too
-- late : 2,05 contre 1,60, et 68 % d'insatisfaction contre
-- 82 %. Contre-intuitif.
--
-- QUATRE HYPOTHÈSES ONT ÉTÉ TESTÉES CI-DESSOUS.


-- ── Q6.a Hypothèse « petit effectif » — ÉCARTÉE ─────────────
-- Q5 la fragilise déjà : RJ (131 avis) ne remonte PAS
-- (83,21 %), tandis que SP (64 avis) chute à 48,44 %.
-- L'anomalie est CONCENTRÉE SUR SÃO PAULO, pas générale.
--
-- Reste à savoir si le phénomène est réel ou du bruit :
-- un effet d'effectif produirait de la DISPERSION ;
-- un phénomène réel produirait une STRUCTURE.
SELECT
    avg_score,
    COUNT(*) AS nb_commandes
FROM mart.orders
WHERE customer_state = 'SP' AND timing = 'Very late'
GROUP BY avg_score
ORDER BY avg_score;

-- RÉSULTAT — 64 commandes, plus de 30 jours de retard, SP
--
--   Note 1    30   ← 47 %
--   Note 2     1
--   Note 3     5
--   Note 4    13
--   Note 5    15   ← 23 %
--
-- DISTRIBUTION EN U, PAS EN J. 28 commandes sur 64 notées
-- 4 ou 5 malgré un retard massif. Un effet d'effectif
-- produirait de la dispersion, pas DEUX PICS OPPOSÉS.
-- → HYPOTHÈSE ÉCARTÉE. Le phénomène est réel.


-- ── Q6.b Hypothèse « geste commercial » — AFFAIBLIE ─────────
-- Un remboursement, un coupon ou un suivi expliqueraient une
-- satisfaction maintenue. Aucune trace directe dans les
-- données — mais les VERBATIMS pourraient en porter mention.
--
-- Les commentaires ont été écartés de staging (extension NLP
-- hors périmètre v1). On les lit ici directement dans raw :
-- lire 15 commentaires à l'œil n'est pas du NLP, c'est de
-- l'investigation.
SELECT
    mo.order_id,
    mo.gap,
    mo.avg_score,
    r.review_comment_title,
    r.review_comment_message
FROM mart.orders AS mo
JOIN raw.order_reviews AS r ON mo.order_id = r.order_id
WHERE mo.customer_state = 'SP'
  AND mo.timing = 'Very late'
  AND mo.avg_score = 5
ORDER BY mo.gap DESC;

-- RÉSULTAT — 15 commandes, retards de 31 à 104 jours
--
--   12 commentaires sur 15 sont VIDES.
--   Trois seulement disent quelque chose :
--     « otima super recomendo »  → super, je recommande
--     « Recomendo »              → je recommande
--     « Recebi certinho »        → J'AI BIEN REÇU
--   Un quatrième, sur une note 5 à 48 jours :
--     « Necessário informar se a entrega será pelos Correios »
--     → il faudrait indiquer si la livraison passe par la Poste
--
-- AUCUNE MENTION DE REMBOURSEMENT, DE COUPON NI DE SERVICE
-- CLIENT. Si un geste commercial avait été fait, un client sur
-- quinze en aurait probablement parlé.
-- → HYPOTHÈSE AFFAIBLIE.
--
-- « Recebi certinho » est révélateur : ce client ne mentionne
-- même pas le retard. Il constate que le colis est arrivé.


-- ── Q6.c Hypothèse « produit non urgent » — ÉCARTÉE ─────────
-- Les commentaires suggèrent des clients simplement non gênés
-- par le délai. Cela se vérifierait par une concentration sur
-- des catégories sans contrainte de date (mobilier, décoration).
--
-- Le chemin passe par order_items puis products : la catégorie
-- est au grain PRODUIT, pas commande.
-- COUNT(DISTINCT order_id) : une commande multi-articles
-- serait sinon comptée plusieurs fois.
SELECT
    p.product_category_name,
    COUNT(DISTINCT mo.order_id) AS nb_commandes
FROM mart.orders AS mo
JOIN staging.order_items AS it ON mo.order_id = it.order_id
JOIN staging.products    AS p  ON it.product_id = p.product_id
WHERE mo.customer_state = 'SP'
  AND mo.timing = 'Very late'
  AND mo.avg_score >= 4
GROUP BY p.product_category_name
ORDER BY nb_commandes DESC;

-- RÉSULTAT — les SATISFAITS (note ≥ 4)
--   utilidades_domesticas 4 · automotivo 3 · moveis_decoracao 3
--   perfumaria 3 · esporte_lazer 2 · cool_stuff 2
--   beleza_saude 2 · brinquedos 2 · puis 7 catégories à 1
--
-- 15 CATÉGORIES POUR 28 COMMANDES. Aucune concentration.
-- On trouve de l'électronique, de l'informatique, de la
-- puériculture — pas seulement du mobilier.


-- Contre-test indispensable : sans comparaison avec les
-- mécontents, impossible de savoir si la catégorie fait une
-- différence.
SELECT
    p.product_category_name,
    COUNT(DISTINCT mo.order_id) AS nb_commandes
FROM mart.orders AS mo
JOIN staging.order_items AS it ON mo.order_id = it.order_id
JOIN staging.products    AS p  ON it.product_id = p.product_id
WHERE mo.customer_state = 'SP'
  AND mo.timing = 'Very late'
  AND mo.avg_score <= 2
GROUP BY p.product_category_name
ORDER BY nb_commandes DESC;

-- RÉSULTAT — les MÉCONTENTS (note ≤ 2)
--   cama_mesa_banho 6 · moveis_decoracao 3 · beleza_saude 2
--   esporte_lazer 2 · fashion_bolsas 2 · ferramentas_jardim 2
--   informatica_acessorios 2 · perfumaria 2 · puis 10 à 1
--
-- MÊME PROFIL : dispersion complète, et huit catégories
-- présentes dans LES DEUX groupes (utilidades_domesticas,
-- moveis_decoracao, beleza_saude, esporte_lazer, perfumaria,
-- automotivo, brinquedos, relogios_presentes).
-- → LA CATÉGORIE N'EXPLIQUE PAS LA SATISFACTION.
--   HYPOTHÈSE ÉCARTÉE.


-- ── Q6.d Hypothèse « date de livraison erronée » — NON TESTABLE
-- Si order_delivered_customer_date correspondait à un
-- enregistrement tardif plutôt qu'à la réception réelle, le
-- client aurait reçu son colis à temps sans le savoir.
-- Le commentaire « Recebi certinho » (j'ai bien reçu), sans
-- aucune mention de retard, irait dans ce sens.
--
-- AUCUNE SECONDE SOURCE DE DATE dans le jeu de données.
-- Hypothèse non vérifiable — et donc non écartée.


-- ── SYNTHÈSE DE L'INVESTIGATION Q6 ──────────────────────────
--   Petit effectif          ❌ écartée (distribution en U)
--   Geste commercial        ❌ affaiblie (aucun verbatim)
--   Produit non urgent      ❌ écartée (aucune concentration)
--   Date de livraison fausse ⬜ non testable
--
-- Trois hypothèses écartées par la donnée, une quatrième hors
-- de portée. L'anomalie est documentée, non expliquée.
--
-- QUESTION À REMONTER AU MÉTIER :
-- « 64 commandes livrées avec plus de 30 jours de retard à
--   São Paulo présentent une distribution en U — 30 notes de 1,
--   mais 28 notes de 4 ou 5. Un dispositif de compensation ou
--   de suivi a-t-il été appliqué sur ce périmètre ? »


-- ============================================================
-- SYNTHÈSE O3
-- ============================================================
--  1. IL N'Y A PAS DE SEUIL DE TOLÉRANCE. Dès le premier jour
--     de retard, l'insatisfaction augmente de 60 %
--  2. LE SEUIL CRITIQUE EST À 3 JOURS : la note passe sous 3,
--     l'insatisfaction dépasse 50 %
--  3. PLATEAU APRÈS 6 JOURS — le mal est fait, gagner des
--     jours au-delà n'apporte plus grand-chose
--  4. L'AVANCE N'APPORTE RIEN : la note plafonne à 4,3 de −30
--     à −5 jours. Le resserrement des délais a un coût nul
--     côté satisfaction (O8)
--  5. LE SEUIL EST NATIONAL : même point de bascule dans les
--     six grands états. Une règle unique suffit
--  6. RJ EST PLUS SÉVÈRE (58 % contre 41-53 %) sans que la
--     promesse l'explique — cas particulier confirmé
--  7. ANOMALIE SÃO PAULO : distribution en U sur les retards
--     de plus de 30 jours. Trois hypothèses écartées, une non
--     testable. Documentée, non expliquée.
--
-- PISTE D'APPROFONDISSEMENT OUVERTE PAR Q6 :
-- « Que faire quand le retard est inévitable ? » — question
-- distincte des 8 objectifs, qui portent tous sur ÉVITER ou
-- ANTICIPER le retard, jamais sur en LIMITER LES EFFETS.
-- ============================================================