# Fiche syntaxe & concepts — SQL / PostgreSQL

Tout ce qui a servi sur le projet Olist, avec la logique derrière.
Pour réviser, et pour les entretiens.

---

## 1. L'ordre des clauses

**Immuable.** Une clause au mauvais endroit = erreur de syntaxe.

```sql
SELECT      -- quoi afficher
FROM        -- quelle table
JOIN        -- quelles tables rattacher
WHERE       -- filtrer des LIGNES (avant regroupement)
GROUP BY    -- regrouper
HAVING      -- filtrer des GROUPES (après regroupement)
ORDER BY    -- trier
LIMIT       -- tronquer
```

**Ordre d'exécution réel** (différent de l'ordre d'écriture) :
`FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY`

C'est ce qui explique deux règles qui surprennent :
- un alias défini dans `SELECT` n'est **pas** utilisable dans `WHERE` ni dans le `CASE` du même bloc
- `HAVING` peut utiliser `COUNT(*)`, `WHERE` non

---

## 2. WHERE vs HAVING

| | Filtre | Quand |
|---|---|---|
| `WHERE` | des **lignes** | avant l'agrégation |
| `HAVING` | des **groupes** | après l'agrégation |

```sql
WHERE nb_sellers = 1        -- RG-09 : écarte des COMMANDES
GROUP BY seller_id
HAVING COUNT(*) >= 10       -- RG-08 : écarte des VENDEURS
```

Les deux coexistent sans se substituer : au moment du `WHERE`, le comptage par vendeur n'existe pas encore.

---

## 3. GROUP BY — la règle qui piège

**Toute colonne du `SELECT` doit être soit agrégée, soit dans le `GROUP BY`.**

```
ERROR: column "x" must appear in the GROUP BY clause
       or be used in an aggregate function
```

PostgreSQL n'infère rien. Même si tu sais qu'un vendeur n'a qu'un seul état, il faut l'écrire :

```sql
GROUP BY seller_id, seller_state
```

**Le piège inverse** : ajouter une colonne au `GROUP BY` pour faire taire l'erreur **change le grain de sortie**. Grouper par `(order_id, review_id)` au lieu de `order_id` produit une ligne par avis, pas par commande — l'objectif est cassé.

> Le `GROUP BY` définit le grain. Ne jamais l'élargir pour contourner une erreur.

---

## 4. Clé composite

Deux colonnes qui, **ensemble**, identifient une ligne — alors qu'aucune ne le fait seule.

```sql
-- order_id seul n'est pas unique (commande multi-articles)
-- order_item_id seul non plus (chaque commande a un n°1)
-- le COUPLE, oui
SELECT order_id, order_item_id, COUNT(*)
FROM raw.order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;
```

**Analogie** : dans une classe, deux élèves peuvent avoir le même prénom (normal), pas le même numéro sur la liste d'appel (anormal).

---

## 5. Détecter les doublons

```sql
SELECT cle, COUNT(*)
FROM table
GROUP BY cle
HAVING COUNT(*) > 1;
```

**Zéro ligne = aucun doublon.** Sur un contrôle d'anomalie, un résultat vide est une bonne nouvelle.

> ⚠️ Un zéro se vérifie : il peut signifier « aucune anomalie » ou « ma requête est cassée ». Test rapide : relancer avec `>= 1` — si des milliers de lignes sortent, la requête fonctionne.

---

## 6. Les orphelins — LEFT JOIN + IS NULL

**Le pattern le plus utile de tout SQL.** Trouver ce qui n'existe pas.

```sql
SELECT COUNT(*)
FROM table_a AS a
LEFT JOIN table_b AS b ON a.cle = b.cle
WHERE b.cle IS NULL;
```

**Logique** : `LEFT JOIN` garde toutes les lignes de A. Sans correspondance dans B, les colonnes de B sont remplies de `NULL`. Le `WHERE` isole exactement ces cas.

**Pourquoi c'est vital** : un `INNER JOIN` fait disparaître les orphelins **silencieusement**. Pas d'erreur, pas d'avertissement — juste des lignes en moins.

