-- Enrichissement des trajets : durée, vitesse, pourboire, dimensions temporelles et catégories

WITH trips AS (
    SELECT
        *,
        DATEDIFF('second', pickup_datetime, dropoff_datetime) / 60 AS trip_duration_minutes
    FROM {{ ref('stg_yellow_taxi_trips') }}
)

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

FROM trips
