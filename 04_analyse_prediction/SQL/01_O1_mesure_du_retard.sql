-- ============================================================
-- O1. MESURE DU RETARD
-- ============================================================
-- Objectif : caractériser le phénomène. Combien, où, quand, et
-- de combien.
--
-- Source     : mart.orders (96 447 commandes du périmètre)
-- Métriques  : M-00, M-14, M-15, M-16
-- Constats   : resultats/01_O1_constats.md
--
-- RÈGLE DE MÉTHODE : toute agrégation porte son VOLUME.
-- Un taux de 21 % sur 397 commandes et un taux de 12 % sur
-- 12 349 ne se lisent pas de la même façon. Le taux dit où le
-- processus dysfonctionne ; le volume dit où l'impact client
-- est le plus fort. Les deux sont nécessaires.


-- ============================================================
-- Q1. LE RETARD PAR ÉTAT (M-00)
-- ============================================================

-- -- Q1.a Taux de retard par état ----------------------------
-- AVG(is_late::INT) : true -> 1, false -> 0. La moyenne de ces
-- 0/1 EST le taux. C'est pour cela que is_late a été conçu
-- comme booléen et non comme libellé texte.
--
-- ROUND(... * 100, 2) : sans mise en forme, PostgreSQL renvoie
-- 0.21410579345088161209 : juste, mais illisible.
--
-- Tri par TAUX et non par volume : trier par nombre de retards
-- placerait São Paulo en tête par simple effet de taille
-- (42 % du périmètre), sans rien dire de sa performance.
SELECT
    customer_state,
    COUNT(*)                          AS total_orders,
    COUNT(*) FILTER (WHERE is_late)   AS late_orders,
    ROUND(AVG(is_late::INT) * 100, 2) AS late_rate_pct
FROM mart.orders
GROUP BY customer_state
ORDER BY late_rate_pct DESC;

-- RÉSULTAT : 27 états · taux national de référence : 6,77 %
--
--   AL    397    85  21,41  <- maximum
--   MA    717   125  17,43
--   SE    335    51  15,22
--   PI    476    66  13,87
--   CE   1279   176  13,76
--   RR     41     5  12,20  volume trop faible
--   BA   3256   396  12,16
--   RJ  12349  1495  12,11  <- cible prioritaire (volume)
--   PA    946   106  11,21
--   ES   1995   214  10,73
--   PB    517    54  10,44
--   TO    274    27   9,85
--   MS    701    68   9,70
--   PE   1593   153   9,60
--   RN    474    44   9,28
--   SC   3544   291   8,21
--   GO   1957   128   6,54
--   RS   5343   325   6,08
--   MT    886    53   5,98
--   DF   2080   118   5,67
--   MG  11349   519   4,57
--   SP  40480  1820   4,50  <- 42 % du périmètre
--   PR   4923   199   4,04
--   AC     80     3   3,75  volume trop faible
--   AP     67     2   2,99  volume trop faible
--   RO    243     7   2,88
--   AM    145     4   2,76  <- minimum
--
-- ÉCART DE 1 À 8 entre AM et AL, mais sur de petits effectifs.
-- Parmi les états de plus de 500 commandes : de 4,04 % (PR) à
-- 17,43 % (MA), soit un RAPPORT DE 1 À 4.
-- La moyenne nationale de 6,77 % ne décrit aucun état réel.
--
-- SP a le plus grand VOLUME de retards (1 820) mais le
-- 2e meilleur TAUX des états de plus de 500 commandes. C'est lui qui tire la moyenne vers le bas.


-- -- Q1.b Les états sous seuil de fiabilité ------------------
-- Même logique que RG-08 sur les vendeurs : un taux calculé
-- sur 41 commandes n'a pas de valeur statistique : cinq
-- retards de plus ou de moins le feraient varier de dix points.
-- Ces états restent dans les totaux nationaux ; seules les
-- conclusions INDIVIDUELLES les excluent.
SELECT
    customer_state,
    COUNT(*) AS total_orders
FROM mart.orders
GROUP BY customer_state
HAVING COUNT(*) < 200
ORDER BY total_orders;

