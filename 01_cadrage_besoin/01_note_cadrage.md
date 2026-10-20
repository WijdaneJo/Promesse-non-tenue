# Note de cadrage : La Promesse Non Tenue

**Version 3.2 : déclencheur ancré dans les données**
*Remplace les versions 3.1 (post-préparation), 2.0 (post-qualification) et 1.0 (avant accès aux données).*

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

**En mars 2018, le taux de retard d'Olist passe de moins de 5 % à 18,96 %, et la
note de satisfaction tombe à 3,81, son plus bas niveau.** Le même décrochage
s'était produit au Black Friday de novembre 2017.

**Le paradoxe :** Olist promet large (91,88 % des commandes arrivent en avance)
et rompt pourtant sa promesse une fois sur quinze.

La direction ne sait pas **où naissent ces ruptures, quel volume d'activité
elles exposent, sur quels leviers agir, ni si elle peut les anticiper.**

> **Cadre du projet.** Projet personnel réalisé sur le jeu de données public
> Olist (Kaggle, commandes 2016-2018, anonymisées à la source). La « direction »
> est un commanditaire fictif, utilisé pour cadrer la démarche comme une mission
> réelle ; **tous les chiffres cités sont issus des données.**

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
| **SQ7** | **Les délais annoncés sont-ils correctement calibrés, et quel serait l'effet d'un resserrement ?** | **Arbitrer entre attractivité commerciale et risque de rupture** |

> **SQ7 : origine et statut.** Cette sous-question n'était pas prévue au
> cadrage initial. Elle a été **ouverte par la qualification** (H12) et
> **confirmée par la préparation** : 91,88 % des commandes sont livrées en
> avance, avec une marge médiane de **13 jours**.
>
> Olist ne promet pas serré : elle promet large. Ce constat inverse la lecture
> du problème. Une promesse aussi prudente a un **coût commercial**, un client
> peut renoncer à un achat annoncé en trois semaines, et son non-respect n'en
> est que **plus significatif**.

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
| O7 | **Estimer** le gain associé à différents scénarios d'amélioration des délais **réels** | SQ6 |
| **O8** | **Évaluer** le calibrage des délais **annoncés** et simuler l'effet d'un resserrement | **SQ7** |

> **Pourquoi O7 et O8 sont distincts.** Ils portent sur deux leviers **opposés**,
> relevant de deux directions différentes :
>
> | | O7 | O8 |
> |---|---|---|
> | Levier | Raccourcir le délai **réel** | Raccourcir le délai **annoncé** |
> | Nature | Opérationnelle | Commerciale |
> | Direction | Logistique | Marketing / Direction générale |
> | Effet sur le taux de retard | Le **réduit** | L'**augmente** mécaniquement |
>
> Les mener ensemble permet de poser l'arbitrage complet : **de combien peut-on
> resserrer la promesse sans dégrader la tenue ?** C'est la conjonction des deux
> qui produit une recommandation, non l'un ou l'autre isolément.

> **Objectif retiré en v2.** L'objectif initial *« quantifier la perte de valeur
> client associée aux retards »* est abandonné. Il supposait un comportement de
> réachat observable, ce que les données infirment. Il est remplacé par O4
> (exposition mesurée) et O5 (mécanisme au niveau vendeur).

---

## 4. Périmètre

### 4.1 Inclus

**Population de référence**

Le périmètre a été construit en v3 par application effective des règles de
gestion. Le décompte final est le suivant :

```
Commandes au statut « delivered »                    96 478
RG-01 : sans date de livraison réelle                    −8
                                                   ---------
                                                     96 470
RG-03 : chronologie impossible                          −23
                                                   ---------
PÉRIMÈTRE D'ANALYSE                                  96 447
```

> **Évolution v2 -> v3.** La v2 arrêtait le périmètre à 96 470 commandes.
> L'application de RG-03 (livraison antérieure à la remise au transporteur,
> physiquement impossible) en retire 23 supplémentaires. **Le périmètre
> définitif est de 96 447 commandes.**

**Décomposition du délai**

Les quatre dates disponibles permettent de segmenter le parcours :

| Segment | Bornes | Ce qu'il mesure |
|---|---|---|
| Validation | achat -> approbation | Traitement du paiement |
| **Préparation** | approbation -> remise au transporteur | **Réactivité du vendeur** |
| **Acheminement** | remise au transporteur -> livraison client | **Performance logistique** |

