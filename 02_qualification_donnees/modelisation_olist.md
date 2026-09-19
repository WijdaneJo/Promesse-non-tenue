# Modélisation — La Promesse Non Tenue

Trois vues complémentaires du même système :

- le **MCD** décrit *ce qui existe* (les objets métier et leurs liens) ;
- le **MLD** décrit *comment c'est stocké* (les tables et leurs clés) ;
- le **BPMN** décrit *comment ça se déroule* (le parcours d'une commande, et où naissent les retards).

> Les diagrammes sont écrits en Mermaid : GitHub les affiche directement.
> ⚠️ Noms de colonnes à vérifier sur les tables `staging` avant publication.

---

## 1. MCD — Modèle Conceptuel de Données

Périmètre : commandes livrées (RG-01).

![MCD en notation Merise](MCD_olist.png)

*Version image ci-dessus ; version Mermaid ci-dessous.*

```mermaid
flowchart LR
    CLIENT["<b>CLIENT</b><br/>customer_unique_id<br/>ville<br/>état"]
    COMMANDE["<b>COMMANDE</b><br/>order_id<br/>statut<br/>date d'achat<br/>date de validation<br/>date de remise au transporteur<br/>date de livraison<br/>date promise"]
    LIGNE["<b>LIGNE_COMMANDE</b><br/>n° de ligne<br/>prix<br/>frais de port<br/>date limite d'expédition"]
    PRODUIT["<b>PRODUIT</b><br/>product_id<br/>poids<br/>dimensions<br/>nombre de photos"]
    CATEGORIE["<b>CATÉGORIE</b><br/>nom portugais<br/>nom anglais"]
    VENDEUR["<b>VENDEUR</b><br/>seller_id<br/>ville<br/>état"]
    PAIEMENT["<b>PAIEMENT</b><br/>n° de séquence<br/>type<br/>nombre d'échéances<br/>montant"]
    AVIS["<b>AVIS</b><br/>review_id<br/>note<br/>commentaire<br/>date de création"]
    ZONE["<b>ZONE_GÉO</b><br/>préfixe de code postal<br/>latitude moyenne<br/>longitude moyenne"]

    PASSER(["passer"])
    CONTENIR(["contenir"])
    CONCERNER(["concerner"])
    VENDRE(["vendre"])
    APPARTENIR(["appartenir"])
    REGLER(["régler"])
    RECEVOIR(["recevoir"])
    LOC_C(["localiser"])
    LOC_V(["localiser"])

    CLIENT ---|"1,n"| PASSER
    PASSER ---|"1,1"| COMMANDE
    COMMANDE ---|"1,n"| CONTENIR
    CONTENIR ---|"1,1"| LIGNE
    LIGNE ---|"1,1"| CONCERNER
    CONCERNER ---|"1,n"| PRODUIT
    LIGNE ---|"1,1"| VENDRE
    VENDRE ---|"1,n"| VENDEUR
    PRODUIT ---|"0,1"| APPARTENIR
    APPARTENIR ---|"0,n"| CATEGORIE
    COMMANDE ---|"0,n"| REGLER
    REGLER ---|"1,1"| PAIEMENT
    COMMANDE ---|"0,n"| RECEVOIR
    RECEVOIR ---|"1,n"| AVIS
    CLIENT ---|"0,1"| LOC_C
    LOC_C ---|"0,n"| ZONE
    VENDEUR ---|"0,1"| LOC_V
    LOC_V ---|"0,n"| ZONE
```

### Ce que traduisent les cardinalités

Chaque cardinalité s'appuie sur un fait vérifié dans les données.

| Association | Cardinalités | Fait observé |
|---|---|---|
| CLIENT – passer – COMMANDE | 1,n / 1,1 | Une personne peut commander plusieurs fois ; une commande n'a qu'un client |
| COMMANDE – contenir – LIGNE | 1,n / 1,1 | Toute commande livrée contient au moins un article |
| LIGNE – concerner – PRODUIT | 1,1 / 1,n | Un produit peut être vendu plusieurs fois |
| LIGNE – vendre – VENDEUR | 1,1 / 1,n | Une commande peut mêler plusieurs vendeurs (`nb_sellers`, RG-09) |
| PRODUIT – appartenir – CATÉGORIE | 0,1 / 0,n | 1 392 commandes portent un produit sans catégorie |
| COMMANDE – régler – PAIEMENT | 0,n / 1,1 | Paiement fractionnable ; 1 commande n'a aucune ligne de paiement |
| COMMANDE – recevoir – AVIS | 0,n / 1,n | 646 commandes sans avis, 547 avec plusieurs ; un même `review_id` peut couvrir plusieurs commandes *(à vérifier)* |
| CLIENT / VENDEUR – localiser – ZONE_GÉO | 0,1 / 0,n | Certains codes postaux sont absents de `geolocation` → 476 distances incalculables |

### Deux choix de modélisation

**LIGNE_COMMANDE est une entité, pas une association.** Une association ternaire COMMANDE–PRODUIT–VENDEUR serait identifiée par le trio (commande, produit, vendeur). Or un même produit d'un même vendeur peut apparaître sur plusieurs lignes d'une commande : c'est ainsi que le dataset représente la quantité. Il faut donc un identifiant propre, le numéro de ligne. C'est aussi pourquoi `nb_items` se calcule avec `COUNT(*)` et non `SUM(order_item_id)`.

**CLIENT est identifié par `customer_unique_id`.** Dans les données, `customer_id` change à chaque commande : c'est un identifiant technique, pas une personne. Le MCD modélise la réalité métier (une personne passe plusieurs commandes) ; le MLD, lui, garde la structure physique du dataset.

---

## 2. MLD — Modèle Logique de Données

### Notation relationnelle

Clé primaire <u>soulignée</u>, clé étrangère précédée de `#`.

- **customers** (<u>customer_id</u>, customer_unique_id, #customer_zip_code_prefix, customer_city, customer_state)
- **orders** (<u>order_id</u>, #customer_id, order_status, order_purchase_timestamp, order_approved_at, order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date)
- **order_items** (<u>#order_id, order_item_id</u>, #product_id, #seller_id, shipping_limit_date, price, freight_value)
- **products** (<u>product_id</u>, #product_category_name, product_weight_g, product_length_cm, product_height_cm, product_width_cm, product_photos_qty)
- **category_translation** (<u>product_category_name</u>, product_category_name_english)
- **sellers** (<u>seller_id</u>, #seller_zip_code_prefix, seller_city, seller_state)
- **order_payments** (<u>#order_id, payment_sequential</u>, payment_type, payment_installments, payment_value)
- **order_reviews** (<u>review_id, #order_id</u>, review_score, review_comment_title, review_comment_message, review_creation_date, review_answer_timestamp)
- **geolocation_pref** (<u>geolocation_zip_code_prefix</u>, avg_lat, avg_lng)

### Schéma

```mermaid
erDiagram
    CUSTOMERS ||--|| ORDERS : "passe"
    ORDERS ||--|{ ORDER_ITEMS : "contient"
    PRODUCTS ||--|{ ORDER_ITEMS : "concerne"
    SELLERS ||--|{ ORDER_ITEMS : "vend"
    CATEGORY_TRANSLATION |o--o{ PRODUCTS : "classe"
    ORDERS ||--o{ ORDER_PAYMENTS : "reglee par"
    ORDERS ||--o{ ORDER_REVIEWS : "recoit"
    GEOLOCATION_PREF |o--o{ CUSTOMERS : "localise"
    GEOLOCATION_PREF |o--o{ SELLERS : "localise"

    CUSTOMERS {
        text customer_id PK
        text customer_unique_id
        int customer_zip_code_prefix FK
        text customer_city
        text customer_state
    }
    ORDERS {
        text order_id PK
        text customer_id FK
        text order_status
        timestamp order_purchase_timestamp
        timestamp order_approved_at
        timestamp order_delivered_carrier_date
        timestamp order_delivered_customer_date
        timestamp order_estimated_delivery_date
    }
    ORDER_ITEMS {
        text order_id PK, FK
        int order_item_id PK
        text product_id FK
        text seller_id FK
        timestamp shipping_limit_date
        numeric price
        numeric freight_value
    }
    PRODUCTS {
        text product_id PK
        text product_category_name FK
        int product_weight_g
        int product_length_cm
        int product_height_cm
        int product_width_cm
        int product_photos_qty
    }
    CATEGORY_TRANSLATION {
        text product_category_name PK
        text product_category_name_english
    }
    SELLERS {
        text seller_id PK
        int seller_zip_code_prefix FK
        text seller_city
        text seller_state
    }
    ORDER_PAYMENTS {
        text order_id PK, FK
        int payment_sequential PK
        text payment_type
        int payment_installments
        numeric payment_value
    }
    ORDER_REVIEWS {
        text review_id PK
        text order_id PK, FK
        int review_score
        text review_comment_title
        text review_comment_message
        timestamp review_creation_date
        timestamp review_answer_timestamp
    }
    GEOLOCATION_PREF {
        int geolocation_zip_code_prefix PK
        numeric avg_lat
        numeric avg_lng
    }
```

### Passage du MCD au MLD

- Chaque **entité** devient une table ; son identifiant devient la clé primaire.
- Une association **1,n – 1,1** disparaît : la clé du côté « n » migre en clé étrangère du côté « 1,1 » (ex. `order_id` dans `order_items`).
- **Écart assumé avec le MCD** : la table `customers` est au grain `customer_id` (une ligne par commande), d'où la relation 1–1 avec `orders`. Pour suivre un client dans le temps, il faut passer par `customer_unique_id`.
- **Les clés étrangères vers `geolocation_pref` ne sont pas contraintes** : des codes postaux clients et vendeurs n'y figurent pas. D'où les jointures en `LEFT JOIN` dans tout le pipeline.
- `geolocation_pref` est une table construite (couche `intermediate`) : la table brute `geolocation` contient plusieurs coordonnées par préfixe, agrégées ici en moyenne.

---

## 3. BPMN — Processus actuel (AS-IS)

Le parcours d'une commande, avec les durées observées par segment (O2).

```mermaid
flowchart LR
    subgraph CL["Client"]
        A0(("Début"))
        A1["Passer la commande<br/>(date promise affichée)"]
        A7["Recevoir le colis"]
        A8["Donner un avis"]
        A9((("Fin")))
    end
    subgraph PF["Plateforme Olist"]
        B1["Valider le paiement"]
    end
    subgraph VD["Vendeur"]
        C1["Préparer la commande"]
        C2{"Remise avant la date<br/>limite d'expédition ?"}
        C3["Remettre au transporteur"]
    end
    subgraph TR["Transporteur"]
        D1["Acheminer le colis"]
        D2{"Livré au plus tard<br/>à la date promise ?"}
    end

    A0 --> A1 --> B1 --> C1 --> C2
    C2 -->|"Oui"| C3
    C2 -->|"Non : risque de retard x4"| C3
    C3 --> D1 --> D2
    D2 -->|"Oui : promesse tenue"| A7
    D2 -->|"Non : promesse non tenue"| A7
    A7 --> A8 --> A9

    N1["Validation<br/>à l'heure 0 j / en retard 0 j"]:::note
    N2["Préparation<br/>à l'heure 2 j / en retard 3 j"]:::note
    N3["Acheminement<br/>à l'heure 7 j / en retard 26 j<br/>≈ 95 % de l'écart"]:::retard
    N4["Insatisfaction<br/>12,34 % → 19,76 %<br/>de 0 à 1 jour de retard"]:::note

    B1 -.- N1
    C1 -.- N2
    D1 -.- N3
    A8 -.- N4

    classDef note fill:#f5f5f5,stroke:#999999,stroke-dasharray:3 3
    classDef retard fill:#fde2e2,stroke:#c0392b,stroke-width:2px
```

**Lecture.** Le retard naît presque entièrement chez le **transporteur** : l'acheminement passe de 7 à 26 jours entre une commande à l'heure et une commande en retard. Le vendeur ajoute un jour. Le seul signal précoce observable est le dépassement de la date limite d'expédition, mais il n'est connu qu'au moment de la remise.

---

## 4. BPMN — Processus cible proposé (TO-BE)

Deux points de détection : à la **commande** (modèle O6) et à l'**expédition** (date limite dépassée).

```mermaid
flowchart LR
    subgraph CL["Client"]
        A0(("Début"))
        A1["Passer la commande"]
        A7["Recevoir le colis"]
        A9((("Fin")))
    end
    subgraph PF["Plateforme Olist"]
        P1["Calculer le score de risque<br/>(modèle O6)"]
        G1{"Niveau de risque ?"}
        P2["Surveillance renforcée<br/>+ information du client"]
        P3["Suivi + information<br/>du client"]
        P4["Parcours standard"]
        M1{"x"}
        B1["Valider le paiement"]
        P6["Alerter et relancer<br/>le vendeur"]
    end
    subgraph VD["Vendeur"]
        C1["Préparer la commande"]
        C2{"Date limite<br/>d'expédition dépassée ?"}
        C3["Remettre au transporteur"]
    end
    subgraph TR["Transporteur"]
        D1["Acheminer le colis"]
    end

    A0 --> A1 --> P1 --> G1
    G1 -->|"Top 1 %"| P2
    G1 -->|"Top 10 %"| P3
    G1 -->|"Autres"| P4
    P2 --> M1
    P3 --> M1
    P4 --> M1
    M1 --> B1 --> C1 --> C2
    C2 -->|"Non"| C3
    C2 -->|"Oui"| P6 --> C3
    C3 --> D1 --> A7 --> A9

    N1["Détection à la commande<br/>top 1 % : retard x5 vs moyenne<br/>mais 82 % de fausses alertes"]:::note
    N2["Détection à l'expédition<br/>risque de retard x4"]:::note
    G1 -.- N1
    C2 -.- N2

    classDef note fill:#f5f5f5,stroke:#999999,stroke-dasharray:3 3
```

**Lecture.** À la commande, le modèle ne justifie que des actions **peu coûteuses** (surveillance, information du client) : même dans le top 1 %, 82 % des alertes sont fausses. Le second point de contrôle, à l'expédition, porte un signal plus fort, mais plus tardif.

**Limites.** Les paliers (top 1 %, top 10 %) sont des propositions : le coût réel des actions n'est pas disponible dans les données. Le modèle a été évalué sur juin-août 2018 uniquement.
