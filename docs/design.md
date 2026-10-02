# Design

## Vue d'ensemble

```
Site NYC TLC (parquet mensuels)
        │  src/load_data.py : téléchargement + PUT
        ▼
Stage interne RAW.taxi_stage
        │  COPY INTO
        ▼
RAW.yellow_taxi_trips          données brutes
        │  sql/03_staging.sql
        ▼
STAGING.clean_trips            nettoyage + enrichissement
        │  sql/04_final.sql
        ▼
FINAL.daily_summary / zone_analysis / hourly_patterns
```

## Objets Snowflake

| Objet | Nom |
|---|---|
| Warehouse | `NYC_TAXI_WH` (MEDIUM, auto-suspend 60 s) |
| Base | `NYC_TAXI_DB` |
| Schémas | `RAW`, `STAGING`, `FINAL` |
| Stage | `RAW.taxi_stage` |
| Format de fichier | `RAW.parquet_format` |

## Tables

### RAW.yellow_taxi_trips

Copie exacte des fichiers parquet (20 colonnes). Description des colonnes : [dictionnaire de données TLC](https://www.nyc.gov/assets/tlc/downloads/pdf/data_dictionary_trip_records_yellow.pdf).

### STAGING.clean_trips

Une ligne = un trajet valide.

| Colonne | Description |
|---|---|
| `vendor_id` | Fournisseur du compteur |
| `pickup_datetime`, `dropoff_datetime` | Début et fin du trajet |
| `passenger_count` | Nombre de passagers (1 si inconnu) |
| `trip_distance` | Distance en miles |
| `pickup_location_id`, `dropoff_location_id` | Zones de départ et d'arrivée |
| `payment_type` | Type de paiement (1 = carte, 2 = espèces) |
| `fare_amount`, `tip_amount`, `tolls_amount`, `total_amount` | Montants en dollars |
| `trip_duration_minutes` | Durée du trajet |
| `pickup_date`, `pickup_hour`, `pickup_day_name`, `pickup_month` | Dimensions temporelles |
| `avg_speed_mph` | Vitesse moyenne = distance / durée |
| `tip_percentage` | Pourboire / tarif de base × 100 |
| `distance_category` | Court (≤ 1), Moyen (1-5), Long (5-10), Très long (> 10 miles) |
| `time_period` | Rush Matinal, Journée, Rush Soir, Soirée, Nuit |
| `day_type` | Semaine ou Weekend |

### FINAL.daily_summary

Une ligne par jour : nombre de trajets, distance et durée moyennes, revenus totaux, revenu moyen par trajet.

### FINAL.zone_analysis

Une ligne par zone de départ : nombre de trajets, revenu moyen et total, distance et durée moyennes, rang de popularité.

### FINAL.hourly_patterns

Une ligne par heure de la journée : nombre de trajets, revenus, vitesse moyenne.

## Version dbt

Le projet `dbt_nyc_taxi/` reproduit les mêmes transformations :

```
RAW.yellow_taxi_trips
        ▼
DBT_STAGING.stg_yellow_taxi_trips        vue : nettoyage
        ▼
DBT_INTERMEDIATE.int_trip_metrics        vue : métriques et catégories
        ▼
DBT_MARTS.fact_trips                     table : une ligne par trajet
        ▼
DBT_MARTS.daily_summary / zone_analysis / hourly_patterns
```