-- RÉSULTAT : RR (41), AP (67), AC (80), AM (145)
-- Seuil de 200 commandes retenu par cohérence avec l'esprit
-- de RG-08. À documenter dans toute restitution par état.


-- -- Q1.c Concentration du volume ----------------------------
-- Combien d'états concentrent l'essentiel de l'activité ?
-- Détermine si une moyenne nationale a un sens.
-- SUM(COUNT(*)) OVER () : fonction fenêtre, le total général
-- reste disponible après le GROUP BY, ce qui permet de
-- calculer une part sans sous-requête.
SELECT
    customer_state,
    COUNT(*)                                           AS total_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS part_pct,
    ROUND(SUM(COUNT(*)) OVER (ORDER BY COUNT(*) DESC)
          * 100.0 / SUM(COUNT(*)) OVER (), 2)          AS part_cumulee_pct
FROM mart.orders
GROUP BY customer_state
ORDER BY total_orders DESC;

-- RÉSULTAT : SP = 42 % à lui seul. SP + RJ + MG = 66 %.
-- CONSÉQUENCE : toute moyenne nationale est dominée par le
-- Sud-Est. Ne jamais conclure sur un chiffre national sans
-- avoir regardé sa déclinaison géographique.


-- ============================================================
-- Q2. L'ÉVOLUTION DANS LE TEMPS (M-00)
-- ============================================================

-- -- Q2.a Taux de retard par mois ----------------------------
-- GROUP BY sur l'ANNÉE ET le mois : grouper par mois seul
-- mélangerait mars 2017 et mars 2018, ce qui écraserait
-- précisément le pic recherché.
-- Tri CHRONOLOGIQUE : pour lire une évolution, l'ordre doit
-- être temporel, pas par valeur.
SELECT
    purchase_year,
    purchase_month,
    COUNT(*)                          AS total_orders,
    COUNT(*) FILTER (WHERE is_late)   AS late_orders,
    ROUND(AVG(is_late::INT) * 100, 2) AS late_rate_pct
FROM mart.orders
GROUP BY purchase_year, purchase_month
ORDER BY purchase_year, purchase_month;

-- RÉSULTAT : extraits significatifs
--
--   2016-09      1       1  100,00  mois incomplet
--   2016-10    261       2    0,77  mois incomplet
--   2016-12      1       0    0,00  mois incomplet
--   2017-03   2545     116    4,56
--   2017-11   7288     904   12,40  <- Black Friday (confirmé)
--   2017-12   5513     411    7,46
--   2018-01   7069     403    5,70
--   2018-02   6555     926   14,13  <- début de crise
--   2018-03   7003    1328   18,96  <- MAXIMUM
--   2018-04   6798     306    4,50  <- retour brutal
--   2018-06   6096      71    1,16  <- minimum
--   2018-08   6351     ...    ~5,5
--
-- Trois mois à écarter des analyses de tendance :
-- 2016-09 (1 commande), 2016-10 (261), 2016-12 (1).
-- Le « 100 % de retard » de septembre 2016 porte sur UNE
-- commande : exactement ce que le cadrage prévoit d'exclure.
--
-- CROISSANCE : 2 545 commandes en mars 2017 contre 7 003 en
-- mars 2018. La plateforme a triplé son activité en un an.


-- -- Q2.b Piste écartée : le volume --------------------------
-- Le pic de mars s'explique-t-il par une saturation ?
-- Comparaison directe dans le résultat de Q2.a :
--
--   Mars 2018     7 003 commandes  -> 18,96 %
--   Janvier 2018  7 069 commandes  ->  5,70 %
--   Juin 2018     6 096 commandes  ->  1,16 %
--
-- JANVIER A PLUS DE COMMANDES QUE MARS ET TROIS FOIS MOINS DE
-- RETARD. La saturation logistique n'explique pas le pic.


-- -- Q2.c Piste écartée : une défaillance régionale ----------
-- Le pic est-il concentré sur quelques états, ou général ?
SELECT
    customer_state,
    COUNT(*)                          AS total_orders,
    COUNT(*) FILTER (WHERE is_late)   AS late_orders,
    ROUND(AVG(is_late::INT) * 100, 2) AS late_rate_pct
FROM mart.orders
WHERE purchase_year = 2018 AND purchase_month = 3
GROUP BY customer_state
ORDER BY late_rate_pct DESC;

