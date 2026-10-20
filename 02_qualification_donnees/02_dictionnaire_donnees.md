# Dictionnaire des données : Olist

Description des tables et champs utilisés dans le projet.

---

## customers : Les clients

**Grain** : une ligne = un client *par commande* (et non une personne unique)
**Volume** : 99 441 lignes / 96 096 personnes distinctes
**Rôle dans le projet** : rattacher chaque commande à sa localisation

| Champ | Type | Signification | Utilisé pour |
|---|---|---|---|
| `customer_id` | texte | Identifiant technique, propre à chaque commande | Clé de jointure vers `orders` |
| `customer_unique_id` | texte | **Identifiant réel de la personne** : stable dans le temps | Mesure du réachat (H1) |
| `customer_zip_code_prefix` | texte | Préfixe du code postal (5 chiffres) | Jointure vers `geolocation` : calcul de distance |
| `customer_city` | texte | Ville du client | Non retenu : trop de modalités |
| `customer_state` | texte | État (27 modalités : SP, RJ, MG…) | **Maille d'analyse géographique** |

> **Piège majeur.** `customer_id` change à chaque commande : une même personne
> qui commande trois fois apparaît avec trois `customer_id` différents. Seul
> `customer_unique_id` identifie une personne. Toute analyse de récurrence doit
> s'appuyer sur ce second champ.

---

## geolocation : Les coordonnées géographiques

**Grain** : une ligne = un point de localisation associé à un préfixe de code postal
**Volume** : environ 1 000 000 lignes pour ~19 000 préfixes distincts
**Rôle dans le projet** : calcul de la distance vendeur -> client (variable prédictive)

| Champ | Type | Signification | Utilisé pour |
|---|---|---|---|
| `geolocation_zip_code_prefix` | texte | Préfixe du code postal (5 chiffres) | Clé de jointure vers `customers` et `sellers` |
| `geolocation_lat` | décimal | Latitude | Calcul de distance |
| `geolocation_lng` | décimal | Longitude | Calcul de distance |
| `geolocation_city` | texte | Ville | Non retenu : redondant |
| `geolocation_state` | texte | État | Non retenu : déjà présent dans `customers` |

> **Table à ne jamais joindre telle quelle.** Un même préfixe de code postal
> apparaît des dizaines de fois, avec des coordonnées légèrement différentes
> (plusieurs points relevés dans la même zone). Une jointure directe
> multiplierait chaque commande par le nombre de points correspondants et
> fausserait tous les totaux.
>
> **Traitement requis** : agréger d'abord par préfixe (moyenne des latitudes et
> longitudes) pour obtenir une ligne unique par code postal, puis joindre.

---

## order_items : Les articles commandés

**Grain** : une ligne = un article dans une commande
**Volume** : environ 112 650 lignes pour 98 666 commandes distinctes
**Rôle dans le projet** : montant des commandes, rattachement au vendeur et au produit

| Champ | Type | Signification | Utilisé pour |
|---|---|---|---|
| `order_id` | texte | Identifiant de la commande | Clé de jointure vers `orders` |
| `order_item_id` | entier | Numéro de l'article dans la commande (1, 2, 3…) | Comptage des articles |
| `product_id` | texte | Identifiant du produit | Jointure vers `products` : analyse par catégorie |
| `seller_id` | texte | Identifiant du vendeur | **Attribution du retard au vendeur** |
| `shipping_limit_date` | date | Date limite d'expédition imposée au vendeur | **Engagement vendeur : à explorer** |
| `price` | décimal | Prix de l'article | Montant de la commande |
| `freight_value` | décimal | Frais de port de l'article | Montant de la commande |

> **Grain différent de `orders`.** Une commande peut contenir plusieurs
> articles : cette table a donc plus de lignes qu'`orders`. Toute jointure doit
> être précédée d'une agrégation par `order_id`, sinon les commandes sont
> dupliquées.

---

## order_payments : Les paiements

