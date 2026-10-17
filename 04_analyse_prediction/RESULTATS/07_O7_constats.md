# O7 — Constats : les scénarios d'amélioration

> Ce document traduit les résultats de `07_O7_scenarios.sql` en
> **énoncés utilisables**.
>
> **Structure de chaque constat** : le fait → ce qu'il signifie → ce qu'il implique.

**Le lien avec O8 — deux leviers opposés :**

| | O8 | **O7** |
|---|---|---|
| Levier | Raccourcir le délai **annoncé** | **Raccourcir le délai réel** |
| Nature | Commerciale | **Opérationnelle** |
| Effet sur le retard | L'**augmente** | Le **réduit** |

---

# 1. Le rendement est linéaire

## Le fait

| Gain | Encore en retard | **Récupérées** | Part des retards |
|---|---|---|---|
| 0 | 6 534 | — | — |
| 1 j | 5 709 | **825** | 12,6 % |
| 2 j | 5 164 | **1 370** | 21,0 % |
| 3 j | 4 664 | **1 870** | 28,6 % |
| 5 j | 3 764 | **2 770** | 42,4 % |
| **7 j** | 2 862 | **3 672** | **56,2 %** |

## Ce que cela signifie

**Le premier jour récupère 825 commandes ; chaque jour suivant, 450 à 550.**
Le premier jour est plus rentable car il ramène à l'heure les commandes à
exactement un jour de retard, les plus nombreuses. Ensuite, pas de seuil
d'efficacité ni de palier : le gain est proportionnel à l'effort.

## Le contraste avec O8

| | Effet d'un jour |
|---|---|
| **O7** — gagner 1 jour en exécution | **−825** commandes en retard |
| **O8** — retrancher 1 jour à la promesse | **+1 292** commandes en retard |

> **Resserrer coûte plus que livrer plus vite ne rapporte.**

---

# 2. Le CA récupéré progresse moins vite que le volume

## Le fait

| Gain | CA encore exposé | **CA récupéré** | Part |
|---|---|---|---|
| 0 | 1 150 866 R$ | — | — |
| 1 j | 1 015 984 | **134 882** | 11,7 % |
| 2 j | **932 499** | **218 367** | 19,0 % |
| 3 j | 855 882 | 294 984 | 25,6 % |
| 5 j | 688 444 | 462 422 | 40,2 % |
| **7 j** | 523 247 | **627 619** | **54,5 %** |

## Ce que cela signifie

**Une coïncidence à noter** : le scénario 2 jours laisse **932 499 R$** exposés —
exactement le CA exposé au seuil de 3 jours mesuré en O4. Gagner 2 jours ramène
sous le seuil critique toutes les commandes qui étaient à 3 jours.

**Mais le CA progresse moins vite que le volume** : 12,6 % des commandes
récupérées pour 11,7 % du CA.

> **Les commandes récupérées en premier sont les moins chères.**

---

# 3. Le gain sur la satisfaction est plus modeste

## La méthode

> ⚠️ **Ce qu'on ne peut pas faire** : prédire la note qu'un client aurait donnée
> si sa commande était arrivée à l'heure.

**Ce qu'on fait à la place** : compter, parmi les commandes qui reviendraient à
l'heure, celles dont le client était **réellement** insatisfait. Des
mécontentements **observés** qui n'auraient pas eu lieu.

## Le fait

**3 984 clients mécontents** parmi les commandes en retard, soit **61 %** des
6 534 concernées.

| Gain | Mécontents évités | Part des 3 984 |
|---|---|---|
| 1 j | 162 | 4,1 % |
| 3 j | 596 | 15,0 % |
| 5 j | 1 120 | 28,1 % |
| **7 j** | **1 777** | **44,6 %** |

## Ce que cela signifie

| 7 jours gagnés | Récupéré |
|---|---|
| Commandes | 3 672 → **56 %** |
| Mécontents | 1 777 → **45 %** |

**Les commandes récupérées en premier sont les moins problématiques** — cohérent
avec O3, où l'insatisfaction ne dépassait 50 % qu'à partir de 3 jours.

> **Limite** : rien ne garantit que ces clients auraient été satisfaits à
> l'heure. Mais O3 mesure que le taux d'insatisfaction passe de 49 % à 11,5 % —
> la majorité aurait basculé. **Estimation haute.**

---

# 4. Le gain rapporte plus à São Paulo qu'à Rio

