# O4 — Constats : l'exposition financière

> Ce document traduit les résultats de `04_O4_exposition_financiere.sql` en
> **énoncés utilisables**.
>
> **Structure de chaque constat** : le fait → ce qu'il signifie → ce qu'il implique.

**Ancrage.** 15 416 546 R$ de chiffre d'affaires sur le périmètre de
96 447 commandes.

> ⚠️ **Exposition ≠ perte.** Ces métriques mesurent l'argent qui **transite** par
> des commandes dont la promesse a été rompue. Avec un réachat de 3,12 % (H1),
> aucune perte future n'est observable. La distinction est maintenue partout.

---

# 1. L'exposition financière dépasse l'exposition en volume

## Le fait

| | Valeur |
|---|---|
| CA total du périmètre | 15 416 546 R$ |
| **CA exposé au retard** | **1 150 866 R$** |
| **Part du CA** | **7,47 %** |
| *Rappel : part des commandes* | *6,77 %* |

## Ce que cela signifie

**7,47 % du CA pour 6,77 % des commandes.** L'écart est petit mais il a un sens :
les commandes en retard sont plus chères que la moyenne.

La question posée en O1 — *« 6,77 % des commandes ne veut pas dire 6,77 % du
CA »* — trouve ici sa réponse.

## Ce que cela implique

**Quand la direction générale lit « 6,77 % de retards », elle sous-estime
l'enjeu.** Le chiffre à communiquer est **7,47 % du chiffre d'affaires**.

---

# 2. Le surcoût vient du produit, pas de la complexité

## Le fait

| Population | Panier moyen |
|---|---|
| Commandes à l'heure | 158,66 R$ |
| **Commandes en retard** | **176,16 R$** |

Décomposition de cet écart de 11 % :

| | À l'heure | En retard | Écart |
|---|---|---|---|
| **Nombre d'articles** | 1,14 | **1,11** | **−3 %** |
| Prix des articles | 136,03 | 150,89 | **+11 %** |
| Frais de port | 22,60 | 25,25 | **+12 %** |

## Ce que cela signifie

**L'hypothèse « commandes plus complexes à préparer » est écartée.** Les
commandes en retard ont **moins** d'articles, pas plus.

Ce sont des commandes **plus chères à l'unité**, avec des frais de port
proportionnellement plus élevés.

> **La piste.** La quasi-proportionnalité entre le surcoût produit (+11 %) et le
> surcoût de transport (+12 %) suggère des articles plus **volumineux** ou plus
> **lourds** — donc un acheminement plus contraignant.
>
> ⚠️ **Piste, pas preuve.** Trancher demanderait le poids et le volume des
> produits (`staging.products`). Non testé.

## Ce que cela implique

Si la piste se confirme, l'encombrement deviendrait une **variable prédictive**
pour O6 — et un critère de segmentation logistique.

> **Précaution méthodologique.** La comparaison oppose bien deux populations
> **disjointes** (`is_late` / `NOT is_late`). Comparer les commandes en retard à
> l'ensemble — qui les contient — aurait atténué l'écart.

---

# 3. Deux tiers du CA exposé s'accompagnent d'un mécontentement

## Le fait

| | Valeur |
|---|---|
| CA exposé (M-06) | 1 150 866 R$ |
| **CA à risque avéré (M-07)** | **721 160 R$** |
| **Part** | **62,66 %** |

## Ce que cela signifie

**La distinction entre les deux métriques est essentielle :**

- **M-06** mesure un **risque** — l'argent associé à une promesse rompue
- **M-07** mesure une **réaction client constatée** — un mécontentement exprimé

Le second est plus difficile à contester.

Ce niveau est cohérent avec O3, qui mesurait 80 % d'insatisfaction dès 8 jours
de retard.

> ⚠️ **Ce montant est un plancher.** Les 646 commandes sans avis (RG-07) sont
> exclues du numérateur. Certaines étaient probablement des clients mécontents
> qui n'ont pas répondu.

## Un second chiffre, plus strict

O3 a établi que la bascule se fait à **3 jours** : la note passe sous 3 et
l'insatisfaction dépasse 50 %.

| Seuil retenu | CA exposé | Part du CA |
|---|---|---|
| Retard ≥ 1 jour | 1 150 866 R$ | 7,47 % |
| **Retard ≥ 3 jours** | **932 499 R$** | **6,05 %** |

**81 % du CA exposé concerne des retards de 3 jours ou plus** — au-delà du seuil
où la majorité des clients bascule.

## Ce que cela implique

**Trois chiffres, trois niveaux de rigueur :**

| Mesure | Montant | Usage |
|---|---|---|
| CA exposé (≥ 1 j) | 1 150 866 R$ | Vision large du risque |
| CA exposé au seuil critique (≥ 3 j) | **932 499 R$** | **Mesure conservatrice** |
| CA à risque avéré | 721 160 R$ | Réaction client constatée |

