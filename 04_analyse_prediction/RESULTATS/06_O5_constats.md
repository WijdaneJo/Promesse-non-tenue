\# O5 — Constats : la trajectoire vendeur



> Ce document traduit les résultats de `06\_O5\_trajectoire\_vendeur.sql` en

> \*\*énoncés utilisables\*\*.

>

> \*\*Structure de chaque constat\*\* : le fait → ce qu'il signifie → ce qu'il implique.



\*\*Pourquoi cet objectif existe.\*\* Le projet a perdu son objectif initial en

qualification : avec 3,12 % de réachat (H1), impossible de mesurer si un client

déçu revient. O5 est le remplacement — faute d'observer le \*\*client\*\*, on observe

le \*\*vendeur\*\*, qui lui dispose d'un historique.



\---



\# 1. Le marché a doublé — c'est le repère de lecture



\## Le fait



| Fenêtre | Commandes |

|---|---|

| \*\*P1\*\* — février-août 2017 | 21 033 |

| \*\*P2\*\* — février-août 2018 | 45 016 |

| \*\*Croissance\*\* | \*\*+114,03 %\*\* |



\## Pourquoi ce découpage



Mêmes mois d'une année sur l'autre : la \*\*saisonnalité est neutralisée\*\*. On sait

qu'elle existe — le Black Friday de novembre a été identifié en O1.



\## Ce que cela implique



> \*\*Un vendeur qui croît de 50 % a en réalité perdu des parts de marché.\*\*



Sans ce repère, toute croissance positive serait lue comme un succès. C'est la

correction la plus importante de cet objectif.



\---



\# 2. Seuls 253 vendeurs sont analysables



Trois règles se cumulent : RG-09 (mono-vendeur), RG-08 (10 commandes \*\*dans

chaque\*\* fenêtre), RG-10 (présent dans les deux).



\*\*Résultat : 253 vendeurs\*\*, sur 1 323 retenus par RG-08 sur l'ensemble de la

période. \*\*81 % sont éliminés.\*\*



Ces 253 sont les vendeurs \*\*établis et durables\*\*. C'est exactement le biais de

survie annoncé par RG-10 — il est mesuré au constat 4, et il changera la

conclusion.



\---



\# 3. Parmi les survivants, le retard n'a aucun effet



\## Le fait



| Groupe | Vendeurs | Retard P1 moyen | Évolution moyenne |

|---|---|---|---|

| \*\*Sous-performe le marché\*\* | 190 | \*\*3,06 %\*\* | −11,05 % |

| \*\*Surperforme le marché\*\* | 63 | \*\*3,36 %\*\* | +419,46 % |



\*Le seuil est +114 %, pas 0 %.\*



\## Ce que cela signifie



\*\*Les deux groupes ont un taux de retard identique.\*\* 0,3 point d'écart — du

bruit. Et dans le sens \*\*inverse\*\* de l'attendu.



Quelques cas individuels le confirment :



| Vendeur | Évolution | Retard P1 |

|---|---|---|

| 6cd68b3e… | \*\*−84,5 %\*\* | \*\*0,00 %\*\* |

| ea8482cd… | \*\*+5 258 %\*\* | \*\*0,00 %\*\* |



Des vendeurs à zéro retard perdent 85 % de leur activité ; d'autres à zéro

retard en gagnent 5 000 %.



\## Une observation de contexte



\*\*190 vendeurs sur 253, soit 75 %, perdent des parts de marché.\*\* Dans une

plateforme qui double, les trois quarts des vendeurs établis reculent

relativement.



\## Conclusion provisoire



> Le marché ne sanctionne pas les vendeurs défaillants.



⚠️ \*\*Corrigée par le constat suivant.\*\*



\---



\# 4. La sanction existe — mais elle est binaire



\## Le test du biais de survie



Le constat 3 ne porte que sur les vendeurs présents dans les deux périodes.

\*\*Le filtre ne porte donc plus que sur P1\*\* — sinon les disparus seraient

éliminés d'office, alors que ce sont eux qu'on cherche à mesurer.



\*Définition : « disparu » = zéro commande en P2.\*



\## Le fait



| Groupe | Vendeurs | Retard P1 |

|---|---|---|

| \*\*Disparus\*\* | 96 | \*\*5,40 %\*\* |

