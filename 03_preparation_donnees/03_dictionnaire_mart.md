# Dictionnaire des tables analytiques — `mart`

Ces deux tables sont les livrables de la phase de préparation.
Toute l'analyse (O1 à O7) se fonde sur elles.

---

## `mart.orders` — Les commandes

**Grain** : une ligne = une commande du périmètre
**Volume** : 96 447 lignes
**Source** : `intermediate.orders` enrichie par jointure des 4 tables satellites

---

### Identifiants

| Champ | Type | Signification | Remarque |
|---|---|---|---|
| `order_id` | texte | Identifiant de la commande | Clé primaire — unicité vérifiée |
| `customer_id` | texte | Identifiant client **propre à cette commande** | ⚠️ Ne pas confondre avec `customer_unique_id` : 96 447 commandes pour 96 447 `customer_id`. Seul `customer_unique_id` (dans `staging.customers`) identifie une personne |

### Dates du parcours

| Champ | Type | Signification |
|---|---|---|
| `order_purchase_timestamp` | timestamp | Date d'achat — début du parcours |
| `order_approved_at` | timestamp | Validation du paiement |
| `order_delivered_carrier_date` | timestamp | Remise au transporteur |
| `order_delivered_customer_date` | timestamp | Livraison effective |
| `order_estimated_delivery_date` | timestamp | **Date promise au client** |

> Les 5 dates sont conservées bien que redondantes avec les écarts calculés : `mart` doit être autosuffisant. Elles servent d'axe chronologique en restitution, de borne pour RG-10, et permettent de recalculer n'importe quoi sans revenir à `intermediate`.

### Le retard

| Champ | Type | Signification | Règle |
|---|---|---|---|
| `gap` | entier | Écart en jours : livraison réelle − date promise. **Positif = retard** | Calculé en `::DATE` : la promesse porte sur une date, pas un horaire |
| `is_late` | booléen | Vrai si `gap > 0` | Seuil strict : livré le jour exact = promesse **tenue** |
| `timing` | texte | Tranche de gravité, 6 modalités | M-14 |

**Modalités de `timing`** — bornes issues de la distribution observée, non de chiffres ronds :

| Modalité | Écart | Volume | Part |
|---|---|---|---|
| Too early | ≤ −4 j | 83 878 | 87,0 % |
| At time | −3 à 0 j | 6 035 | 6,3 % |
| Barely late | 1 à 7 j | 3 672 | 3,8 % |
| Late | 8 à 15 j | 1 637 | 1,7 % |
| Too late | 16 à 30 j | 880 | 0,9 % |
| Very late | ≥ 31 j | 345 | 0,4 % |

> **87 % des commandes arrivent avec 4 jours d'avance ou plus**, avec un pic à −14 jours. Olist annonce des délais très conservateurs — c'est la marge mesurée par M-16 et le gisement des scénarios O7.

### Les segments du parcours (O2)

| Champ | Type | De → à | Responsable |
|---|---|---|---|
| `gap_validation` | entier | achat → approbation | Système de paiement |
| `gap_preparation` | entier | approbation → transporteur | **Le vendeur** |
| `gap_shipping` | entier | transporteur → livraison | **Le transporteur** |

> ⚠️ **`gap_preparation` est NULL sur 689 commandes** — décomposition vérifiée en recette :
> - 674 : remise au transporteur antérieure à l'approbation (RG-04)
> - 14 : `order_approved_at` manquante
> - 1 : `order_delivered_carrier_date` manquante
>
> Ces commandes **restent au périmètre** : seul ce segment est neutralisé. Une absence honnête vaut mieux qu'une durée négative, qui contaminerait la médiane par segment (M-03).

### Variables temporelles (O6)

| Champ | Type | Signification |
|---|---|---|
| `purchase_year` | entier | Année d'achat — sert à RG-10 et à écarter les mois incomplets |
| `purchase_month` | entier | Mois (1-12) — saisonnalité, pics de volume |
| `purchase_dow` | entier | Jour de la semaine, **0 = dimanche à 6 = samedi** — rythme opérationnel |

> Ces trois variables sont connues **au moment de la commande** : c'est le critère d'éligibilité au modèle prédictif.

### Composition et montants

| Champ | Type | Signification | Usage |
|---|---|---|---|
| `nb_items` | entier | Nombre d'articles | `COUNT(*)` des lignes, jamais `SUM(order_item_id)` — c'est un numéro d'ordre, pas une quantité |
| `nb_sellers` | entier | Nombre de vendeurs distincts | Filtre RG-09 : `= 1` pour l'analyse au grain vendeur |
| `total_price` | décimal | Somme des prix articles | Décomposition du CA |
| `total_freight` | décimal | Somme des frais de port | Part du transport dans le CA exposé |
| `payment_total` | décimal | **Encaissement réel du client** | **Montant de référence (RG-11)** |

