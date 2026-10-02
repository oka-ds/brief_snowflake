USE ROLE ACCOUNTADMIN;
USE WAREHOUSE NYC_TAXI_WH;
USE DATABASE NYC_TAXI_DB;

-- Aperçu des données
SELECT * FROM RAW.yellow_taxi_trips LIMIT 10;

-- Nombre de lignes par mois (permet de vérifier que les 12 mois sont chargés)
SELECT
    DATE_TRUNC('month', tpep_pickup_datetime) AS mois,
    COUNT(*) AS nb_trajets
FROM RAW.yellow_taxi_trips
GROUP BY mois
ORDER BY mois;

-- Pourcentage de lignes concernées par chaque problème
SELECT
    COUNT(*) AS nb_lignes,
    ROUND(100 * COUNT_IF(passenger_count IS NULL) / COUNT(*), 2) AS pct_passenger_count_null,
    ROUND(100 * COUNT_IF(PULocationID IS NULL OR DOLocationID IS NULL) / COUNT(*), 2) AS pct_zone_null,
    ROUND(100 * COUNT_IF(fare_amount < 0 OR total_amount < 0) / COUNT(*), 2) AS pct_montant_negatif,
    ROUND(100 * COUNT_IF(trip_distance = 0) / COUNT(*), 2) AS pct_distance_zero,
    ROUND(100 * COUNT_IF(trip_distance > 100) / COUNT(*), 2) AS pct_distance_sup_100,
    ROUND(100 * COUNT_IF(tpep_pickup_datetime >= tpep_dropoff_datetime) / COUNT(*), 2) AS pct_dates_incoherentes,
    ROUND(100 * COUNT_IF(YEAR(tpep_pickup_datetime) != 2025) / COUNT(*), 2) AS pct_hors_2025
FROM RAW.yellow_taxi_trips;

-- Valeurs extrêmes
SELECT
    MIN(tpep_pickup_datetime) AS pickup_min,
    MAX(tpep_pickup_datetime) AS pickup_max,
    MIN(trip_distance) AS distance_min,
    MAX(trip_distance) AS distance_max,
    MIN(total_amount) AS montant_min,
    MAX(total_amount) AS montant_max
FROM RAW.yellow_taxi_trips;
