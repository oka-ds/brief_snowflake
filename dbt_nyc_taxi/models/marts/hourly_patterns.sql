-- Patterns horaires : une ligne par heure de la journée

SELECT
    pickup_hour,
    time_period,
    COUNT(*) AS nb_trips,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    ROUND(AVG(total_amount), 2) AS avg_revenue,
    ROUND(AVG(avg_speed_mph), 2) AS avg_speed_mph
FROM {{ ref('fact_trips') }}
GROUP BY pickup_hour, time_period
