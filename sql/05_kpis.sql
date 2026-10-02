-- ============================================================
-- 05 - KPIs demandés dans le brief
-- ============================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE NYC_TAXI_WH;
USE DATABASE NYC_TAXI_DB;

-- Nombre total de trajets par mois
SELECT
    MONTH(pickup_date) AS mois,
    SUM(nb_trips) AS nb_trajets
FROM FINAL.daily_summary
GROUP BY mois
ORDER BY mois;

-- Revenu moyen par trajet et distance moyenne parcourue
SELECT
    ROUND(AVG(total_amount), 2) AS revenu_moyen_par_trajet,
    ROUND(AVG(trip_distance), 2) AS distance_moyenne
FROM STAGING.clean_trips;

-- Top 10 des zones de départ les plus populaires
SELECT *
FROM FINAL.zone_analysis
ORDER BY popularity_rank
LIMIT 10;

-- Heures de pointe
SELECT *
FROM FINAL.hourly_patterns
ORDER BY nb_trips DESC
LIMIT 5;

-- Revenus : semaine vs weekend
SELECT
    day_type,
    ROUND(AVG(total_revenue), 2) AS revenu_moyen_par_jour,
    ROUND(SUM(total_revenue) / SUM(nb_trips), 2) AS revenu_moyen_par_trajet
FROM FINAL.daily_summary
GROUP BY day_type;

-- Pourboires selon le type de paiement (1 = carte, 2 = espèces)
SELECT
    payment_type,
    COUNT(*) AS nb_trajets,
    ROUND(AVG(tip_percentage), 2) AS pourboire_moyen_pct
FROM STAGING.clean_trips
GROUP BY payment_type
ORDER BY payment_type;

-- Vitesse moyenne par période de la journée
SELECT
    time_period,
    ROUND(AVG(avg_speed_mph), 2) AS vitesse_moyenne_mph
FROM STAGING.clean_trips
GROUP BY time_period
ORDER BY vitesse_moyenne_mph;
