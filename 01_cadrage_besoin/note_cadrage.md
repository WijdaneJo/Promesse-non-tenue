# Note de cadrage — La Promesse Non Tenue

**Version 2.0 — révisée après qualification des données**
*Remplace la version 1.0, rédigée avant accès aux données.*

---

## 1. Contexte

Olist est une marketplace brésilienne qui met en relation de petits commerçants
répartis sur tout le territoire avec des acheteurs, via un contrat unique et un
canal de vente mutualisé. Les vendeurs partenaires expédient directement aux
clients en s'appuyant sur les partenaires logistiques d'Olist.

Le parcours type d'une commande est le suivant :

1. Le client passe commande et se voit annoncer une **date de livraison estimée**.
2. Le vendeur partenaire est notifié et prépare l'expédition.
3. Le colis est remis à un partenaire logistique, qui l'achemine.
4. Une enquête de satisfaction est envoyée au client par e-mail.

### La tension centrale de la mission

Olist **annonce une promesse de délai** qu'elle ne maîtrise pas entièrement :
l'exécution dépend de la réactivité du vendeur, de la distance à parcourir et
du partenaire logistique. La plateforme porte la responsabilité commerciale
d'un engagement dont elle ne contrôle qu'une partie.

Cette configuration soulève une question opérationnelle directe : **lorsqu'une
promesse est rompue, où le problème est-il né ?** Chez le vendeur qui a tardé à
expédier, ou dans la chaîne d'acheminement ? Les deux causes appellent des
leviers d'action distincts.

### Un point structurant du dispositif de mesure

L'enquête de satisfaction est déclenchée **à la réception du produit ou à
l'échéance de la date de livraison estimée**, selon ce qui survient en premier.

Conséquence directe : un client dont la commande est en retard peut être
sollicité **avant même d'avoir reçu son colis**. La note recueillie mesure alors
la déception liée à la promesse rompue, indépendamment de la qualité du produit.
Le dispositif de mesure d'Olist capte donc spécifiquement l'effet du
non-respect du délai.

### Le déclencheur de la mission

La direction constate une dégradation des notes de satisfaction et une pression
concurrentielle croissante, sans disposer d'éléments pour répondre à trois
questions : où le problème se situe, quel volume d'activité il concerne, et sur
quels leviers agir en priorité.

---

## 2. Problématique

> **Où naissent les ruptures de délai sur une marketplace, quel volume
> d'activité exposent-elles, et peut-on les anticiper au moment de la commande ?**

### Évolution par rapport à la version 1.0

La problématique initiale portait sur l'impact du retard sur la **fidélité
client** et la valeur vie client. La phase de qualification a établi que le taux
de réachat est de **3,12 %** : 93 099 clients sur 96 096 n'ont passé qu'une
seule commande. Aucune trajectoire client n'est donc observable, et l'effet d'un
retard sur les achats ultérieurs n'est pas mesurable.

La problématique a été recentrée sur trois axes que les données permettent de
traiter : **l'origine du retard**, **l'exposition financière**, et
**l'anticipation**.

### Sous-questions

| # | Sous-question | Enjeu |
|---|---|---|
| SQ1 | À partir de combien de jours de retard la satisfaction bascule-t-elle ? | Identifier le seuil de tolérance |
| SQ2 | Le retard naît-il de la préparation vendeur ou de l'acheminement ? | Attribuer la cause, orienter le levier |
| SQ3 | Quel chiffre d'affaires est exposé à une rupture de promesse, et comment se concentre-t-il ? | Mesurer l'enjeu |
| SQ4 | Un vendeur dont les livraisons dérapent voit-il son activité reculer ? | Établir le mécanisme de destruction de valeur |
| SQ5 | Peut-on prédire le risque de retard au moment de la commande ? | Passer du constat à l'anticipation |
| SQ6 | Quel gain attendre d'une réduction des délais de X jours ? | Justifier l'investissement |

---

## 3. Objectifs

| # | Objectif | Sous-questions |
|---|---|---|
| O1 | **Mesurer** le taux de respect des délais annoncés et caractériser l'ampleur des écarts | SQ1 |
| O2 | **Décomposer** le délai total en trois segments (validation, préparation vendeur, acheminement) et identifier le segment où naît le retard | SQ2 |
| O3 | **Établir** le lien entre l'ampleur du retard et la dégradation de la satisfaction, et en déduire un seuil critique | SQ1 |
| O4 | **Quantifier** le chiffre d'affaires exposé à une rupture de promesse et sa concentration par vendeur, état et catégorie | SQ3 |
| O5 | **Tester** l'existence d'un lien entre la performance de livraison d'un vendeur et l'évolution de son activité | SQ4 |
| O6 | **Prédire** le risque de non-respect du délai à partir des seules informations disponibles au moment de la commande | SQ5 |
| O7 | **Estimer** le gain associé à différents scénarios d'amélioration des délais | SQ6 |

> **Objectif retiré en v2.** L'objectif initial *« quantifier la perte de valeur
> client associée aux retards »* est abandonné. Il supposait un comportement de
> réachat observable, ce que les données infirment. Il est remplacé par O4
> (exposition mesurée) et O5 (mécanisme au niveau vendeur).