-- RÉSULTAT : comparaison période complète / mars 2018
--
--   État   Complet   Mars 2018   Facteur
--   SP       4,50 %     9,42 %     ×2,1
--   MG       4,57 %    20,44 %     ×4,5
--   RS       6,08 %    19,16 %     ×3,2
--   RJ      12,11 %    34,49 %     ×2,8
--   SC       8,21 %    19,43 %     ×2,4
--
-- LES 27 ÉTATS DÉGRADENT, SANS EXCEPTION : y compris MG,
-- habituellement l'un des mieux servis, multiplié par 4,5.
-- Ce n'est donc ni un transporteur régional, ni une route
-- bloquée, ni un événement local. LA CAUSE EST CENTRALE.
--
-- RJ atteint 34,49 % avec 298 commandes en retard : l'état
-- déjà le plus fragile encaisse le choc le plus fort.
-- SP résiste le mieux (×2,1) : proximité des vendeurs.


-- -- Q2.d Le segment défaillant ------------------------------
-- Lequel des trois segments a lâché ?
--
-- PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY x) : la médiane
-- en PostgreSQL. Il n'existe pas de fonction MEDIAN().
--
-- MÉDIANE ET NON MOYENNE : l'acheminement va jusqu'à 205 jours.
-- Quelques valeurs extrêmes tireraient la moyenne vers le haut
-- et donneraient une image fausse du cas courant.
--
-- NOTE DE MÉTHODE : il n'existe pas de « retard » sur un
-- segment : Olist ne promet rien sur la préparation ou
-- l'acheminement pris séparément. La seule promesse est la
-- date finale. On compare donc chaque segment À SA PROPRE
-- NORMALE (médiane 2017), pas à un engagement.
SELECT
    purchase_year,
    purchase_month,
    COUNT(*) AS total_orders,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gap_validation)  AS med_validation,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gap_preparation) AS med_preparation,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gap_shipping)    AS med_acheminement
FROM mart.orders
GROUP BY purchase_year, purchase_month
ORDER BY purchase_year, purchase_month;

-- RÉSULTAT
--
--   Mois          Valid.  Prépa.  ACHEMINEMENT   Retard
--   2017 (norme)     0       2         7          ~4 %
--   2017-11          0       3         9         12,40 %
--   2018-01          0       2         8          5,70 %
--   2018-02          0       2        11         14,13 %  <-
--   2018-03          0       2        10         18,96 %  <-
--   2018-04          0       1         7          4,50 %
--   2018-06          0       1         6          1,16 %
--   2018-08          0       1         5          ~5,5 %
--
-- LA PRÉPARATION VENDEUR NE BOUGE PAS : 2 jours, stable depuis
-- 2017. Les vendeurs ne sont pas en cause.
-- L'ACHEMINEMENT PASSE DE 7 À 11 JOURS, puis redescend.
-- Le transport a lâché pendant deux mois.
--
-- Novembre 2017 présente la même signature à moindre échelle :
-- acheminement à 9 jours, retard à 12,40 %. (Cause identifiée
-- en Q2.g : Black Friday.)
--
-- SECOND CONSTAT, PLUS IMPORTANT : après avril 2018, la
-- performance ne revient pas au niveau d'avant : elle le
-- DÉPASSE. Acheminement 7 à 5 jours, préparation 2 à 1.
-- Ce n'est pas un retour à la normale, c'est une amélioration
-- structurelle.


-- -- Q2.e Le paradoxe février / mars -------------------------
-- Février : acheminement 11 j à 14,13 % de retard
-- Mars    : acheminement 10 j à 18,96 % de retard
-- Mars livre PLUS VITE et génère PLUS DE RETARD.
--
-- Hypothèse : la promesse s'est resserrée.
-- La promesse n'existe pas comme colonne, elle se calcule :
-- date annoncée − date d'achat.
SELECT
    purchase_year,
    purchase_month,
    PERCENTILE_CONT(0.5) WITHIN GROUP (
        ORDER BY order_estimated_delivery_date::DATE
                 - order_purchase_timestamp::DATE
    ) AS med_promesse
