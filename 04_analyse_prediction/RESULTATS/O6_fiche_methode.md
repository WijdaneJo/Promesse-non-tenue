# O6. Fiche méthode : comprendre le modèle et ses choix

Cette fiche explique **les notions** utilisées dans l'O6, **les choix** faits à chaque étape et **pourquoi**. Elle sert aussi de préparation d'entretien.

---

## 1. Le machine learning supervisé en quelques mots

**L'idée :** on montre à un algorithme des milliers d'exemples dont on connaît déjà la réponse (commande en retard ou non). Il cherche seul les combinaisons de variables qui annoncent la réponse. On lui soumet ensuite des exemples qu'il n'a jamais vus, et on mesure s'il devine juste.

| Terme | Signification | Dans l'O6 |
|---|---|---|
| **Variables** (*features*), notées **X** | Les indices qui servent à prédire | Distance, frais de port, état, délai promis… (36 variables) |
| **Cible** (*target*), notée **y** | La réponse à prédire | `is_late` |
| **Entraînement** (*train*) | Les exemples sur lesquels le modèle apprend | Commandes jusqu'à fin mai 2018 |
| **Test** | Les exemples qu'il n'a jamais vus, pour le juger | Commandes de juin à août 2018 |
| **`fit`** | Apprendre | `modele.fit(X_train_sc, y_train)` |
| **`predict` / `predict_proba`** | Prédire une classe / une probabilité | `modele.predict_proba(X_test_sc)` |
| **Surapprentissage** (*overfitting*) | Le modèle récite ses exemples au lieu d'apprendre une règle générale | Risque de la forêt aléatoire (Q6) |

**Pourquoi un test séparé ?** C'est comme un examen : si l'élève a déjà vu les questions en révisant, sa note ne prouve rien.

---

## 2. Les fuites de données (*data leakage*)

**Définition :** utiliser une information qui n'est pas disponible au moment de la décision. Le modèle paraît excellent à l'entraînement, puis s'effondre en situation réelle.

**Règle appliquée :** on se place à l'instant du clic « Acheter ». Une variable n'est utilisable que si sa valeur est déjà connue.

| Situation | Fuite ? | Décision |
|---|---|---|
| `gap`, dates de livraison, avis | Oui : connus après | Exclus |
| `order_approved_at` | Oui : arrive après le clic, parfois des jours après | Exclu |
| Date promise | Non : affichée au client avant validation | **Gardée** -> `promised_days` |
| `late_rate` du vendeur (`mart.sellers`) | Oui : contient la commande à prédire et le futur | Exclu (version correcte possible avec une fonction fenêtre) |
| Moyenne de standardisation calculée sur le test | Oui : information du futur | Calculée sur l'entraînement seulement |
| Liste d'états choisie avec les taux du test | Oui | Recalculée sur l'entraînement seulement |

**À retenir :** la fuite est l'erreur la plus grave en machine learning, car elle est **invisible** dans les scores.

---

## 3. La règle de référence (*baseline*)

**Définition :** une méthode simple, sans machine learning, que le modèle doit battre.

**Pourquoi :** un chiffre seul ne dit rien. Un modèle à 50 % de détection est-il bon ? On ne le sait qu'en le comparant à ce qu'on obtient sans lui.

**Dans l'O6 :** alerter toutes les commandes vers les états au-dessus du taux moyen de retard. Sur le test : 28,1 % de détection, 96,3 % de fausses alertes.

