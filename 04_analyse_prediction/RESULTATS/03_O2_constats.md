# O2. Constats : où naît le retard

> Ce document traduit les résultats de `03_O2_origine_du_retard.sql` en
> **énoncés utilisables**.
>
> **Structure de chaque constat** : le fait, ce qu'il signifie, ce qu'il implique.

**Périmètre.** 689 commandes ont un `gap_preparation` à `NULL` (RG-04 et dates
manquantes). Le dénominateur de ce segment est de **95 758**.

---

# 1. Le retard naît de l'acheminement

## Le fait

| Segment | Ensemble | À l'heure | En retard |
|---|---|---|---|
| Validation | 0 j | 0 j | 0 j |
| Préparation | 2 j | 2 j | **3 j** |
| **Acheminement** | 7 j | 7 j | **26 j** |
| *Volume* | 96 447 | 89 913 | 6 534 |

## Ce que cela signifie

**Sur les 20 jours d'écart entre une commande à l'heure et une commande en
retard, 19 viennent du transport.** Soit 95 %.

La préparation vendeur ne gagne qu'**un seul jour**. Le vendeur n'est pas le
moteur du retard.

La validation est instantanée dans les deux cas : le paiement n'est jamais en
cause.

> **Ce résultat confirme O1.** L'incident de février-mars 2018 avait déjà pointé
> l'acheminement (de 7 à 11 jours). On voit ici que ce n'était pas un cas
> particulier : c'est le **mécanisme structurel du retard**, en dehors de toute
> crise.

## Ce que cela implique

**Le levier est le transport.** Une action sur l'accompagnement des vendeurs
produirait un effet marginal : au mieux un jour sur vingt.

---

# 2. Le mécanisme est national

## Le fait

Acheminement médian par état, à l'heure et en retard :

| État | Distance | À l'heure | En retard | Facteur | Préparation |
|---|---|---|---|---|---|
| SP | 166 km | **4 j** | 15 j | ×3,8 | 2 à 4 |
| **RJ** | 396 km | **8 j** | **30 j** | ×3,8 | 2 à 3 |
| PR | 427 km | 7 j | 24 j | ×3,4 | 2 à 3 |
| MG | 491 km | 7 j | 22 j | ×3,1 | 2 à 3 |
| SC | 529 km | 9 j | 27 j | ×3,0 | 2 à 3 |
| RS | 856 km | 9 j | 32 j | ×3,6 | 2 à 3 |
| **AL** | 1 915 km | **16 j** | 36 j | ×2,3 | 2 à 2 |
| **CE** | 2 292 km | **14 j** | 35 j | ×2,5 | 2 à 3 |

## Ce que cela signifie

**La préparation est stable partout** : 2 jours à l'heure, 3 en retard, dans les
huit états. Elle n'explique **aucun** écart géographique.

**Le levier est donc unique et national : le transport.**

## Ce que cela implique

Pas besoin de politique différenciée sur les vendeurs par région. La
recommandation portera sur la chaîne d'acheminement.

---

# 3. Rio de Janeiro : la question d'O1 est résolue

## Le fait

**RJ met 8 jours à livrer en régime normal.** MG (491 km) et PR (427 km), tous
deux **plus éloignés**, en mettent 7. São Paulo en met 4.

Et quand ça dérape, RJ monte à **30 jours** : le pire des grands états.

## Ce que cela signifie

O1 avait établi que RJ dysfonctionne sans que la distance ni la promesse
l'expliquent. **La réponse est là** : Rio est le seul état où la distance ne
prédit pas le délai.

> **Son acheminement est structurellement plus lent, même quand tout va bien.**

Ce n'est ni un problème de calibrage de la promesse, ni un effet de la
géographie : c'est la **performance du transport sur cette zone**.

## Trois vérifications convergentes

| Angle | Résultat |
|---|---|
| Durée d'acheminement | 8 j en normal, contre 7 pour des états plus éloignés |
| Vendeurs installés à RJ *(Q7)* | **0** vendeur en difficulté sur 72 |
| Part des retards imputable à la préparation *(Q7 bis)* | **14,62 %**, sous la moyenne nationale |

