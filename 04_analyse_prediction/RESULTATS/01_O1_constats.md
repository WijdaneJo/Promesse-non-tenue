# O1 — Constats : la mesure du retard

> Ce document traduit les résultats de `SQL/01_O1_mesure_du_retard.sql` en
> **énoncés utilisables**. Le SQL produit des chiffres ; ce fichier produit des
> phrases. C'est lui qui alimentera le dashboard et l'executive summary.
>
> **Structure de chaque constat** : le fait → ce qu'il signifie → ce qu'il implique.

---

# 1. Le retard est un phénomène géographique

## Le fait

Le taux de retard varie de **2,76 % (AM) à 21,41 % (AL)** selon l'état de
destination. São Paulo, qui représente **42 % du périmètre**, affiche 4,50 %.

## Ce que cela signifie

**La moyenne nationale de 6,77 % ne décrit aucun état réel.** Elle est le produit
d'une concentration géographique, pas d'une tendance. Communiquer sur ce chiffre
revient à décrire la situation de São Paulo, pas celle du Brésil.

Un écart de 1 à 8 entre le meilleur et le pire état signale que le problème n'est
pas uniforme : il a une géographie.

> **Le cas São Paulo illustre le piège.** Il concentre le plus grand **volume**
> de retards du pays — 1 820 commandes — tout en affichant le 4ᵉ meilleur
> **taux**. Volume et taux racontent deux histoires différentes.

## Ce que cela implique

**Toute métrique du projet doit être déclinée par état.** Cela vaut pour M-04
(segments), M-06 (CA exposé) et M-17 (calibrage). Un chiffre national masque un
facteur 8.

---

## La cible prioritaire : Rio de Janeiro

Deux lectures du même tableau désignent deux cibles différentes.

| Critère | État | Volume concerné |
|---|---|---|
| Taux le plus élevé | AL — 21,41 % | 85 commandes |
| Volume le plus élevé (hors SP) | **RJ — 12,11 %** | **1 495 commandes** |

**RJ est retenu.** Son taux est presque le double du taux national, *et* il
concerne dix-huit fois plus de clients qu'AL.

> **Le taux dit où le processus dysfonctionne ; le volume dit où l'impact client
> est le plus fort.** Prioriser sur le seul taux conduirait à traiter 85 clients
> plutôt que 1 495.

> ⚠️ **Nuance à lever par O4.** Cet arbitrage repose sur le volume de commandes.
> Si les commandes d'AL sont significativement plus chères, l'exposition
> financière pourrait rééquilibrer la priorité.

---

## Quatre états sous seuil de fiabilité

| État | Commandes | Taux affiché |
|---|---|---|
| RR | 41 | 12,20 % |
| AP | 67 | 2,99 % |
| AC | 80 | 3,75 % |
| AM | 145 | 2,76 % |

Un taux calculé sur 41 commandes n'a pas de valeur statistique — cinq retards de
plus ou de moins le feraient varier de dix points.

**Ces états restent dans les totaux nationaux ; seules les conclusions
individuelles les excluent.** Même logique que RG-08 pour les vendeurs : on
écarte le bruit, pas la donnée.

---

# 2. Un incident national en février-mars 2018

## Le fait

```
Nov. 2017   12,40 %
Déc. 2017    7,46 %
Jan. 2018    5,70 %
Fév. 2018   14,13 %
Mars 2018   18,96 %   ← maximum de la période
Avr. 2018    4,50 %
```

Mars 2018 : **1 328 commandes en retard sur 7 003**. Un an plus tôt, mars 2017
était à 4,56 % — quatre fois moins.

## Ce que cela signifie

**Ce n'est pas de la saisonnalité, c'est un incident.** Une saisonnalité se
répète d'une année sur l'autre ; celle-ci n'apparaît qu'en 2018. Et elle se
résorbe brutalement : 4,50 % dès avril.

## Ce que cela implique

Un incident daté appelle une explication précise, pas une politique générale.
Trois pistes ont été testées.

---

## Piste 1 — Le volume : écartée

| Mois | Commandes | Retard |
|---|---|---|
| Mars 2018 | 7 003 | **18,96 %** |
| Janvier 2018 | 7 069 | 5,70 % |
| Juin 2018 | 6 096 | 1,16 % |

**Janvier 2018 a plus de commandes que mars et trois fois moins de retard.**
La saturation logistique n'explique pas le pic.

> *À noter au passage : la plateforme a triplé son activité en un an — 2 545
> commandes en mars 2017 contre 7 003 en mars 2018. Ce n'est pas une
> saisonnalité, c'est une croissance.*

---

## Piste 2 — Une défaillance régionale : écartée

