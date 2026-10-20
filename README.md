# La Promesse Non Tenue
### Où naissent les retards de livraison, combien ils exposent, et comment les anticiper

Projet data de bout en bout sur 96 447 commandes réelles de la marketplace
brésilienne Olist : du cadrage du besoin jusqu'aux recommandations chiffrées, en
passant par la qualification des données, un pipeline SQL, l'analyse, un modèle
prédictif et un dashboard Power BI.

![Page de synthèse du dashboard](05_dashboard/captures/01_synthese.png)

---

## En bref

**Le problème.** Sur une marketplace, la date de livraison annoncée est une
promesse commerciale. La plateforme la formule, mais ne la maîtrise qu'en
partie : l'exécution dépend du vendeur, de la distance et du transporteur. En
mars 2018, le taux de retard d'Olist passe de moins de 5 % à 18,96 %, et la note
de satisfaction tombe à 3,81, son plus bas niveau.

**La problématique.**

> Où naissent les ruptures de délai sur une marketplace, quel volume d'activité
> exposent-elles, et peut-on les anticiper au moment de la commande ?

**Les réponses.**

| Question | Réponse |
|---|---|
| Où naît le retard ? | Dans le **transport** : 19 des 20 jours d'écart entre une commande à l'heure et une commande en retard viennent de l'acheminement |
| Combien expose-t-il ? | **1,15 M R$**, soit 7,47 % du chiffre d'affaires, dont 48 % sur São Paulo et Rio de Janeiro |
| Le client tolère-t-il un retard ? | Non : dès 3 jours de retard, un client sur deux est mécontent, et livrer en avance n'améliore pas la note |
| Peut-on l'anticiper ? | En partie : le modèle détecte deux fois plus de retards qu'une règle simple, mais 83 % de ses alertes restent fausses au mieux |
| Quel levier Olist contrôle-t-elle ? | **Sa promesse** : retrancher un jour coûte 1 292 retards, quand gagner un jour de transport n'en récupère que 825 |

---

## Le dashboard

Six pages, chacune destinée à une direction et portant un message dans son titre.

| Page | Message | Direction |
|---|---|---|
| Synthèse | Une commande sur quinze rompt la promesse faite au client | Direction générale |
| Où agir | Le retard naît du transport, et se concentre sur quelques états | Logistique |
| Client | Le client ne tolère aucun retard, et l'avance ne rapporte rien | Relation client |
| Les leviers | Retrancher un jour de promesse coûte plus que gagner un jour de transport ne rapporte | Logistique et marketing |
| Anticiper | Le modèle détecte deux fois plus de retards qu'une règle par état, mais se trompe encore neuf fois sur dix | Relation client |
| Vendeurs | Le taux de retard ne désigne pas les vendeurs à suivre, la date limite d'expédition oui | Partenariats vendeurs |

La page « Les leviers » contient un simulateur : deux curseurs chiffrent en
direct l'effet d'un resserrement de la promesse et celui d'une accélération du
transport.

![Page Les leviers](05_dashboard/captures/04_les_leviers.png)

Toutes les pages : [`05_dashboard/olist_dashboard.pdf`](05_dashboard/olist_dashboard.pdf) ·
captures dans [`05_dashboard/captures`](05_dashboard/captures).

---

## Les recommandations

| # | Recommandation | Direction | Gain mesuré | Effort |
|---|---|---|---|---|
| R1 | Ne resserrer la promesse qu'à hauteur des jours gagnés sur le transport | Marketing | 1 292 retards évités par jour non retranché | Faible |
| R2 | Corriger en profondeur l'acheminement vers Rio de Janeiro | Logistique | 251 556 R$ exposés, dont 58 % de retards graves | Élevé |
| R3 | Gagner quelques jours d'acheminement dans les autres grands états | Logistique | 134 882 R$ au premier jour, puis environ 82 000 R$ par jour | Moyen |
| R4 | Piloter les vendeurs sur la date limite d'expédition, alerte à 20 % | Partenariats | Risque de retard divisé par 4, départs de vendeurs anticipés | Faible |
| R5 | Anticiper le Black Friday | Logistique, marketing | Pic daté et récurrent (12,40 % de retard en novembre 2017) | Moyen |
| R6 | Alerter à la commande, pour des actions peu coûteuses seulement | Relation client | Au top 1 %, risque de retard près de cinq fois supérieur à la moyenne | Faible |