> Toujours tester la **clé de jointure**, pas une autre colonne : c'est elle qui prouve l'absence de correspondance.

---

## 7. INNER vs LEFT — la règle de la chaîne

Quand une table porte le périmètre, **tous** les JOIN doivent être `LEFT`. Un seul `INNER` en fin de chaîne annule l'effet de tous les précédents.

*Vécu sur le projet : 476 commandes perdues (95 971 au lieu de 96 447) à cause d'`INNER JOIN` vers `geolocation`.*

---

## 8. Valeur manquante ≠ ligne absente

Deux problèmes distincts, deux détections différentes :

| Cas | Détection |
|---|---|
| Une **valeur** vide dans une ligne existante | `WHERE colonne IS NULL` |
| Une **ligne** entièrement absente | `LEFT JOIN ... WHERE cle IS NULL` |

*Exemple : 0 `review_score` NULL dans `order_reviews`, mais **646 commandes** sans aucun avis. Le second cas est invisible depuis la table des avis.*

---

## 9. NULL — le comportement à connaître

**Toute comparaison avec `NULL` renvoie `NULL`** — ni vrai, ni faux. Un `WHERE` écarte donc silencieusement ces lignes.

```sql
-- Écarterait aussi les lignes où carrier_date est NULL
WHERE customer_date >= carrier_date

-- Les conserve explicitement
WHERE (carrier_date IS NULL OR customer_date >= carrier_date)
```

*Sans cette précaution : 25 exclusions au lieu de 23.*

**Autres effets** :
- `NULL × valeur = NULL` (utile : un volume sans dimension reste inconnu)
- `COUNT(*)` compte les lignes, `COUNT(colonne)` **ignore les NULL**

---

## 10. NULLIF — corriger une valeur fausse

```sql
NULLIF(valeur, 0)   -- renvoie NULL si valeur = 0, sinon valeur
```

**L'usage** : quand une valeur plausible code en réalité une absence.

*Les 4 produits à `product_weight_g = 0` ne pèsent pas zéro gramme — le zéro code une saisie manquante. Sans `NULLIF`, ils tireraient toute moyenne vers le bas et fourniraient une information fausse au modèle.*

> Principe : **on corrige ce qui est faux, on ne comble pas ce qui manque.**

---

## 11. CAST — conversion de type

Deux écritures équivalentes :

```sql
CAST(colonne AS INT)   -- standard SQL, portable
colonne::INT           -- raccourci PostgreSQL
```

**Conversions utilisées** : `::INT`, `::NUMERIC`, `::TIMESTAMP`, `::DATE`

**Deux usages différents du même CAST** :
- dans un `SELECT` → un **test** : si une valeur n'est pas convertible, la requête plante. Une exécution sans erreur vaut validation de toute la colonne
- dans un `CREATE TABLE` → une **transformation** : la nouvelle colonne naît avec le bon type

> ⚠️ Un identifiant ou un code postal reste en **TEXT**, même s'il ne contient que des chiffres. `'09790'::INT` donne `9790` — le zéro initial disparaît et la jointure casse.
> **Test** : additionner deux de ces valeurs a-t-il un sens ? Non → c'est du texte.

---

## 12. Dates — TIMESTAMP vs DATE

| Type | Contenu |
|---|---|
| `DATE` | `2017-12-05` |
| `TIMESTAMP` | `2017-12-05 14:37:22` |

**Soustraire deux `TIMESTAMP`** renvoie un `INTERVAL` : `-8 days -04:37:12`. Inexploitable pour des tranches ou une médiane.

**Soustraire deux `DATE`** renvoie un **entier** — un nombre de jours.

```sql
date_a::DATE - date_b::DATE   -- entier propre
```

*Choix du projet : la promesse porte sur une date, pas un horaire. Livré le jour promis à 23h = 0 jour de retard.*

---

## 13. EXTRACT

```sql
EXTRACT(YEAR  FROM colonne)   -- 2017
EXTRACT(MONTH FROM colonne)   -- 1 à 12
EXTRACT(DOW   FROM colonne)   -- 0 = dimanche à 6 = samedi
EXTRACT(HOUR  FROM colonne)   -- 0 à 23
```