## Le fait

| État | CA exposé | Récupéré à 7 j | **Part récupérable** |
|---|---|---|---|
| **SP** | 303 157 | **197 056** | **65,0 %** |
| **RJ** | 251 556 | **105 797** | **42,1 %** |
| ES | 40 333 | 29 521 | **73,2 %** |
| SC | 45 023 | 29 588 | 65,7 % |
| MG | 88 243 | 53 391 | 60,5 % |
| PR | 34 203 | 21 379 | 62,5 % |
| RS | 51 863 | 25 336 | 48,9 % |
| BA | 73 541 | 35 560 | 48,4 % |

## Ce que cela signifie — et cela contredit l'intuition

**Un gain de 7 jours récupère 197 056 R$ à São Paulo contre 105 797 R$ à Rio** —
presque le double, alors que leur CA exposé est comparable.

**Pourquoi RJ résiste** : seuls **42 %** de son CA exposé est récupérable. C'est
ce qu'O1 montrait — **58 % des retards de RJ dépassent 8 jours**.

## Ce que cela implique

> **RJ est la cible prioritaire du diagnostic, mais pas du gain opérationnel
> léger.**

| Cible | Action | Justification |
|---|---|---|
| SP, ES, SC, MG, PR | Gain de quelques jours | **60-73 %** de récupération |
| **RJ** | **Correction de fond** | **42 %** seulement |

---

# 5. Viser le retour à l'heure, pas un seuil intermédiaire

## Le fait — inattendu

| Gain | Ramenées à l'heure | Passées sous 3 jours |
|---|---|---|
| 2 j | **1 370** | 953 |
| 3 j | **1 870** | 1 400 |
| 5 j | **2 770** | 2 302 |

**L'objectif « à l'heure » est plus atteignable que l'objectif « sous 3 jours ».**

## Pourquoi

| Objectif | Population visée |
|---|---|
| **« À l'heure »** | Les commandes à 1, 2, 3 jours — nombreuses et proches du but |
| **« Sous 3 jours »** | Uniquement celles **déjà au-dessus de 3 jours** |

## Ce que cela implique

> **L'objectif intermédiaire n'apporte rien.** Plus difficile à atteindre *et*
> moins satisfaisant — une commande à 2 jours de retard produit encore 34 %
> d'insatisfaction.

Cela confirme O3 : **il n'y a pas de zone de confort.**

---

# 6. Le scénario de 7 jours est prudent

## La vérification

**Méthode** : comparer l'acheminement médian des commandes en retard à celui des
commandes à l'heure, **dans le même état**. L'écart mesure le gain
théoriquement récupérable.

## Le fait

| État | À l'heure | En retard | **Gain théorique** |
|---|---|---|---|
| RS | 9 j | 32 j | **23 j** |
| **RJ** | 8 j | 30 j | **22 j** |
| SC | 9 j | 27 j | 18 j |
| BA | 13 j | 30 j | 17 j |
| MG | 7 j | 22 j | 15 j |
| **SP** | 4 j | 15 j | **11 j** |

## Ce que cela implique

**L'écart réel est de 11 à 23 jours.** Le scénario de 7 jours ne comble qu'un
tiers à deux tiers de cet écart.

> **Les simulations ne sont pas ambitieuses, elles sont prudentes.** Le gisement
> est plus large que ce qui a été chiffré.

---

# 7. Les commandes irrécupérables sont à Rio

## Le fait

Après 7 jours gagnés, **2 862 commandes restent en retard** :

| État | Tranche | Commandes | CA résiduel | Retard médian |
|---|---|---|---|---|
| **RJ** | Late | **423** | 72 292 | 11 j |
| SP | Late | 345 | 64 733 | 10 j |
| **RJ** | Too late | **313** | 49 959 | 21 j |
| SP | Too late | 145 | 29 028 | 20 j |
| **RJ** | Very late | **135** | 23 508 | **38 j** |
| BA | Late | 119 | 24 655 | 11 j |
| SP | Very late | 65 | 12 340 | 52 j |

## Ce que cela signifie

**RJ cumule 871 commandes irrécupérables pour 145 759 R$** — de loin le premier
état. Ses `Very late` ont un retard médian de **38 jours**.

> **Aucun gain opérationnel raisonnable ne les rattrapera.**

---

# 8. Un jour gagné rapporte 90 000 R$

## Le problème

