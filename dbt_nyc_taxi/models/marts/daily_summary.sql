-- Résumé quotidien : une ligne par jour

SELECT
    pickup_date,
    day_type,
    COUNT(*) AS nb_trips,
    ROUND(AVG(trip_distance), 2) AS avg_distance,
    ROUND(AVG(trip_duration_minutes), 2) AS avg_duration_minutes,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    ROUND(AVG(total_amount), 2) AS avg_revenue_per_trip
FROM {{ ref('fact_trips') }}
GROUP BY pickup_date, day_type
