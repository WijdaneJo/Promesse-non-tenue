# La Promesse Non Tenue
### *Où naissent les retards de livraison, combien ils exposent, et comment les anticiper*

Projet data de bout en bout : du cadrage du besoin jusqu'aux recommandations chiffrées, en passant par la qualification, la préparation, l'analyse, la visualisation et la prédiction.

---

## Pourquoi ce projet ? (La valeur business)

Sur une marketplace, la date de livraison annoncée est une **promesse commerciale**. La plateforme la formule, mais ne la maîtrise qu'en partie : l'exécution dépend du vendeur, de la distance et du transporteur.

Quand la promesse est rompue, trois questions restent sans réponse :

- **Où le retard est-il né ?** Chez le vendeur qui a tardé à expédier, ou dans l'acheminement ?
- **Quel volume d'activité est concerné ?**
- **Aurait-on pu le voir venir ?**

Ce projet répond aux trois, et débouche sur un outil d'aide à la décision qui **diagnostique**, **chiffre** et **anticipe**.

---

## Problématique

> **Où naissent les ruptures de délai sur une marketplace, quel volume d'activité exposent-elles, et peut-on les anticiper au moment de la commande ?**

**Sous-questions :**

| # | Question | Enjeu |
|---|---|---|
| 1 | À partir de combien de jours de retard la satisfaction bascule-t-elle ? | Seuil de tolérance |
| 2 | Le retard naît-il de la préparation vendeur ou de l'acheminement ? | Attribuer la cause |
| 3 | Quel chiffre d'affaires est exposé, et comment se concentre-t-il ? | Mesurer l'enjeu |
| 4 | Un vendeur qui livre mal voit-il son activité reculer ? | Mécanisme de destruction de valeur |
| 5 | Peut-on prédire le risque de retard dès la commande ? | Anticipation |
| 6 | Quel gain attendre d'une réduction des délais réels ? | Justifier l'investissement |
| **7** | **Les délais annoncés sont-ils bien calibrés ?** | **Arbitrer attractivité / tenue de la promesse** |

> *La 7ᵉ question n'était pas prévue. Elle a été ouverte par la qualification, qui a révélé que **91,88 % des commandes sont livrées en avance, avec une marge médiane de 13 jours**. Olist ne promet pas serré : elle promet large.*

---

## Ce que les données ont changé

Deux phases ont modifié le cadrage avant même l'analyse.

### La qualification a invalidé l'objectif central

| Hypothèse testée | Résultat | Décision |
|---|---|---|
| Les clients repassent commande | ❌ **3,12 %** de réachat | Analyse du comportement post-retard abandonnée |
| Les dates de livraison sont exploitables | ✅ **99,99 %** | Périmètre confirmé |
| Les avis clients sont disponibles | ✅ **99,33 %** | Lien retard-satisfaction mesurable |
| Le retard est imputable à un vendeur | ✅ **98,7 %** mono-vendeur | Analyse au grain vendeur possible |
| Le volume de retards est suffisant | ✅ **6,77 %** | Projet viable — **et SQ7 ouverte** |

**Le pivot :** faute de trajectoire client observable, le chiffrage ne porte plus sur une *perte future estimée* mais sur une **exposition présente mesurée** — le chiffre d'affaires réellement concerné par une promesse rompue. Le mécanisme de destruction de valeur est reporté au niveau du vendeur, qui dispose lui d'un historique exploitable.

### La préparation a corrigé la qualification

| Élément | Annoncé | Vérifié |
|---|---|---|
| Périmètre d'analyse | 96 470 | **96 447** |
| Commandes expédiées avant validation | 1 350 | **674** |
| Vendeurs analysables | 3 095 | **1 323** |

Le chiffre de 1 350 était mesuré **tous statuts confondus** ; sur le seul périmètre livré, la moitié disparaît. C'est la fonction de la recette : produire des chiffres vérifiés sur le périmètre final, jamais déduits par soustraction.

> *Aucun résultat de ce projet ne repose sur une donnée simulée ou une hypothèse non sourcée. Les limites sont documentées plutôt que contournées.*

---

## Premiers résultats

Produits par la préparation, ils servent d'ancrage à l'analyse.

| Indicateur | Valeur |
|---|---|
| Taux de commandes en retard | **6,77 %** — 6 534 sur 96 447 |
| Chiffre d'affaires du périmètre | **15 416 546 R$** |
| Note moyenne de satisfaction | 4,16 / 5 |
| Distance médiane vendeur → client | 434 km |
| Commandes livrées avec ≥ 4 jours d'avance | **87 %** |

**Une commande sur quinze rompt la promesse** — mais 6,77 % des *commandes* ne signifie pas 6,77 % du *chiffre d'affaires*. Si les retards touchent des commandes plus chères, l'exposition financière est supérieure.

**La promesse est largement surdimensionnée**, avec un pic à quatorze jours d'avance. Cette marge est à la fois un gisement d'amélioration commerciale et un facteur aggravant : un retard survient malgré une promesse déjà prudente.