> Ne fonctionne **que** sur un type date/timestamp. C'est le typage de la couche `staging` qui rend ces fonctions disponibles.

---

## 14. Booléens — le raccourci le plus rentable

**Une comparaison EST un booléen.** Pas besoin de `CASE WHEN` :

```sql
(gap > 0) AS is_late              -- true / false
```

**Et surtout** :

```sql
AVG(is_late::INT) AS late_rate    -- true→1, false→0 → la moyenne EST le taux
```

*Un vendeur avec 3 retards sur 10 : (1+1+1+0+0+0+0+0+0+0)/10 = 0,3.*

> C'est pour ça qu'on conçoit `is_late` en booléen plutôt qu'en libellé texte : un libellé imposerait de compter puis diviser.

---

## 15. CASE WHEN

```sql
CASE
    WHEN condition1 THEN 'valeur1'
    WHEN condition2 THEN 'valeur2'
    ELSE 'defaut'
END AS nom_colonne
```

**Trois pièges** :
- pas de virgule entre les `WHEN`
- **s'arrête à la première condition vraie** → l'ordre compte
- **sans `ELSE`, une condition fausse renvoie `NULL`** — cause classique d'une colonne entièrement vide

**Couvrir tous les cas** : si une modalité manque, ces lignes tombent en `NULL` et sortent de toutes les analyses par groupe.

*Sur le projet : les commandes à l'heure ont leur propre modalité — sans elle, le groupe de référence disparaissait.*

---

## 16. CTE — `WITH ... AS`

```sql
WITH base AS (
    SELECT col_a - col_b AS gap
    FROM table
)
SELECT
    gap,
    CASE WHEN gap > 7 THEN 'Late' ELSE 'OK' END AS timing
FROM base;
```

**Le problème résolu** : un alias du `SELECT` n'est pas réutilisable dans le même bloc. Sans CTE, il faudrait réécrire le calcul complet à chaque `WHEN`.

**CTE vs sous-requête** : même mécanisme, la CTE est déclarée **avant** avec un nom. Plus lisible dès qu'on enchaîne plusieurs transformations.

**CTE vs table** : la CTE est **temporaire**, elle disparaît à la fin de la requête. `CREATE TABLE` crée un objet **permanent**.

`base.*` reprend toutes les colonnes de la CTE sans les relister.

---

## 17. Créer une table depuis une requête

```sql
CREATE TABLE schema.nom AS
SELECT ...
FROM ...;
```

La table naît **remplie**, et ses types sont déduits du `SELECT` : écrire `price::NUMERIC` fait naître une colonne `NUMERIC`.

**Rendre un script rejouable** :

```sql
DROP TABLE IF EXISTS schema.nom;
```

> Toujours reconstruire plutôt que corriger par `ALTER` ou `DELETE`. Un script qui ne se rejoue pas d'un bloc n'est pas reproductible.
>
> ⚠️ Un `ALTER` fait à la main doit **toujours** être reporté dans le script. Sinon : base juste, script faux — le bug se révèle des semaines plus tard.

---

## 18. Compter sous condition — FILTER

```sql
SELECT
    COUNT(*) FILTER (WHERE colonne IS NULL) AS manquants,
    COUNT(*)                                AS total
FROM table;
```

Plusieurs comptages conditionnels en **une seule** requête. Syntaxe PostgreSQL ; l'équivalent portable est `SUM(CASE WHEN ... THEN 1 ELSE 0 END)`.

---

## 19. UNION ALL

Empile les résultats de plusieurs requêtes. Chacune doit renvoyer le **même nombre de colonnes**, du même type.

```sql
SELECT 'orders' AS nom, COUNT(*) FROM staging.orders
UNION ALL
SELECT 'items',         COUNT(*) FROM staging.order_items;
```

---

## 20. Fonctions utiles