**Seuil choisi :** le taux moyen (7,53 % sur l'entraînement), car c'est le risque d'une commande prise au hasard. Un état au-dessus est « plus risqué que la normale ».

---

## 4. Le découpage entraînement / test

| Méthode | Principe | Avantage | Défaut |
|---|---|---|---|
| **Au hasard** | 20 % des commandes tirées au sort | Simple, tests aux mêmes conditions | Le modèle apprend avec des commandes « du futur » : score optimiste |
| **Dans le temps** | Apprendre sur le passé, tester sur le plus récent | Reproduit l'usage réel | Le test peut avoir un contexte différent |

**Choix :** découpage dans le temps, coupure au 1er juin 2018.

**Ce qu'il a révélé :** le changement de politique de promesse et l'inversion RJ / SP, que le découpage au hasard aurait masqués.

**Pour aller plus loin :** la **validation temporelle glissante** (`TimeSeriesSplit` dans scikit-learn) répète ce découpage sur plusieurs périodes successives, pour vérifier que le résultat ne dépend pas d'une seule coupure.

---

## 5. La préparation des données

### Les valeurs manquantes

La régression logistique refuse les cases vides. Deux options :

- **Exclure** les lignes : on perd des données.
- **Imputer** : remplacer la case vide par une valeur (médiane, moyenne…).

**Choix : exclusion** des 477 commandes (0,5 %). Vérification préalable : elles contiennent 44 retards seulement. L'imputation aurait inventé une distance qui n'existe pas.

**Réflexe à garder :** avant d'exclure, vérifier que les lignes exclues ne sont pas différentes du reste.

### Le one-hot encoding

**Problème :** un modèle ne calcule qu'avec des nombres. Numéroter les états (SP = 1, RJ = 2, AL = 3) créerait un ordre qui n'existe pas.

**Solution :** une colonne par modalité, qui vaut 1 (True) si la ligne a cette modalité.

| customer_state | state_RJ | state_SP | state_AL |
|---|---|---|---|
| RJ | 1 | 0 | 0 |
| SP | 0 | 1 | 0 |
| AC | 0 | 0 | 0 |

**`drop_first=True`** supprime une colonne (ici AC) : si toutes les autres valent 0, on sait que c'est elle. Conséquence : les poids des états se lisent **par rapport à AC**.

**Limite de l'O6 :** le mois a été laissé comme un nombre (1 à 12). Le modèle suppose donc un risque qui monte régulièrement de janvier à décembre, ce qui est faux (pics en février-mars et en novembre). Il aurait fallu l'encoder comme l'état.

### La standardisation

**Problème :** les variables ont des échelles très différentes (prix en milliers, états à 0 ou 1). La régression logistique apprend mal dans ces conditions.

**Solution :** transformer chaque variable pour qu'elle ait une moyenne de 0 et un écart-type de 1.

$$x_{standardisé} = \frac{x - \text{moyenne}}{\text{écart-type}}$$

Une valeur de 0 est dans la moyenne, une valeur de +2 est nettement au-dessus. L'unité disparaît.

| Méthode | Sur l'entraînement | Sur le test |
|---|---|---|
| `fit_transform` | Calcule moyenne et écart-type, puis transforme | Non |
| `transform` | | Réutilise les valeurs de l'entraînement |

**Bonus :** les poids du modèle deviennent comparables entre eux.

**Inutile pour les arbres** : ils posent des questions du type « supérieur à tel seuil ? », l'échelle ne change rien.

---

## 6. La régression logistique

### Le principe

Elle transforme les informations d'une commande en **probabilité de retard**, en deux étapes.

**Étape 1, un score :** chaque variable reçoit un poids, et on additionne.

$$z = b_0 + b_1 x_1 + b_2 x_2 + \dots + b_{36} x_{36}$$

- les **x** sont les variables de la commande ;
- les **b** sont les poids, ce que le modèle **apprend** ;
- $b_0$ est le point de départ (*intercept*) ;
- un poids positif fait monter le risque, un poids négatif le fait baisser.

**Étape 2, la probabilité :** le score passe dans la **fonction sigmoïde**, qui écrase n'importe quel nombre entre 0 et 1.

$$p = \frac{1}{1 + e^{-z}}$$

| Score z | Probabilité p |
|---|---|
| −5 | ≈ 0,01 |
| 0 | 0,5 |
| +5 | ≈ 0,99 |

**Exemple** (poids inventés) : $z = -3 + 0{,}02 \times \text{frais de port} + 1{,}2 \times (\text{état = RJ})$. Pour une commande vers RJ avec 25 R$ de frais : $z = -1{,}3$, donc $p \approx 0{,}21$.

**Entraîner**, c'est trouver les poids qui donnent des probabilités hautes aux commandes réellement en retard, et basses aux autres.

### Pourquoi l'avoir choisie

- **Simple** : un bon premier modèle, rapide à entraîner.
- **Lisible** : chaque poids s'interprète. On peut expliquer à un manager pourquoi une commande est jugée risquée.
- **Robuste** : dans l'O6, elle a battu la forêt aléatoire.
- **Elle extrapole** : face à une promesse plus courte que tout ce qu'elle a vu, elle prolonge la tendance.

### Ses limites

- Elle additionne les effets **séparément** : elle ne voit pas d'elle-même les combinaisons (« promesse courte **et** longue distance »).
- Elle suppose un effet régulier de chaque variable (d'où le problème du mois traité comme un nombre).

### Les réglages utilisés

| Réglage | Valeur | Signification |
|---|---|---|
| `class_weight` | `"balanced"` | Donne plus de poids aux retards (7,5 %), pour ne pas les ignorer |
| `max_iter` | 1000 | Nombre maximum d'essais pour trouver les poids (100 par défaut) |
| `C` | 1,0 (défaut) | Freine les poids pour limiter le surapprentissage. Plus C est petit, plus le frein est fort |
| `fit_intercept` | True (défaut) | Calcule $b_0$ |
| `solver` | `lbfgs` (défaut) | La méthode de calcul des poids |
| `tol` | 0,0001 (défaut) | La précision à atteindre avant de s'arrêter |

**Pourquoi `class_weight="balanced"` :** sans lui, le modèle pourrait prédire « pas de retard » presque partout et afficher 92,5 % de bonnes réponses, sans détecter un seul retard.

**Son effet secondaire :** les probabilités sont **gonflées**. Un seuil de 0,721 ne veut pas dire 72 % de risque (le vrai taux dans les alertes était de 6,7 %). On dit que les probabilités ne sont pas **calibrées**. Elles servent à **classer** les commandes, pas à lire un pourcentage.

---

## 7. Le seuil d'alerte

**`predict`** alerte automatiquement si la probabilité dépasse 0,5. Ce seuil n'a rien d'obligatoire.

**`predict_proba`** donne la probabilité brute : c'est à nous de choisir le seuil.

| Seuil | Alertes | Détection | Fiabilité des alertes |
|---|---|---|---|
| Bas | Nombreuses | Élevée | Faible |
| Haut | Rares | Faible | Meilleure |

**Deux usages du seuil dans l'O6 :**

1. **Comparer équitablement** : donner au modèle le même nombre d'alertes que la règle (5 065). Comme deux pêcheurs à qui on donne le même nombre de filets.
2. **Décider selon le métier** : le coût d'une fausse alerte dépend de l'action (e-mail au client, surveillance, changement de transporteur). D'où une procédure **en escalade** par paliers (top 1 %, top 10 %…).

**L'arbitrage est métier, pas technique.**

---

## 8. Les métriques

### La matrice de confusion

Chaque commande tombe dans une des quatre cases. Exemple à 5 065 alertes sur le test :

| | Réellement en retard | Réellement à l'heure |
|---|---|---|
| **Alertée** | ≈ 338 **vrais positifs** (VP) | ≈ 4 727 **faux positifs** (FP) |
| **Non alertée** | ≈ 327 **faux négatifs** (FN) | ≈ 13 133 **vrais négatifs** (VN) |

### Les formules

| Métrique | Formule | Dans l'O6 | scikit-learn |
|---|---|---|---|
| **Rappel** (*recall*) | VP ÷ (VP + FN) | **M-11** | `recall_score` |
| **Précision** | VP ÷ (VP + FP) | 1 − M-12 | `precision_score` |
| **Taux de fausses découvertes** | FP ÷ (VP + FP) | **M-12** | `1 - precision_score` |
| **Justesse** (*accuracy*) | (VP + VN) ÷ total | Écartée | `accuracy_score` |

**Piège de vocabulaire :** M-12 n'est **pas** le « taux de faux positifs » des statisticiens, qui vaut FP ÷ (FP + VN). Ce sont deux formules différentes.

**Piège de lecture :** M-11 seul ne veut rien dire. Un modèle qui alerte tout détecte 100 % des retards. Toujours regarder le nombre d'alertes à côté.

**Piège de comparaison :** M-12 dépend du taux de retard de l'échantillon. Plus il y a de retards, moins il y a mécaniquement de fausses alertes. Pour comparer deux tests différents, utiliser le **rapport au hasard** : taux de retard dans les alertes ÷ taux de retard global (on parle de *lift*).

---

## 9. La forêt aléatoire (*random forest*)

### Le principe

- Un **arbre de décision** pose une suite de questions oui / non (« promesse < 15 jours ? » -> « distance > 1 000 km ? »). Au bout du chemin, il donne un niveau de risque.
- Une **forêt** construit des centaines d'arbres, chacun sur un échantillon un peu différent, et fait la **moyenne** de leurs réponses. C'est plus stable qu'un arbre seul.

### Les réglages utilisés

| Réglage | Valeur | Signification |
|---|---|---|
| `n_estimators` | 200 | Nombre d'arbres |
| `min_samples_leaf` | 50 | Chaque réponse finale s'appuie sur au moins 50 commandes (limite le surapprentissage) |
| `class_weight` | `"balanced"` | Comme pour la régression |
| `random_state` | 42 | Rend le résultat reproductible |
| `n_jobs` | −1 | Utilise tous les processeurs |

### Pourquoi elle a perdu dans l'O6

1. Elle apprend des règles **trop spécifiques au passé** (ex. « RJ en février-mars 2018 = retard ») qui ne se répètent pas.
2. Elle **n'extrapole pas** : face à des promesses plus courtes que tout ce qu'elle a vu, elle les range avec les cas connus les plus proches.

**Leçon :** plus complexe ne veut pas dire meilleur, surtout quand le contexte change.

---

## 10. Lire les poids du modèle

| Règle de lecture | Exemple O6 |
|---|---|
| Le signe donne le sens | `promised_days` −0,58 : promesse longue -> moins de risque |
| La valeur absolue donne l'importance (variables standardisées) | −0,58 pèse plus que +0,14 |
| Un poids se lit **à autres variables égales** | Distance +0,35 : à promesse égale, plus loin -> plus de risque |
| Un poids nul = n'apporte rien **de plus** que les autres | Prix 0,01 : son information est déjà portée par la distance, l'état, les frais de port |
| Les états se lisent par rapport à la modalité supprimée | RJ +0,32 : plus risqué qu'AC, à distance et promesse égales |

**Variables redondantes** (prix, paiement, frais de port disent presque la même chose) : le modèle répartit le poids entre elles. Leur poids individuel est alors peu fiable.

---

## 11. Créer une variable : le *feature engineering*

**Définition :** construire de nouvelles variables à partir des variables existantes, pour donner au modèle une information qu'il ne peut pas fabriquer seul.

**Dans l'O6 : la marge.**

$$\text{marge} = \frac{\text{promised\_days}}{\max(\text{distance\_km},\ 100) \div 100}$$

soit les **jours promis par 100 km**.

**Pourquoi elle était nécessaire :** la régression logistique ne sait faire que des **additions**. Elle peut écrire $a_1 \times \text{promesse} + a_2 \times \text{distance}$, mais jamais « promesse ÷ distance ». On lui donne donc le rapport tout fait, **en plus** des deux variables d'origine :

$$z = \dots + a_1 \times \text{promesse} + a_2 \times \text{distance} + a_3 \times \text{marge} + \dots$$

**Le plancher à 100 km :** sans lui, une commande à 3 km donnerait 24 ÷ 0,03 = 800 jours par 100 km, une valeur absurde qui écraserait les autres. En dessous de 100 km, le temps de transport est à peu près constant.

**D'où est venue l'idée :** d'une chaîne de constats. O1 (la distance explique la promesse) -> Q1 (la promesse seule ne distingue rien) -> Q5 (l'anomalie d'août, promesses courtes) -> Q8 (SP, promesse divisée par deux). **La variable découle d'une phrase métier : un retard, c'est une promesse trop serrée pour le trajet.**

**Résultat :** +9 points de détection au top 20 %, là où la forêt aléatoire, plus complexe, avait fait moins bien.

**Les formes classiques à connaître :**

| Forme | Exemple |
|---|---|
| Ratio | Jours promis par 100 km, prix par article |
| Écart | Promesse moins délai habituel vers l'état |
| Historique | Taux de retard passé du vendeur (sur ses commandes antérieures uniquement) |
| Regroupement | Une colonne par mois au lieu d'un nombre de 1 à 12 |

**Méthode :** avant d'ajouter une variable au modèle, vérifier qu'elle a un sens (ici : le retard baisse de 10,4 % à 3,3 % quand la marge augmente), puis comparer le modèle **avec et sans**, sur le même test et aux mêmes paliers.

---

## 12. Glossaire du code

### pandas

| Code | Rôle |
|---|---|
| `pd.read_sql(requete, engine)` | Exécute une requête SQL et renvoie un tableau |
| `df.shape` | Nombre de lignes et de colonnes |
| `df.isna().sum()` | Nombre de cases vides par colonne |
| `df["col"].mean()` | Moyenne ; sur un booléen, donne le taux de True |
| `df[condition]` | Filtre les lignes, comme un `WHERE` |
| `df.dropna()` | Supprime les lignes avec au moins une case vide |
| `pd.get_dummies(df, columns=[...], drop_first=True)` | One-hot encoding |
| `df.filter(like="texte")` | Garde les colonnes dont le nom contient ce texte |
| `df.drop(columns=[...])` | Retire des colonnes |
| `df.copy()` | Crée une copie indépendante |
| `df.groupby("col").agg(...)` | Agrège par groupe, comme un `GROUP BY` |
| `value_counts()` | Compte les occurrences de chaque valeur |
| `rank(ascending=False, pct=True)` | Classe les lignes, en pourcentage (0 = premier) |
| `idxmax(axis=1)` | Pour chaque ligne, nom de la colonne à la valeur maximale |
| `sort_values()` | Trie |
| `head(n)` / `tail(n)` | Premières / dernières lignes |
| `.to_string()` | Force l'affichage complet |
| `df["col"].clip(lower=100)` | Remplace toute valeur inférieure à 100 par 100 |
| `pd.qcut(serie, 5)` | Découpe en 5 groupes de même taille |

### scikit-learn et numpy

| Code | Rôle |
|---|---|
| `StandardScaler()` | Standardisation |
| `fit_transform` / `transform` | Calculer et appliquer / appliquer seulement |
| `LogisticRegression(...)` | Régression logistique |
| `RandomForestClassifier(...)` | Forêt aléatoire |
| `.fit(X, y)` | Entraîner |
| `.predict(X)` | Prédire une classe (seuil 0,5) |
| `.predict_proba(X)[:, 1]` | Probabilité de la classe « en retard » |
| `.coef_` | Poids appris par la régression logistique |
| `recall_score` / `precision_score` | Rappel / précision |
| `train_test_split(..., stratify=y)` | Découpage au hasard, en gardant le même taux de retard |
| `np.sort(p)[-n]` | La n-ième valeur la plus haute : seuil qui donne n alertes |

---

## 13. Récapitulatif des choix

| Choix | Justification |
|---|---|
| Variables connues à l'achat uniquement | Éviter les fuites |
| `promised_days` ajouté | Connu à l'achat ; variable n° 1 une fois combinée à la distance |
| `late_rate` vendeur écarté | Contient la commande à prédire et le futur |
| Règle par état comme référence | Savoir si le modèle apporte vraiment quelque chose |
| Découpage dans le temps | Reproduit l'usage réel ; a révélé le changement de contexte |
| Exclusion des 477 valeurs manquantes | 0,5 % des commandes, 44 retards ; l'imputation inventerait des données |
| One-hot encoding de l'état | Numéroter créerait un ordre inexistant |
| Standardisation sur l'entraînement seul | Variables comparables, sans information du futur |
| `class_weight="balanced"` | Ne pas ignorer les retards (7,5 %) |
| Seuil choisi, pas 0,5 | Le seuil par défaut alertait 77 % des commandes |
| Comparaison à 5 065 alertes | Juger la règle et le modèle à charge égale |
| Régression logistique retenue | Meilleure que la forêt à tous les paliers, et lisible |
| Variable de marge ajoutée | Le modèle ne peut pas fabriquer seul le rapport promesse / distance ; +9 points au top 20 % |

---

## 14. Questions d'entretien possibles

**« Pourquoi ne pas utiliser la justesse (*accuracy*) ? »**
Avec 6,77 % de retards, un modèle qui prédit toujours « pas de retard » a 93 % de justesse et ne détecte rien. On mesure donc la détection (M-11) et la fiabilité des alertes (M-12).

**« Votre modèle a 82 % de fausses alertes au mieux. Il ne sert à rien ? »**
Il détecte deux fois plus de retards qu'une règle simple à charge égale, et son top 1 % est cinq fois plus exposé que la moyenne. Il justifie des actions peu coûteuses (surveillance, information du client). Et sa limite est logique : 95 % du retard naît pendant l'acheminement, après la commande.

**« Pourquoi un découpage dans le temps ? »**
Parce qu'en réalité, on prédit le futur à partir du passé. Ce choix a révélé que la politique de promesse avait changé, ce qu'un découpage au hasard aurait masqué.

**« Pourquoi la régression logistique et pas un modèle plus avancé ? »**
Je l'ai comparée à une forêt aléatoire : elle a gagné à tous les paliers. Elle est plus robuste au changement de contexte et elle est lisible, ce qui compte pour une équipe métier.

**« Comment avez-vous amélioré votre modèle ? »**
Pas en changeant de modèle, mais en créant une variable. L'étude des erreurs a montré que le retard dépend du rapport entre la promesse et la distance. J'ai créé une marge, les jours promis par 100 km : +9 points de détection au top 20 %. Une anomalie, une explication, une variable, un gain mesuré.

**« Quelle est votre principale découverte ? »**
Le retard dépend fortement de la promesse faite au client. À l'été 2018, Olist a raccourci ses délais, surtout vers SP, et le retard y a été multiplié par 12. La promesse est un levier qu'Olist contrôle directement.

---

## Pour aller plus loin

- **Courbe précision-rappel** : visualiser le compromis pour tous les seuils à la fois.
- **Calibration** (`CalibratedClassifierCV`) : rendre les probabilités lisibles comme de vrais pourcentages.
- **Validation temporelle glissante** (`TimeSeriesSplit`) : tester plusieurs coupures successives.
- **Gradient boosting** (`HistGradientBoostingClassifier`) : une autre famille de modèles à base d'arbres, souvent plus performante que la forêt.
- **SHAP** : expliquer la prédiction d'une commande précise, variable par variable.
