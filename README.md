#  La Promesse Non Tenue
### *Quel est le coût réel d'une date de livraison non respectée ?*

Projet data de bout en bout : du cadrage du besoin jusqu'aux recommandations stratégiques chiffrées, en passant par l'analyse, la visualisation et la prédiction.

---

##  Pourquoi ce projet ? (La valeur business)

Dans toute entreprise, un délai est une **promesse** faite au client. 
Quand elle est rompue, une chaîne de conséquences s'enclenche : **insatisfaction → perte de confiance → dégradation de la relation commerciale**.

**Le problème** : Tout le monde sait que ça arrive. Peu savent **combien ça coûte**.

**La solution proposée** : Un outil d'aide à la décision qui :
-  **Chiffre** l'impact financier des retards.
-  **Prédit** les risques de rupture avant la livraison.
-  **Prescrit** une liste d'actions priorisées (vendeurs, régions, produits) pour maximiser le ROI de chaque jour gagné.

---

##  Problématique centrale (Le "So What ?")

> *"Dans quelle mesure un retard de livraison dégrade-t-il la satisfaction et la valeur client, et comment anticiper ces ruptures de promesse pour optimiser la performance logistique et commerciale ?"*

**Sous-questions stratégiques :**
1. **Seuil de tolérance** : À partir de combien de jours de retard la satisfaction client bascule-t-elle ?
2. **Coût du retard** : Quelle est la perte de valeur imputable à un client insatisfait par un retard ?
3. **Cartographie du risque** : Quels vendeurs, régions et catégories de produits concentrent les retards les plus coûteux ?
4. **Anticipation** : Peut-on prédire, au moment de la commande, un risque de non-respect du délai promis ?
5. **Levier d'action** : Quel est le gain estimé si l'on réduit les délais de X jours ?

> *Périmètre à confirmer après la phase de qualification des données.*

---

##  Données utilisées

**Source** : Brazilian E-Commerce Public Dataset by Olist (Kaggle)
- **Volume** : 9 tables relationnelles, ~100 000 commandes réelles.
- **Champs clés** : Date de commande, date de livraison estimée, date de livraison réelle, note de satisfaction, montant de la commande, région, vendeur.

> *Les fichiers bruts ne sont pas versionnés (`.gitignore`). Seuls les scripts de nettoyage et les données agrégées sont poussés.*

---

##  Démarche méthodologique (Le pipeline Consulting)

Chaque étape de ce projet répond à une phase de la méthode CRISP-DM, adaptée au conseil :

| Dossier | Étape | Objectif métier | Livrable |
| :--- | :--- | :--- | :--- |
| `01_cadrage_besoin` | Cadrage & Règles de gestion | Définir ce qu'est un "retard" et une "promesse" (SLA). | Note de cadrage, hypothèses documentées |
| `02_qualification_donnees` | Qualification | Audit de la qualité (dates manquantes, valeurs aberrantes). | Dictionnaire des données et rapport de fiabilité |
| `03_preparation_donnees` | Préparation | Nettoyage et calcul des écarts (Jours de retard). | Table analytique (SQL / Python) prête à l'emploi |
| `04_analyse_prediction` | Analyse & Modélisation | Analyse des impacts + Score de risque (ML). | Notebooks Python |
| `05_dashboard` | Restitution | Visualisation interactive des pertes et des risques. | Rapport Power BI (pages "Constats" et "Scénarios") |
| `06_conclusions_recommandations` | Synthèse | Propositions chiffrées et priorisées (Matrice ROI). | Executive Summary (PDF 5 slides) |

---

##  Ma valeur ajoutée (Ce qui rend ce projet unique)

- **Approche AMOA au centre** : Pas de code avant d'avoir défini les règles de gestion métier. Le projet est structuré comme une vraie mission de conseil.
- **Du constat à la prédiction** : Ne pas se contenter de décrire la performance passée, mais anticiper les risques futurs.
- **Un chiffrage financier** : Un décideur ne signe pas sur un graphique, il signe sur un retour sur investissement (ROI).

---

##  Stack technique utilisée

- **Langages** : Python (Pandas, Scikit-learn, Matplotlib) · SQL
- **Visualisation** : Power BI (DAX, Power Query)
- **Gestion de projet** : Git / GitHub · Travail itératif par livrables incrémentaux
- **Modélisation** : Algorithmes de classification pour la prédiction du risque

---

##  Statut d'avancement (Work In Progress)

*Démarrage du projet : Août 2026*

- [ ] Cadrage du besoin et définition des métriques
- [ ] Qualification des données (taux de remplissage, fiabilité)
- [ ] Préparation de la table analytique (calcul des retards)
- [ ] Analyse exploratoire et modélisation prédictive
- [ ] Conception du Dashboard Power BI
- [ ] Rédaction des recommandations finales

---

##  Auteur

**EL HARIRI WIJDANE**  
*Étudiante Ingénieur INPT – Innovation & AMOA (Data/IA)*  
[LinkedIn](https://www.linkedin.com/in/wijdane-el-hariri-871a81343)