| Survivants | 331 | \*\*3,52 %\*\* |



\*\*Les disparus avaient 53 % de retard en plus.\*\*



\## Ce que cela signifie



```

Parmi les survivants        → le retard n'a AUCUN effet   (3,06 % vs 3,36 %)

Survivants vs disparus      → l'écart est NET             (3,52 % vs 5,40 %)

```



> \*\*Un vendeur qui livre mal ne recule pas progressivement. Il disparaît.\*\*



\## Ce que cela implique



\*\*La sanction du marché existe, mais elle arrive tard et d'un coup\*\* — quand le

vendeur est déjà perdu pour la plateforme.



> \*\*Olist ne peut pas compter sur cette autorégulation.\*\* Elle doit intervenir

> \*\*en amont\*\*, avant que le vendeur ne quitte la plateforme.



> ⚠️ \*\*Nuance.\*\* 96 vendeurs sur 427 ont disparu, soit \*\*22 %\*\* — ce n'est pas

> marginal. Mais « disparu du dataset » ne signifie pas forcément « a cessé son

> activité » : le dataset s'arrête en août 2018.



\---



\# 5. L'engagement contractuel prédit le départ



\## Pourquoi cet indicateur



O2 avait identifié `shipping\_limit\_date` — la date limite d'expédition imposée au

vendeur. Trois avantages sur le taux de retard :



| | Taux de retard | Dépassement de la date limite |

|---|---|---|

| \*\*Ce qu'il mesure\*\* | Résultat final, toutes causes | \*\*La part du vendeur seule\*\* |

| \*\*Quand on le sait\*\* | À la livraison, des semaines plus tard | \*\*Dès l'expédition\*\* |