Le segment « préparation » n'est pas calculable sur **689 commandes** (0,71 % du
périmètre) : 674 relèvent de RG-04, 14 n'ont pas de date d'approbation et 1 n'a
pas de date de remise au transporteur. Ces commandes restent au périmètre : seul
ce segment est neutralisé.

**Granularité d'analyse**

- **Grain principal : la commande.** C'est l'unité à laquelle la promesse est
  formulée et à laquelle la satisfaction est mesurée. Table `mart.orders`,
  96 447 lignes.
- **Grain secondaire : le vendeur.** Table `mart.sellers`, **1 217 vendeurs**
  après application de RG-08 (seuil de 10 commandes) et RG-09 (mono-vendeur).
  Contrairement aux clients, les vendeurs disposent d'un historique permettant
  d'observer une trajectoire dans le temps.
- **Grain client : écarté** (cf. 4.3, H1).

> **Précision.** La note de satisfaction est rattachée à une commande et non à
> une personne. L'enquête mesure une expérience d'achat, pas une relation client
> globale. Le lien entre retard et satisfaction s'établit donc au grain commande.

**Périmètre géographique**

- Analyse au niveau de l'**état** (27 unités), et non de la ville.
  *Justification :* le niveau ville représente plusieurs milliers de modalités,
  non exploitable pour une recommandation opérationnelle. L'état constitue une
  maille pilotable, cohérente avec une organisation logistique régionale.
- La **distance vendeur -> client** est retenue comme variable explicative et
  calculée (formule de Haversine). Distribution obtenue : médiane 434 km,
  moyenne 601 km, maximum 8 678 km. Elle n'est pas calculable sur 476 commandes
  (0,49 %), dont un code postal est absent de la table de géolocalisation.

**Périmètre temporel**

- La période couverte par le jeu de données. Les mois incomplets en début et fin
  de période seront écartés des analyses de tendance.

### 4.2 Exclu

| Exclusion | Justification |
|---|---|
| Analyse du comportement d'achat après un retard | Taux de réachat de 3,12 % ; aucune trajectoire client observable (cf. H1) |
| Commandes annulées, indisponibles ou non livrées | Exclues du **calcul du retard** : sans date de livraison réelle, l'écart n'est pas mesurable. Conservées comme population d'analyse distincte (cf. encadré) |
| Commandes chronologiquement impossibles | 23 commandes livrées avant remise au transporteur (RG-03). Erreur de saisie manifeste |
| Commandes multi-vendeurs pour l'analyse d'imputation | 1,3 % des commandes ; le retard ne peut être attribué à un vendeur identifié (RG-09) |
| Vendeurs à faible volume | Seuil de 10 commandes (RG-08). Écarte 59 % des vendeurs mais seulement 6,2 % de l'activité |
| Analyse du contenu textuel des commentaires | Hors périmètre de la **v1** (traitement du langage naturel, verbatims en portugais), mais identifiée comme **extension prioritaire** : le texte est la seule source permettant de distinguer un mécontentement lié au retard d'un mécontentement lié au produit ou au vendeur. Il qualifie la cause, il ne mesure pas le délai |
| Comparaison inter-sectorielle ou multi-marketplaces | Aucune donnée externe disponible ; l'étude porte sur un périmètre interne |
| Coûts logistiques réels et marges | Absents du jeu de données. Le chiffrage portera sur le chiffre d'affaires, non sur la marge |

> **Révision v3 : table de géolocalisation.** La v2 écartait cette table, jugée
> inexploitable en raison de ses doublons, tout en réservant sa réintégration
> *« si le calcul de distance est retenu comme variable prédictive »*. Elle est
> **réintégrée** : l'agrégation par préfixe de code postal (moyenne des
> coordonnées) neutralise les doublons et rend la distance calculable sur
> 99,5 % du périmètre.

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
| H1 | Volume suffisant de clients multi-commandes | **3,12 %** (2 997 clients sur 96 096) | Analyse avant/après abandonnée ; chiffrage reporté au niveau vendeur |
| H2 | Dates estimée et réelle renseignées | **99,99 %** (8 valeurs manquantes sur 96 478) | Périmètre confirmé |
| H3 | Note de satisfaction disponible | **99,33 %** des commandes livrées | Lien retard-satisfaction mesurable sans biais de couverture |
| H5 | Commandes mono-vendeur majoritaires | **98,7 %** (97 388 commandes) | Imputation du retard au vendeur possible |
| H6 | Date d'annulation exploitable | **Champ inexistant** | Piste du délai de patience abandonnée |
| H7 | Cohérence chronologique des dates | **1 373 anomalies** (1 350 + 23) | Deux règles de gestion : RG-03 et RG-04 |
| H9 | Concordance des montants entre sources | **99,69 %** revalidé sur le périmètre | 299 écarts sur 96 447, maximum 0,02 R$ (arrondis) |
| H11 | Historique suffisant par vendeur | Distribution très concentrée : médiane de 6 commandes | Seuil de 10 commandes retenu (RG-08) |
| H12 | Volume de retards suffisant | **6,77 %** (6 534 commandes) | Projet viable ; **SQ7 ouverte** |