**Grain** : une ligne = un moyen de paiement utilisé pour une commande
**Volume** : environ 103 886 lignes pour 99 440 commandes distinctes
**Rôle dans le projet** : vérification du montant des commandes

| Champ | Type | Signification | Utilisé pour |
|---|---|---|---|
| `order_id` | texte | Identifiant de la commande | Clé de jointure vers `orders` |
| `payment_sequential` | entier | Numéro du moyen de paiement (1, 2, 3…) | Détection des paiements multiples |
| `payment_type` | texte | Type : carte de crédit, boleto, voucher, carte de débit | Analyse descriptive : non retenu |
| `payment_installments` | entier | Nombre de mensualités | Non retenu |
| `payment_value` | décimal | Montant payé par ce moyen de paiement | **Contrôle de cohérence du montant (H9)** |

> **Une commande peut avoir plusieurs lignes de paiement.** Un client peut
> régler avec une carte plus un bon d'achat, ou fractionner son règlement. Le
> montant total d'une commande est donc la **somme** de ses `payment_value`, pas
> la valeur d'une ligne.
>
> Ce champ a servi de contre-mesure au montant calculé depuis `order_items`
> (H9 : concordance vérifiée à 99,75 %).

---

## order_reviews : Les avis clients

**Grain** : une ligne = un avis
**Volume** : 99 224 lignes pour 98 673 commandes distinctes
**Rôle dans le projet** : mesurer la conséquence du retard sur la satisfaction

| Champ | Type | Signification | Utilisé pour |
|---|---|---|---|
| `review_id` | texte | Identifiant de l'avis | Clé technique |
| `order_id` | texte | Commande évaluée | Clé de jointure vers `orders` |
| `review_score` | entier | **Note de 1 à 5** | Variable de résultat centrale |
| `review_comment_title` | texte | Titre du commentaire (souvent vide) | Extension NLP : hors v1 |
| `review_comment_message` | texte | Commentaire libre, en portugais | Extension NLP : hors v1 |
| `review_creation_date` | date | **Date d'envoi de l'enquête au client** | Analyse du moment de l'évaluation |
| `review_answer_timestamp` | date | Date de réponse du client | Délai de réponse |

> **Environ 550 commandes ont plusieurs avis** (99 224 lignes pour 98 673
> commandes). Une règle de sélection doit être définie avant toute jointure :
> premier avis, dernier avis, ou moyenne des notes.

---

## orders : Les commandes

**Grain** : une ligne = une commande
**Volume** : 99 441 lignes, dont 96 478 au statut `delivered`
**Rôle dans le projet** : **table de faits centrale**, porte la promesse et sa réalisation

| Champ | Type | Signification | Utilisé pour |
|---|---|---|---|
| `order_id` | texte | Identifiant unique de la commande | Clé primaire : jointures vers toutes les tables |
| `customer_id` | texte | Identifiant client propre à cette commande | Jointure vers `customers` |
| `order_status` | texte | État : delivered, shipped, canceled, unavailable… | Filtrage du périmètre |
| `order_purchase_timestamp` | date | Date d'achat | Point de départ du parcours |
| `order_approved_at` | date | Validation du paiement | Fin du segment « validation » |
| `order_delivered_carrier_date` | date | Remise du colis au transporteur | **Frontière de responsabilité vendeur / transporteur** |
| `order_delivered_customer_date` | date | Livraison effective au client | Fin du parcours : calcul du retard |
| `order_estimated_delivery_date` | date | **Date promise au client à la commande** | Référence de la promesse |

> **Les quatre dates réelles structurent le projet.** Elles permettent de
> découper le parcours en trois segments et d'identifier où naît le retard :
>
> | Segment | Bornes | Responsable |
> |---|---|---|
> | Validation | achat -> approbation | Système de paiement |
> | Préparation | approbation -> remise transporteur | **Le vendeur** |
> | Acheminement | remise transporteur -> livraison | **Le transporteur** |