| \*\*Opposabilité\*\* | Contestable (« c'est le transporteur ») | \*\*Incontestable\*\* |



\## Le fait



| Profil | Vendeurs | Disparus | Taux de disparition | Dépassement moyen |

|---|---|---|---|---|

| Dépassement ≤ 20 % | 360 | 76 | \*\*21,11 %\*\* | 3,87 % |

| \*\*Dépassement > 20 %\*\* | 67 | 20 | \*\*29,85 %\*\* | \*\*37,89 %\*\* |



\## Ce que cela signifie



\*\*Les vendeurs qui ne tiennent pas leur engagement contractuel disparaissent

41 % plus souvent.\*\*



Et les deux groupes ne se ressemblent pas : \*\*37,89 % contre 3,87 %\*\* de

dépassement moyen. Ce sont deux comportements distincts, pas deux nuances d'un

même profil.



\## Ce que cela implique



> \*\*Le dépassement de la date limite d'expédition est un signal d'alerte

> exploitable — et meilleur que le taux de retard.\*\*



C'est directement actionnable par la direction des partenariats.



\---



\# 6. Le signal est dans le niveau, pas dans la pente



\## La question



Si le taux de dépassement se \*\*dégrade\*\* avant le départ, Olist dispose d'une

fenêtre d'intervention. S'il est stable, le départ n'est précédé d'aucun signal.



P1 est découpée en deux moitiés : février-avril et juin-août 2017.



\## Le fait — contre-intuitif



| Groupe | Vendeurs | Fév-avr | Juin-août | Évolution |

|---|---|---|---|---|

| \*\*Disparus\*\* | 32 | \*\*21,84 %\*\* | \*\*11,92 %\*\* | \*\*−9,92 pts\*\* |

| Survivants | 197 | 7,14 % | 7,22 % | +0,09 pt |



\*\*Les disparus s'améliorent avant de partir.\*\* Leur taux baisse de moitié, alors

que les survivants restent stables.



\## Trois lectures possibles



| Hypothèse | Ce qu'elle supposerait |

|---|---|

| A — Tentative de redressement | Ils essaient et échouent quand même |

| B — Effet de volume | Ils réduisent leur activité et gèrent mieux leurs dernières commandes |

| \*\*C — Effet de sélection\*\* | \*\*Seuls 32 disparus sur 96 passent le filtre\*\* des 5 commandes par demi-période |



\*\*C est probablement dominant.\*\* Ceux qui sont partis brutalement, sans commandes

en fin de P1, sont exclus de ce test.



\## Ce qu'on retient malgré tout



\*\*Le niveau de départ est le vrai signal\*\* : 21,84 % contre 7,14 %. \*\*Trois fois

plus, six mois avant le départ.\*\*



> Un vendeur qui dépasse sa date limite trois fois plus que la moyenne est déjà

> en danger — sans qu'il soit besoin d'attendre une dégradation.



\## Ce que cela implique



\*\*La recommandation change de forme.\*\*



Ce n'est pas \*« surveillez la pente »\*, c'est \*\*« surveillez le niveau »\*\*.



C'est même préférable pour Olist : un niveau se lit immédiatement, une tendance

demande des mois d'observation.



\---



\# L'enseignement de méthode



\*\*Le constat 3, seul, aurait conclu à l'absence de lien.\*\*



C'est le constat 4 qui révèle que le lien existait — \*\*masqué par la composition

de l'échantillon\*\*. Les vendeurs les plus affectés avaient déjà quitté la

plateforme, donc l'analyse ne les voyait plus.



> RG-10 annonçait ce biais au cadrage, en précisant qu'il pousserait le résultat

> vers une \*\*sous-estimation\*\* de l'effet. C'est exactement ce qui s'est produit.



\*\*Une analyse qui ne teste pas ce qu'elle ne voit pas produit une conclusion

fausse.\*\*



\---



\# Synthèse — ce que O5 a établi



| # | Constat |

|---|---|

| 1 | \*\*Le marché a doublé\*\* (+114 %) — tout vendeur sous ce seuil perd des parts |

| 2 | \*\*253 vendeurs seulement\*\* sont présents dans les deux périodes |

| 3 | \*\*Parmi eux, le retard n'a aucun effet\*\* : 3,06 % contre 3,36 % |

| 4 | \*\*75 % des vendeurs établis\*\* perdent des parts de marché |

| 5 | \*\*Les disparus avaient 5,40 % de retard\*\* contre 3,52 % — 53 % de plus |

| 6 | \*\*La sanction est binaire\*\* : un vendeur qui livre mal ne recule pas, il disparaît |

| 7 | \*\*Les vendeurs dépassant leur date limite disparaissent 41 % plus souvent\*\* |

| 8 | \*\*Le signal est dans le niveau\*\* : 21,84 % six mois avant le départ, contre 7,14 % |



\---



\# La recommandation



> \*\*Olist doit intervenir en amont, sur un indicateur qu'elle possède déjà.\*\*



Le marché sanctionne, mais tardivement et brutalement — quand le vendeur est

déjà perdu. L'autorégulation ne suffit pas.



\*\*Le dépassement de `shipping\_limit\_date` fournit l'indicateur\*\* :



| Critère | Valeur |

|---|---|

| Disponible | Dès l'expédition |

| Imputable | Au vendeur, sans ambiguïté |

| Prédictif | +41 % de risque de départ au-delà de 20 % |

| Seuil d'alerte | \*\*20 % de dépassement\*\* |



\---



\# Ce que O5 apporte aux autres objectifs



\*\*Lien avec O2\*\* — la liste des vendeurs à problème d'expédition prend ici tout

son sens : ce sont des candidats au départ, pas seulement des partenaires

défaillants.



\*\*Lien avec O4\*\* — l'absence de concentration du CA exposé par vendeur

relativisait l'enjeu de cet objectif. Le constat 6 lui donne une portée

\*\*stratégique\*\* : perdre un vendeur coûte plus qu'un retard.



\*\*Pour la restitution\*\* — un indicateur de pilotage prêt à l'emploi, avec son

seuil.



\---



\# Questions ouvertes



\- \[ ] \*\*Les 96 vendeurs disparus ont-ils cessé leur activité ou simplement

&#x20;     réduit ?\*\* Le dataset s'arrête en août 2018 — impossible de trancher

\- \[ ] Le seuil de 20 % est-il optimal ? Un test à 15 % ou 25 % affinerait

&#x20;     l'alerte

\- \[ ] Le constat 6 est fragilisé par l'effet de sélection (32 disparus sur 96).

&#x20;     Un découpage différent de P1 donnerait-il un résultat plus robuste ?



> \*\*Hors périmètre assumé\*\* : expliquer ce qui détermine la trajectoire d'un

> vendeur — prix, catalogue, ancienneté. Le sujet du projet est la promesse non

> tenue, pas la performance commerciale des partenaires.

