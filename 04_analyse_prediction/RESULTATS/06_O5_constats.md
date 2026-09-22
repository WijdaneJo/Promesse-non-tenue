# O5 — Constats : la trajectoire vendeur

> Ce document traduit les résultats de `06_O5_trajectoire_vendeur.sql` en
> **énoncés utilisables**.
>
> **Structure de chaque constat** : le fait → ce qu'il signifie → ce qu'il implique.

**Pourquoi cet objectif existe.** Le projet a perdu son objectif initial en
qualification : avec 3,12 % de réachat (H1), impossible de mesurer si un client
déçu revient. O5 est le remplacement — faute d'observer le **client**, on observe
le **vendeur**, qui lui dispose d'un historique.

---

# 1. Le marché a doublé — c'est le repère de lecture

## Le fait

| Fenêtre | Commandes |
|---|---|
| **P1** — février-août 2017 | 21 033 |
| **P2** — février-août 2018 | 45 016 |
| **Croissance** | **+114,03 %** |

## Pourquoi ce découpage

Mêmes mois d'une année sur l'autre : la **saisonnalité est neutralisée**. On sait
qu'elle existe — le Black Friday de novembre a été identifié en O1.

## Ce que cela implique

> **Un vendeur qui croît de 50 % a en réalité perdu des parts de marché.**

Sans ce repère, toute croissance positive serait lue comme un succès. C'est la
correction la plus importante de cet objectif.

---

# 2. Seuls 241 vendeurs sont analysables

Trois règles se cumulent : RG-09 (mono-vendeur), RG-08 (10 commandes **dans
chaque** fenêtre), RG-10 (présent dans les deux).

**Résultat : 241 vendeurs**, sur 1 217 retenus par RG-08 sur l'ensemble de la
période. **80 % sont éliminés.**

Ces 241 sont les vendeurs **établis et durables**. C'est exactement le biais de
survie annoncé par RG-10 — il est mesuré au constat 4, et il changera la
conclusion.

---

# 3. Parmi les survivants, le retard n'a aucun effet

## Le fait

| Groupe | Vendeurs | Retard P1 moyen | Évolution moyenne |
|---|---|---|---|
| **Sous-performe le marché** | 181 | **3,11 %** | −13,17 % |
| **Surperforme le marché** | 60 | **2,99 %** | +413,78 % |

*Le seuil est +114 %, pas 0 %.*

## Ce que cela signifie

**Les deux groupes ont un taux de retard identique.** 0,12 point d'écart — du
bruit, sans portée.

Quelques cas individuels le confirment :

| Vendeur | Évolution | Retard P1 |
|---|---|---|
| 6cd68b3e… | **−83,6 %** | **0,00 %** |
| ea8482cd… | **+5 050 %** | **0,00 %** |

Des vendeurs à zéro retard perdent 84 % de leur activité ; d'autres à zéro
retard en gagnent 5 000 %.

## Une observation de contexte

**181 vendeurs sur 241, soit 75 %, perdent des parts de marché.** Dans une
plateforme qui double, les trois quarts des vendeurs établis reculent
relativement.

## Conclusion provisoire

> Le marché ne sanctionne pas les vendeurs défaillants.

**Corrigée par le constat suivant.**

---

# 4. La sanction existe — mais elle est binaire

## Le test du biais de survie

Le constat 3 ne porte que sur les vendeurs présents dans les deux périodes.
**Le filtre ne porte donc plus que sur P1** — sinon les disparus seraient
éliminés d'office, alors que ce sont eux qu'on cherche à mesurer.

*Définition : « disparu » = zéro commande en P2.*

## Le fait

| Groupe | Vendeurs | Retard P1 |
|---|---|---|
| **Disparus** | 81 | **4,76 %** |
| Survivants | 316 | **3,38 %** |

**Les disparus avaient 41 % de retard en plus.**

## Ce que cela signifie

```
Parmi les survivants        → le retard n'a AUCUN effet   (3,11 % vs 2,99 %)
Survivants vs disparus      → l'écart est NET             (3,38 % vs 4,76 %)
```

> **Un vendeur qui livre mal ne recule pas progressivement. Il disparaît.**

## Ce que cela implique

**La sanction du marché existe, mais elle arrive tard et d'un coup** — quand le
vendeur est déjà perdu pour la plateforme.

> **Olist ne peut pas compter sur cette autorégulation.** Elle doit intervenir
> **en amont**, avant que le vendeur ne quitte la plateforme.

> **Nuance.** 81 vendeurs sur 397 ont disparu, soit **20 %** — ce n'est pas
> marginal. Mais « disparu du dataset » ne signifie pas forcément « a cessé son
> activité » : le dataset s'arrête en août 2018.

---

# 5. L'engagement contractuel prédit le départ

## Pourquoi cet indicateur

O2 avait identifié `shipping_limit_date` — la date limite d'expédition imposée au
vendeur. Trois avantages sur le taux de retard :