**Améliorer l'acheminement coûte de l'argent** — transporteurs supplémentaires,
entrepôts régionaux, partenaire premium.

**Aucune donnée de coût logistique n'existe dans le dataset.** Le rapport
coût/bénéfice est donc hors de portée.

## Ce qu'on peut faire à la place

Calculer le **bénéfice par jour gagné**. Il devient alors un **seuil de
décision**.

| Jour | Gain marginal |
|---|---|
| **1er** | **134 882 R$** |
| 2e | 83 486 |
| 3e | 76 617 |
| 5e | 86 625 |
| 7e | 84 265 |
| **Moyenne** | **~89 660 R$** |

## Ce que cela signifie

**Le premier jour rapporte 60 % de plus que les suivants** — il récupère les
commandes à exactement 1 jour de retard, les plus nombreuses. Deux chiffres
justes, à ne pas confondre : **134 882 R$** pour le premier jour, **~89 660 R$**
en moyenne sur 7 jours (627 619 ÷ 7), soit **~82 000 R$** pour chacun des jours
suivants (492 737 ÷ 6).

**Ensuite le rendement se stabilise** autour de 80 000 à 87 000 R$ par jour. Pas
de décroissance marquée, ce qui est encourageant pour un investissement
progressif.

## Ce que cela implique

> **Un jour gagné sur l'acheminement rapporte environ 90 000 R$ de chiffre
> d'affaires récupéré.**
>
> Tout investissement permettant de gagner un jour pour moins de 90 000 R$ est
> rentable sur ce seul critère — sans compter les ~250 clients mécontents évités.

**Deux nuances à poser :**

1. Ces 90 000 R$ sont du **CA exposé récupéré**, pas du profit
2. Le gain est calculé sur la période du dataset — à rapporter à une base
   annuelle pour comparer à un investissement

> **C'est ainsi qu'une question sans réponse devient un critère de décision.**
> On ne dit pas « ça vaut le coup », on donne au métier le seuil qui lui permet
> de trancher.

---

# Synthèse — ce que O7 a établi

| # | Constat |
|---|---|
| 1 | **Le rendement est quasi linéaire** : 825 commandes le 1er jour, puis 450 à 550 par jour gagné |
| 2 | **7 jours récupèrent 3 672 commandes** (56 %) et **627 619 R$** (54,5 %) |
| 3 | **Le CA progresse moins vite que le volume** |
| 4 | **3 984 clients mécontents** concernés ; 7 jours en éviteraient **1 777** |
| 5 | **Le gain rapporte plus à São Paulo** (65 %) **qu'à Rio** (42 %) |
| 6 | **Viser le retour à l'heure**, pas un seuil intermédiaire |
| 7 | **Le gain théorique est de 11 à 23 jours** — le scénario de 7 jours est prudent |
| 8 | **871 commandes irrécupérables à RJ**, dont 135 à 38 jours |
| 9 | **Un jour gagné rapporte ~90 000 R$** — seuil de décision |

---

# La recommandation

## En deux volets

| Périmètre | Action | Gain attendu |
|---|---|---|
| **Partout sauf RJ** | Gain de quelques jours sur l'acheminement | **60 à 73 %** du CA exposé récupéré |
| **RJ** | **Correction de fond** de la chaîne d'acheminement | Aucun ajustement ne suffira |

## Le critère financier

> **90 000 R$ par jour gagné.** C'est le seuil au-dessous duquel un
> investissement logistique est rentable.

## Le lien avec O8

| | |
|---|---|
| Gagner 1 jour en exécution | **récupère** 825 commandes |
| Retrancher 1 jour à la promesse | **coûte** 1 292 commandes |

> **Mieux vaut gagner en exécution que raccourcir la promesse.**

Et les deux se combinent : un gain opérationnel de 3 jours permettrait de
resserrer la promesse de 3 jours **à taux de retard constant**.

---

# Questions ouvertes

- [ ] **Quel investissement correspond à un jour gagné ?** Le seuil de 90 000 R$
      est posé, mais le coût réel relève de la direction logistique
- [ ] Le gain théorique de 11 à 23 jours est-il atteignable, ou reflète-t-il des
      cas structurellement différents (zones isolées, transporteurs distincts) ?
      La donnée ne contient pas l'identité du transporteur
- [ ] Un gain **différencié par état** — plus ambitieux là où l'écart est large —
      rapporterait-il davantage qu'un gain uniforme ?
