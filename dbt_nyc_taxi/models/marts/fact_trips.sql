-- Table de faits : une ligne par trajet valide, avec toutes les métriques

SELECT *
FROM {{ ref('int_trip_metrics') }}