Pour la direction générale : *721 000 R$ de chiffre d'affaires ont généré un
client explicitement mécontent.*

---

# 4. RJ concentre l'enjeu financier

## Le fait

| État | CA total | CA exposé | Taux |
|---|---|---|---|
| AL | 94 196 | 20 964 | **22,26 %** |
| MA | 147 807 | 29 031 | 19,64 % |
| SE | 70 289 | 12 726 | 18,10 % |
| CE | 266 464 | 36 919 | 13,85 % |
| BA | 591 271 | 73 541 | 12,44 % |
| **RJ** | 2 055 579 | **251 556** | **12,24 %** |
| **SP** | 5 766 546 | **303 157** | 5,26 % |
| MG | 1 818 183 | 88 243 | 4,85 % |
| RO | 56 976 | 1 216 | 2,13 % |

## Ce que cela signifie

**Deux lectures désignent deux cibles différentes** — c'est le même arbitrage
qu'en O1.

**Par intensité** : AL (22,26 %), MA, SE. Plus d'un cinquième du CA d'Alagoas
transite par des commandes en retard. **Mais les montants sont faibles** —
21 K, 29 K, 13 K R$.

**Par montant** : SP (303 157 R$) et RJ (251 556 R$).

> **RJ cumule les deux.** Deuxième montant du pays **avec** un taux de 12,24 %,
> soit **deux fois et demie celui de São Paulo**.

**São Paulo expose plus en valeur absolue, mais c'est mécanique** : son CA est
presque trois fois supérieur, et son taux reste parmi les meilleurs du pays.
C'est un effet de taille, pas une contre-performance.

## Ce que cela implique

**RJ est la cible prioritaire en volume (O1) et en montant (O4).** L'arbitrage
tient sur les deux dimensions.

**Et la concentration est nette** : SP + RJ = **554 713 R$**, soit **48 % du CA
exposé**. Deux états sur vingt-sept concentrent la moitié de l'enjeu.

> **Note de méthode.** La comparaison se fait **à l'intérieur** de chaque état,
> ce qui neutralise l'effet distance : deux commandes du même état ont des frais
> de port comparables. Cette analyse **hiérarchise**, elle n'explique pas.

---

# 5. Aucune concentration par vendeur

## Le fait

Le plus gros vendeur pèse 497 775 R$ de CA total, mais seulement **40 065 R$
exposés** — soit 3,5 % du CA exposé national.

**Aucun vendeur ne dépasse 4 % de l'enjeu.**

## Le contraste avec les états

| Découpage | Concentration |
|---|---|
| Par état | **SP + RJ = 48 %** du CA exposé |
| Par vendeur | **Aucun ne dépasse 4 %** |

## Ce que cela signifie

> **Le problème est géographique, pas vendeur.**

Cohérent avec O2 : le retard vient du transport, et le transport dépend de la
**destination**, pas de qui expédie.

## Les cas individuels extrêmes

| Vendeur | CA total | CA exposé | Taux |
|---|---|---|---|
| **b1b39487…** | 21 924 | 18 308 | **83,51 %** |
| 2709af95… | 5 796 | 4 206 | 72,57 % |
| 0d85bbda… | 11 374 | 6 211 | 54,61 % |

**`b1b39487` réapparaît pour la troisième fois** — déjà identifié en O2 sur la
préparation (64 %) et sur le dépassement contractuel. Trois angles indépendants
convergent.

> **Mais une distinction s'impose :**
>
> | Niveau | Constat |
> |---|---|
> | Vendeur individuel | L'impact est **massif** — 83 % de son CA exposé |
> | National | **Négligeable** — 18 308 R$, soit 1,6 % de l'enjeu |
>
> Régler totalement son cas ne ferait pas bouger le chiffre global.

## Ce que cela implique

**L'action prioritaire ne peut pas être une liste de vendeurs.** Elle doit porter
sur la chaîne d'acheminement, en ciblant RJ.

Le suivi des vendeurs défaillants reste légitime — mais comme chantier
secondaire, pas comme levier principal.

---

# 6. Aucun effet de catégorie

## Le fait

| Catégorie | CA total | CA exposé | Taux |
|---|---|---|---|
| beleza_saude | 1 591 475 | 122 158 | 7,68 % |
| cama_mesa_banho | 1 511 495 | 114 432 | 7,57 % |
| informatica_acessorios | 1 453 179 | 107 538 | 7,40 % |
| relogios_presentes | 1 348 112 | 103 453 | 7,67 % |
| esporte_lazer | 1 294 756 | 90 043 | 6,95 % |
| moveis_decoracao | 1 274 822 | 107 806 | 8,46 % |
| utilidades_domesticas | 1 019 928 | 56 711 | 5,56 % |
| automotivo | 816 969 | 78 052 | **9,55 %** |
| *Non renseigné* | 226 825 | 20 958 | 9,24 % |

