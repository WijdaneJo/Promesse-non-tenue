# 02 — Qualification des données

Vérification que le jeu de données permet de répondre à la problématique,
**avant** toute préparation ou analyse.

## Contenu

| Fichier | Description |
|---|---|
| `01_qualification_donnees.ipynb` | Contrôles chiffrés des hypothèses H1 à H11 |
| `rapport_qualification.md` | Synthèse des résultats et conséquences sur le périmètre |
| `dataset/` | Données brutes Olist — non versionnées (`.gitignore`) |

## Démarche

Chaque hypothèse posée dans la note de cadrage v1 est testée par un contrôle
chiffré, puis validée ou invalidée. Les hypothèses invalidées entraînent une
révision du périmètre, tracée dans la note de cadrage v2.

## Résultat principal

Le taux de réachat client s'établit à **3,12 %**. L'analyse du comportement
d'achat après un retard est donc abandonnée, et le chiffrage de la valeur
reporté au grain vendeur.