| État | Toute période | Mars 2018 | Facteur |
|---|---|---|---|
| SP | 4,50 % | 9,42 % | ×2,1 |
| MG | 4,57 % | **20,44 %** | ×4,5 |
| RS | 6,08 % | 19,16 % | ×3,2 |
| RJ | 12,11 % | **34,49 %** | ×2,8 |
| SC | 8,21 % | 19,43 % | ×2,4 |

**Les 27 états dégradent, sans exception** — y compris MG, habituellement l'un
des mieux servis, multiplié par 4,5.

Ce n'est donc ni un transporteur régional, ni une route bloquée, ni un événement
local. **La cause est centrale.**

> RJ atteint 34,49 % avec 298 commandes en retard : l'état déjà le plus fragile
> encaisse le choc le plus fort.
>
> SP résiste le mieux (×2,1) — la proximité des vendeurs amortit probablement.

---

## Piste 3 — Le segment défaillant : l'ACHEMINEMENT

| Mois | Validation | Préparation | **Acheminement** | Retard |
|---|---|---|---|---|
| 2017 (norme) | 0 | 2 | **7** | ~4 % |
| Jan. 2018 | 0 | 2 | 8 | 5,70 % |
| **Fév. 2018** | 0 | 2 | **11** | 14,13 % |
| **Mars 2018** | 0 | 2 | **10** | 18,96 % |
| Avr. 2018 | 0 | 1 | 7 | 4,50 % |

## Ce que cela signifie

**La préparation vendeur ne bouge pas** — 2 jours, stable depuis 2017. Les
vendeurs ne sont pas en cause.

**L'acheminement passe de 7 à 11 jours**, puis redescend. Le transport a lâché
pendant deux mois.

## Ce que cela implique

**Le levier est le transport, pas l'accompagnement des vendeurs.** Deux causes
possibles, une seule retenue, donc une seule direction concernée.

> **Note de méthode.** Il n'existe pas de « retard » sur un segment : Olist ne
> promet rien sur la préparation ou l'acheminement pris séparément. La seule
> promesse est la date finale. On compare donc chaque segment **à sa propre
> normale**, pas à un engagement. La référence retenue est la médiane observée
> sur 2017 : 7 jours d'acheminement.

---

## Une seconde dégradation, de nature différente : le Black Friday

Novembre 2017 présente la même signature à moindre échelle — acheminement à
9 jours, retard à 12,40 %, isolé entre octobre (4,18 %) et décembre (7,46 %).

**Vérification effectuée** sur le volume quotidien :

| Jour | Commandes |
|---|---|
| 23 nov. | 268 |
| **24 nov.** | **1 147** |
| 25 nov. | 487 |
| 26 nov. | 382 |

**×4,3 en une journée.** Le 24 novembre 2017 correspond au Black Friday
brésilien. La piste est confirmée.

## Ce que cela change

Deux natures de dégradation, deux traitements :

| | Février-mars 2018 | Novembre 2017 |
|---|---|---|
| Nature | Incident inexpliqué | Pic commercial |
| Retard | 18,96 % | 12,40 % |
| Récurrence | Ponctuel | **Annuel** |
| Action | À diagnostiquer | **Anticipable** |

**Olist connaît la date du Black Friday un an à l'avance.** Renforcer la capacité
d'acheminement sur cette période, ou allonger temporairement les délais annoncés,
sont deux leviers concrets — contrairement à l'incident de mars, dont la cause
reste à établir.

---

# 3. Le retard dépend aussi de la promesse

## Le paradoxe

| | Acheminement | Retard |
|---|---|---|
| Février 2018 | **11 jours** | 14,13 % |
| Mars 2018 | **10 jours** | **18,96 %** |

**Mars livre plus vite que février et génère plus de retard.** La performance
d'exécution n'explique pas tout.

## L'explication

| | Promesse | Acheminement | Retard |
|---|---|---|---|
| Février 2018 | **25 jours** | 11 j | 14,13 % |
| Mars 2018 | **22 jours** | 10 j | **18,96 %** |

**Mars promet trois jours de moins.** La marge se réduit plus vite que
l'exécution ne s'améliore.

## Ce que cela signifie

> **Le retard n'est pas une mesure de performance. C'est un écart entre deux
> grandeurs qui varient toutes les deux** : ce qui est promis et ce qui est
> exécuté.

Une hausse du taux de retard peut donc signifier trois choses différentes :
l'exécution s'est dégradée, la promesse s'est resserrée, ou les deux.

## Ce que cela implique

**Aucune conclusion sur la performance logistique ne peut être tirée du seul
taux de retard.** Toute analyse de M-00 doit être accompagnée de l'évolution des
délais annoncés (M-16), sans quoi elle est ininterprétable.

