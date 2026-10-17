# 04 — Analyse et prédiction

> **Où naissent les ruptures de délai sur une marketplace, quel volume d'activité exposent-elles, et peut-on les anticiper au moment de la commande ?**

**Périmètre :** `mart.orders`, 96 447 commandes livrées (2016-2018) · 6 534 en retard, soit **6,77 %** · 15,4 M R$ de chiffre d'affaires.

---

## En une phrase

> **Le retard n'est pas un défaut d'exécution isolé : c'est un écart entre ce qu'Olist promet et ce que le transport livre.** Il naît de l'acheminement, se concentre sur quelques états, expose 1,15 M R$ de chiffre d'affaires, et il est reparti à la hausse à l'été 2018 quand Olist a réduit ses délais promis plus vite que son transport ne s'améliorait.

---

## Les huit objectifs

| Objectif | Question | Constat principal | Chiffres clés |
|---|---|---|---|
| [**O1**](RESULTATS/01_O1_constats.md) Mesure | Où et quand le retard apparaît-il ? | Le retard est géographique et dépend autant de la promesse que de l'exécution | De 2,76 % à 21,41 % selon l'état · RJ 12,11 %, 1 495 retards · incident mars 2018 : 18,96 % |
| [**O2**](RESULTATS/03_O2_constats.md) Origine | Quel maillon du parcours est responsable ? | Le retard naît de l'acheminement, pas du vendeur | Acheminement 7 → 26 j (95 % de l'écart) · 84 % des retards imputables au transport |
| [**O3**](RESULTATS/02_O3_constats.md) Tolérance | À partir de quand le client décroche-t-il ? | Aucune tolérance ; bascule à 3 jours ; l'avance n'apporte rien | Insatisfaction ×4,3 dès 1-7 j de retard · 50,4 % à 3 j |
| [**O4**](RESULTATS/04_O4_constats.md) Exposition | Combien d'argent est concerné ? | L'enjeu est géographique, ni vendeur ni catégorie | 1 150 866 R$ exposés (7,47 %) · 721 160 R$ avec client mécontent · SP + RJ = 48 % |
| [**O5**](RESULTATS/06_O5_constats.md) Vendeurs | Le marché sanctionne-t-il les vendeurs défaillants ? | Oui, mais de façon binaire : ils disparaissent | Disparus : 4,76 % de retard contre 3,38 % · +47 % de départs au-delà de 20 % de dépassement |
| **O6** Prédiction ([constats](RESULTATS/08_O6_constats.md) · [méthode](RESULTATS/O6_fiche_methode.md)) | Peut-on anticiper le retard à la commande ? | En partie : le modèle bat une règle simple, mais devient obsolète quand la promesse change | 50,8 % de détection contre 28,1 % · 82 % de fausses alertes au mieux |
| [**O7**](RESULTATS/07_O7_constats.md) Scénarios | Que rapporte un transport plus rapide ? | Le gain est quasi linéaire et chiffrable | 1er jour gagné = 825 commandes et 134 882 R$ · ~90 000 R$ par jour en moyenne sur 7 jours |
| [**O8**](RESULTATS/05_O8_constats.md) Calibrage | Que coûte une promesse plus courte ? | Retrancher un jour coûte plus que gagner un jour ne rapporte, et la marge est déjà tombée à 7 jours en août 2018 | +1 292 commandes en retard au premier jour retranché · marge de 20 j en juin, 7 j en août |

---

## Six découvertes

**1. La moyenne nationale ne décrit personne.** Le taux de retard varie d'un facteur 8 selon l'état. São Paulo, 42 % du volume, affiche 4,50 % et fabrique la moyenne ; Rio de Janeiro, proche et pourtant trois fois plus en retard que PR et MG, est le point noir historique du réseau. *(O1)*

**2. Le transport est le levier, le vendeur est secondaire.** 19 des 20 jours d'écart entre une commande à l'heure et une commande en retard viennent de l'acheminement. Le problème de RJ est établi de trois façons comme un problème de transport. *(O2)*

**3. Le client ne tolère aucun retard.** Dès le premier jour, l'insatisfaction augmente de 60 % ; à 3 jours, un client sur deux est mécontent. À l'inverse, livrer en avance n'améliore pas la note. *(O3)*