| Fonction | Effet |
|---|---|
| `FLOOR(x)` | Entier inférieur — 3,9 → 3 |
| `ROUND(x, n)` | Arrondi à n décimales |
| `ABS(x)` | Valeur absolue — utile pour comparer deux montants |
| `COUNT(DISTINCT x)` | Valeurs distinctes |
| `NULLIF(a, b)` | `NULL` si `a = b` |
| `AVG` `SUM` `MIN` `MAX` | Agrégations |

> `FLOOR` vs `ROUND` n'est pas un détail technique : c'est une décision métier. Sur le projet, `FLOOR` a été retenu par principe de prudence — mieux vaut surestimer l'insatisfaction que la manquer.

---

# Concepts — pour les entretiens

## Le grain

**La question la plus importante à se poser sur une table** : que représente une ligne ?

Une jointure entre deux tables de grains différents **duplique** silencieusement. Aucune erreur SQL, juste des totaux faux.

*Exemple vécu : `geolocation` a 1 000 163 lignes pour ~19 000 codes postaux. Une jointure directe multiplierait chaque commande par le nombre de points de sa zone.*

**La méthode** : ramener chaque table au grain voulu **avant** toute jointure, puis vérifier avec le test de doublons.

## L'architecture en couches

`raw → staging → intermediate → mart`, où chaque couche ne lit que la précédente.

**Ce que ça apporte** :
- traçabilité : remonter d'une valeur finale à la donnée source
- rejouabilité : reconstruire une couche sans tout refaire
- séparation : `raw` copie, `staging` type, `intermediate` applique les règles, `mart` sert l'analyse

## Le filtre de périmètre

Ce qui transforme une **statistique** en **règle de gestion**.

*2 965 commandes sans date de livraison, tous statuts → descriptif, sans intérêt (ce sont les annulées).*
*8 commandes sans date de livraison **parmi les livrées** → une anomalie, et une règle d'exclusion.*

Le même comptage, deux significations. Le filtre fait toute la différence.

## Le journal d'exclusions

Tracer, règle par règle, combien de lignes sont retirées et combien il reste.

Sans lui, impossible de répondre à « pourquoi 96 447 et pas 96 478 ? ».

**Corollaire** : toujours **compter avant d'exclure**. Une fois le filtre appliqué, le volume retiré n'est plus mesurable.

## Exclusion générale vs exclusion ciblée

Toute anomalie ne justifie pas de retirer une ligne du périmètre.

| Type | Exemple | Traitement |
|---|---|---|
| **Générale** | Pas de date de livraison → retard incalculable | Ligne exclue |
| **Ciblée** | Pas d'avis → satisfaction inconnue | Ligne conservée, une seule analyse fermée |

*Le niveau d'exigence dépend de l'**usage**, pas de la colonne. Une même colonne peut être indispensable à une métrique et facultative pour une autre.*

## Corriger vs combler

- Une valeur **fausse** (poids à 0 g) → corriger en `NULL`
- Une valeur **absente** (date manquante) → laisser absente

> Une absence honnête vaut mieux qu'une valeur fausse. La seconde contamine les moyennes et trompe le modèle ; la première est visible et gérable.

## La recette

Prouver que les tables sont justes **avant** de fonder une analyse dessus.

Cinq questions : périmètre conforme ? grain respecté ? valeurs manquantes expliquées ? valeurs plausibles ? chiffres cohérents avec la phase précédente ?

*Sur le projet, la recette a **corrigé** un chiffre : RG-04 concerne 674 commandes sur le périmètre, pas 1 350 — ce dernier était calculé tous statuts confondus.*

## La reproductibilité

Le test : détruire tous les schémas et tout reconstruire depuis les fichiers sources. Si les chiffres sont identiques, le pipeline est reproductible.

C'est ce qui distingue un travail de données d'une suite de manipulations.

---

# Python — ce qui a servi

## Connexion pandas ↔ PostgreSQL

```python
from sqlalchemy import create_engine
engine = create_engine(
    f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{database}"
)
```

`create_engine` **ne se connecte pas** — il prépare. La connexion réelle a lieu au premier appel (`read_sql`). Un « connexion OK » affiché juste après ne prouve rien.

## Lire et écrire

```python
df = pd.read_sql(requete, engine)          # SQL → DataFrame

df.to_sql("nom", engine, schema="intermediate",
          if_exists="replace", index=False)  # DataFrame → SQL
```

