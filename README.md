#  La Promesse Non Tenue
### *Où naissent les retards de livraison, combien ils exposent, et comment les anticiper*

Projet data de bout en bout : du cadrage du besoin jusqu'aux recommandations chiffrées, en passant par la qualification, l'analyse, la visualisation et la prédiction.

---

##  Pourquoi ce projet ? (La valeur business)

Sur une marketplace, la date de livraison annoncée est une **promesse commerciale**. La plateforme la formule, mais ne la maîtrise qu'en partie : l'exécution dépend du vendeur, de la distance et du transporteur.

Quand la promesse est rompue, trois questions restent sans réponse :

- **Où le retard est-il né ?** Chez le vendeur qui a tardé à expédier, ou dans l'acheminement ?
- **Quel volume d'activité est concerné ?**
- **Aurait-on pu le voir venir ?**

Ce projet répond aux trois, et débouche sur un outil d'aide à la décision qui **diagnostique**, **chiffre** et **anticipe**.

---

##  Problématique

> **Où naissent les ruptures de délai sur une marketplace, quel volume d'activité exposent-elles, et peut-on les anticiper au moment de la commande ?**

**Sous-questions :**

| # | Question | Enjeu |
|---|---|---|
| 1 | À partir de combien de jours de retard la satisfaction bascule-t-elle ? | Seuil de tolérance |
| 2 | Le retard naît-il de la préparation vendeur ou de l'acheminement ? | Attribuer la cause |
| 3 | Quel chiffre d'affaires est exposé, et comment se concentre-t-il ? | Mesurer l'enjeu |
| 4 | Un vendeur qui livre mal voit-il son activité reculer ? | Mécanisme de destruction de valeur |
| 5 | Peut-on prédire le risque de retard dès la commande ? | Anticipation |
| 6 | Quel gain attendre d'une réduction des délais ? | Justifier l'investissement |

---

##  Ce que la qualification a changé

La problématique initiale portait sur l'impact des retards sur la **fidélité client**. La phase de qualification l'a invalidée avant toute analyse :

| Hypothèse testée | Résultat | Décision |
|---|---|---|
| Les clients repassent commande | ❌ **3,12 %** de réachat | Analyse du comportement post-retard abandonnée |
| Les dates de livraison sont exploitables | ✅ **99,99 %** | Périmètre confirmé |
| Les avis clients sont disponibles | ✅ **99,33 %** | Lien retard-satisfaction mesurable |
| Le retard est imputable à un vendeur | ✅ **98,7 %** mono-vendeur | Analyse au grain vendeur possible |

**Le pivot :** faute de trajectoire client observable, le chiffrage ne porte plus sur une *perte future estimée* mais sur une **exposition présente mesurée** — le chiffre d'affaires réellement concerné par une promesse rompue. Le mécanisme de destruction de valeur est reporté au niveau du vendeur, qui dispose lui d'un historique exploitable.

> *Aucun résultat de ce projet ne repose sur une donnée simulée ou une hypothèse non sourcée. Les limites sont documentées plutôt que contournées.*

---

##  Données utilisées

**Brazilian E-Commerce Public Dataset by Olist** (Kaggle)

- 9 tables relationnelles, ~100 000 commandes réelles (2016-2018)
- **Périmètre d'analyse : 96 470 commandes livrées**, 3 095 vendeurs, 27 états
- Champs clés : dates d'achat, d'approbation, de remise au transporteur, de livraison, et **date de livraison estimée**

Les quatre dates réelles permettent de décomposer le parcours en trois segments — validation, **préparation vendeur**, **acheminement** — et donc d'identifier où naît le retard.

> *Les fichiers bruts ne sont pas versionnés (`.gitignore`). Seuls les scripts, notebooks et données agrégées sont poussés.*

---

##  Démarche méthodologique

| Dossier | Étape | Objectif | Livrable |
| :--- | :--- | :--- | :--- |
| `01_cadrage_besoin` | Cadrage & règles de gestion | Définir la promesse, le retard, le périmètre | Note de cadrage (v1 et v2) |
| `02_qualification_donnees` | Qualification | Vérifier que la donnée permet de répondre | Contrôles d'hypothèses, dictionnaire, rapport qualité |
| `03_preparation_donnees` | Préparation | Jointures, nettoyage, calcul des écarts | Table analytique (SQL / Python) |
| `04_analyse_prediction` | Analyse & modélisation | Seuils, concentration, score de risque | Notebooks Python |
| `05_dashboard` | Restitution | Diagnostic visuel et simulation | Rapport Power BI |
| `06_conclusions_recommandations` | Synthèse | Décisions chiffrées et priorisées | Executive summary (5 slides) |

---

##  Ma valeur ajoutée

- **Approche AMOA au centre.** Pas de code avant d'avoir défini les règles de gestion métier. Chaque indicateur est relié à un besoin identifié.
- **Une qualification qui sert à quelque chose.** Les hypothèses ont été testées *avant* l'analyse, et l'une d'elles a modifié le périmètre. La démarche est tracée, pas reconstruite après coup.
- **Un diagnostic, pas un constat.** Séparer le retard vendeur du retard transporteur, c'est produire deux leviers d'action distincts au lieu d'une alerte générale.
- **Du passé à l'anticipation.** Le modèle prédictif estime le risque au moment de la commande, quand il est encore possible d'agir.

---

##  Stack technique

- **Langages** : Python (Pandas, Scikit-learn, Matplotlib) · SQL
- **Visualisation** : Power BI (DAX, Power Query)
- **Versioning** : Git / GitHub · Travail itératif par livrables incrémentaux

---

##  Statut d'avancement

*Démarrage : août 2026*

- [x] Cadrage du besoin — note de cadrage v1
- [x] Qualification des données — hypothèses H1 à H6 testées
- [x] Révision du périmètre — note de cadrage v2
- [ ] Définition des métriques et règles de gestion
- [ ] Préparation de la table analytique
- [ ] Analyse exploratoire et recherche des seuils
- [ ] Modélisation prédictive
- [ ] Dashboard Power BI
- [ ] Recommandations finales

---

##  Auteur

**EL HARIRI WIJDANE**  
*Étudiante Ingénieur INPT – Innovation & AMOA (Data/IA)*  
[LinkedIn](https://www.linkedin.com/in/wijdane-el-hariri-871a81343)
