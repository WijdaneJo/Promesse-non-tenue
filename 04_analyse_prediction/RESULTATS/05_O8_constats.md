# O8. Constats : le calibrage de la promesse

> Ce document traduit les résultats de `SQL/05_O8_calibrage_de_promesse.sql`
> en énoncés utilisables.
>
> Structure de chaque constat : le fait, ce qu'il signifie, ce qu'il implique.

**Métriques.** M-16 (marge sur les délais annoncés), M-17 (taux de retard
simulé selon un resserrement de la promesse).

**Définition de la marge.** Pour une commande livrée en avance, nombre de jours
entre la livraison réelle et la date promise. Les commandes en retard n'ont pas
de marge : elles l'ont dépassée. Elles sont donc exclues du calcul de la marge,
mais pas des simulations.

**Origine de l'objectif.** O8 n'était pas prévu au cadrage initial. Il a été
ouvert par la qualification (H12) : 91,88 % des commandes arrivent en avance.
La question posée est un arbitrage commercial : une promesse plus courte est
plus attractive, mais elle crée mécaniquement des retards.

---

# 1. Sur l'année, la marge est de 13 jours, et elle est uniforme

## Le fait

| Année | Commandes en avance | Marge médiane |
|---|---|---|
| 2016 | 259 | 39 j (non exploitable) |
| 2017 | 40 529 | **13 j** |
| 2018 | 47 833 | **13 j** |

Par état de destination, la marge va de **12 jours (SP) à 17 jours (PA)** pour
tous les états à volume significatif. Seuls les cinq états amazoniens (RR, AC,
AP, RO, AM) dépassent 19 jours, avec moins de 240 commandes chacun.

## Ce que cela signifie

Olist calibre sa promesse sur la distance (O1) : 46 jours à 2 700 km, 19 jours
à 166 km. Résultat, le coussin restant est le même partout. Le taux de retard
varie de 1 à 4 entre les grands états, mais la marge ne varie que de 5 jours.

## Ce que cela implique

**Un resserrement différencié par état n'a pas de sens.** Une règle nationale
suffit. La métrique M-17 prévoyait au contraire un recalibrage par état : c'est
la donnée qui a tranché, pas l'intuition de départ.

---

# 2. La médiane annuelle masque l'été 2018

## Le fait

| Mois 2018 | Commandes | Promesse médiane | Délai réel médian | Marge médiane | Taux de retard |
|---|---|---|---|---|---|
| Janvier | 7 069 | 26 j | 12 j | 14 j | 5,70 % |
| Février | 6 555 | 25 j | 14 j | 12 j | 14,13 % |
| Mars | 7 003 | 22 j | 13 j | 9 j | 18,96 % |
| Avril | 6 798 | 24 j | 9 j | 14 j | 4,50 % |
| Mai | 6 749 | 22 j | 9 j | 13 j | 6,56 % |
| Juin | 6 096 | 28 j | 8 j | **20 j** | **1,16 %** |
| Juillet | 6 156 | 20 j | 7 j | 11 j | 3,38 % |
| Août | 6 351 | **14 j** | 7 j | **7 j** | **6,19 %** |

## Ce que cela signifie

**En août 2018, la marge n'est plus que de 7 jours**, contre 13 en médiane
annuelle et 20 en juin. Elle a été divisée par trois en deux mois.

Le chiffre annuel de 13 jours était exact, mais il mélangeait des mois à
promesse longue (janvier à juin) et un mois à promesse courte (août). Une
politique qui change en cours d'année ne se lit pas dans une médiane annuelle.

Le taux de retard suit la marge : 1,16 % en juin avec 20 jours de marge,
6,19 % en août avec 7 jours. O6 l'a vérifié à l'intérieur du seul mois d'août :
les commandes promises en 14 jours ou moins ont 10,5 % de retard, contre 1,5 %
pour les autres.

## Ce que cela implique