> **Anomalies chronologiques identifiées (H7)** : 1 350 commandes présentent
> une remise au transporteur antérieure à l'approbation du paiement (expédition
> avant validation), et 23 une livraison antérieure à la remise au transporteur
> (impossible : erreur de saisie). Règles de gestion à définir.

> **Dates à convertir avant tout calcul.** Les colonnes sont chargées comme
> du texte par `read_csv`. Sans `pd.to_datetime()`, aucune soustraction ni
> comparaison n'est fiable.

---

## products : Les produits

**Grain** : une ligne = un produit
**Volume** : environ 32 950 lignes
**Rôle dans le projet** : caractériser les produits, catégorie et encombrement

| Champ | Type | Signification | Utilisé pour |
|---|---|---|---|
| `product_id` | texte | Identifiant du produit | Clé de jointure vers `order_items` |
| `product_category_name` | texte | Catégorie, **en portugais** | Analyse par catégorie : à traduire |
| `product_name_lenght` | entier | Nombre de caractères du nom | Non retenu |
| `product_description_lenght` | entier | Nombre de caractères de la description | Non retenu |
| `product_photos_qty` | entier | Nombre de photos | Non retenu |
| `product_weight_g` | entier | **Poids en grammes** | Variable prédictive du délai |
| `product_length_cm` | entier | Longueur | Calcul du volume |
| `product_height_cm` | entier | Hauteur | Calcul du volume |
| `product_width_cm` | entier | Largeur | Calcul du volume |

> **Traduction des catégories.** Les noms sont en portugais. La table
> `product_category_name_translation` fournit la correspondance vers l'anglais
> et doit être jointe pour la restitution.

> **Poids et dimensions : variables prédictives.** Un produit lourd ou
> encombrant est plus complexe à expédier et plus susceptible de générer un
> retard. Le volume se calcule en multipliant les trois dimensions.

---

## sellers : Les vendeurs

**Grain** : une ligne = un vendeur
**Volume** : 3 095 vendeurs
**Rôle dans le projet** : localiser le vendeur, origine de l'expédition

| Champ | Type | Signification | Utilisé pour |
|---|---|---|---|
| `seller_id` | texte | Identifiant du vendeur (anonymisé) | Clé de jointure vers `order_items` |
| `seller_zip_code_prefix` | texte | Préfixe du code postal | Jointure vers `geolocation` : **calcul de la distance vendeur -> client** |
| `seller_city` | texte | Ville du vendeur | Non retenu : trop de modalités |
| `seller_state` | texte | État du vendeur | Analyse de la concentration géographique de l'offre |

> **Identifiants anonymisés.** Les noms de vendeurs et partenaires ont été
> remplacés avant publication du jeu de données (maisons de *Game of Thrones*).
> Aucune donnée directement identifiante n'est manipulée.

> **Le champ clé du projet : `seller_zip_code_prefix`.** Croisé avec celui du
> client, il permet de calculer la distance parcourue par le colis : variable
> probablement déterminante du délai d'acheminement, et indispensable pour
> comparer les transporteurs à distance équivalente.

---

## product_category_name_translation : Traduction des catégories

**Grain** : une ligne = une catégorie de produit
**Volume** : environ 71 catégories
**Rôle dans le projet** : rendre les catégories lisibles dans la restitution

| Champ | Type | Signification | Utilisé pour |
|---|---|---|---|
| `product_category_name` | texte | Nom de la catégorie en portugais | Clé de jointure vers `products` |
| `product_category_name_english` | texte | Nom de la catégorie en anglais | Libellé affiché dans le dashboard |

> **Table de référence.** Elle ne contient aucune donnée mesurable : sa seule
> fonction est de traduire un code en libellé lisible. C'est une table de
> correspondance, à joindre en fin de préparation.

> **Deux catégories sans traduction** (73 dans `products`, 71 traduites).
> Une jointure `left` laissera ces valeurs vides : conserver le nom portugais
> par défaut.