*Les hypothèses H4, H8 et H10 de la v1 ont été abandonnées avant contrôle.*

### 4.4 Corrections apportées par la préparation des données

La phase de préparation a **corrigé plusieurs chiffres** de la qualification et
mis au jour des anomalies non détectées. Ces écarts ne remettent pas en cause le
périmètre mais doivent être connus.

| Élément | Annoncé en v2 | Vérifié en v3 | Explication |
|---|---|---|---|
| Périmètre d'analyse | 96 470 | **96 447** | Application de RG-03 (−23) |
| RG-04 : expédition avant validation | 1 350 | **674** | Le chiffre v2 portait sur les 99 441 commandes **tous statuts**. Sur le seul périmètre livré, elles sont 674 |
| Commandes sans date transporteur | 2 | **1** | L'une des deux a été écartée par RG-03 |
| Commandes sans avis (RG-07) | ≈ 640 | **646** | Chiffre exact |
| Vendeurs retenus (RG-08) | 1 271 | **1 217** | Mesuré sur le périmètre final (commandes livrées et mono-vendeur, RG-09). Un premier comptage à 1 323 portait sur toutes les commandes, tous statuts confondus |

**Ce qui se confirme exactement**

> H12 avait mesuré **6,77 %** de commandes en retard en pandas. La chaîne
> PostgreSQL complète retrouve **6,77 %** : 6 534 commandes sur 96 447.
> Deux outils, deux méthodes indépendantes, le même résultat.

**Anomalies non détectées en qualification**

- **789 `review_id` sont dupliqués** : un même identifiant d'avis rattaché à
  plusieurs commandes, avec note et dates identiques. Il s'agit vraisemblablement
  d'une enquête unique couvrant deux commandes livrées ensemble. *Sans impact :
  la jointure vers les commandes s'effectue sur `order_id`.*
- **4 produits ont un poids déclaré à 0 g** : le zéro y code une saisie
  manquante, non un poids réel. Ces valeurs sont converties en `NULL` : une
  absence honnête vaut mieux qu'une valeur fausse qui biaiserait les moyennes et
  tromperait le modèle prédictif.
- **14 commandes livrées n'ont pas de date d'approbation** : leur segment
  « validation » est incalculable.
- **476 commandes n'ont pas de distance calculable** : code postal absent de la
  table de géolocalisation.

**Points de vigilance confirmés**

- L'identifiant `customer_id` est propre à chaque commande ; seul
  `customer_unique_id` identifie une personne. Le périmètre compte 96 447
  commandes pour 96 447 `customer_id` : confirmation directe du piège.
- La concentration de l'activité vendeur, anticipée par H11, est vérifiée : 493
  vendeurs n'ont qu'une seule commande, tandis que le plus actif en compte 1 960.

---

## 5. Parties prenantes

| Partie prenante | Attente principale | Livrable prioritaire |
|---|---|---|
| Direction générale | Connaître l'exposition financière **et arbitrer le calibrage de la promesse** | Executive summary |
| Direction logistique | Savoir où agir, et sur quel segment du parcours | Décomposition du délai, cartographie des états |
| Direction des partenariats vendeurs | Identifier les vendeurs à accompagner | Classement des vendeurs par performance de livraison |
| Direction relation client | Anticiper les mécontentements | Score de risque de retard |
| **Direction marketing** | **Savoir de combien la promesse peut être resserrée sans dégrader la tenue** | **Scénarios de recalibrage (O8)** |

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
- **Le coût commercial d'une promesse large n'est pas mesurable.** SQ7 repose
  sur l'hypothèse qu'un délai annoncé long décourage l'achat. Le jeu de données
  ne contient **aucune trace des visiteurs n'ayant pas commandé** : cet effet ne
  peut être quantifié, seulement postulé. Les scénarios de O8 mesurent donc
  l'effet d'un resserrement **sur le taux de retard**, jamais sur les ventes.
  *(limite identifiée en v3.1)*
