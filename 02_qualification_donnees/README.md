# 02 — Qualification des données

Vérification que le jeu de données permet de répondre à la problématique,
**avant** toute préparation ou analyse.

## Contenu

| Fichier | Description |
|---|---|
| `01_qualification_donnees.ipynb` | Contrôles chiffrés des hypothèses H1 à H11 |
| `02_dictionnaire_donnees.md` | Description des 9 tables et de leurs champs |
| `rapport_qualification.md` | Synthèse des résultats et conséquences sur le périmètre |
| `dataset/` | Données brutes Olist — non versionnées (`.gitignore`) |

## Démarche

Chaque hypothèse posée dans la note de cadrage v1 est testée par un contrôle
chiffré, puis validée ou invalidée. Les hypothèses invalidées entraînent une
révision du périmètre, tracée dans la note de cadrage v2.

**Le principe** : on ne découvre pas qu'une analyse est impossible après trois
semaines de préparation. On le découvre avant.

## Résultat principal

Le taux de réachat client s'établit à **3,12 %**. L'analyse du comportement
d'achat après un retard est donc abandonnée, et le chiffrage de la valeur
reporté au grain vendeur.

C'est le résultat le plus structurant de cette phase : il a fait tomber
l'objectif central de la v1 et imposé une reformulation de la problématique.

## Conséquences sur la suite

Les hypothèses testées ici ont produit les **11 règles de gestion** consignées
dans `01_cadrage/02_regles_et_metriques.md`.

Leurs volumétries ont été **revérifiées sur le périmètre final** lors de la
préparation des données. Plusieurs chiffres annoncés ici ont dû être corrigés —
non par erreur de méthode, mais parce qu'ils étaient mesurés tous statuts
confondus. Le plus notable : **RG-04 concerne 674 commandes et non 1 350**.

Le détail des corrections figure en fin de `rapport_qualification.md`.

> **Ce qu'une qualification peut voir, et ce qui lui échappe.** Cette phase a
> rempli sa fonction : écarter une analyse impossible avant d'y investir des
> semaines. Mais certains problèmes n'apparaissent qu'en manipulant réellement
> les données — 789 `review_id` dupliqués, 4 poids produit à zéro, 14 commandes
> sans date d'approbation. Qualification et préparation sont complémentaires,
> pas redondantes.
