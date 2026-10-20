# 01. Cadrage du besoin

Définition du problème métier avant toute manipulation de données :
contexte, problématique, périmètre, règles de gestion et métriques.

## Contenu

| Fichier | Description |
|---|---|
| `1.note_cadrage.md` | Note de cadrage : **version 3.1**, révisée après préparation |
| `02.regles_et_metriques.md` | **11 règles de gestion et 19 métriques** : version 2.2 |

## Principe

Le cadrage est un **document vivant**. Chaque phase du projet le confronte à la
réalité de la donnée, et il est révisé en conséquence. L'historique complet est
tracé dans la note elle-même.

| Version | Ce qui l'a déclenchée | Ce qui a changé |
|---|---|---|
| **1.0** | - | Hypothèses posées avant accès aux données |
| **2.0** | Qualification | Problématique recentrée après invalidation de H1 (réachat 3,12 %) ; ajout de O2 et O5 |
| **3.0** | Préparation | Périmètre définitif à 96 447 ; correction de RG-04 (674 et non 1 350) ; réintégration de la géolocalisation |
| **3.1** | Relecture du notebook | Intégration de **SQ7** et de l'objectif **O8** : le calibrage des délais annoncés |

## Deux révisions structurantes

**La qualification a fait tomber l'objectif central.** La v1 visait à quantifier
la perte de valeur client liée aux retards. Avec un taux de réachat de 3,12 %,
aucune trajectoire client n'est observable. L'objectif est remplacé par une
**exposition mesurée** (O4) et un mécanisme au grain vendeur (O5).

**La préparation a ouvert une piste non prévue.** 87 % des commandes arrivent
avec quatre jours d'avance ou plus, avec un pic à quatorze jours. Olist promet
large. D'où **SQ7** : de combien la promesse peut-elle être resserrée sans
dégrader sa tenue ?

> **Pourquoi O7 et O8 sont distincts.** O7 simule un raccourcissement du délai
> **réel** (levier opérationnel, direction logistique). O8 simule un
> resserrement du délai **annoncé** (levier commercial, direction marketing).
> Deux leviers opposés : l'un réduit le taux de retard, l'autre l'augmente
> mécaniquement. C'est leur conjonction qui produit une recommandation.

## Les règles de gestion

Onze règles numérotées, chacune définie, justifiée et **chiffrée sur le
périmètre final**. Aucun calcul n'est produit dans ce projet sans règle
correspondante.

**Test de validation** : une autre personne, en lisant ce document, doit
calculer exactement les mêmes chiffres.

| Type | Règles | Effet |
|---|---|---|
| Exclusion générale | RG-01, RG-03 | La commande sort du périmètre |
| Exclusion ciblée | RG-04, RG-07, RG-08, RG-09 | La commande reste, une analyse lui est fermée |
| Définition | RG-02, RG-05, RG-06, RG-11 | Comment mesurer |
| Méthode | RG-10 | Comment découper l'observation |

## Les métriques

Dix-huit métriques, chacune reliée à une sous-question et à une **décision
qu'elle éclaire**. Une métrique qui n'éclaire aucune décision est retirée.

> **Règle de construction du dashboard** : tout visuel doit correspondre à une
> métrique. Une métrique sans visuel n'est pas restituée ; un visuel sans
> métrique n'a pas lieu d'être.
