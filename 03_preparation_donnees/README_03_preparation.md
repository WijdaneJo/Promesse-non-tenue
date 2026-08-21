# 03 — Préparation des données

Construction des tables analytiques à partir des CSV bruts Olist.
**PostgreSQL 17** pour les transformations, **Python** pour l'orchestration et le calcul de distance.

---

## Le livrable

| Table | Grain | Volume |
|---|---|---|
| `mart.orders` | une commande | **96 447** |
| `mart.sellers` | un vendeur | **1 323** |

Toute l'analyse (O1 à O8) se fonde sur ces deux tables.
Leur dictionnaire complet : `03_dictionnaire_mart.md`.

---

## L'architecture en couches

Quatre schémas, où **chaque couche ne lit que la précédente** :

| Schéma | Contenu | Règle |
|---|---|---|
| `raw` | Les 9 CSV chargés tels quels, **tout en TEXT** | Jamais modifié après chargement |
| `staging` | Données typées et nettoyées, 1 table = 1 source | Ne lit que `raw` |
| `intermediate` | Grains corrigés, périmètre appliqué | Ne lit que `staging` |
| `mart` | Tables analytiques finales | Ne lit que `intermediate` |

**Pourquoi `raw` en TEXT intégral** : si une valeur est malformée, le chargement
passe quand même et l'anomalie se découvre par requête, pas par un plantage
d'import. Le typage se fait au passage vers `staging`, sous contrôle.

**Pourquoi des couches** : quand un chiffre final paraît faux, on remonte couche
par couche pour trouver où il s'est cassé. Avec un schéma unique et des tables
écrasées au fil de l'eau, il n'y a rien à remonter.

---

## Ordre d'exécution

Le pipeline est **hybride** SQL / Python. L'ordre n'est pas négociable :

| # | Fichier | Produit |
|---|---|---|
| 1 | `SQL/01_raw/01_create_tables_raw.sql` | Structure des 9 tables |
| 2 | `PYTHON/chargement.py` | Chargement des CSV (`COPY`) |
| 3 | `SQL/02_staging/01_create_tables_staging.sql` | Couche typée |
| 4 | `SQL/03_intermediate/01_intermediate.sql` | Grains corrigés + périmètre |
| 5 | `PYTHON/distances.py` | `intermediate.distances` (Haversine) |
| 6 | `SQL/04_mart/02_mart_orders.sql` | Table commandes |
| 7 | `SQL/04_mart/03_mart_sellers.sql` | Table vendeurs |
| 8 | `SQL/99_controles/02_recette.sql` | Validation |

**Reproductibilité vérifiée** : les 4 schémas ont été détruits
(`99_controles/03_preuve_de_rejeu.sql`) et intégralement reconstruits depuis les
CSV bruts. Les chiffres obtenus sont identiques.

---

## Arborescence

```
03_preparation_donnees/
├── SQL/
│   ├── 01_raw/
│   │   └── 01_create_tables_raw.sql
│   ├── 02_staging/
│   │   └── 01_create_tables_staging.sql
│   ├── 03_intermediate/
│   │   ├── 01_intermediate.sql
│   │   └── 02_coordonnees_export.sql      (lu par distances.py)
│   ├── 04_mart/
│   │   ├── 01_variables.sql               (exploration, ne crée rien)
│   │   ├── 02_mart_orders.sql
│   │   └── 03_mart_sellers.sql
│   └── 99_controles/
│       ├── 01_controles_integrite.sql     (blocs A, B, C, D)
│       ├── 02_recette.sql
│       └── 03_preuve_de_rejeu.sql
├── PYTHON/
│   ├── chargement.py
│   ├── distances.py
│   ├── .env                               (non versionné)
│   └── .env.example
├── 03_dictionnaire_mart.md
├── decisions.md
└── README.md
```

**Un fichier = un livrable.** Les fichiers de construction créent des tables,
les fichiers de contrôle vérifient. Le numéro indique l'ordre d'exécution.

---

## Journal d'exclusions

```
Commandes au statut « delivered »                    96 478
RG-01 : sans date de livraison réelle                    −8
                                                   ─────────
                                                     96 470
RG-03 : chronologie impossible                          −23
                                                   ─────────
PÉRIMÈTRE D'ANALYSE                                  96 447
```

