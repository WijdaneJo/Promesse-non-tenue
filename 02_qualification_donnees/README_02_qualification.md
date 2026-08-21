# 02 — Qualification des données

Vérification que le jeu de données permet de répondre à la problématique,
**avant** toute préparation ou analyse.

## Contenu

| Fichier | Description |
|---|---|
| `01_qualification_donnees.ipynb` | Contrôles chiffrés de 9 hypothèses |
| `02_dictionnaire_donnees.md` | Description des 9 tables sources et de leurs champs |
| `03_rapport_qualification.md` | Synthèse des résultats et conséquences sur le périmètre |
| `dataset/` | Données brutes Olist — non versionnées (`.gitignore`) |

## Démarche

Chaque hypothèse posée dans la note de cadrage v1 est testée par un contrôle
chiffré, puis validée ou invalidée. Les hypothèses invalidées entraînent une
révision du périmètre, tracée dans la note de cadrage v2.

**Le principe** : on ne découvre pas qu'une analyse est impossible après trois
semaines de préparation. On le découvre avant.

> **Numérotation.** Les hypothèses testées sont **H1, H2, H3, H5, H6, H7, H9,
> H11 et H12**. Les numéros manquants correspondent à des hypothèses de la v1
> abandonnées avant contrôle. H12 a été ajoutée en cours de qualification.

## Deux résultats structurants

**Le taux de réachat client s'établit à 3,12 %** *(H1)*. L'analyse du
comportement d'achat après un retard est abandonnée, et le chiffrage de la
valeur reporté au grain vendeur. C'est ce résultat qui a fait tomber l'objectif
central de la v1 et imposé une reformulation de la problématique.

**91,88 % des commandes sont livrées en avance, avec une marge médiane de
13 jours** *(H12)*. Constat non anticipé : Olist ne promet pas serré, elle
promet large. Une sous-question **SQ7** est ajoutée au cadrage — de combien la
promesse peut-elle être resserrée sans dégrader sa tenue ?

Le premier a fermé une porte. Le second en a ouvert une.

## Conséquences sur la suite

Les hypothèses testées ici ont produit les **11 règles de gestion** consignées
dans `01_cadrage_besoin/02.regles_et_metriques.md`.

Leurs volumétries ont été **revérifiées sur le périmètre final** lors de la
préparation. Plusieurs chiffres annoncés ici ont dû être corrigés — non par
erreur de méthode, mais parce qu'ils étaient mesurés tous statuts confondus.
Le plus notable : **RG-04 concerne 674 commandes et non 1 350**.

Le détail des corrections figure en fin de `03_rapport_qualification.md`.

## Ce qui se confirme exactement

> H12 avait mesuré **6,77 %** de commandes en retard en pandas.
> La chaîne PostgreSQL complète retrouve **6,77 %** — 6 534 sur 96 447.

Deux outils, deux méthodes indépendantes, le même résultat. C'est la meilleure
validation possible du pipeline de préparation.

> **Ce qu'une qualification peut voir, et ce qui lui échappe.** Cette phase a
> rempli sa fonction : écarter une analyse impossible avant d'y investir des
> semaines. Mais certains problèmes n'apparaissent qu'en manipulant réellement
> les données — 789 `review_id` dupliqués, 4 poids produit à zéro, 14 commandes
> sans date d'approbation. Qualification et préparation sont complémentaires,
> pas redondantes.