| | Taux de retard | Dépassement de la date limite |
|---|---|---|
| **Ce qu'il mesure** | Résultat final, toutes causes | **La part du vendeur seule** |
| **Quand on le sait** | À la livraison, des semaines plus tard | **Dès l'expédition** |
| **Opposabilité** | Contestable (« c'est le transporteur ») | **Incontestable** |

## Le fait

| Profil | Vendeurs | Disparus | Taux de disparition | Dépassement moyen |
|---|---|---|---|---|
| Dépassement ≤ 20 % | 340 | 65 | **19,12 %** | 4,13 % |
| **Dépassement > 20 %** | 57 | 16 | **28,07 %** | **36,93 %** |

## Ce que cela signifie

**Les vendeurs qui ne tiennent pas leur engagement contractuel disparaissent
47 % plus souvent.**

Et les deux groupes ne se ressemblent pas : **36,93 % contre 4,13 %** de
dépassement moyen. Ce sont deux comportements distincts, pas deux nuances d'un
même profil.

> **Prudence.** Le groupe à risque compte 57 vendeurs, dont 16 disparus.
> L'écart est net, mais il repose sur de petits effectifs.

## Ce que cela implique

> **Le dépassement de la date limite d'expédition est un signal d'alerte
> exploitable — et meilleur que le taux de retard.**

C'est directement actionnable par la direction des partenariats.

---

# 6. Le signal est dans le niveau, pas dans la pente

## La question

Si le taux de dépassement se **dégrade** avant le départ, Olist dispose d'une
fenêtre d'intervention. S'il est stable, le départ n'est précédé d'aucun signal.

P1 est découpée en deux moitiés : février-avril et juin-août 2017.

## Le fait

| Groupe | Vendeurs | Fév-avr | Juin-août | Évolution |
|---|---|---|---|---|
| **Disparus** | 27 | **15,53 %** | **12,79 %** | −2,74 pts |
| Survivants | 183 | 7,29 % | 7,08 % | −0,20 pt |

## Ce que cela signifie

**Aucune dégradation n'annonce le départ.** Les deux groupes restent à peu près
stables : une variation de 2,74 points sur 27 vendeurs ne permet pas de conclure
à une tendance.

**Le niveau, en revanche, sépare nettement les deux groupes** : 15,53 % de
dépassement chez les futurs disparus contre 7,29 % chez les survivants, soit
**deux fois plus, six mois avant le départ.**

> Un vendeur qui dépasse sa date limite deux fois plus que la moyenne est déjà
> en danger — sans qu'il soit besoin d'attendre une dégradation.

> **Prudence.** Seuls 27 disparus sur 81 passent le filtre des 5 commandes par
> demi-période. Ceux qui sont partis brutalement, sans commandes en fin de P1,
> sont exclus de ce test.

## Ce que cela implique

**La recommandation change de forme.**

Ce n'est pas *« surveillez la pente »*, c'est **« surveillez le niveau »**.

C'est même préférable pour Olist : un niveau se lit immédiatement, une tendance
demande des mois d'observation.

---

# L'enseignement de méthode

**Le constat 3, seul, aurait conclu à l'absence de lien.**

C'est le constat 4 qui révèle que le lien existait — **masqué par la composition
de l'échantillon**. Les vendeurs les plus affectés avaient déjà quitté la
plateforme, donc l'analyse ne les voyait plus.

> RG-10 annonçait ce biais au cadrage, en précisant qu'il pousserait le résultat
> vers une **sous-estimation** de l'effet. C'est exactement ce qui s'est produit.

**Une analyse qui ne teste pas ce qu'elle ne voit pas produit une conclusion
fausse.**

---

# Synthèse — ce que O5 a établi

| # | Constat |
|---|---|
| 1 | **Le marché a doublé** (+114 %) — tout vendeur sous ce seuil perd des parts |
| 2 | **241 vendeurs seulement** sont présents dans les deux périodes |
| 3 | **Parmi eux, le retard n'a aucun effet** : 3,11 % contre 2,99 % |
| 4 | **75 % des vendeurs établis** perdent des parts de marché |
| 5 | **Les disparus avaient 4,76 % de retard** contre 3,38 % — 41 % de plus |
| 6 | **La sanction est binaire** : un vendeur qui livre mal ne recule pas, il disparaît |
| 7 | **Les vendeurs dépassant leur date limite disparaissent 47 % plus souvent** |
| 8 | **Le signal est dans le niveau** : 15,53 % de dépassement six mois avant le départ, contre 7,29 % |

---

# La recommandation

> **Olist doit intervenir en amont, sur un indicateur qu'elle possède déjà.**

Le marché sanctionne, mais tardivement et brutalement — quand le vendeur est
déjà perdu. L'autorégulation ne suffit pas.

**Le dépassement de `shipping_limit_date` fournit l'indicateur** :

| Critère | Valeur |
|---|---|
| Disponible | Dès l'expédition |
| Imputable | Au vendeur, sans ambiguïté |
| Prédictif | +47 % de risque de départ au-delà de 20 % |
| Seuil d'alerte | **20 % de dépassement** |

---

# Ce que O5 apporte aux autres objectifs

**Lien avec O2** — la liste des vendeurs à problème d'expédition prend ici tout
son sens : ce sont des candidats au départ, pas seulement des partenaires
défaillants.

**Lien avec O4** — l'absence de concentration du CA exposé par vendeur
relativisait l'enjeu de cet objectif. Le constat 6 lui donne une portée
**stratégique** : perdre un vendeur coûte plus qu'un retard.

**Pour la restitution** — un indicateur de pilotage prêt à l'emploi, avec son
seuil.

---

# Questions ouvertes

- [ ] **Les vendeurs disparus ont-ils cessé leur activité ou simplement
      réduit ?** Le dataset s'arrête en août 2018 — impossible de trancher
- [ ] Le seuil de 20 % est-il optimal ? Un test à 15 % ou 25 % affinerait
      l'alerte
- [ ] Le constat 6 est fragilisé par l'effet de sélection (27 disparus sur 81).
      Un découpage différent de P1 donnerait-il un résultat plus robuste ?

> **Hors périmètre assumé** : expliquer ce qui détermine la trajectoire d'un
> vendeur — prix, catalogue, ancienneté. Le sujet du projet est la promesse non
> tenue, pas la performance commerciale des partenaires.