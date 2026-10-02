USE ROLE ACCOUNTADMIN;
USE WAREHOUSE NYC_TAXI_WH;
USE DATABASE NYC_TAXI_DB;

-- Résumé quotidien
CREATE OR REPLACE TABLE FINAL.daily_summary AS
SELECT
    pickup_date,
    day_type,
    COUNT(*) AS nb_trips,
    ROUND(AVG(trip_distance), 2) AS avg_distance,
    ROUND(AVG(trip_duration_minutes), 2) AS avg_duration_minutes,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    ROUND(AVG(total_amount), 2) AS avg_revenue_per_trip
FROM STAGING.clean_trips
GROUP BY pickup_date, day_type
ORDER BY pickup_date;

-- Analyse par zone de départ
CREATE OR REPLACE TABLE FINAL.zone_analysis AS
SELECT
    pickup_location_id,
    COUNT(*) AS nb_trips,
    ROUND(AVG(total_amount), 2) AS avg_revenue,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    ROUND(AVG(trip_distance), 2) AS avg_distance,
    ROUND(AVG(trip_duration_minutes), 2) AS avg_duration_minutes,
    -- Popularité : classement des zones par nombre de trajets (1 = la plus populaire)
    RANK() OVER (ORDER BY COUNT(*) DESC) AS popularity_rank
FROM STAGING.clean_trips
GROUP BY pickup_location_id
ORDER BY popularity_rank;

-- Patterns horaires
CREATE OR REPLACE TABLE FINAL.hourly_patterns AS
SELECT
    pickup_hour,
    time_period,
    COUNT(*) AS nb_trips,
    ROUND(SUM(total_amount), 2) AS total_revenue,
    ROUND(AVG(total_amount), 2) AS avg_revenue,
    ROUND(AVG(avg_speed_mph), 2) AS avg_speed_mph
FROM STAGING.clean_trips
GROUP BY pickup_hour, time_period
ORDER BY pickup_hour;

-- Vérification
SELECT * FROM FINAL.daily_summary LIMIT 10;
SELECT * FROM FINAL.zone_analysis LIMIT 10;
SELECT * FROM FINAL.hourly_patterns;
