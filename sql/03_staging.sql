USE ROLE ACCOUNTADMIN;
USE WAREHOUSE NYC_TAXI_WH;
USE DATABASE NYC_TAXI_DB;

CREATE OR REPLACE TABLE STAGING.clean_trips AS

-- Etape 1 : nettoyage
WITH filtered AS (
    SELECT
        VendorID AS vendor_id,
        tpep_pickup_datetime AS pickup_datetime,
        tpep_dropoff_datetime AS dropoff_datetime,
        -- Valeurs manquantes : on suppose 1 passager quand l'info est absente
        COALESCE(passenger_count, 1) AS passenger_count,
        trip_distance,
        PULocationID AS pickup_location_id,
        DOLocationID AS dropoff_location_id,
        payment_type,
        fare_amount,
        tip_amount,
        tolls_amount,
        total_amount,
        DATEDIFF('second', tpep_pickup_datetime, tpep_dropoff_datetime) / 60 AS trip_duration_minutes
    FROM RAW.yellow_taxi_trips
    WHERE fare_amount >= 0
        AND total_amount >= 0
        AND tpep_pickup_datetime < tpep_dropoff_datetime
        -- Certains trajets ont une date hors 2025 (erreurs de compteur)
        AND YEAR(tpep_pickup_datetime) = 2025
        AND trip_distance BETWEEN 0.1 AND 100
        AND PULocationID IS NOT NULL
        AND DOLocationID IS NOT NULL
)

-- Etape 2 : enrichissement
SELECT
    *,

    -- Dimensions temporelles
    DATE(pickup_datetime) AS pickup_date,
    HOUR(pickup_datetime) AS pickup_hour,
    DAYNAME(pickup_datetime) AS pickup_day_name,
    MONTH(pickup_datetime) AS pickup_month,

    -- Métriques
    ROUND(trip_distance / (trip_duration_minutes / 60), 2) AS avg_speed_mph,
    CASE
        WHEN fare_amount > 0 THEN ROUND(100 * tip_amount / fare_amount, 2)
    END AS tip_percentage,

    -- Catégories
    CASE
        WHEN trip_distance <= 1 THEN 'Court'
        WHEN trip_distance <= 5 THEN 'Moyen'
        WHEN trip_distance <= 10 THEN 'Long'
        ELSE 'Très long'
    END AS distance_category,

    CASE
        WHEN HOUR(pickup_datetime) BETWEEN 6 AND 9 THEN 'Rush Matinal'
        WHEN HOUR(pickup_datetime) BETWEEN 10 AND 15 THEN 'Journée'
        WHEN HOUR(pickup_datetime) BETWEEN 16 AND 19 THEN 'Rush Soir'
        WHEN HOUR(pickup_datetime) BETWEEN 20 AND 23 THEN 'Soirée'
        ELSE 'Nuit'
    END AS time_period,

    CASE
        WHEN DAYNAME(pickup_datetime) IN ('Sat', 'Sun') THEN 'Weekend'
        ELSE 'Semaine'
    END AS day_type

FROM filtered;

-- Vérification
SELECT COUNT(*) FROM STAGING.clean_trips;
SELECT * FROM STAGING.clean_trips LIMIT 10;

-- Combien de lignes ont été gardées par rapport aux données brutes ?
SELECT
    (SELECT COUNT(*) FROM RAW.yellow_taxi_trips) AS nb_raw,
    (SELECT COUNT(*) FROM STAGING.clean_trips) AS nb_clean,
    ROUND(100 * nb_clean / nb_raw, 2) AS pct_garde;