`if_exists="replace"` rend le script rejouable.

## Charger des CSV — COPY

```python
cur.copy_expert(
    f"COPY {table} FROM STDIN WITH (FORMAT csv, HEADER true)", f
)
```

Le `COPY` natif PostgreSQL, piloté depuis Python. Bien plus rapide que `to_sql` sur de gros volumes.

> ⚠️ `COPY` associe les colonnes **par position**, jamais par nom. Une inversion dans le `CREATE TABLE` se charge sans erreur et place les données au mauvais endroit.
>
> ⚠️ `HEADER true` est obligatoire, sinon la ligne d'en-tête est chargée comme une donnée.
>
> ⚠️ `connexion.commit()` est indispensable avec psycopg2. Sans lui, tout est annulé à la fermeture — le script affiche les bons comptes et la base reste vide.

## Boucle sur un dictionnaire

```python
for fichier, table in fichiers.items():
    ...
```

Écrire une fois, exécuter N fois. À chaque tour, `fichier` prend la clé et `table` la valeur.

## Calcul vectorisé — numpy

```python
df["distance_km"] = haversine(
    df["customer_lat"], df["customer_lng"],
    df["seller_lat"],   df["seller_lng"]
)
```

La formule s'applique aux 97 607 lignes **d'un coup**, sans boucle. C'est la force de numpy.

## GROUP BY de pandas

```python
df.groupby("order_id")["distance_km"].max().reset_index()
```

`reset_index()` remet la clé de regroupement en colonne normale.

## Haversine — et pourquoi pas Euclide

```python
def haversine(lat1, lon1, lat2, lon2):
    R = 6371  # rayon terrestre en km
    lat1, lon1, lat2, lon2 = map(np.radians, [lat1, lon1, lat2, lon2])
    dlat, dlon = lat2 - lat1, lon2 - lon1
    a = np.sin(dlat/2)**2 + np.cos(lat1) * np.cos(lat2) * np.sin(dlon/2)**2
    return 2 * R * np.arcsin(np.sqrt(a))
```

**La logique** : la Terre est une sphère. Un degré de latitude vaut toujours ~111 km, mais un degré de **longitude rétrécit** à mesure qu'on s'éloigne de l'équateur.

Traiter lat/lng comme des coordonnées planes revient à mesurer une distance sur une carte dépliée — ça déforme. Sur le Brésil, qui s'étend sur ~39 degrés de latitude, l'erreur est significative.

Haversine calcule la distance **sur la sphère**, le long de la surface.

## Sécurité — le .env

```python
from dotenv import load_dotenv
load_dotenv()
password = os.getenv("DB_PASSWORD")
```

Jamais d'identifiants en dur dans un fichier versionné. Le `.env` va dans `.gitignore` ; un `.env.example` versionné montre les clés attendues sans les valeurs.

> `load_dotenv()` cherche le fichier dans le **dossier de travail courant**, pas à côté du script.

---

# Réflexes de débogage

**Lire la vraie erreur.** Si un outil masque le message (encodage, wrapper), tester la même opération directement — `psql` en ligne de commande a diagnostiqué en 10 secondes ce que Python cachait depuis 20 minutes.

**Un zéro se vérifie.** Il peut signifier « aucune anomalie » ou « requête cassée ».

**Ce qui « existe visiblement » mais reste introuvable = caractère invisible.** Espace, casse, encodage. *Vécu : une base nommée `Olist ` avec un espace final — listée par `\l`, mais introuvable par `psql -d Olist`.*
> Pour rendre visible : `SELECT '[' || colonne || ']'`, ou `LENGTH()`.

**Vérifier que le fichier exécuté est bien le bon.** Un script sauvegardé nulle part, ou un fichier temporaire généré par l'IDE, fait débuguer un fantôme.

**La documentation ne remplace pas la donnée.** Le dictionnaire annonçait 547 commandes multi-avis ; il ne mentionnait pas que 789 `review_id` sont dupliqués. Ce sont les contrôles qui l'ont révélé.