**Le problème de RJ est exclusivement dans le transport**, en entrée comme en
sortie. C'est établi de trois façons indépendantes.

## Ce que cela implique

RJ appelle une action sur ses **partenaires logistiques**, pas sur ses délais
annoncés ni sur ses vendeurs.

Une commande sur laquelle Olist promet 25 jours en consomme déjà 8 en transport,
contre 4 à São Paulo : **avant même le moindre incident**.

---

# 4. AL et CE : un profil différent

## Le fait

| État | Acheminement à l'heure | Taux de retard | Retard médian |
|---|---|---|---|
| AL | **16 j** | 21,41 % | 7 j |
| CE | **14 j** | 13,76 % | 10 j |
| SP | 4 j | 4,50 % | 5 j |

## Ce que cela signifie

AL et CE sont **quatre fois plus lents que São Paulo en régime normal**. Leur
promesse de 32 jours est déjà tendue : le moindre écart fait basculer.

Cela explique le paradoxe d'O1 : AL a le pire taux du pays (21,41 %) mais des
retards courts (7 jours médians). **Il rate souvent, de peu.**

## Ce que cela implique

**Deux problèmes distincts, deux traitements :**

| Profil | États | Diagnostic |
|---|---|---|
| Lents en **permanence** | AL, CE | La base est mauvaise, pas la variabilité |
| Lent **et instable** | RJ | La base est mauvaise *et* dérape |

Pour AL et CE, améliorer la régularité ne suffirait pas : c'est le niveau de
service normal qu'il faut relever.

---

# 5. L'attribution commande par commande

## Le fait

Pour chaque commande en retard, le segment dont la durée s'écarte le plus de sa
normale :

| Segment responsable | Commandes | Part |
|---|---|---|
| **Acheminement** | 5 465 | **83,6 %** |
| **Préparation** | 1 054 | **16,1 %** |
| Indéterminé | 15 | 0,2 % |

## Ce que cela signifie

**Un écart avec le constat 1 mérite d'être noté.** Les médianes donnaient 95 %
pour le transport ; le décompte par commande donne 84 %.

Une médiane écrase les cas individuels. **1 054 commandes ont bien un problème
vendeur**, même si globalement le transport domine.

## Ce que cela implique

**Le levier principal reste le transport** : cinq fois plus de commandes.

**Mais un second chantier existe**, relevant d'une direction différente : la
direction des partenariats vendeurs.

---

# 6. Le piège du volume, encore

## Le fait

Le classement brut des vendeurs par nombre de retards de préparation place en
tête :

| Vendeur | Commandes | Retards prépa | Taux |
|---|---|---|---|
| 7c67e144… | 1 342 | 26 | **1,94 %** |
| 1025f0e2… | 1 372 | 26 | **1,90 %** |
| 6560211a… | 1 960 | 5 | **0,26 %** |

**Ils apparaissent en tête parce qu'ils vendent beaucoup, pas parce qu'ils sont
mauvais.** C'est le même piège que São Paulo en O1.

## Les vrais cas problématiques

| Vendeur | Commandes | Retards prépa | **Taux prépa** | Taux global |
|---|---|---|---|---|
| b1b39487… | 14 | 9 | **64,29 %** | 64,29 % |
| b19f3ca2… | 18 | 5 | **27,78 %** | 33,33 % |
| **54965bbe…** | **80** | **22** | **27,50 %** | 32,50 % |
| ad781527… | 33 | 7 | **21,21 %** | 36,36 % |
| 835f0f78… | 45 | 9 | **20,00 %** | 28,89 % |
| beadbee3… | 67 | 12 | **17,91 %** | 22,39 % |

**`54965bbe` est le cas le plus sérieux** : 80 commandes, volume suffisant pour
être fiable, et 27,5 % de retard imputable à sa propre expédition.

**`b1b39487` affiche 64 %, mais sur 14 commandes seulement.** Il passe le seuil
RG-08 de justesse : deux commandes de moins et le taux bougerait de 15 points.

