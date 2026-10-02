-- Analyse par zone de départ : une ligne par zone

SELECT
    pickup_location_id,
    COUNT(*) AS nb_trips,
    ROUND(AVG(total_amount), 2) AS avg_revenue,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    ROUND(AVG(trip_distance), 2) AS avg_distance,
    ROUND(AVG(trip_duration_minutes), 2) AS avg_duration_minutes,
    -- Popularité : classement des zones par nombre de trajets (1 = la plus populaire)
    RANK() OVER (ORDER BY COUNT(*) DESC) AS popularity_rank
FROM {{ ref('fact_trips') }}
GROUP BY pickup_location_id
