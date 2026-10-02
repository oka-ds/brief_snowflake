# Rapport qualité des données et KPIs

Source : `RAW.yellow_taxi_trips` (taxis jaunes NYC, année 2025).
Requêtes utilisées : `sql/02_data_quality.sql` et `sql/05_kpis.sql`, exécutées sur Snowflake.

## 1. Qualité des données brutes

| Problème | Année 2025 |
|---|---|
| Nombre de lignes | 48 722 602 |
| `passenger_count` manquant | 23,83 % |
| Zone de départ ou d'arrivée manquante | 0,00 % |
| Montant négatif (`fare_amount` ou `total_amount`) | 5,86 % |
| Distance égale à zéro | 2,88 % |
| Distance > 100 miles | 0,006 % |
| Dates incohérentes (pickup ≥ dropoff) | 1,12 % |
| Pickup hors 2025 | 0,0001 % |

Valeurs extrêmes : distance maximum de 397 994 miles, montant total entre -1 832,85 $ et 863 380,37 $.

Les chiffres du brief (15,54 % de valeurs manquantes, 4,15 % de montants négatifs, 2,62 % de distances nulles) correspondent au mois de janvier seul. Sur l'année complète les problèmes sont plus fréquents, surtout les valeurs manquantes.

## 2. Nettoyage appliqué

Voir `sql/03_staging.sql` :

1. Suppression des montants négatifs
2. Suppression des trajets où le pickup n'est pas avant le dropoff
3. Suppression des trajets dont la date n'est pas en 2025
4. Distance gardée entre 0.1 et 100 miles
5. Suppression des zones NULL
6. `passenger_count` manquant remplacé par 1

| | Nombre de lignes |
|---|---|
| `RAW.yellow_taxi_trips` | 48 722 602 |
| `STAGING.clean_trips` | 43 888 653 |
| Lignes gardées | 90,08 % |

## 3. KPIs

### Nombre de trajets par mois

| Mois | Nombre de trajets |
|---|---|
| Janvier | 3 236 423 |
| Février | 3 287 571 |
| Mars | 3 805 664 |
| Avril | 3 653 150 |
| Mai | 4 065 003 |
| Juin | 3 841 454 |
| Juillet | 3 469 796 |
| Août | 3 159 701 |
| Septembre | 3 811 140 |
| Octobre | 3 919 847 |
| Novembre | 3 624 140 |
| Décembre | 4 014 764 |

### Indicateurs globaux

| Indicateur | Valeur |
|---|---|
| Revenu moyen par trajet | 28,85 $ |
| Distance moyenne parcourue | 3,51 miles |
| Durée moyenne d'un trajet | 17,66 minutes |

### Top 10 des zones de départ

Le nom des zones vient de la table de correspondance de la TLC (*Taxi Zone Lookup*), qui n'est pas chargée dans Snowflake.

| Rang | Zone | Nom | Nombre de trajets | Revenu moyen |
|---|---|---|---|---|
| 1 | 237 | Upper East Side South | 1 991 729 | 21,24 $ |
| 2 | 161 | Midtown Center | 1 936 411 | 26,20 $ |
| 3 | 132 | JFK Airport | 1 861 237 | 82,08 $ |
| 4 | 236 | Upper East Side North | 1 740 059 | 21,52 $ |
| 5 | 186 | Penn Station / Madison Sq West | 1 438 869 | 25,96 $ |
| 6 | 162 | Midtown East | 1 406 144 | 25,20 $ |
| 7 | 230 | Times Sq / Theatre District | 1 385 341 | 29,06 $ |
| 8 | 142 | Lincoln Square East | 1 281 913 | 22,78 $ |
| 9 | 138 | LaGuardia Airport | 1 220 242 | 70,44 $ |
| 10 | 234 | Union Sq | 1 181 246 | 23,60 $ |

### Heures de pointe

| Heure | Période | Nombre de trajets | Vitesse moyenne |
|---|---|---|---|
| 18h | Rush Soir | 2 919 104 | 10,03 mph |
| 17h | Rush Soir | 2 809 362 | 9,59 mph |
| 21h | Soirée | 2 652 680 | 12,42 mph |
| 19h | Rush Soir | 2 647 153 | 10,81 mph |
| 15h | Journée | 2 638 932 | 9,52 mph |

L'heure la plus calme est 4h du matin (318 403 trajets).

### Semaine vs weekend

| Type de jour | Revenu moyen par jour | Revenu moyen par trajet |
|---|---|---|
| Semaine | 3 486 952 $ | 29,20 $ |
| Weekend | 3 424 347 $ | 27,99 $ |

### Pourboires selon le type de paiement

| Type de paiement | Nombre de trajets | Pourboire moyen |
|---|---|---|
| 0 - Non renseigné | 8 678 058 | 1,76 % |
| 1 - Carte | 30 287 211 | 25,45 % |
| 2 - Espèces | 4 258 589 | 0,00 % |
| 3 - Sans frais | 153 678 | 0,07 % |
| 4 - Litige | 511 116 | 0,04 % |

### Vitesse moyenne par période

| Période | Vitesse moyenne |
|---|---|
| Journée (10h-15h) | 10,00 mph |
| Rush Soir (16h-19h) | 10,02 mph |
| Rush Matinal (6h-9h) | 12,21 mph |
| Soirée (20h-23h) | 12,66 mph |
| Nuit (0h-5h) | 15,65 mph |

## 4. Observations

- **Demande** : le pic est en fin d'après-midi (17h-18h). Mai et décembre sont les mois les plus chargés, août le plus calme.
- **Zones** : Manhattan (Upper East Side, Midtown) domine en volume. Les aéroports (JFK, LaGuardia) font moins de trajets mais rapportent 3 à 4 fois plus par course.
- **Trafic** : la circulation est la plus lente en journée et au rush du soir (environ 10 mph) et la plus fluide la nuit.
- **Pourboires** : ils n'apparaissent que pour les paiements par carte. Les pourboires en espèces ne sont pas enregistrés par le compteur, donc 0 % ne veut pas dire que les clients ne donnent rien.
- **Semaine / weekend** : peu de différence, un trajet rapporte un peu plus en semaine.

### Limites du nettoyage

Les filtres du brief ne portent que sur les montants négatifs, les dates, les distances et les zones. Il reste donc des valeurs aberrantes dans `STAGING.clean_trips` :

| Problème restant | Nombre de trajets |
|---|---|
| Vitesse > 100 mph (maximum : 102 490 mph) | 9 789 |
| Durée > 10 heures (maximum : 14 881 minutes) | 12 401 |
| Montant total maximum | 863 380 $ |
| Pourcentage de pourboire maximum | 2 000 000 % |

Cela représente moins de 0,1 % des lignes, mais ces valeurs tirent les moyennes vers le haut (vitesse, revenu moyen, pourboire moyen). Une amélioration possible serait d'ajouter des filtres sur la durée, la vitesse et le montant maximum.