- **Commandes multi-vendeurs : expéditions indistinguables.** Le jeu de données
  ne fournit qu'une seule date de livraison par commande, même lorsque deux
  vendeurs ont expédié séparément. La distance retenue pour ces commandes est la
  plus longue, faute de pouvoir distinguer les colis. *(limite identifiée en v3)*
- **Retard mesuré en jours calendaires.** La promesse d'Olist porte sur une date,
  non sur un horaire : une livraison le jour promis à 23 h ne constitue pas un
  retard. En contrepartie, une livraison le lendemain à 0 h 30 compte pour un
  jour entier. *(convention retenue en v3)*
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

## 7. Analyse de sensibilité : traitement de la valeur client non mesurable

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

**La même règle s'applique à O8.** Le coût commercial d'une promesse large
n'étant pas mesurable, tout chiffrage de ce côté relève de la même catégorie :
un scénario sourcé, jamais un résultat.

---

## 8. Premiers résultats issus de la préparation

Ces chiffres sont produits par la construction des tables analytiques. Ils
servent d'ancrage à l'analyse et n'en constituent pas les conclusions.

| Indicateur | Valeur |
|---|---|
| Taux de commandes en retard (M-00) | **6,77 %** : 6 534 sur 96 447 |
| Chiffre d'affaires du périmètre | **15 416 546 R$** |
| Note moyenne de satisfaction | 4,16 / 5 |
| Distance médiane vendeur -> client | 434 km |
| Commandes livrées avec ≥ 4 jours d'avance | **87 %** |

**Deux constats orientent d'emblée l'analyse.**

**Une commande sur quinze rompt la promesse.** Le volume est significatif, mais
6,77 % des commandes ne signifie pas 6,77 % du chiffre d'affaires : si les
retards touchent des commandes plus chères, l'exposition financière est
supérieure. C'est précisément l'objet de O4.

**La promesse est très largement surdimensionnée.** 87 % des commandes arrivent
avec quatre jours d'avance ou plus, avec un pic à quatorze jours. Olist annonce
des délais conservateurs qui la protègent. Ce constat, ouvert par H12 et
confirmé ici, fonde **SQ7 et O8** : de combien la promesse peut-elle être
resserrée sans dégrader sa tenue ?

---

## 9. Critères de succès

La mission est considérée comme réussie si :

1. Un seuil de retard critique est identifié et documenté.
2. L'origine du retard est attribuée entre préparation vendeur et acheminement.
3. Le chiffre d'affaires exposé est quantifié, avec sa concentration.
4. Un modèle prédictif opérationnel est produit, évalué, et ses limites exposées.
5. **Un arbitrage chiffré est proposé sur le calibrage des délais annoncés.**
6. Chaque recommandation est associée à un gain estimé et à un niveau d'effort.
7. Chaque limite méthodologique est explicitée plutôt que contournée.

---

## 10. Suivi des versions

| Version | Date | Modification |
|---|---|---|
| 1.0 | | Rédaction initiale, avant qualification des données |
| 2.0 | | Révision post-qualification : problématique recentrée après invalidation de H1 (réachat 3,12 %) ; ajout de la décomposition du délai (O2) et de l'analyse au grain vendeur (O5) ; ajout de la section d'analyse de sensibilité |
| 3.0 | | Révision post-préparation : périmètre définitif arrêté à 96 447 commandes après application de RG-03 ; correction du volume RG-04 (674 et non 1 350) ; réintégration de la table de géolocalisation et calcul de la distance ; ajout de la section 4.4 (corrections et anomalies) ; ajout de la section 8 (premiers résultats) ; ajout de deux limites assumées (expéditions indistinguables, jours calendaires) |
| 3.1 | | Intégration de **SQ7** et de l'objectif **O8** (calibrage des délais annoncés), ouverts par H12 et confirmés par la préparation. Ajout de H11 et H12 au tableau 4.3. Ajout de la direction marketing aux parties prenantes. Ajout d'une limite assumée sur le coût commercial non mesurable. Critères de succès portés à 7. |
| 3.2 | | Réécriture du **déclencheur de la mission** : la « dégradation des notes » et la « pression concurrentielle », non vérifiées, sont remplacées par un constat mesuré (note moyenne mensuelle : 3,81 en mars 2018 contre ~4,2 en 2017, en miroir des pics de retard). Ajout d'un encadré précisant le cadre du projet (commanditaire fictif, chiffres réels). |