-- Nettoyage des données brutes : renommage des colonnes et filtrage des lignes invalides

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
    total_amount
FROM {{ source('raw', 'yellow_taxi_trips') }}
WHERE fare_amount >= 0
    AND total_amount >= 0
    AND tpep_pickup_datetime < tpep_dropoff_datetime
    -- Certains trajets ont une date hors 2025 (erreurs de compteur)
    AND YEAR(tpep_pickup_datetime) = 2025
    AND trip_distance BETWEEN 0.1 AND 100
    AND PULocationID IS NOT NULL
    AND DOLocationID IS NOT NULL