FROM mart.orders
GROUP BY purchase_year, purchase_month
ORDER BY purchase_year, purchase_month;

-- RÉSULTAT : durée médiane promise
--
--   2017-01                39 jours
--   2017-02                31 jours
--   2017-03 à 2017-11      23-26 jours
--   2018-02                25 jours
--   2018-03                22 jours   <- 3 jours de moins
--   2018-05                22 jours
--   2018-07                20 jours
--   2018-08                14 jours   <- −40 % vs 2017
--
-- HYPOTHÈSE CONFIRMÉE : mars promet 3 jours de moins que
-- février. La marge se réduit plus vite que l'exécution ne
-- s'améliore : d'où plus de retards malgré une meilleure
-- performance.
--
-- LE RETARD N'EST PAS UNE MESURE DE PERFORMANCE. C'est un
-- écart entre deux grandeurs qui varient toutes les deux :
-- ce qui est promis et ce qui est exécuté.
--
-- CONSTAT MAJEUR : le resserrement de la promesse a déjà
-- commencé. 23 à 26 jours en 2017, 14 en août 2018.


-- -- Q2.f Contrôle de validité : troncature ------------------
-- Le constat sur août 2018 est le plus fort de O1 : il doit
-- donc être le plus challengé.
--
-- LE RISQUE : mart.orders ne contient que des commandes
-- LIVRÉES. Si le jeu de données s'arrête peu après août, les
-- commandes d'août lentes n'y figurent pas : elles n'étaient
-- pas encore livrées. Il ne resterait que les rapides, et le
-- taux de retard d'août serait artificiellement bas.
SELECT
    MAX(order_purchase_timestamp)      AS dernier_achat,
    MAX(order_delivered_customer_date) AS derniere_livraison
FROM mart.orders;

-- RÉSULTAT : dernier achat 2018-08-29 · dernière livraison 2018-10-17
-- SEPT SEMAINES D'ÉCART : largement de quoi livrer même les
-- commandes lentes d'août.
--
-- Second contrôle, sur le volume (cf. Q2.a) : août 2018 compte
-- 6 351 commandes, contre 6 156 en juillet et 6 096 en juin.
-- Volume normal, voire supérieur.
--
-- PAS DE TRONCATURE. Le constat est validé sur deux critères.


-- -- Q2.g Vérification du Black Friday -----------------------
-- Novembre 2017 affiche 12,40 % de retard, isolé entre octobre
-- (4,18 %) et décembre (7,46 %). Le Black Friday brésilien a
-- lieu fin novembre : piste à vérifier.
--
-- EXTRACT(DAY FROM ...) : le jour du MOIS (1 à 31).
-- Ne pas confondre avec purchase_dow, qui donne le jour de la
-- SEMAINE (0 = dimanche à 6 = samedi) et ne permettrait pas
-- d'identifier une date précise.
SELECT
    EXTRACT(DAY FROM order_purchase_timestamp) AS jour,
    COUNT(*)                                   AS total_orders
FROM mart.orders
WHERE purchase_year = 2017 AND purchase_month = 11
GROUP BY jour
ORDER BY total_orders DESC;

-- RÉSULTAT
--
--   24 nov.   1 147 commandes   <- Black Friday 2017
--   25 nov.     487
--   27 nov.     395
--   26 nov.     382
--   28 nov.     371
--   29 nov.     314
--   23 nov.     268             <- la veille
--
-- PISTE CONFIRMÉE : ×4,3 en une journée. Le 24 novembre 2017
-- correspond bien au Black Friday brésilien.
--
-- CONSÉQUENCE : deux natures de dégradation à distinguer :
--
--   |            | Fév-mars 2018      | Novembre 2017     |
--   |------------|--------------------|-------------------|
--   | Nature     | Incident inexpliqué| Pic commercial    |
--   | Retard     | 18,96 %            | 12,40 %           |
--   | Récurrence | Ponctuel           | ANNUEL            |
--   | Action     | À diagnostiquer    | ANTICIPABLE       |
--
-- Olist connaît la date du Black Friday un an à l'avance.
-- Renforcer la capacité d'acheminement sur cette période, ou
-- allonger temporairement les délais annoncés, sont deux
-- leviers concrets.