**4. Un indicateur contractuel existe déjà.** Le dépassement de la date limite d'expédition multiplie le risque de retard par 4 et annonce le départ des vendeurs, six mois à l'avance. Il est imputable et opposable. *(O2, O5)*

**5. La promesse est un levier qu'Olist contrôle, et qu'elle a déjà actionné.** Entre 2017 et août 2018, le délai promis passe d'environ 23 à 14 jours, quand l'exécution ne gagne qu'environ 3 jours. À l'été 2018, les retards repartent : de 1,2 % en juin à 6,2 % en août, et jusqu'à 9,0 % vers São Paulo. Retrancher un jour de promesse coûte 1 292 retards ; gagner un jour de transport en récupère 825. *(O1, O6, O7, O8)*

**6. Le retard est difficile à prédire à la commande, et c'est logique.** Il se produit pendant l'acheminement, après la commande. Un modèle simple détecte deux fois plus de retards qu'une règle par état, et une variable de marge (promesse rapportée à la distance) l'améliore de 9 points. Mais il doit être ré-entraîné dès que la politique de promesse change. *(O6)*

---

## Ce que cela implique

| Levier | Cible | Appui |
|---|---|---|
| **Aligner la promesse sur l'exécution** : ne resserrer qu'à hauteur des jours réellement gagnés | Surtout SP à l'été 2018 | O1, O6, O7, O8 |
| **Corriger la chaîne d'acheminement** de Rio de Janeiro, où un gain léger ne suffit pas | RJ | O1, O2, O7 |
| **Gagner quelques jours d'acheminement** ailleurs, rentable sous ~90 000 R$ par jour | SP, MG, PR, SC, ES | O7 |
| **Piloter les vendeurs sur la date limite d'expédition**, seuil d'alerte à 20 % | Direction des partenariats | O2, O5 |
| **Anticiper le Black Friday**, pic récurrent et daté | National | O1 |
| **Alerter à la commande** pour les actions peu coûteuses (suivi, information du client) | Top 1 à 10 % du risque | O6 |

*Les recommandations détaillées sont rédigées en phase 06.*

---

## Organisation du dossier

```
04_analyse_prediction/
├── SQL/          Requêtes commentées, résultats en commentaire
├── PYTHON/       O6_modele_predictif.ipynb (modèle prédictif)
└── RESULTATS/    Un fichier de constats par objectif
                  + O6_fiche_methode.md, O6_nuage_seuil.png, O6_seuils.csv
```

Chaque fichier de constats suit la même structure : **le fait → ce qu'il signifie → ce qu'il implique**, avec une synthèse et les questions ouvertes.

---

## Méthode

Quelques réflexes appliqués tout au long de l'analyse :

- **Toujours le volume à côté du taux** : SP a le plus de retards et l'un des meilleurs taux.
- **Vérifier ce qui pourrait invalider un résultat** : Santa Catarina (artefact du transport), les articles de Noël (petit effectif), la troncature d'août 2018 (vérifiée, pas de biais).
- **Tester ce que l'analyse ne voit pas** : parmi les seuls vendeurs survivants, le retard n'avait aucun effet ; en intégrant les disparus, le lien apparaît.
- **Évaluer un modèle comme il sera utilisé** : découpage dans le temps, qui a révélé le changement de politique de promesse.

---

## Limites

- **Aucune donnée de coût logistique** : les gains sont exprimés en chiffre d'affaires exposé, pas en profit.
- **Identité des transporteurs absente** : la cause précise de la lenteur de RJ et de l'incident de mars 2018 reste à établir avec le métier.
- **Réachat de 3,12 %** : l'effet du retard sur la fidélité client n'est pas mesurable.
- **Fin des données en août 2018** : les effets du resserrement de la promesse ne sont observés que sur trois mois.

---

## Questions ouvertes prioritaires

- [ ] Quelle est la cause externe de l'incident de février-mars 2018 ? *(O1)*
- [ ] Pourquoi l'acheminement est-il structurellement lent à RJ, et pourquoi s'améliore-t-il en 2018 ? *(O2, O6)*
- [ ] Le resserrement de la promesse de l'été 2018 était-il une décision délibérée ? *(O1, O6)*
- [ ] Les commandes en retard portent-elles des produits plus lourds ou volumineux ? *(O4, O6)*
- [ ] Pourquoi certains clients de SP restent-ils satisfaits malgré 30 jours de retard ? *(O3)*