## Ce que cela signifie

**L'écart entre la meilleure et la pire des grandes catégories est de 3 points.**

À comparer aux états : de 2,13 % à 22,26 %, soit un **facteur 10**.

> **La catégorie n'explique pas le retard.** Cela confirme O2 : le problème est
> le transport, qui dépend de la destination, pas du produit.

> ⚠️ Les taux extrêmes — 0,00 % ou 34 % — concernent tous des catégories à moins
> de 20 000 R$ de CA. Trop peu de commandes pour être fiables.

## L'exception démasquée : les articles de Noël

`artigos_de_natal` affichait **34,57 %** de CA exposé, trois fois la moyenne.
Hypothèse plausible : vente concentrée en fin d'année, donc pendant le Black
Friday et le pic de décembre identifiés en O1.

**Vérification par mois :**

| Mois | Commandes | En retard | Taux |
|---|---|---|---|
| Nov. 2017 | 18 | 2 | 9,09 % |
| **Déc. 2017** | 14 | **0** | **0,00 %** |
| Jan. 2018 | 9 | 0 | 0,00 % |
| **Fév. 2018** | 17 | 4 | **37,50 %** |
| **Mars 2018** | 12 | 3 | **25,00 %** |

**Décembre 2017 : zéro retard.** La période de Noël est parfaitement servie.

**Les retards se concentrent en février-mars 2018** — c'est l'**incident national
d'O1**, pas un effet de la catégorie.

> **Et surtout : 7 commandes en retard sur 125 au total.** Le taux de 34,57 % en
> CA venait de quelques commandes chères, pas d'un phénomène. Piège classique du
> petit effectif.

## Ce que cela implique

**Aucun levier logistique par catégorie.** L'action reste géographique.

> ⚠️ **Une nuance à garder.** Cette conclusion porte sur la **catégorie**, pas sur
> l'**encombrement**. La piste ouverte au constat 2 — produits plus lourds ou
> volumineux — reste ouverte : le poids ne se confond pas avec la catégorie.

---

# Synthèse — ce que O4 a établi

| # | Constat |
|---|---|
| 1 | **CA exposé : 1 150 866 R$**, soit 7,47 % du CA total |
| 2 | L'exposition financière **dépasse** l'exposition en volume (7,47 % vs 6,77 %) |
| 3 | Le surcoût vient du **produit** (+11 %) et du **transport** (+12 %), pas du nombre d'articles (−3 %) |
| 4 | **CA à risque avéré : 721 160 R$** (62,66 % du CA exposé) — un plancher |
| 5 | **Au seuil critique de 3 jours : 932 499 R$**, soit 81 % du CA exposé |
| 6 | **RJ est la cible prioritaire en montant** : 251 556 R$, taux 2,5× celui de SP |
| 7 | **SP + RJ = 48 % du CA exposé** — deux états, la moitié de l'enjeu |
| 8 | **Aucune concentration par vendeur** — aucun ne dépasse 4 % |
| 9 | **Aucun effet de catégorie** — 3 points d'écart contre un facteur 10 entre états |

## La conclusion transversale

> **L'enjeu financier est géographique.** Ni le vendeur ni le produit ne le
> structurent. L'action doit porter sur l'acheminement, en ciblant Rio de Janeiro.

C'est la troisième fois que le projet aboutit à cette conclusion, par trois
chemins différents : le délai (O2), l'insatisfaction (O3) et maintenant le
montant (O4).

---

# Ce que O4 apporte aux autres objectifs

**Pour O6 (prédiction)** — la piste de l'encombrement (constat 2) désigne le
poids et le volume comme variables candidates. Elles sont disponibles dans
`staging.products` et connues au moment de la commande.

**Pour O7 (scénarios)** — le CA exposé est le dénominateur du gain. Un scénario
d'amélioration doit se chiffrer en part des **1,15 M R$** récupérables, ou des
**932 K R$** si l'on retient le seuil critique de 3 jours.

**Pour O5 (trajectoire vendeur)** — l'absence de concentration par vendeur
relativise l'enjeu de cet objectif. Il reste utile pour comprendre le mécanisme,
moins pour l'action.

**Pour la restitution** — trois chiffres à mettre en avant :
- **1,15 M R$** de CA exposé (7,47 %)
- **721 K R$** de CA à risque avéré
- **48 %** de l'enjeu concentré sur deux états

---

# Questions ouvertes

- [ ] **Les commandes en retard portent-elles des produits plus lourds ou plus
      volumineux ?** Piste ouverte par le constat 2, testable avec
      `product_weight_g` et les dimensions de `staging.products`
- [ ] Le surcoût de transport (+12 %) tient-il à la distance ou à
      l'encombrement ? *(la distance a déjà été écartée comme facteur de retard
      en O1, mais pas comme facteur de coût)*