Cette règle vaut pour le dashboard : afficher le taux de retard sans la promesse
exposerait à un contresens.

---

# 4. L'ampleur du retard est faible partout — sauf à Rio

## Le fait

Retard médian, sur les commandes en retard uniquement :

| État | Commandes en retard | Retard médian |
|---|---|---|
| CE | 176 | 10 j |
| RJ | 1 495 | 9 j |
| MA | 125 | 8 j |
| BA | 396 | 7 j |
| **AL** | 85 | **7 j** |
| SP | 1 820 | 5 j |
| MG | 519 | 5 j |

*AP (72,5 j), AC, AM, RR et RO sont écartés : moins de 10 commandes en retard.*

## Ce que cela signifie

**L'amplitude est faible : 5 à 10 jours partout**, contre un facteur 8 sur les
taux. **Le problème est la fréquence, pas la gravité.**

Et deux profils opposés apparaissent :

- **AL** — pire taux du pays (21,41 %) mais retard le plus court (7 j).
  Rate souvent, de peu.
- **CE** — rate moins souvent (13,76 %) mais plus largement (10 j).

## La distribution nuance ce constat

| État | 1-7 j | 8-15 j | 16-30 j | > 30 j | Total | Part grave |
|---|---|---|---|---|---|---|
| SP | 1 265 | 345 | 145 | 65 | 1 820 | 30 % |
| **RJ** | 624 | **423** | **313** | **135** | 1 495 | **58 %** |
| MG | 336 | 108 | 61 | 14 | 519 | 35 % |
| CE | 63 | 60 | 31 | 22 | 176 | **64 %** |
| AL | 45 | 28 | 8 | 4 | 85 | 47 % |

**RJ est le seul grand état où la majorité des retards sont graves** : 871
commandes au-delà de 8 jours, dont **135 à plus de 30 jours**. São Paulo a plus
de retards en volume, mais 70 % sont courts et seulement 65 dépassent 30 jours.

## Ce que cela implique

**Le simulateur (M-13) sera efficace partout sauf à RJ.** Un gain de 7 jours
ramènerait la majorité des retards dans les délais dans la plupart des états —
mais laisserait 58 % des cas de RJ non résolus.

**RJ appelle un traitement différent des autres** : pas un ajustement, une
correction de fond.

---

# 5. La distance explique la promesse, pas le retard

## Le fait

| État | Distance | Promesse | Retard |
|---|---|---|---|
| AM | 2 693 km | 46 j | 2,76 % |
| RR | 3 303 km | 45 j | **12,20 %** |
| AL | 1 915 km | 32 j | **21,41 %** |
| CE | 2 292 km | 32 j | 13,76 % |
| **RJ** | **396 km** | 25 j | **12,11 %** |
| PR | 427 km | 25 j | 4,04 % |
| MG | 491 km | 24 j | 4,57 % |
| SP | 166 km | 19 j | 4,50 % |

## Ce que cela signifie

**La promesse est bien calibrée sur la distance.** 46 jours à 2 700 km, 19 jours
à 166 km. Olist ajuste correctement son engagement à la difficulté logistique.

**Mais la distance n'explique pas le retard.** Trois observations le montrent :

- **RJ est l'état le plus proche après SP.** Il a la même promesse que PR et MG,
  qui sont à distance comparable. PR fait 4,04 %, MG 4,57 %, **RJ 12,11 %** —
  trois fois plus, à conditions égales.
- **AL est plus proche que CE et RR**, avec une promesse comparable, et affiche
  le pire taux du pays.
- **AM et RR promettent tous deux ~45 jours.** L'un est à 2,76 %, l'autre à
  12,20 %. Même promesse, résultat quatre fois pire.

## Ce que cela implique

Deux profils d'états, deux leviers différents :

| Profil | États | Diagnostic | Levier |
|---|---|---|---|
| Promesse large, retard élevé | AL, MA, RR | L'ajustement a été fait et ne suffit pas | **Opérationnel** |
| Promesse serrée, retard élevé | **RJ** | Calibré comme un état facile alors qu'il ne l'est pas | **Recalibrage** |

---

# 6. Deux évolutions structurelles

## La performance s'est durablement améliorée

```
2017 (norme)      préparation 2    acheminement 7
Fév-mars 2018     préparation 2    acheminement 10-11   ← crise
Avr. 2018         préparation 1    acheminement 7
Juin 2018         préparation 1    acheminement 6
Août 2018         préparation 1    acheminement 5
```

**Après avril 2018, la performance ne revient pas au niveau d'avant — elle le
dépasse.** L'acheminement passe de 7 à 5 jours, la préparation de 2 à 1.