> **Une distinction essentielle.** Pour ces vendeurs, le taux de préparation
> représente **l'essentiel** de leur taux global : le premier affiche 64,29 %
> dans les deux colonnes.
>
> À l'inverse, `da8622b1` a 6,48 % de retard global mais 0,60 % imputable à la
> préparation. **Ses retards viennent du transport, pas de lui.**
>
> À vérifier avant toute mise en cause d'un partenaire.

---

# 7. Santa Catarina : un artefact démasqué

## Le premier signal

Répartition des vendeurs en difficulté (taux de retard > 20 %) par état :

| État | Vendeurs | En difficulté | Part |
|---|---|---|---|
| **SC** | 65 | 9 | **13,85 %** |
| RS | 44 | 3 | 6,82 % |
| SP | 818 | 37 | 4,52 % |
| MG | 115 | 5 | 4,35 % |
| PR | 146 | 3 | 2,05 % |
| **RJ** | 72 | **0** | **0,00 %** |

Santa Catarina semble décrocher : trois fois plus de vendeurs en difficulté que
la moyenne.

## La vérification

> **`late_rate` est le taux global du vendeur** : il inclut les retards dus au
> transport. Un vendeur de SC expédiant vers des zones lentes aurait un taux
> élevé **sans être responsable**.

Recalcul sur la part des retards **réellement imputable à la préparation** :

| État vendeur | Retards | Part préparation | vs national (16,1 %) |
|---|---|---|---|
| **MA** | 74 | **41,89 %** | ×2,6 |
| **RS** | 61 | **31,15 %** | ×1,9 |
| PR | 400 | 21,25 % | ×1,3 |
| MG | 370 | 18,65 % | - |
| **SC** | 175 | **16,57 %** | **= moyenne** |
| SP | 5 005 | 15,26 % | - |
| RJ | 301 | 14,62 % | inférieur |

**SC était bien un artefact.** 16,57 %, soit exactement la moyenne nationale.
Ses vendeurs ne sont pas en cause : ils expédient vers des zones difficiles.

## Ce que cela signifie

**Deux états ressortent réellement** : MA (41,89 %) et RS (31,15 %). Au
Maranhão, quatre retards sur dix viennent de la préparation vendeur, contre un
et demi sur dix en moyenne.

> **Précaution.** MA a 74 retards et RS 61 : le seuil de 50 retenu est bas.
> Ces taux sont **indicatifs, pas solides**. SP, avec 5 005 retards, est le seul
> chiffre pleinement fiable.

## Ce que cela implique

**Un indicateur mal choisi conduit à accuser à tort.** Sans cette vérification,
la recommandation aurait ciblé Santa Catarina : alors que le problème y est le
transport, pas les vendeurs.

C'est le même raisonnement que pour `da8622b1` : toujours isoler ce qui est
imputable au vendeur avant de le mettre en cause.

---

# 8. L'engagement contractuel : un indicateur plus fort

## Pourquoi cet indicateur

`shipping_limit_date` est la **date limite d'expédition** imposée au vendeur par
Olist. Colonne disponible depuis le début du projet, jamais exploitée.

> **C'est un engagement contractuel, pas une statistique.** Un dépassement est
> **opposable** au partenaire : contrairement à un taux de retard, qui peut venir
> du transport et qu'il pourrait contester.

## Le fait

**9,30 % des articles sont expédiés après la date limite** : 10 240 sur 110 138.
Un sur onze.

## L'engagement est-il bien calibré ?

| | Commandes | Taux de retard |
|---|---|---|
| Date limite respectée | 87 739 | **5,38 %** |
| **Date limite dépassée** | 8 707 | **20,83 %** |

**Un dépassement multiplie le risque de retard par près de 4.**

## Ce que cela signifie

**L'indicateur est valide.** Respecter la date limite suffit largement à tenir la
promesse : Olist ne l'a pas fixée trop serrée.

C'est un levier **actionnable** et **opposable**.

## Deux profils de vendeurs

**A : Dépassent sans conséquence** : la marge absorbe

