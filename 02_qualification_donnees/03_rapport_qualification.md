# Rapport de qualification des données

**Projet** : La Promesse Non Tenue — Olist
**Objet** : vérifier que le jeu de données permet de répondre à la
problématique, **avant** toute préparation ou analyse.

---

## Démarche

La note de cadrage v1 posait des hypothèses sur ce que la donnée devait
permettre. Chacune a été traduite en **contrôle chiffré**, puis validée ou
invalidée. Les hypothèses invalidées entraînent une révision du périmètre,
tracée dans la note de cadrage v2.

**Le principe** : on ne découvre pas qu'une analyse est impossible après trois
semaines de préparation. On le découvre avant.

> **Numérotation.** Les hypothèses testées sont H1, H2, H3, H5, H6, H7, H9, H11
> et H12. Les numéros manquants correspondent à des hypothèses de la v1
> abandonnées avant contrôle. H12 a été ajoutée en cours de qualification.

---

## Deux résultats structurants

> **1. Le taux de réachat client s'établit à 3,12 %.**
> L'analyse du comportement d'achat après un retard est abandonnée, et le
> chiffrage de la valeur reporté au grain vendeur. *(H1)*

> **2. 91,88 % des commandes sont livrées en avance, avec une marge médiane de
> 13 jours.**
> Constat non anticipé : les délais annoncés intègrent une marge de sécurité
> considérable. Une sous-question **SQ7** est ajoutée au cadrage. *(H12)*

Le premier a fait tomber l'objectif central de la v1. Le second a ouvert une
piste qui n'était pas prévue.

---

## Synthèse des hypothèses

| # | Hypothèse testée | Résultat | Verdict |
|---|---|---|---|
| H1 | Volume suffisant de clients multi-commandes | **3,12 %** — 2 997 clients sur 96 096 | ❌ Invalidée |
| H2 | Dates de livraison disponibles | **99,99 %** — 8 valeurs manquantes | ✅ Validée |
| H3 | Note de satisfaction disponible | **99,33 %** des commandes livrées | ✅ Validée |
| H5 | Commandes mono-vendeur majoritaires | **98,7 %** — 97 388 sur 98 666 | ✅ Validée |
| H6 | Date d'annulation exploitable | **Champ inexistant** | ❌ Invalidée |
| H7 | Cohérence chronologique des dates | **1 373 anomalies** (1 350 + 23) | ⚠️ Partiellement validée |
| H9 | Montant des commandes reconstituable | **99,75 %** de concordance | ✅ Validée |
| H11 | Historique suffisant par vendeur | Distribution très concentrée | ⚠️ Validée sous condition |
| H12 | Volume de retards suffisant | **6,77 %** — 6 534 commandes | ✅ Validée |

---

## H1 — Le réachat client

**Hypothèse.** Un nombre significatif de clients a passé plusieurs commandes,
permettant d'observer l'évolution du comportement d'achat après un retard.

**Contrôle.** Nombre de `customer_unique_id` associés à plus d'une commande.

**Résultat.** 96 096 clients uniques, dont **2 997 avec plusieurs commandes
(3,12 %)**. 93 099 clients n'ont passé qu'une seule commande.

**Verdict.** ❌ **Invalidée.**

**Conséquences sur le cadrage.**

L'objectif initial — *« quantifier la perte de valeur client associée aux
retards »* — est abandonné. Aucune trajectoire client n'étant observable,
l'effet d'un retard sur les achats ultérieurs ne peut être établi.

Deux objectifs le remplacent :
- **O4** — quantifier le **chiffre d'affaires exposé** (mesure, pas perte)
- **O5** — tester le lien performance / activité **au grain vendeur**, qui
  dispose lui d'un historique

> **Limite structurelle, non défaut de qualité.** Ce faible réachat reflète le
> modèle d'intermédiation d'Olist et la nature des catégories vendues
> (ameublement, décoration, électroménager), sur un marché e-commerce brésilien
> encore émergent en 2016-2018. Sur une plateforme à achat récurrent, l'analyse
> de la fidélité serait pertinente ; elle ne l'est pas ici.

> ⚠️ **Piège d'identifiant, signalé avant le contrôle.** `customer_id` change à
> chaque commande : une même personne ayant commandé trois fois apparaît avec
> trois `customer_id` différents. Seul `customer_unique_id` identifie une
> personne. Un contrôle mené sur le mauvais champ aurait conclu à **0 %** de
> réachat.

---

## H2 — Les dates de livraison

**Hypothèse.** Les dates de livraison estimée et réelle sont renseignées sur la
majorité des commandes livrées.

