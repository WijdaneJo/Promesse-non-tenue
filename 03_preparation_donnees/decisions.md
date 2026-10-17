# Journal des décisions

Chaque décision structurante du projet, avec sa justification et son impact.
Ce fichier répond à la question : *« pourquoi as-tu fait ce choix ? »*

---

## Architecture et environnement

### D-01 — PostgreSQL plutôt que SQLite
**Décision.** SGBD : PostgreSQL 17, port **5433**.
**Pourquoi.** Typage explicite obligatoire, vraie gestion de connexion, et surtout support des **schémas** — que SQLite ne connaît pas. C'est ce qui rend possible l'architecture en couches.
**À savoir.** Deux serveurs sont installés (PostgreSQL 12 sur 5432, PostgreSQL 17 sur 5433). Le nom d'un serveur dans pgAdmin est une simple étiquette : c'est le port dans ses propriétés qui fait foi.

### D-02 — Architecture en quatre couches
**Décision.** Quatre schémas : `raw` → `staging` → `intermediate` → `mart`. Chaque couche ne lit que la précédente.
**Pourquoi.** Quand un chiffre final paraît faux, on remonte couche par couche pour trouver où il s'est cassé. Avec un schéma unique et des tables écrasées au fil de l'eau, il n'y a rien à remonter. Permet aussi de rejouer une couche sans recharger le million de lignes de `geolocation`.

### D-03 — `raw` intégralement en TEXT
**Décision.** Toutes les colonnes de la couche `raw` sont déclarées `TEXT`, y compris les dates et les montants.
**Pourquoi.** Si une valeur est malformée, le chargement passe quand même et l'anomalie se découvre par requête, tranquillement, avec les lignes sous les yeux. Un typage à l'import ferait planter le chargement sur une seule ligne parmi 99 441.
**Vérification.** Le bloc C a confirmé que toutes les colonnes sont convertibles — le typage en `staging` s'est fait sans risque.

### D-04 — Base renommée `olist`
**Décision.** La base, créée sous le nom `Olist ` (avec un espace final), a été renommée `olist`.
**Pourquoi.** L'espace invisible rendait la base introuvable par `psql -d Olist` alors qu'elle apparaissait dans `\l`. Deux sessions de débogage perdues.
**Leçon retenue.** Quand quelque chose « existe visiblement » mais reste introuvable, c'est presque toujours un caractère invisible — espace, casse, encodage. Réflexe : rendre visible avec `SELECT '[' || colonne || ']'`.

---

## Conventions