-- ============================================================
-- Q3. L'AMPLEUR DU RETARD (M-15)
-- ============================================================

-- -- Q3. Retard médian par état ------------------------------
-- Quand la promesse est rompue, DE COMBIEN l'est-elle ?
--
-- WHERE is_late OBLIGATOIRE : sur l'ensemble du périmètre, la
-- médiane du gap serait d'environ −12 jours : elle décrirait
-- l'avance, pas le retard.
--
-- ENJEU : ce chiffre conditionne l'intérêt du simulateur
-- (M-13). Un gain de 3 jours ne sert à rien si les retards
-- sont de 15 jours.
SELECT
    customer_state,
    COUNT(*)                                         AS nb_late_orders,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gap) AS med_retard
FROM mart.orders
WHERE is_late
GROUP BY customer_state
ORDER BY med_retard DESC;

-- RÉSULTAT : extraits (états sous 10 commandes en retard écartés)
--
--   CE    176   10 j
--   RJ   1495    9 j
--   PA    106    9 j
--   PE    153    9 j
--   MA    125    8 j
--   BA    396    7 j
--   AL     85    7 j
--   RS    325    7 j
--   ES    214    6 j
--   SC    291    6 j
--   SP   1820    5 j
--   MG    519    5 j
--   PR    199    5 j
--
-- AP affiche 72,5 jours : sur 2 commandes. Écarté.
--   Idem AC (3), AM (4), RR (5), RO (7).
--
-- AMPLITUDE FAIBLE : 5 à 10 jours partout, contre un rapport de
-- 1 à 4 sur les TAUX des grands états. LE PROBLÈME EST LA FRÉQUENCE, PAS LA GRAVITÉ.
--
-- AL : pire taux du pays (21,41 %) mais retard le plus court
-- (7 j). Rate souvent, de peu.
-- CE : rate moins souvent (13,76 %) mais plus largement (10 j).
-- Deux profils opposés, deux traitements différents.


-- ============================================================
-- M-14. LA DISTRIBUTION DE LA GRAVITÉ
-- ============================================================

-- -- Distribution des retards par état -----------------------
-- La médiane de Q3 donne le cas CENTRAL. Cette requête montre
-- les EXTRÊMES : un état peut avoir une médiane correcte et
-- beaucoup de cas catastrophiques.
--
-- Une colonne par tranche via COUNT(*) FILTER : plus lisible
-- qu'un GROUP BY customer_state, timing, qui produirait
-- 27 × 6 = 162 lignes.
-- Les modalités « Too early » et « At time » sont exclues par
-- le WHERE : elles écraseraient le tableau (93 % du périmètre).
SELECT
    customer_state,
    COUNT(*) FILTER (WHERE timing = 'Barely late') AS barely_late,
    COUNT(*) FILTER (WHERE timing = 'Late')        AS late,
    COUNT(*) FILTER (WHERE timing = 'Too late')    AS too_late,
    COUNT(*) FILTER (WHERE timing = 'Very late')   AS very_late,
    COUNT(*)                                       AS total_late
FROM mart.orders
WHERE is_late
GROUP BY customer_state
ORDER BY total_late DESC;

-- RÉSULTAT : extraits
--
--   État  1-7j   8-15j  16-30j  >30j   Total   Part grave
--   SP    1265    345     145     65   1820      30 %
--   RJ     624    423     313    135   1495      58 %  <-
--   MG     336    108      61     14    519      35 %
--   BA     209    119      42     26    396      47 %
--   RS     165    106      46      8    325      49 %
--   SC     179     69      37      6    291      38 %
--   CE      63     60      31     22    176      64 %  <-
--   AL      45     28       8      4     85      47 %
--
-- RJ EST LE SEUL GRAND ÉTAT OÙ LA MAJORITÉ DES RETARDS SONT
-- GRAVES : 871 commandes au-delà de 8 jours, dont 135 à plus
-- de 30 jours. São Paulo a plus de retards en volume mais
-- 70 % sont courts et seulement 65 dépassent 30 jours.
--
-- AL CHANGE DE STATUT : 45 des 85 retards sont courts, 4
-- seulement dépassent 30 jours. Mauvaise fréquence, faible
-- gravité : problème de calibrage, pas de défaillance.