**Contrôle.** Taux de valeurs manquantes sur les commandes au statut
`delivered`.

**Résultat.** 96 478 commandes livrées :
- **8** sans date de livraison réelle
- **0** sans date estimée
- **2** sans date de remise au transporteur

**Verdict.** ✅ **Validée** — couverture de 99,99 %.

**Conséquences.** Les 8 commandes fondent la règle **RG-01** : le périmètre
passe de 96 478 à **96 470**. La décomposition du délai en trois segments est
exploitable sur la quasi-totalité du périmètre.

---

## H3 — La couverture des avis

**Hypothèse.** Une part importante des commandes livrées dispose d'une note de
satisfaction.

**Contrôle.** Couverture des avis sur les commandes livrées.

**Résultat.** **99,33 %** des commandes livrées disposent d'un avis.
La table compte **99 224 lignes pour 98 673 commandes distinctes** : environ
550 commandes ont plusieurs évaluations.

**Verdict.** ✅ **Validée.**

**Conséquences.**
- Les commandes sans avis fondent la règle **RG-07** : exclusion **ciblée** des
  seules analyses de satisfaction.
- Les commandes à évaluations multiples imposent une **règle de sélection**
  (devenue RG-06).

> ⚠️ **Le biais de sélection subsiste.** Une couverture élevée ne garantit pas
> la représentativité. Les clients qui répondent à une enquête ne constituent
> pas un échantillon neutre : les expériences extrêmes y sont surreprésentées.
> Ce biais affecte la note comme le verbatim, et doit être rappelé dans les
> livrables.

---

## H5 — L'attribution du retard à un vendeur

**Hypothèse.** La majorité des commandes ne comporte qu'un seul vendeur,
permettant d'attribuer un retard à un responsable identifié.

**Contrôle.** Distribution du nombre de vendeurs distincts par commande.

**Résultat.** **98,7 %** des commandes sont mono-vendeur (97 388 sur 98 666).
3 095 vendeurs distincts.

**Verdict.** ✅ **Validée.**

**Conséquences.** Les 1,3 % de commandes multi-vendeurs fondent la règle
**RG-09** : exclusion des seules analyses d'imputation. Le jeu de données ne
comportant qu'une date de livraison par commande, il est impossible de
déterminer lequel des vendeurs est à l'origine du retard.

---

## H6 — Le délai de patience

**Hypothèse.** Une date d'annulation permettrait de mesurer le délai entre une
promesse rompue et le renoncement du client.

**Résultat.** **Le champ n'existe pas** dans le jeu de données.

**Verdict.** ❌ **Invalidée.**

**Conséquences.** La piste du délai de patience est abandonnée.

> **Une seconde limite s'ajoute à l'absence de date.** Le sens de la relation
> serait de toute façon ambigu : une annulation peut être à l'initiative du
> **vendeur**, précisément parce que la commande allait être en retard. Même
> datée, cette variable aurait été difficile à interpréter.

Les commandes annulées sont conservées en base et décrites en volume, sans
entrer dans le calcul du taux de retard.

---

## H7 — La cohérence chronologique

**Hypothèse.** Les dates respectent l'ordre logique du parcours :
achat ≤ approbation ≤ remise transporteur ≤ livraison.

**Contrôle.** Comptage des violations à chaque étape.

**Résultat.**

| Violation testée | Volume |
|---|---|
| Approbation antérieure à l'achat | **0** |
| Remise au transporteur antérieure à l'approbation | **1 350** (1,4 %) |
| Livraison antérieure à la remise au transporteur | **23** |

**Verdict.** ⚠️ **Partiellement validée** — 1 373 anomalies, deux traitements
distincts requis.

**Conséquences.**

- Les 23 commandes chronologiquement impossibles relèvent d'une erreur de
  saisie : **exclusion générale** (règle **RG-03**).
- Les 1 350 expéditions avant validation sont plausibles — un vendeur peut
  expédier sans attendre la confirmation, ou l'enregistrement du paiement peut
  être décalé. **Exclusion ciblée** du seul segment « préparation vendeur »
  (règle **RG-04**), où elles produiraient une durée négative.

> ⚠️ **Chiffre à relativiser.** Les 1 350 sont mesurées **tous statuts
> confondus**. Sur le seul périmètre des commandes livrées, la préparation des
> données a établi qu'elles ne sont que **674**. Voir section « Corrections ».

---

## H9 — La reconstitution du montant

**Hypothèse.** Le montant d'une commande est reconstituable de manière fiable.

**Contrôle.** Écart entre la somme des articles (`price + freight_value`) et la
somme des paiements enregistrés (`payment_value`).