Ce n'est pas un retour à la normale, c'est **une amélioration structurelle**.

> **Implication pour O8** : si Olist livre désormais en 5 jours au lieu de 7, la
> marge disponible sur les délais annoncés est supérieure à ce que la moyenne
> historique laisse croire. Les scénarios de M-17 doivent se caler sur la
> performance **récente**, pas sur la moyenne de la période.

## Le resserrement de la promesse a déjà commencé

```
2017 (toute l'année)   23-24 jours
Mars 2018              22 jours
Juillet 2018           20 jours
Août 2018              14 jours   ← −40 % par rapport à 2017
```

**Olist annonçait 23 jours en 2017. En août 2018, elle n'en annonce plus que
14.** Et le taux de retard d'août reste bas.

### Contrôle de validité — effectué

Ce constat étant le plus fort de O1, il a été challengé.

**Le risque** : `mart.orders` ne contient que des commandes livrées. Si le jeu de
données s'arrêtait peu après août, les commandes lentes d'août n'y figureraient
pas, et le taux de retard serait artificiellement bas.

| Contrôle | Résultat |
|---|---|
| Dernier achat | 2018-08-29 |
| Dernière livraison | **2018-10-17** |
| Écart | **7 semaines** |
| Volume d'août | 6 351 — supérieur à juillet (6 156) et juin (6 096) |

**Pas de troncature.** Le constat est validé sur deux critères.

### Ce que cela change pour O8

L'objectif O8 posait la question *« et si l'on resserrait les délais annoncés ? »*
comme un scénario théorique.

**Les données montrent que c'est déjà fait.** Ce n'est plus une hypothèse à
simuler mais une décision observable, dont on peut mesurer le résultat.

> **La recommandation en sort renforcée.** Au lieu de *« on pourrait
> resserrer »*, on peut écrire : *« le resserrement a été engagé, il a été
> absorbé par l'amélioration de l'acheminement, voici jusqu'où il peut aller »*.

---

# Synthèse — ce que O1 a établi

| # | Constat |
|---|---|
| 1 | Le retard varie de 1 à 8 selon l'état ; la moyenne nationale ne décrit personne |
| 2 | RJ est la cible prioritaire — 1 495 commandes en retard |
| 3 | Un incident national en février-mars 2018, non expliqué par le volume ni par une défaillance régionale |
| 4 | L'acheminement a lâché (7 → 11 jours), pas la préparation vendeur |
| 5 | Novembre 2017 = Black Friday — dégradation **anticipable** car récurrente |
| 6 | Le retard dépend autant de la promesse que de l'exécution |
| 7 | L'ampleur est faible partout (5 à 10 j) — sauf à RJ, 58 % de retards graves |
| 8 | La distance explique la promesse, pas le retard : RJ et AL sortent du modèle |
| 9 | La performance s'est améliorée après la crise : acheminement à 5 jours |
| 10 | Olist a déjà resserré sa promesse de 40 % (23 → 14 jours) — constat validé |

## Le cas Rio de Janeiro

RJ cumule **quatre** signaux défavorables, ce qui en fait le point noir du réseau :

- Taux élevé (12,11 %) alors que c'est l'état le plus proche après SP
- Volume important (1 495 commandes en retard)
- Retards majoritairement graves (58 % au-delà de 8 jours)
- Promesse calibrée comme un état facile, alors qu'il ne l'est pas

---

# Questions ouvertes

- [ ] **Quelle est la cause de l'incident de février-mars 2018 ?** Les données
      seules ne le diront pas. Les trois pistes internes ont été testées et
      écartées ; l'explication est probablement externe. Question à poser au
      métier, ou à chercher dans l'actualité logistique brésilienne de la période
- [ ] **Pourquoi RJ dysfonctionne-t-il ?** Ni la distance ni la promesse ne
      l'expliquent. La réponse est dans O2 : préparation ou acheminement ?
- [ ] L'exposition financière confirme-t-elle RJ comme priorité ? *(O4)*
- [ ] Le retard du Nord-Est vient-il de l'acheminement, comme l'incident de
      mars ? *(O2, M-04)*

---

# Contrôles effectués

| Contrôle | Résultat |
|---|---|
| Troncature de fin de période | ✅ 7 semaines d'écart, pas de biais |
| Volume d'août 2018 | ✅ normal (6 351) |
| Mois incomplets identifiés | ✅ sept. 2016 (1), oct. 2016 (261), déc. 2016 (1) |
| États sous seuil de fiabilité | ✅ RR, AP, AC, AM — écartés des conclusions individuelles |
| Hypothèse Black Friday | ✅ vérifiée — 24 nov. 2017, ×4,3 en une journée |