-- ============================================================
-- Q4. LA MARGE SUR LES DÉLAIS ANNONCÉS (M-16)
-- ============================================================

-- -- Q4. Promesse et distance par état -----------------------
-- QUESTION : AM affiche 2,76 % de retard alors qu'il est à
-- 2 700 km. Est-ce une bonne performance, ou une promesse
-- large ? Trois colonnes pour trancher.
SELECT
    customer_state,
    COUNT(*)                          AS nb_orders,
    PERCENTILE_CONT(0.5) WITHIN GROUP (
        ORDER BY order_estimated_delivery_date::DATE
                 - order_purchase_timestamp::DATE
    )                                 AS med_promesse,
    ROUND(AVG(is_late::INT) * 100, 2) AS late_rate,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY distance_km) AS med_distance
FROM mart.orders
GROUP BY customer_state
ORDER BY med_promesse DESC;

-- RÉSULTAT : extraits
--
--   État  Promesse  Retard   Distance
--   AP      48 j     2,99 %   2 663 km
--   AM      46 j     2,76 %   2 693 km
--   RR      45 j    12,20 %   3 303 km
--   AC      41 j     3,75 %   2 713 km
--   RO      38 j     2,88 %   2 280 km
--   PA      37 j    11,21 %   2 394 km
--   AL      32 j    21,41 %   1 915 km  <-
--   CE      32 j    13,76 %   2 292 km
--   BA      30 j    12,16 %   1 424 km
--   RS      29 j     6,08 %     856 km
--   SC      26 j     8,21 %     529 km
--   DF      25 j     5,67 %     867 km
--   PR      25 j     4,04 %     427 km
--   RJ      25 j    12,11 %     396 km  <-
--   MG      24 j     4,57 %     491 km
--   SP      19 j     4,50 %     166 km
--
-- LA PROMESSE EST BIEN CALIBRÉE SUR LA DISTANCE : 46 j à
-- 2 700 km, 19 j à 166 km. Olist ajuste son engagement à la
-- difficulté logistique.
--
-- MAIS LA DISTANCE N'EXPLIQUE PAS LE RETARD :
--
--   - RJ est l'état le plus PROCHE après SP (396 km) et a la
--     même promesse que PR (427 km) et MG (491 km).
--     PR : 4,04 % · MG : 4,57 % · RJ : 12,11 %
--     -> TROIS FOIS PLUS DE RETARD À CONDITIONS ÉGALES.
--
--   - AL est plus proche que CE et RR, avec une promesse
--     comparable, et affiche le PIRE TAUX DU PAYS.
--
--   - AM et RR promettent tous deux ~45 j : l'un est à 2,76 %,
--     l'autre à 12,20 %. Même promesse, résultat 4× pire.
--
-- DEUX PROFILS À TRAITER DIFFÉREMMENT :
--   AL, MA, RR -> promesse déjà large, problème OPÉRATIONNEL
--   RJ         -> promesse calibrée comme un état facile,
--                alors qu'il ne l'est pas -> RECALIBRAGE


-- ============================================================
-- SYNTHÈSE O1
-- ============================================================
--  1. Le retard varie de 1 à 4 entre les grands états ; la moyenne
--     nationale de 6,77 % ne décrit aucun état réel
--  2. RJ est la cible prioritaire : 1 495 commandes en retard
--  3. Incident national en février-mars 2018, non expliqué
--     par le volume ni par une défaillance régionale
--  4. L'ACHEMINEMENT a lâché (de 7 à 11 j), pas la préparation
--     vendeur
--  5. Le retard dépend autant de la promesse que de
--     l'exécution
--  6. L'ampleur est faible partout (5 à 10 j) SAUF à RJ,
--     où 58 % des retards dépassent 8 jours
--  7. La distance explique la PROMESSE mais pas le RETARD :
--     RJ et AL sortent du modèle
--  8. La performance s'est améliorée après la crise :
--     acheminement à 5 jours
--  9. Olist a déjà resserré sa promesse de 40 % (de 23 à 14 j) :
--     constat validé contre le risque de troncature
-- 10. Novembre 2017 = Black Friday, dégradation ANTICIPABLE
--     car récurrente
-- ============================================================