| Vendeur | Commandes | Dépassement | Retard |
|---|---|---|---|
| 48efc9d9… | 34 | **82,35 %** | **0,00 %** |
| a7f13822… | 84 | 59,52 % | 3,57 % |
| 1da366ca… | 47 | 55,32 % | 6,38 % |

**Le premier dépasse sa date limite huit fois sur dix et n'a aucun retard.** La
marge d'Olist (13 jours médians, voir O8) est si large qu'un vendeur peut expédier
en retard et le colis arriver quand même à temps.

**B : Dépassent ET génèrent du retard** : cible prioritaire

| Vendeur | Commandes | Dépassement | Retard |
|---|---|---|---|
| **835f0f78…** | 45 | **72,92 %** | **28,89 %** |
| **a49928bc…** | 101 | **55,77 %** | **21,78 %** |
| **54965bbe…** | 80 | **54,32 %** | **32,50 %** |
| **ad781527…** | 33 | **47,37 %** | **36,36 %** |
| bbad7e51… | 80 | 46,43 % | 23,75 % |

> **Ce sont les mêmes que la liste du constat 6.** Deux méthodes indépendantes :
> analyse des segments et respect de l'engagement : **convergent** sur les mêmes
> vendeurs.

## Ce que cela implique

**Deux populations, deux traitements :**

| Profil | Action |
|---|---|
| Dépassent sans conséquence | Rappel des engagements. Pas d'urgence : la marge absorbe |
| Dépassent **et** génèrent du retard | **Cible prioritaire.** Liste courte, action immédiate |

**Le chiffre à retenir pour la recommandation** : *respecter la date limite
d'expédition divise le taux de retard par 4.*

---

# Synthèse : ce que O2 a établi

| # | Constat |
|---|---|
| 1 | **Le retard naît de l'acheminement** : de 7 à 26 jours, soit 95 % de l'écart |
| 2 | La préparation ne gagne qu'un jour : le vendeur n'est pas le moteur |
| 3 | La structure est **identique dans tous les états** : levier unique et national |
| 4 | **RJ résolu** : acheminement structurellement lent, établi de trois façons |
| 5 | **AL et CE** relèvent d'un autre profil : lents en permanence, pas instables |
| 6 | Attribution par commande : **84 % acheminement, 16 % préparation** |
| 7 | **SC était un artefact** ; MA et RS ressortent réellement, sous réserve d'effectifs |
| 8 | **Le respect de la date limite divise le taux de retard par 4** |
| 9 | Quatre vendeurs cumulent dépassement contractuel et retard client |

---

# Ce que O2 apporte aux autres objectifs

**Pour O5 (trajectoire vendeur)** : la liste des vendeurs à problème
d'expédition est établie et **doublement validée**. Reste à savoir si leur
activité en souffre.

**Pour O6 (prédiction)** : l'acheminement étant le facteur dominant, les
variables liées au transport (distance, état de destination) devraient être les
plus prédictives. Le dépassement de `shipping_limit_date` pourrait aussi être un
signal fort, mais il n'est **pas connu au moment de la commande** : donc
inutilisable comme variable prédictive.

**Pour O7 (scénarios)** : un scénario d'amélioration doit porter sur
l'acheminement. Agir sur la préparation ne ferait gagner qu'un jour. En
revanche, faire respecter la date limite d'expédition à tous les vendeurs
ramènerait 8 707 commandes d'un risque de 20,83 % à 5,38 %.

**Pour la restitution** : deux directions concernées, deux niveaux de priorité :
la logistique (5 465 commandes) et les partenariats vendeurs (1 054 commandes,
dont quatre cas prioritaires nommés).

---

# Questions ouvertes

- [ ] **Pourquoi l'acheminement est-il structurellement lent à RJ ?** La donnée
      ne contient pas l'identité du transporteur. Question à poser au métier
- [ ] MA et RS ressortent sur la préparation, mais avec des effectifs faibles
      (74 et 61 retards). À reconfirmer sur une période plus longue
- [ ] Les vendeurs du profil A, qui dépassent sans conséquence, profitent-ils
      délibérément de la marge ? Si Olist resserre ses délais (O8), ils
      basculeraient en retard