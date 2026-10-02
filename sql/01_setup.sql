USE ROLE ACCOUNTADMIN;

-- Warehouse : la ressource de calcul
-- MEDIUM comme demandé dans le brief (XSMALL suffit si on veut économiser des crédits)
CREATE WAREHOUSE IF NOT EXISTS NYC_TAXI_WH
    WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

-- Base de données et schémas
CREATE DATABASE IF NOT EXISTS NYC_TAXI_DB;

CREATE SCHEMA IF NOT EXISTS NYC_TAXI_DB.RAW;
CREATE SCHEMA IF NOT EXISTS NYC_TAXI_DB.STAGING;
CREATE SCHEMA IF NOT EXISTS NYC_TAXI_DB.FINAL;

USE WAREHOUSE NYC_TAXI_WH;
USE DATABASE NYC_TAXI_DB;
USE SCHEMA RAW;

-- Format de fichier pour lire les parquet
CREATE FILE FORMAT IF NOT EXISTS RAW.parquet_format
    TYPE = PARQUET
    USE_LOGICAL_TYPE = TRUE;

-- Stage interne : zone de dépôt des fichiers parquet avant le COPY INTO
CREATE STAGE IF NOT EXISTS RAW.taxi_stage
    FILE_FORMAT = RAW.parquet_format;

-- Table brute : mêmes colonnes que les fichiers parquet, sans modification
CREATE TABLE IF NOT EXISTS RAW.yellow_taxi_trips (
    VendorID              NUMBER,
    tpep_pickup_datetime  TIMESTAMP_NTZ,
    tpep_dropoff_datetime TIMESTAMP_NTZ,
    passenger_count       NUMBER,
    trip_distance         FLOAT,
    RatecodeID            NUMBER,
    store_and_fwd_flag    VARCHAR,
    PULocationID          NUMBER,
    DOLocationID          NUMBER,
    payment_type          NUMBER,
    fare_amount           FLOAT,
    extra                 FLOAT,
    mta_tax               FLOAT,
    tip_amount            FLOAT,
    tolls_amount          FLOAT,
    improvement_surcharge FLOAT,
    total_amount          FLOAT,
    congestion_surcharge  FLOAT,
    Airport_fee           FLOAT,
    cbd_congestion_fee    FLOAT
);

-- Vérification
SHOW SCHEMAS IN DATABASE NYC_TAXI_DB;