**Exclusions ciblées** — ces commandes restent au périmètre, seule une analyse
leur est fermée :

| Règle | Volume | Analyse fermée |
|---|---|---|
| RG-04 | 674 | Segment « préparation » |
| RG-06 | 547 | — *(avis fusionnés, aucune perte)* |
| RG-07 | 646 | Analyses de satisfaction |
| — | 476 | Analyses de distance |

---

## Les décisions structurantes

Les 27 décisions du projet sont consignées dans `decisions.md`, avec leur
justification et leur impact chiffré. Les principales :

**Identifiants et codes postaux restent en TEXT.** Un code postal converti en
`INT` perdrait son zéro initial (`'09790'` → 9790) et casserait la jointure vers
`geolocation` — or São Paulo, première région du dataset, est entièrement en
`0xxxx`.

**Les 4 tables au mauvais grain sont agrégées avant toute jointure.**
`order_items`, `order_payments`, `order_reviews` et `geolocation` ont plus d'une
ligne par commande. Le cas le plus dangereux : `geolocation`, **1 000 163 lignes
pour ~19 000 codes postaux** — une jointure directe aurait multiplié chaque
commande par le nombre de points relevés dans sa zone.

**Les valeurs fausses deviennent NULL, les valeurs absentes restent absentes.**
Les 4 poids produit à `0 g` ne pèsent pas zéro gramme — le zéro code une saisie
manquante. À l'inverse, les 8 commandes sans date de livraison ne sont pas
« corrigées » : elles sortent du périmètre.

**`payment_total` comme montant de référence.** Le chiffre d'affaires est
l'encaissement réel, pas la valeur théorique du panier. Concordance avec
`order_items` vérifiée : écart maximum 0,02 R$.

**Retard en jours calendaires.** La promesse porte sur une date, pas un horaire.
Livré le jour promis à 23 h = 0 jour de retard.

**Distance calculée en Python (Haversine).** La Terre est une sphère : une
distance euclidienne sur lat/lng déforme, et le Brésil s'étend sur ~39 degrés de
latitude.

---

## Résultats de recette

| Contrôle | Résultat |
|---|---|
| Périmètre | 96 447 ✅ |
| Grain (doublons) | 0 ✅ |
| Valeurs manquantes | toutes rattachées à une exclusion documentée ✅ |
| Plausibilité | aucune valeur aberrante ✅ |
| Cohérence avec la qualification | taux de retard 6,77 % ✅ |
| Rejeu complet du pipeline | chiffres identiques ✅ |

**Correction apportée par la recette** : RG-04 concerne **674** commandes sur le
périmètre d'analyse, et non 1 350 comme annoncé en qualification — ce chiffre
était calculé tous statuts confondus. La note de cadrage et le fichier de règles
ont été mis à jour.

---

## Premiers chiffres

Produits par la préparation, ils servent d'ancrage à l'analyse :

| Indicateur | Valeur |
|---|---|
| Taux de commandes en retard (M-00) | **6,77 %** — 6 534 sur 96 447 |
| CA total du périmètre | **15 416 546 R$** |
| Note moyenne | 4,16 / 5 |
| Distance médiane vendeur → client | 434 km |
| Commandes livrées avec ≥ 4 j d'avance | **87 %** |
| Concentration géographique | **42 %** des commandes sur un seul état |

> Une commande sur quinze rompt la promesse. Mais 6,77 % des commandes ne
> signifie pas 6,77 % du CA : si les retards touchent des commandes plus chères,
> l'exposition financière est supérieure. C'est l'objet de O4.

> **La concentration géographique impose de décliner par état.** Une moyenne
> nationale sera dominée par São Paulo. Si cet état a de bons délais — proximité
> des vendeurs — le taux global de 6,77 % masquera des situations bien pires
> ailleurs.

---

## Reste à faire

- [ ] Environnement virtuel + `requirements.txt`
- [ ] Rattacher `product_category_name` à `mart.orders` — règle d'attribution à
      définir pour les commandes multi-catégories. 1 392 commandes (1,44 %)
      portent un produit sans catégorie : prévoir une modalité « non renseigné »
- [ ] Vérifier l'absence de volumes produit à 0 (même piège que les poids)
- [ ] Externaliser le chemin du dossier CSV dans le `.env`