---

## 4. Périmètre

### 4.1 Inclus

**Population de référence**

- Les **96 478 commandes au statut « delivered »**, pour lesquelles l'écart entre
  date estimée et date réelle est mesurable.
- Après exclusion des 8 commandes sans date de livraison réelle : **96 470
  commandes** constituent le périmètre d'analyse.

**Décomposition du délai**

Les quatre dates disponibles permettent de segmenter le parcours :

| Segment | Bornes | Ce qu'il mesure |
|---|---|---|
| Validation | achat → approbation | Traitement du paiement |
| **Préparation** | approbation → remise au transporteur | **Réactivité du vendeur** |
| **Acheminement** | remise au transporteur → livraison client | **Performance logistique** |

Seules 2 commandes livrées n'ont pas de date de remise au transporteur : la
décomposition est exploitable sur la quasi-totalité du périmètre.

**Granularité d'analyse**

- **Grain principal : la commande.** C'est l'unité à laquelle la promesse est
  formulée et à laquelle la satisfaction est mesurée.
- **Grain secondaire : le vendeur.** 3 095 vendeurs distincts, environ 32
  commandes en moyenne. Contrairement aux clients, les vendeurs disposent d'un
  historique permettant d'observer une trajectoire dans le temps.
- **Grain client : écarté** (cf. 4.3, H1).

> **Précision.** La note de satisfaction est rattachée à une commande et non à
> une personne. L'enquête mesure une expérience d'achat, pas une relation client
> globale. Le lien entre retard et satisfaction s'établit donc au grain commande.

**Périmètre géographique**

- Analyse au niveau de l'**état** (27 unités), et non de la ville.
  *Justification :* le niveau ville représente plusieurs milliers de modalités,
  non exploitable pour une recommandation opérationnelle. L'état constitue une
  maille pilotable, cohérente avec une organisation logistique régionale.
- Compte tenu de l'étendue du territoire brésilien, la distance est conservée
  comme variable explicative probable du délai.

**Périmètre temporel**

- La période couverte par le jeu de données. Les mois incomplets en début et fin
  de période seront écartés des analyses de tendance.

### 4.2 Exclu

| Exclusion | Justification |
|---|---|
| Analyse du comportement d'achat après un retard | Taux de réachat de 3,12 % ; aucune trajectoire client observable (cf. H1) |
| Commandes annulées, indisponibles ou non livrées | Exclues du **calcul du retard** : sans date de livraison réelle, l'écart n'est pas mesurable. Conservées comme population d'analyse distincte (cf. encadré) |
| Commandes multi-vendeurs pour l'analyse d'imputation | 1,3 % des commandes ; le retard ne peut être attribué à un vendeur identifié |
| Table de géolocalisation détaillée | Contient des doublons connus ; le niveau état suffit au périmètre retenu. Réexaminable si le calcul de distance est retenu comme variable prédictive |
| Analyse du contenu textuel des commentaires | Hors périmètre de la **v1** (traitement du langage naturel, verbatims en portugais), mais identifiée comme **extension prioritaire** : le texte est la seule source permettant de distinguer un mécontentement lié au retard d'un mécontentement lié au produit ou au vendeur. Il qualifie la cause, il ne mesure pas le délai |
| Comparaison inter-sectorielle ou multi-marketplaces | Aucune donnée externe disponible ; l'étude porte sur un périmètre interne |
| Coûts logistiques réels et marges | Absents du jeu de données. Le chiffrage portera sur le chiffre d'affaires, non sur la marge |

> **L'annulation, donnée manquante ou signal de rupture ?**
>
> Une commande annulée ne permet pas de mesurer un retard, mais elle peut en
> être une conséquence : un client déçu peut renoncer à une commande suivante.
>
> Deux limites empêchent d'exploiter cette piste :
> - **Aucune date d'annulation n'est enregistrée** dans le jeu de données (cf.
>   H6). Le délai entre la promesse rompue et le renoncement n'est donc pas
>   calculable.
> - **Le sens de la relation est ambigu.** Une annulation peut être à
>   l'initiative du vendeur, précisément parce que la commande allait être en
>   retard.
>
> Les commandes annulées sont conservées en base et décrites en volume, sans
> intégrer le calcul du taux de retard.

### 4.3 Résultats de la qualification

| # | Hypothèse | Résultat | Décision |
|---|---|---|---|
| H1 | Volume suffisant de clients multi-commandes | ❌ **3,12 %** (2 997 clients sur 96 096) | Analyse avant/après abandonnée ; chiffrage reporté au niveau vendeur |
| H2 | Dates estimée et réelle renseignées | ✅ **99,99 %** (8 valeurs manquantes sur 96 478) | Périmètre confirmé |
| H3 | Note de satisfaction disponible | ✅ **99,33 %** des commandes livrées | Lien retard-satisfaction mesurable sans biais de couverture |
| H5 | Commandes mono-vendeur majoritaires | ✅ **98,7 %** (97 388 commandes) | Imputation du retard au vendeur possible |
| H6 | Date d'annulation exploitable | ❌ **Champ inexistant** | Piste du délai de patience abandonnée |