**Le coussin de sécurité a été entamé à l'été 2018.** La première lecture de ce
projet (« le resserrement est compensé par l'amélioration du transport ») était
vraie à l'échelle de l'année, fausse à l'échelle du mois.

**La marge doit être suivie chaque mois, pas chaque année.** C'est le seul
moyen de voir un changement de politique au moment où il se produit.

---

# 3. Deux pics de retard, deux causes opposées

## Le fait

| | Mars 2018 | Août 2018 |
|---|---|---|
| Promesse | 22 j | 14 j |
| Délai réel | **13 j** (le plus lent de l'année) | **7 j** (le plus rapide de l'année) |
| Marge | 9 j | 7 j |
| Taux de retard | 18,96 % | 6,19 % |

## Ce que cela signifie

**En mars, l'exécution a craqué.** La promesse était encore longue, mais le
délai réel est monté à 13 jours : c'est l'incident d'acheminement identifié en
O1 (7 à 11 jours d'acheminement).

**En août, l'exécution n'a jamais été aussi bonne**, et le retard remonte
quand même. Il est créé par la promesse seule, raccourcie de moitié en deux
mois.

La marge d'août est même plus faible qu'en mars (7 jours contre 9), pour un
retard trois fois moindre. Une exécution régulière tient une marge courte ; une
exécution qui dérape fait déborder même une marge confortable.

## Ce que cela implique

**Un même taux de retard peut appeler deux directions différentes.** Mars
relève de la direction logistique. Août relève de la direction marketing, qui
fixe la promesse. Sans la décomposition promesse / exécution, les deux
situations seraient confondues.

---

# 4. Le coût d'un resserrement n'est pas linéaire

## Le fait

Simulation sur l'ensemble du périmètre, à exécution inchangée : retrancher X
jours à la promesse revient à ajouter X jours à l'écart de chaque commande.

| Resserrement | Commandes en retard | Taux | Écart avec aujourd'hui |
|---|---|---|---|
| Actuel | 6 534 | 6,77 % | |
| 1 jour | 7 826 | 8,11 % | +1 292 commandes |
| 2 jours | 9 288 | 9,63 % | +2 754 commandes |
| 3 jours | 10 838 | 11,24 % | +4 304 commandes |
| 5 jours | 14 486 | 15,02 % | +7 952 commandes |
| 7 jours | 20 330 | 21,08 % | +13 796 commandes |
| 10 jours | 34 620 | 35,90 % | +28 086 commandes |

## Ce que cela signifie

**La marge de 13 jours n'est pas un gisement disponible.** C'est une médiane :
la moitié des commandes ont moins de 13 jours d'avance, et beaucoup sont au
bord. Environ 1 300 à 1 700 commandes se trouvent à chacun des écarts 0, −1,
−2 et −3 jours : retrancher trois jours les fait toutes basculer.

Le coût est d'environ 1,4 point de retard par jour retranché jusqu'à 3 jours,
puis il s'emballe.

## Ce que cela implique

Sur la moyenne de la période, la zone défendable serait de **1 à 2 jours** (le
taux passerait de 6,77 % à 9,63 %).

**Mais cette simulation part de la situation moyenne, avec 13 jours de marge.
En août 2018, Olist n'en a plus que 7.** Le resserrement a déjà consommé cette
zone défendable, et au-delà. Il ne reste plus de jours à retrancher sans que le
transport s'améliore d'abord.

---

# 5. Retrancher un jour coûte plus que gagner un jour ne rapporte

## Le fait

| Levier | Effet d'un jour | Source |
|---|---|---|
| Gagner 1 jour sur le transport | **825** commandes ramenées à l'heure | O7 |
| Retrancher 1 jour à la promesse | **1 292** commandes basculées en retard | O8 |

Côté satisfaction (O3), la note plafonne à 4,3 quelle que soit l'avance (de 5 à
30 jours), alors qu'un seul jour de retard fait passer l'insatisfaction de
12,34 % à 19,76 %.

## Ce que cela signifie

**Les deux leviers ne sont pas symétriques.** La marge protège d'un risque réel
(le retard, sanctionné dès le premier jour) contre un bénéfice nul en
satisfaction (l'avance n'est pas récompensée). Mais la retirer coûte plus cher
que de la reconstituer par le transport.

## Ce que cela implique

**La règle d'arbitrage : ne resserrer la promesse qu'à hauteur des jours
réellement gagnés sur l'exécution.** Trois jours gagnés sur le transport
permettent trois jours de promesse en moins, à taux de retard constant.

C'est exactement ce qu'Olist n'a pas fait à l'été 2018 : la promesse a perdu
environ 9 jours depuis 2017, quand l'exécution n'en gagnait qu'environ 3.

---

# 6. Le bénéfice d'une promesse courte n'est pas mesurable

## Le fait

Le jeu de données ne contient que des commandes passées. Aucune trace des
visiteurs qui ont renoncé à acheter devant un délai trop long.

## Ce que cela signifie

M-17 mesure le **coût** d'un resserrement (des retards en plus), jamais son
**gain** (des ventes en plus). L'arbitrage complet ne peut pas être tranché par
les données seules.

## Ce que cela implique

La décision revient au métier. Le projet lui fournit ce qu'il ne pouvait pas
connaître : le prix exact, en commandes en retard, de chaque jour retranché.
Si le marketing estime qu'un jour de promesse en moins rapporte plus que 1 292
commandes en retard ne coûtent, le resserrement se défend. Sinon, non.

---

# Synthèse : ce que O8 a établi

| # | Constat |
|---|---|
| 1 | La marge médiane annuelle est de 13 jours en 2017 comme en 2018 |
| 2 | Elle est uniforme par état (12 à 17 jours) : une règle nationale suffit |
| 3 | La médiane annuelle masque l'été 2018 : la marge passe de 20 jours en juin à **7 jours en août** |
| 4 | Le retard suit la marge : 1,16 % en juin, 6,19 % en août |
| 5 | Mars et août 2018 ont deux causes opposées : l'exécution en mars, la promesse en août |
| 6 | Le coût d'un resserrement est non linéaire : +1 292 commandes en retard au premier jour, 21 % de retard à 7 jours |
| 7 | La zone défendable de 1 à 2 jours est déjà consommée en août 2018 |
| 8 | Retrancher un jour coûte 1 292 retards, gagner un jour en récupère 825 |
| 9 | Le bénéfice commercial d'une promesse courte n'est pas mesurable |

---

# La recommandation

**Arrêter le resserrement de la promesse tant que le transport ne s'est pas
amélioré d'autant.**

| Action | Direction | Appui |
|---|---|---|
| Ne resserrer la promesse qu'à hauteur des jours gagnés sur l'exécution | Marketing, avec la logistique | Constats 5 et 7 |
| Suivre la marge médiane chaque mois, et non chaque année | Direction générale | Constats 2 et 3 |
| Lire tout pic de retard avec sa décomposition promesse / exécution avant de désigner un responsable | Direction générale | Constat 3 |
| Appliquer une règle nationale, sans différenciation par état | Marketing | Constat 1 |

---

# Limites

- **Exécution supposée inchangée** dans la simulation : on décale la promesse,
  pas la performance.
- **La simulation porte sur toute la période.** Partant de la marge d'août
  2018 (7 jours), le coût d'un jour retranché serait plus élevé encore.
- **Effet sur la satisfaction extrapolé** : rien ne garantit qu'un retard créé
  par un resserrement soit perçu comme un retard subi.
- **Fin des données en août 2018** : le resserrement n'est observé que sur
  deux mois.

---

# Questions ouvertes

- [ ] Le resserrement de l'été 2018 était-il une décision délibérée d'Olist ?
- [ ] La marge d'août 2018 est-elle aussi faible dans tous les états, ou
      surtout vers São Paulo, où le retard est passé de 0,7 % à 9,0 % (O6) ?
- [ ] Quelle marge minimale tient le retard sous un niveau cible ? Le tableau
      du constat 2 donne une première courbe, mais sur huit mois seulement.