> **Pourquoi `payment_total` et non `total_price + total_freight`** : le chiffre d'affaires est l'argent qui entre, pas la valeur théorique du panier.
> Concordance vérifiée entre les deux sources : 299 écarts sur 96 447 (0,31 %), maximum **0,02 R$** — des arrondis. H9 revalidé.
>
> **CA total du périmètre : 15 416 546 R$**

### Satisfaction (O3)

| Champ | Type | Signification | Règle |
|---|---|---|---|
| `avg_score` | entier | Note de 1 à 5 | RG-06 : moyenne des avis **tronquée** (`FLOOR`) |
| `nb_reviews` | entier | Nombre d'avis reçus | Permet de retrouver les 547 commandes multi-avis |
| `is_unsatisfied` | booléen | Vrai si `avg_score ≤ 2` | RG-05 |

> **Troncature plutôt qu'arrondi** : choix conservateur assumé. Sur un projet dont l'objet est d'identifier des ruptures de promesse, mieux vaut surestimer légèrement l'insatisfaction que la manquer.
>
> ⚠️ **646 commandes ont `avg_score` NULL** (RG-07) : elles n'ont aucun avis. Exclusion ciblée des analyses de satisfaction, pas du périmètre.
>
> Note moyenne du périmètre : **4,16 / 5** — élevée malgré 6,77 % de retards, ce qui rend O3 d'autant plus pertinent.

### Distance (O6)

| Champ | Type | Signification |
|---|---|---|
| `distance_km` | décimal | Distance vendeur → client, formule de Haversine |

**Distribution** : médiane 434 km · moyenne 601 km · maximum 8 678 km

> **Calculée en Python**, pas en SQL : la Terre est une sphère, une distance euclidienne sur lat/lng déforme — un degré de longitude rétrécit avec la latitude, et le Brésil s'étend sur ~39 degrés.
>
> **Commandes multi-vendeurs** : la distance retenue est la **plus longue**. Le dataset ne fournit qu'une date de livraison par commande, qui correspond vraisemblablement au dernier colis arrivé.
> *Limite assumée : les expéditions séparées ne sont pas distinguables dans les données.*
>
> ⚠️ **476 commandes ont `distance_km` NULL** : code postal absent de `geolocation`. Exclusion ciblée.

---

## `mart.sellers` — Les vendeurs

**Grain** : une ligne = un vendeur retenu
**Volume** : 1 323 lignes
**Source** : `mart.orders` jointe à `staging.order_items` et `staging.sellers`

| Champ | Type | Signification |
|---|---|---|
| `seller_id` | texte | Identifiant du vendeur (anonymisé à la source) |
| `seller_state` | texte | État brésilien |
| `nb_orders` | entier | Nombre de commandes mono-vendeur livrées |
| `total_revenue` | décimal | CA généré |
| `late_rate` | décimal | **Taux de retard**, entre 0 et 1 |
| `avg_gap` | décimal | Écart moyen à la promesse |
| `avg_preparation_days` | décimal | Délai de préparation moyen — **son** segment |
| `avg_score` | décimal | Note moyenne reçue |

### Les deux filtres

| Règle | Clause | Ce qu'elle filtre |
|---|---|---|
| **RG-09** | `WHERE nb_sellers = 1` | Des **commandes** — les multi-vendeurs (1,3 %) sont écartées : le retard ne peut être imputé à un vendeur identifié |
| **RG-08** | `HAVING COUNT(*) >= 10` | Des **vendeurs** — un vendeur à 2 commandes dont 1 en retard afficherait 50 %, ce qui ne signifie rien |

> Le `WHERE` ne peut pas faire le travail du `HAVING` : au moment où il s'applique, le comptage par vendeur n'existe pas encore.

### Impact du seuil RG-08 — mesuré avant décision

| | Retenu | Total | Part |
|---|---|---|---|
| Vendeurs | 1 323 | 2 948 | **44,9 %** |
| Commandes | 101 382 | 107 087 | **94,7 %** |

> On écarte 55 % des vendeurs mais seulement 5,3 % de l'activité. Le bruit statistique part, le phénomène reste.
>
> *2 948 vendeurs et non 3 095 : l'écart correspond aux vendeurs n'apparaissant que dans des commandes multi-vendeurs ou hors périmètre.*

---

## Ce qui n'est pas dans `mart`

Deux besoins imposent de redescendre en `staging` :

| Besoin | Table | Pourquoi |
|---|---|---|
| Analyse par catégorie (O4) | `staging.products` + `staging.category_translation` | `product_category_name` est au grain **produit**. Une commande peut mêler plusieurs catégories — une règle d'attribution reste à définir (produit le plus cher ? le plus fréquent ?) |
| Détail article par article | `staging.order_items` | Grain plus fin que la commande |

> ⚠️ 1 392 commandes du périmètre (1,44 %) portent un produit **sans catégorie**. Prévoir une modalité « non renseigné » plutôt que de les faire disparaître : ce sont des commandes réelles avec un montant réel.