### D-05 — Nommage en anglais
**Décision.** Tables et colonnes en anglais, `snake_case`, sans majuscules.
**Pourquoi.** Cohérence avec les noms de colonnes de la source. Les majuscules sont à proscrire : PostgreSQL les replie en minuscules sauf guillemets, source de bugs.
**Exception corrigée.** La colonne `payed_montant` (mélange anglais/français, et faute d'orthographe) a été renommée `payment_total`.

### D-06 — Noms de tables raccourcis
**Décision.** `olist_customers_dataset.csv` → `raw.customers`.
**Pourquoi.** Le préfixe `olist_` et le suffixe `_dataset` n'apportent rien : la base s'appelle `olist` et tout ce qu'elle contient est un dataset. Les noms retenus sont ceux du dictionnaire de données — documentation et base restent cohérentes.
**Limite.** Les **noms de colonnes** ne sont pas modifiés dans `raw`, y compris la faute de la source (`product_name_lenght`). `raw` copie, il ne transforme pas.

---

## Typage et nettoyage

### D-07 — Codes postaux et identifiants en TEXT
**Décision.** `customer_zip_code_prefix`, `seller_zip_code_prefix` et tous les identifiants restent en TEXT, même composés uniquement de chiffres.
**Pourquoi.** `'09790'::INT` donne `9790` — le zéro initial disparaît et la jointure vers `geolocation` échoue silencieusement. Or **São Paulo, première région du dataset, est entièrement en `0xxxx`**.
**Test à retenir.** Additionner deux de ces valeurs a-t-il un sens ? Non → c'est du texte.

### D-08 — Dimensions produit en INT
**Décision.** `product_length_cm`, `product_height_cm`, `product_width_cm` en `INT` plutôt qu'en `NUMERIC`.
**Pourquoi.** Vérifié sur la donnée (`WHERE colonne LIKE '%.%'`) : aucune décimale dans la source. `INT` est sémantiquement plus juste.
**Méthode.** Le doute a été tranché par une requête, pas par une supposition.

### D-09 — Poids à 0 convertis en NULL
**Décision.** `NULLIF(product_weight_g::INT, 0)` en couche `staging`.
**Pourquoi.** Les 4 produits concernés sont quatre déclinaisons d'un même article (catégorie `cama_mesa_banho`), dimensions et descriptifs renseignés, seul le poids à 0. Le zéro **code une saisie manquante**, il ne décrit pas un poids réel.
**Impact.** Sans correction, ces valeurs tireraient toute moyenne vers le bas et fourniraient une information fausse au modèle prédictif — pire qu'une information absente.
**Principe général.** On corrige ce qui est **faux**, on ne comble pas ce qui **manque**.

### D-10 — Colonnes écartées en `staging`
**Décision.** Ne sont pas reprises : `customer_city`, `seller_city`, `geolocation_city`, `geolocation_state`, `review_comment_title`, `review_comment_message`, `product_name_lenght`, `product_description_lenght`, `product_photos_qty`.
**Pourquoi.** Les villes comptent plusieurs milliers de modalités, non exploitables ; la maille d'analyse est l'état. Les commentaires relèvent d'une extension NLP hors v1. Les trois colonnes descriptives sont marquées « non retenu » au dictionnaire.
**Conservé malgré tout.** `customer_unique_id` : coût nul, et permet de tester l'hypothèse des `review_id` dupliqués (même client ?).

---

## Grain et périmètre

### D-11 — Agrégation des quatre tables au mauvais grain
**Décision.** `order_items`, `order_payments`, `order_reviews` et `geolocation` sont ramenées à une ligne par commande (ou par code postal) **avant** toute jointure.
**Pourquoi.** Les joindre en l'état multiplierait le périmètre. Le cas le plus dangereux est `geolocation` : 1 000 163 lignes pour ~19 000 codes postaux — chaque commande serait multipliée par le nombre de points relevés dans sa zone.
**Vérification.** Test de doublons sur chaque table produite : 0 ligne. C'est ce contrôle qui garantit que l'assemblage final ne duplique rien.

### D-12 — `nb_items` par `COUNT(*)`, jamais `SUM(order_item_id)`
**Décision.** Le nombre d'articles d'une commande est le nombre de **lignes**.
**Pourquoi.** `order_item_id` est un **numéro d'ordre** (1, 2, 3), pas une quantité. En sommer trois donnerait 6, ce qui ne veut rien dire. Olist ne stocke pas de quantité : deux articles identiques produisent deux lignes.

### D-13 — RG-01 et RG-03 exclues, RG-04 conservée
**Décision.**
- **Exclues** : 8 commandes sans date de livraison (RG-01), 23 livrées avant remise au transporteur (RG-03).
- **Conservées** : 674 commandes remises au transporteur avant validation du paiement (RG-04), avec segment « préparation » neutralisé en `NULL`.

**Pourquoi.** Une livraison antérieure à l'expédition est **physiquement impossible** — c'est une erreur de saisie. Expédier avant validation du paiement est improbable mais **possible**. Les exclure ferait perdre de l'activité sans justification.
**Distinction retenue.** Exclusion **générale** (la ligne sort du périmètre) vs exclusion **ciblée** (la ligne reste, une seule analyse lui est fermée).

### D-14 — Traitement explicite des NULL dans le filtre RG-03
**Décision.** `WHERE (carrier_date IS NULL OR customer_date >= carrier_date)`.
**Pourquoi.** Toute comparaison avec `NULL` renvoie `NULL` — ni vrai ni faux — et le `WHERE` écarte donc silencieusement ces lignes. Sans la clause `IS NULL` : 25 exclusions au lieu de 23.
**Le `>=`** admet une livraison le jour même de la remise au transporteur.

---

## Règles de calcul

### D-15 — RG-06 : moyenne tronquée des avis multiples
**Décision.** Pour les 547 commandes à plusieurs avis : `FLOOR(AVG(review_score))`.
**Pourquoi la moyenne** plutôt que le premier ou le dernier avis : les avis multiples portent le plus souvent le même score.
**Pourquoi `FLOOR`** plutôt que `ROUND` : **choix conservateur assumé**. Sur un projet dont l'objet est d'identifier des ruptures de promesse, mieux vaut surestimer légèrement l'insatisfaction que la manquer.
**Effet mesurable.** Une commande notée 2 et 3 donne une moyenne de 2,5, tronquée à 2 → comptée insatisfaite (M-02). Avec un arrondi, elle serait à 3 → satisfaite.
**Conséquence.** `review_id` est abandonné : il n'a plus de sens au grain commande une fois les avis fusionnés. Les dates sont prises en `MIN()` — la première sollicitation est la plus proche de l'événement livraison.

### D-16 — Retard en jours calendaires
**Décision.** Toutes les soustractions de dates passent par `::DATE`.
**Pourquoi.** La promesse d'Olist porte sur une **date**, pas sur un horaire. Un client qui reçoit son colis le jour promis à 23 h n'est pas en retard.
**Contrepartie assumée.** Une livraison le lendemain à 0 h 30 compte pour un jour entier de retard, alors que l'écart réel est de 90 minutes. Cohérent avec la logique métier : le jour promis est dépassé.
**Aspect technique.** Sans `::DATE`, la soustraction de deux `TIMESTAMP` renvoie un `INTERVAL` (`-8 days -04:37:12`), inexploitable pour des tranches ou une médiane.

### D-17 — Seuil de retard strict
**Décision.** `is_late = (gap > 0)`, et non `>= 0`.
**Pourquoi.** Livré le jour exact de la promesse, l'engagement est **tenu**. Le cadrage parle de rupture de promesse, pas de délai dépassé à la minute.

### D-18 — Bornes des tranches de gravité
**Décision.** Six modalités : `Too early` (≤ −4 j), `At time` (−3 à 0), `Barely late` (1-7), `Late` (8-15), `Too late` (16-30), `Very late` (≥ 31).
**Pourquoi ces bornes.** Elles suivent la **distribution observée**, non des chiffres ronds arbitraires. Deux ruptures nettes dans les volumes : après 1 jour (825 → 545) et après 7-8 jours (483 → 336). Elles coïncident avec des unités de temps parlantes pour un décideur (la semaine, le mois).
**Pourquoi une modalité pour les commandes à l'heure.** Sans elle, ces commandes tomberaient en `NULL` et sortiraient de toutes les analyses par tranche — or elles constituent le **groupe de référence** de M-01.
**Frontière à −4 jours.** Au-delà de trois jours d'avance, la livraison n'est plus perçue comme ponctuelle mais comme anticipée, avec un coût réel pour le client (absence, stockage).
**Limite connue.** La modalité `Too early` regroupe 87 % du périmètre, de −4 à −147 jours — très hétérogène. Un découpage plus fin de l'avance sera nécessaire pour M-16 (marge sur les délais annoncés).

### D-19 — RG-11 : `payment_total` comme montant de référence
**Décision.** Le chiffre d'affaires est mesuré par `payment_total` (somme des `payment_value`), et non par `total_price + total_freight`.
**Pourquoi.** Le chiffre d'affaires est **l'argent qui entre**, pas la valeur théorique du panier.
**Contrôle effectué.** Comparaison des deux sources sur le périmètre : 299 écarts sur 96 447 (0,31 %), maximum **0,02 R$** — des arrondis. H9 revalidé.
**Conservé.** `total_price` et `total_freight` restent en colonnes séparées : ils permettent de mesurer la part du transport dans le CA exposé (O4). Ce n'est pas une redondance mais une décomposition.

### D-20 — Booléens plutôt que libellés texte
**Décision.** `is_late` et `is_unsatisfied` sont des booléens, pas des libellés.
**Pourquoi.** `AVG(booleen::INT)` donne directement un **taux** — `true` devient 1, `false` devient 0. Un libellé imposerait de compter puis diviser. Or M-00 et M-02 sont précisément des taux.

---

## Distance

### D-21 — Calcul en Python, résultat réinjecté en base
**Décision.** La distance est calculée par la formule de **Haversine** en Python, puis écrite dans `intermediate.distances`.
**Pourquoi Haversine et non une distance euclidienne.** La Terre est une sphère. Un degré de latitude vaut toujours ~111 km, mais un degré de **longitude rétrécit** à mesure qu'on s'éloigne de l'équateur. Traiter lat/lng comme des coordonnées planes revient à mesurer sur une carte dépliée — sur le Brésil, qui s'étend sur ~39 degrés de latitude, la déformation est significative.
**Pourquoi Python plutôt que SQL.** La formule est lourde à écrire en SQL ; elle est lisible en quelques lignes avec numpy, et le calcul est **vectorisé** (97 607 lignes traitées d'un coup, sans boucle).
**Pourquoi réinjecter en base.** La distance sert à la fois au modèle prédictif (O6) et au dashboard. La stocker évite de la recalculer.
**Conséquence assumée.** Le pipeline devient **hybride** : le SQL seul ne reconstruit plus la base. L'ordre d'exécution est documenté dans le README.

### D-22 — Distance maximale pour les commandes multi-vendeurs
**Décision.** Une commande à plusieurs vendeurs retient la distance la **plus longue**.
**Pourquoi.** Le dataset ne fournit qu'**une seule date de livraison** par commande, même à deux vendeurs. Cette date correspond vraisemblablement au dernier colis arrivé — donc au vendeur le plus éloigné.
**Limite à documenter.** Les expéditions séparées ne sont pas distinguables dans les données. C'est une hypothèse, non un fait établi.
**Ce qui n'est pas perdu.** Le détail commande × vendeur reste accessible : `mart.sellers` est construite depuis `staging.order_items`.

### D-23 — `LEFT JOIN` pour préserver le périmètre
**Décision.** Tous les `JOIN` de la chaîne de coordonnées et de l'assemblage final sont des `LEFT JOIN`.
**Pourquoi.** En `INNER JOIN`, 476 commandes disparaissaient (95 971 au lieu de 96 447) : un code postal absent de `geolocation`. Une distance manquante ne justifie pas d'exclure une commande des analyses de retard, de satisfaction ou de CA.
**Règle de la chaîne.** Un seul `INNER` en fin de chaîne annule l'effet de tous les `LEFT` précédents.

---

## Grain vendeur

### D-24 — RG-09 : commandes mono-vendeur uniquement
**Décision.** `WHERE nb_sellers = 1` — filtre appliqué aux **commandes**.
**Pourquoi.** Sur une commande à deux vendeurs, le retard ne peut être imputé à aucun des deux. L'attribution serait arbitraire.

### D-25 — RG-08 : seuil de 10 commandes par vendeur
**Décision.** `HAVING COUNT(*) >= 10` — filtre appliqué aux **vendeurs**.
**Pourquoi.** Un vendeur à 2 commandes dont 1 en retard affiche 50 % de taux de retard, ce qui ne signifie rien statistiquement.
**Impact mesuré avant décision.**

| | Retenu | Total | Part |
|---|---|---|---|
| Vendeurs | 1 217 | 2 948 | 41,3 % |
| Commandes | 89 250 | 95 191 | **93,8 %** |

On écarte 59 % des vendeurs mais seulement **6,2 % de l'activité**.
*Mesuré sur le périmètre final, mono-vendeur (RG-09). Un premier comptage à 1 323 portait sur toutes les commandes, tous statuts confondus.* Le bruit statistique part, le phénomène reste.
**Point technique.** Le `WHERE` ne peut pas faire ce travail : au moment où il s'applique, le comptage par vendeur n'existe pas encore. C'est la raison d'être de `HAVING`.

---

## Hygiène technique

### D-26 — Identifiants dans un `.env`
**Décision.** Host, port, base, utilisateur et mot de passe sont lus depuis un fichier `.env`, non versionné.
**Pourquoi.** Un mot de passe en dur dans un fichier poussé sur GitHub est une mauvaise pratique, même sur une base locale. Un `.env.example` versionné montre les clés attendues sans les valeurs.
**Point d'attention.** `load_dotenv()` cherche le fichier dans le **dossier de travail courant**, pas à côté du script.

### D-27 — Scripts rejouables
**Décision.** Chaque fichier SQL commence par `DROP TABLE IF EXISTS`. Le chargement Python fait un `TRUNCATE` avant `COPY`. `to_sql` utilise `if_exists="replace"`.
**Pourquoi.** Le pipeline doit se rejouer de bout en bout sans intervention manuelle. Une correction faite par `ALTER` ou `DELETE` rend le script dépendant de l'ordre historique des opérations.
**Vérification effectuée.** Les quatre schémas ont été détruits et intégralement reconstruits depuis les CSV bruts. Les chiffres obtenus sont **identiques**.
**Piège rencontré.** Un `ALTER` fait à la main doit **toujours** être reporté dans le script source. Sinon : base juste, script faux — et le bug se révèle des semaines plus tard.

---

## À faire

- [ ] Environnement virtuel Python + `requirements.txt` (packages actuellement installés en global)
- [ ] Rattacher `product_category_name` à `mart.orders` — règle d'attribution à définir pour les commandes multi-catégories (produit le plus cher ? le plus fréquent ?). 1 392 commandes (1,44 %) portent un produit sans catégorie : prévoir une modalité « non renseigné »
- [ ] Vérifier l'absence de volumes produit à 0 (même piège que les poids, cf. D-09)
- [ ] Découpage plus fin de la modalité `Too early` pour M-16 (cf. D-18)