**Résultat.** Médiane et 75ᵉ centile de l'écart à **zéro**. **249 commandes**
présentent un écart supérieur à 1 R$, soit 0,25 % du périmètre.

**Verdict.** ✅ **Validée** — 99,75 % de concordance.

**Conséquences.** Les deux sources mesurent bien la même chose, ce qui permet
d'en choisir une comme référence et d'utiliser l'autre en contre-mesure.

> **Choix révisé depuis.** La v1 des règles retenait `order_items` comme source
> de référence. La préparation a inversé ce choix au profit de
> `order_payments` : **le chiffre d'affaires est l'argent qui entre**, non la
> valeur théorique du panier. Voir RG-11 v2.

---

## H11 — L'historique par vendeur

**Hypothèse.** Les vendeurs disposent d'un volume de commandes permettant
d'observer une trajectoire dans le temps.

**Contrôle.** Distribution du nombre de commandes par vendeur, et part du
volume total couverte selon différents seuils.

**Résultat.** Distribution **très concentrée** :
- moyenne de **32 commandes** pour une médiane de **6**
- maximum à **1 854**
- un quart des vendeurs a **2 commandes ou moins**

Avec un seuil de 10 commandes minimum : **1 271 vendeurs** retenus, couvrant
**93,9 %** du volume total.

**Verdict.** ⚠️ **Validée sous condition.**

**Conséquences.** Un seuil de 10 commandes est retenu comme règle de gestion
(**RG-08**) : il élimine les vendeurs non analysables tout en préservant 93,9 %
de l'activité.

> **Pourquoi la moyenne ne suffisait pas.** Une moyenne de 32 commandes par
> vendeur pouvait laisser croire à un historique confortable. La médiane de 6
> révèle l'inverse : la moyenne est tirée par quelques vendeurs très actifs.
> C'est le décalage entre les deux qui a motivé la règle.

---

## H12 — La viabilité du volume de retards

**Hypothèse.** Le nombre de commandes en retard est suffisant pour permettre les
découpages prévus (par état, par vendeur, par tranche de gravité).

**Contrôle.** Application de RG-02 (retard en jours calendaires, heures
ignorées) et comptage.

**Enjeu.** Un volume trop faible rendrait les analyses segmentées impossibles et
**remettrait en cause le projet**.

**Résultat.** **6 534 commandes en retard, soit 6,77 %** des commandes livrées.
Volume suffisant pour l'ensemble des découpages prévus.

**Verdict.** ✅ **Validée** — le projet est viable.

### Le constat inattendu

> **91,88 % des commandes sont livrées en avance, avec une marge médiane de
> 13 jours.**

Les dates annoncées aux clients intègrent donc une **marge de sécurité
considérable**. Olist ne promet pas serré : elle promet large.

**Conséquence sur le cadrage.** Ce constat ouvre une question non prévue
initialement. Une promesse aussi large a un **coût commercial** — un client peut
renoncer à un achat annoncé en trois semaines — et son non-respect n'en est que
**plus significatif**.

> **Sous-question SQ7 ajoutée** : *les délais annoncés sont-ils correctement
> calibrés, et quel serait l'effet d'un resserrement ?*

Cette sous-question motive la métrique **M-16** (marge sur les délais annoncés)
et un scénario symétrique dans le simulateur (M-13).

---

## Contrôles complémentaires

### Couverture de la table de traduction

**Résultat.** **73 catégories** dans `products`, **71 traduites**. Deux
catégories sans correspondance.

**Conséquence.** Jointure `LEFT` avec conservation du nom portugais par défaut.

### Les avis multiples

**Résultat.** **547 commandes** disposent de plusieurs avis, dont **202 avec des
notes divergentes** (0,2 % du périmètre).

**Règle retenue (RG-06).** En cas d'avis multiples, la note retenue est la
**moyenne arrondie à l'entier inférieur**. *Justification : une insatisfaction
exprimée ne doit pas être effacée par lissage, dans une étude portant
précisément sur le mécontentement.*

---

## Points de vigilance identifiés

Ces constats n'invalident aucune hypothèse mais conditionnent la préparation.

**Le piège des identifiants client.** `customer_id` est propre à **chaque
commande** ; seul `customer_unique_id` identifie une personne.

**La table de géolocalisation.** Un même préfixe de code postal apparaît des
dizaines de fois avec des coordonnées légèrement différentes. Une jointure
directe multiplierait chaque commande par le nombre de points relevés dans sa
zone. **Agrégation préalable obligatoire.**

**Les dates chargées en texte.** `read_csv` charge les colonnes de dates comme
du texte. Sans conversion explicite, aucune soustraction ni comparaison n'est
fiable.