Détail, priorisation et limites : [`06_conclusions_recommandations`](06_conclusions_recommandations/README.md).

---

## Ce que les données ont changé

Le cadrage a été révisé trois fois, à chaque fois parce que les données le
contredisaient.

**La qualification a invalidé l'objectif central.** Le projet devait mesurer
l'effet du retard sur la fidélité client. Le taux de réachat s'est révélé être de
**3,12 %** : aucune trajectoire client n'est observable. Le chiffrage a donc
porté sur une **exposition mesurée** (le chiffre d'affaires concerné par une
promesse rompue) plutôt que sur une perte future estimée, et le mécanisme de
destruction de valeur a été étudié au niveau du vendeur.

**La qualification a ouvert une question non prévue.** 91,88 % des commandes
arrivent en avance, avec une marge médiane de 13 jours : Olist ne promet pas
serré, elle promet large. D'où une septième sous-question sur le calibrage de la
promesse, qui a produit le résultat le plus actionnable du projet.

**La préparation a corrigé la qualification.**

| Élément | Annoncé | Vérifié sur le périmètre final |
|---|---|---|
| Périmètre d'analyse | 96 470 | **96 447** |
| Commandes expédiées avant validation | 1 350 | **674** |
| Vendeurs analysables | 1 323 | **1 217** |

Les premiers chiffres avaient été mesurés tous statuts confondus. Un chiffre se
mesure sur le périmètre où il sera utilisé.

**L'analyse a corrigé l'analyse.** La marge de la promesse paraissait stable à
13 jours en 2017 comme en 2018. Mesurée mois par mois, elle tombe de 20 jours en
juin 2018 à 7 jours en août : la médiane annuelle masquait le changement de
politique de l'été.

---

## Démarche

| Dossier | Étape | Livrable |
|---|---|---|
| [`01_cadrage_besoin`](01_cadrage_besoin) | Cadrage et règles de gestion | Note de cadrage (v1 à v3.2), 11 règles de gestion, 19 métriques |
| [`02_qualification_donnees`](02_qualification_donnees) | Qualification | 9 hypothèses testées, dictionnaire de données, rapport |
| [`03_preparation_donnees`](03_preparation_donnees) | Préparation | Pipeline SQL et Python reproductible, tables `mart.orders` (96 447) et `mart.sellers` (1 217) |
| [`04_analyse_prediction`](04_analyse_prediction) | Analyse et modélisation | 8 objectifs, un fichier de constats chacun, modèle prédictif |
| [`05_dashboard`](05_dashboard) | Restitution | Dashboard Power BI de 6 pages, export PDF |
| [`06_conclusions_recommandations`](06_conclusions_recommandations) | Synthèse | 6 recommandations chiffrées et priorisées |

Chaque fichier de constats suit la même structure : le fait, ce qu'il signifie,
ce qu'il implique.

---

## Le pipeline de préparation

Architecture en quatre couches, où chaque couche ne lit que la précédente :

```
CSV bruts  ->  raw  ->  staging  ->  intermediate  ->  mart
```

| Couche | Rôle |
|---|---|
| `raw` | Copie fidèle des 9 CSV, tout en texte, jamais modifiée |
| `staging` | Données typées et nettoyées |
| `intermediate` | Grains corrigés, périmètre appliqué |
| `mart` | Tables analytiques finales |

**Reproductibilité vérifiée** : les quatre schémas ont été détruits puis
reconstruits depuis les CSV bruts, avec des chiffres identiques.

**Trois pièges de grain neutralisés**, dont la table de géolocalisation :
1 000 163 lignes pour environ 19 000 codes postaux. Une jointure directe aurait
multiplié chaque commande par le nombre de points relevés dans sa zone.