---

## Données utilisées

**Brazilian E-Commerce Public Dataset by Olist** (Kaggle)

- 9 tables relationnelles, ~100 000 commandes réelles (2016-2018)
- **Périmètre d'analyse : 96 447 commandes livrées**, 27 états, 1 323 vendeurs analysables
- Champs clés : dates d'achat, d'approbation, de remise au transporteur, de livraison, et **date de livraison estimée**

Les quatre dates réelles permettent de décomposer le parcours en trois segments — validation, **préparation vendeur**, **acheminement** — et donc d'identifier où naît le retard.

> *Les fichiers bruts ne sont pas versionnés (`.gitignore`). Seuls les scripts, notebooks et données agrégées sont poussés.*

---

## Démarche méthodologique

| Dossier | Étape | Objectif | Livrable | Statut |
| :--- | :--- | :--- | :--- | :---: |
| `01_cadrage_besoin` | Cadrage & règles de gestion | Définir la promesse, le retard, le périmètre | Note de cadrage (v1 → v3.1), 11 règles, 18 métriques | ✅ |
| `02_qualification_donnees` | Qualification | Vérifier que la donnée permet de répondre | Contrôles d'hypothèses, dictionnaire, rapport | ✅ |
| `03_preparation_donnees` | Préparation | Pipeline SQL/Python, tables analytiques | `mart.orders` (96 447) · `mart.sellers` (1 323) | ✅ |
| `04_analyse_prediction` | Analyse & modélisation | Seuils, concentration, score de risque | Notebooks Python | ⬜ |
| `05_dashboard` | Restitution | Diagnostic visuel et simulation | Rapport Power BI | ⬜ |
| `06_conclusions_recommandations` | Synthèse | Décisions chiffrées et priorisées | Executive summary | ⬜ |

---

## Le pipeline de préparation

Architecture en quatre couches, où **chaque couche ne lit que la précédente** :

```
CSV bruts → raw → staging → intermediate → mart
```

| Couche | Rôle |
|---|---|
| `raw` | Copie fidèle des 9 CSV, **tout en TEXT** — jamais modifiée |
| `staging` | Données typées et nettoyées |
| `intermediate` | Grains corrigés, périmètre appliqué |
| `mart` | Tables analytiques finales |

**Reproductibilité vérifiée** : les quatre schémas ont été détruits et intégralement reconstruits depuis les CSV bruts. Les chiffres obtenus sont identiques.

Trois pièges de grain neutralisés au passage — le plus dangereux étant la table de géolocalisation, **1 000 163 lignes pour ~19 000 codes postaux** : une jointure directe aurait multiplié chaque commande par le nombre de points relevés dans sa zone.

---

## Ma valeur ajoutée

- **Approche AMOA au centre.** Pas de code avant d'avoir défini les règles de gestion métier. Chaque indicateur est relié à un besoin identifié.
- **Une qualification qui sert à quelque chose.** Les hypothèses ont été testées *avant* l'analyse. L'une a modifié le périmètre, une autre a ouvert une sous-question non prévue. La démarche est tracée, pas reconstruite après coup.
- **Une recette qui corrige.** La préparation a revérifié chaque volumétrie sur le périmètre final et corrigé plusieurs chiffres de la qualification. Un pipeline qui ne se contredit pas est un pipeline qu'on peut défendre.
- **Un diagnostic, pas un constat.** Séparer le retard vendeur du retard transporteur, c'est produire deux leviers d'action distincts au lieu d'une alerte générale.
- **Du passé à l'anticipation.** Le modèle prédictif estime le risque au moment de la commande, quand il est encore possible d'agir.

---

## Stack technique

- **Base de données** : PostgreSQL 17 — architecture en couches, 4 schémas
- **Langages** : SQL (CTE, fonctions fenêtre, agrégations) · Python (pandas, numpy, SQLAlchemy, psycopg2)
- **Modélisation** : Scikit-learn *(à venir)*
- **Visualisation** : Power BI (DAX, Power Query) *(à venir)*
- **Versioning** : Git / GitHub · Travail itératif par livrables incrémentaux

---

## Statut d'avancement

*Démarrage : août 2026*

- [x] Cadrage du besoin — note de cadrage v1
- [x] Qualification des données — 9 hypothèses testées
- [x] Révision du périmètre — note de cadrage v2
- [x] Définition des métriques et règles de gestion — 11 règles, 18 métriques
- [x] Préparation de la table analytique — pipeline SQL/Python reproductible
- [x] Recette et documentation — note de cadrage v3.1
- [ ] Analyse exploratoire et recherche des seuils
- [ ] Modélisation prédictive
- [ ] Dashboard Power BI
- [ ] Recommandations finales

---

## Auteur

**EL HARIRI WIJDANE**
*Étudiante Ingénieur INPT – Innovation & AMOA (Data/IA)*
[LinkedIn](https://www.linkedin.com/in/wijdane-el-hariri-871a81343)