**Points de vigilance identifiés en qualification**

- L'identifiant `customer_id` est propre à chaque commande ; seul
  `customer_unique_id` identifie une personne. Toute analyse de récurrence doit
  s'appuyer sur ce second identifiant.
- La table des avis comporte **99 224 lignes pour 98 673 commandes distinctes** :
  environ 550 commandes ont plusieurs évaluations. Une règle de sélection devra
  être définie (première, dernière, ou moyenne).
- La moyenne de 32 commandes par vendeur masque probablement une forte
  concentration. Les vendeurs à très faible volume ne permettront aucune
  conclusion individuelle : un seuil minimal de commandes devra être fixé pour
  l'analyse au grain vendeur.

---

## 5. Parties prenantes

| Partie prenante | Attente principale | Livrable prioritaire |
|---|---|---|
| Direction générale | Connaître l'exposition financière | Executive summary |
| Direction logistique | Savoir où agir, et sur quel segment du parcours | Décomposition du délai, cartographie des états |
| Direction des partenariats vendeurs | Identifier les vendeurs à accompagner | Classement des vendeurs par performance de livraison |
| Direction relation client | Anticiper les mécontentements | Score de risque de retard |

---

## 6. Contraintes et limites assumées

- **Impossibilité de mesurer la valeur vie client.** Avec un réachat de 3,12 %,
  aucun montant de perte future ne peut être calculé sur les données. Le
  chiffrage porte sur le **chiffre d'affaires exposé**, non sur une perte
  constatée. Cette distinction est maintenue dans l'ensemble des livrables.
- **Limite structurelle, non liée à la qualité des données.** Le faible réachat
  reflète le modèle d'intermédiation d'Olist et la nature des catégories
  vendues (ameublement, décoration, électroménager), sur un marché e-commerce
  brésilien encore émergent en 2016-2018. Sur une plateforme à achat récurrent,
  l'analyse de la fidélité serait pertinente ; elle ne l'est pas ici.
- **Biais de sélection des avis** : les clients qui répondent à l'enquête ne
  constituent pas un échantillon représentatif. Les expériences extrêmes y sont
  surreprésentées. Ce biais affecte la note comme le verbatim.
- **Causalité non démontrable** : l'étude établit des associations statistiques.
  Une corrélation entre retard et insatisfaction ne prouve pas à elle seule un
  lien de causalité ; les conclusions sont formulées en conséquence.
- **Absence de données de coûts** : le chiffrage porte sur le chiffre
  d'affaires, non sur la rentabilité.
- **Données historiques uniquement** : période close, sans actualisation.
- **Anonymisation à la source** : les identifiants de vendeurs et de partenaires
  ont été remplacés avant publication. Aucune donnée directement identifiante
  n'est manipulée.
- **Contexte national spécifique** : les résultats reflètent la réalité
  logistique brésilienne et ne sont pas directement transposables.

---

## 7. Analyse de sensibilité — traitement de la valeur client non mesurable

Le chiffrage de la perte de valeur client étant hors de portée des données, une
**analyse de sensibilité** est prévue en complément, clairement identifiée comme
telle et distincte des résultats mesurés.

**Principe.** Plutôt qu'un montant unique reposant sur une hypothèse implicite,
une fourchette est présentée, calculée à partir de plusieurs taux d'attrition
issus de la littérature sectorielle, chacun explicitement sourcé.

**Formulation retenue dans les livrables.**

> *Le jeu de données ne permet pas de mesurer l'impact du retard sur la fidélité.
> À titre illustratif, en appliquant des taux d'attrition observés dans la
> littérature sectorielle [source, année], l'exposition se situerait entre X et
> Y selon l'hypothèse retenue.*

**Règles à respecter.**

1. Aucun chiffre issu de cette analyse n'est présenté comme un résultat mesuré.
2. Chaque taux appliqué est sourcé et daté.
3. La fourchette est toujours présentée avec ses bornes, jamais réduite à une
   valeur centrale.
4. L'écart de contexte (secteur, pays, période) est mentionné.

Cette section illustre un scénario ; elle ne démontre rien. Sa fonction est de
donner un ordre de grandeur à un décideur, en assumant son caractère
hypothétique.

---

## 8. Critères de succès

La mission est considérée comme réussie si :

1. Un seuil de retard critique est identifié et documenté.
2. L'origine du retard est attribuée entre préparation vendeur et acheminement.
3. Le chiffre d'affaires exposé est quantifié, avec sa concentration.
4. Un modèle prédictif opérationnel est produit, évalué, et ses limites exposées.
5. Chaque recommandation est associée à un gain estimé et à un niveau d'effort.
6. Chaque limite méthodologique est explicitée plutôt que contournée.

---

## 9. Suivi des versions

| Version | Date | Modification |
|---|---|---|
| 1.0 | | Rédaction initiale, avant qualification des données |
| 2.0 | | Révision post-qualification : problématique recentrée après invalidation de H1 (réachat 3,12 %) ; ajout de la décomposition du délai (O2) et de l'analyse au grain vendeur (O5) ; ajout de la section d'analyse de sensibilité |