---

## Méthode

Quelques réflexes appliqués tout au long du projet :

- **Pas de calcul sans règle de gestion.** Chaque indicateur est défini, justifié
  et relié à une décision avant d'être calculé.
- **Toujours le volume à côté du taux.** São Paulo a le plus de retards en
  volume et l'un des meilleurs taux.
- **Vérifier ce qui pourrait invalider un résultat.** Santa Catarina semblait
  avoir des vendeurs défaillants : c'était un effet du transport. Les articles de
  Noël semblaient très exposés : c'était un petit effectif.
- **Tester ce que l'analyse ne voit pas.** Parmi les seuls vendeurs survivants,
  le retard n'avait aucun effet ; en intégrant les vendeurs disparus, le lien
  apparaît.
- **Évaluer un modèle comme il sera utilisé.** Le découpage dans le temps a
  révélé que le modèle devenait obsolète dès que la politique de promesse
  changeait.

---

## Données

**Brazilian E-Commerce Public Dataset by Olist**, disponible sur Kaggle.

- 9 tables relationnelles, environ 100 000 commandes réelles (2016-2018),
  anonymisées à la source
- Périmètre d'analyse : 96 447 commandes livrées, 27 états, 1 217 vendeurs
  analysables
- Les fichiers bruts ne sont pas versionnés : ils sont à télécharger sur Kaggle
  et à placer dans `02_qualification_donnees/dataset/`

**Cadre du projet.** Projet personnel. La « direction » d'Olist est un
commanditaire fictif, utilisé pour cadrer la démarche comme une mission réelle.
Tous les chiffres cités sont issus des données.

---

## Reproduire le projet

1. Télécharger le jeu de données Olist sur Kaggle et le placer dans
   `02_qualification_donnees/dataset/`.
2. Créer une base PostgreSQL, puis copier `03_preparation_donnees/PYTHON/env.example`
   en `.env` et y renseigner les paramètres de connexion.
3. Exécuter dans l'ordre :
   1. `03_preparation_donnees/SQL/01_raw/01_create_tables_raw.sql`
   2. `03_preparation_donnees/PYTHON/chargement.py`
   3. `03_preparation_donnees/SQL/02_staging/01_create_tables_staging.sql`
   4. `03_preparation_donnees/SQL/03_intermediate/01_intermediate.sql`
   5. `03_preparation_donnees/PYTHON/distances.py`
   6. les scripts de `03_preparation_donnees/SQL/04_mart/`, dans l'ordre de leur numéro
   7. `03_preparation_donnees/SQL/99_controles/02_recette.sql`
4. Les requêtes d'analyse se trouvent dans `04_analyse_prediction/SQL/`, le
   modèle dans `04_analyse_prediction/PYTHON/O6_modele_predictif.ipynb`.

---

## Stack technique

- **Base de données** : PostgreSQL 17, architecture en 4 schémas
- **SQL** : CTE, fonctions fenêtre, agrégats ordonnés, contrôles de recette
- **Python** : pandas, NumPy, SQLAlchemy, psycopg2, scikit-learn (régression
  logistique, forêt aléatoire)
- **Visualisation** : Power BI (DAX, paramètres de simulation, mise en forme
  conditionnelle)
- **Versioning** : Git et GitHub, livrables incrémentaux

---

## Limites

- Aucune donnée de coût logistique : les gains sont exprimés en chiffre
  d'affaires exposé, pas en profit.
- Identité des transporteurs absente : la cause précise de la lenteur vers Rio
  et de l'incident de mars 2018 reste à établir avec le métier.
- Réachat de 3,12 % : l'effet du retard sur la fidélité n'est pas mesurable.
- Fin des données en août 2018 : le resserrement de la promesse n'est observé
  que sur deux mois.
- Les résultats établissent des associations, pas des causalités démontrées.

---

## Auteur

**EL HARIRI Wijdane**
Élève ingénieure à l'INPT, filière Innovation et AMOA (Data et IA)
[LinkedIn](https://www.linkedin.com/in/wijdane-el-hariri-871a81343)