---

## Corrections apportées par la préparation des données

La phase suivante a **vérifié** chacun de ces chiffres sur le périmètre final.
Plusieurs ont dû être corrigés — non par erreur de méthode, mais parce qu'ils
étaient mesurés sur une population plus large.

| Élément | Qualification | Vérifié | Explication |
|---|---|---|---|
| Périmètre d'analyse | 96 470 | **96 447** | Application de RG-03 (−23) |
| RG-04 — expédition avant validation | 1 350 | **674** | Chiffre initial mesuré **tous statuts** ; sur le seul périmètre livré, la moitié disparaît |
| Commandes sans date transporteur | 2 | **1** | L'une des deux écartée par RG-03 |
| Commandes sans avis | ≈ 640 | **646** | Chiffre exact |
| Commandes multi-avis | 547 | **547** | Confirmé |
| Vendeurs retenus (RG-08) | 1 271 | **1 217** | Mesuré sur le périmètre final (commandes livrées et mono-vendeur, RG-09) |
| Concordance des montants (H9) | 99,75 % | **99,69 %** | Écart maximal : **0,02 R$** — arrondis |

### Ce qui se confirme exactement

> **H12 avait mesuré 6,77 % de commandes en retard. La chaîne PostgreSQL
> complète retrouve 6,77 % — 6 534 commandes sur 96 447.**

Deux outils différents (pandas puis SQL), deux méthodes de calcul indépendantes,
le même résultat. C'est la meilleure validation possible du pipeline.

De même, le constat de la marge se confirme : H12 annonçait 91,88 % de
livraisons en avance avec une médiane de 13 jours ; la préparation établit que
**87 % des commandes arrivent avec quatre jours d'avance ou plus**, avec un pic
à **−14 jours**.

### Anomalies non détectées en qualification

La préparation a mis au jour trois éléments que les contrôles H1-H12 n'avaient
pas relevés :

**789 `review_id` dupliqués.** Un même identifiant d'avis rattaché à plusieurs
commandes, avec note et dates identiques à la seconde près — vraisemblablement
une enquête unique pour deux commandes livrées ensemble. *Sans impact : la
jointure s'effectue sur `order_id`.*

**4 produits au poids déclaré à 0 g.** Quatre déclinaisons d'un même article,
dimensions renseignées, poids à zéro. Le zéro **code une saisie manquante**. Ces
valeurs sont converties en `NULL` : une information absente vaut mieux qu'une
information fausse, qui biaiserait les moyennes et tromperait le modèle
prédictif.

**14 commandes livrées sans date d'approbation.** Leur segment « validation »
est incalculable. H2 avait contrôlé les dates de livraison, pas celle
d'approbation.

> **Ce que cela dit de la méthode.** La qualification a rempli sa fonction —
> écarter une analyse impossible avant d'y investir des semaines. Mais elle ne
> peut pas tout voir : certains problèmes n'apparaissent qu'au moment de
> manipuler réellement les données. **Les deux phases sont complémentaires, pas
> redondantes.**

---

## Conclusion

**Le jeu de données permet de répondre à la problématique reformulée.**

| Objectif | Faisable ? | Hypothèse fondatrice |
|---|---|---|
| O1 — Mesurer le taux de respect des délais | ✅ | H2, H12 |
| O2 — Décomposer le délai en segments | ✅ | H7, sous réserve de RG-03 et RG-04 |
| O3 — Lien retard / satisfaction | ✅ | H3 |
| O4 — Quantifier le CA exposé | ✅ | H9 |
| O5 — Trajectoire vendeur | ✅ | H5, H11 |
| O6 — Prédire le risque de retard | ✅ | H12 (volume suffisant) |
| O7 — Simuler des scénarios | ✅ | H12 (SQ7) |
| ~~Perte de valeur client~~ | ❌ | **H1 — abandonné** |

**Une seule analyse est écartée**, et elle l'est pour une raison structurelle
tenant au modèle économique d'Olist, non à un défaut de qualité des données.

**Une piste est ouverte** qui n'était pas prévue : le calibrage des délais
annoncés (SQ7), révélé par la marge médiane de 13 jours.

Le périmètre révisé et les règles de gestion qui en découlent sont consignés
dans la note de cadrage v2 et le fichier `02_regles_et_metriques.md`.

---

## Suivi des versions

| Version | Date | Modification |
|---|---|---|
| 1.0 | | Rédaction initiale — contrôles H1 à H12 |
| 1.1 | | Ajout de la section « Corrections apportées par la préparation » : chiffres revérifiés sur le périmètre final, confirmation croisée du taux de retard, anomalies découvertes en préparation |
