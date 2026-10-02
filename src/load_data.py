"""Chargement des fichiers NYC Yellow Taxi 2025 dans Snowflake (table RAW.yellow_taxi_trips).

Etapes pour chaque mois :
1. Télécharger le fichier parquet dans le dossier data/
2. L'envoyer dans le stage interne Snowflake (PUT)
3. Copier le contenu du stage dans la table RAW (COPY INTO)

Lancement : python src/load_data.py
"""

import os
from pathlib import Path

import requests
import snowflake.connector
from dotenv import load_dotenv

BASE_URL = "https://d37ci6vzurychx.cloudfront.net/trip-data/"
YEAR = 2025
DATA_DIR = Path("data")


def get_connection():
    """Ouvre une connexion à Snowflake avec les identifiants du fichier .env."""
    load_dotenv()
    return snowflake.connector.connect(
        account=os.getenv("SNOWFLAKE_ACCOUNT"),
        user=os.getenv("SNOWFLAKE_USER"),
        password=os.getenv("SNOWFLAKE_PASSWORD"),
        role=os.getenv("SNOWFLAKE_ROLE"),
        warehouse=os.getenv("SNOWFLAKE_WAREHOUSE"),
        database=os.getenv("SNOWFLAKE_DATABASE"),
        schema="RAW",
    )


def download_file(file_name):
    """Télécharge un fichier parquet dans data/ s'il n'y est pas déjà.

    Retourne le chemin du fichier local.
    """
    DATA_DIR.mkdir(exist_ok=True)
    file_path = DATA_DIR / file_name

    if file_path.exists():
        print(f"{file_name} déjà téléchargé")
        return file_path

    print(f"Téléchargement de {file_name}...")
    response = requests.get(BASE_URL + file_name, stream=True, timeout=60)
    response.raise_for_status()

    # On écrit d'abord dans un fichier temporaire pour ne pas garder un fichier incomplet
    tmp_path = DATA_DIR / (file_name + ".tmp")
    with open(tmp_path, "wb") as f:
        for chunk in response.iter_content(chunk_size=1024 * 1024):
            f.write(chunk)
    tmp_path.rename(file_path)

    return file_path


def load_file(cursor, file_path):
    """Envoie un fichier dans le stage puis le copie dans RAW.yellow_taxi_trips."""
    print(f"Envoi de {file_path.name} dans le stage...")
    cursor.execute(f"PUT file://{file_path.resolve()} @RAW.taxi_stage AUTO_COMPRESS = FALSE")

    # Snowflake retient les fichiers déjà copiés : relancer le script ne crée pas de doublons
    cursor.execute(f"""
        COPY INTO RAW.yellow_taxi_trips
        FROM @RAW.taxi_stage/{file_path.name}
        FILE_FORMAT = (FORMAT_NAME = 'RAW.parquet_format')
        MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
    """)
    result = cursor.fetchone()
    print(f"Résultat du COPY : {result}")


def main():
    """Charge les 12 mois de l'année dans Snowflake."""
    conn = get_connection()
    cursor = conn.cursor()

    for month in range(1, 13):
        file_name = f"yellow_tripdata_{YEAR}-{month:02d}.parquet"
        file_path = download_file(file_name)
        load_file(cursor, file_path)

    cursor.execute("SELECT COUNT(*) FROM RAW.yellow_taxi_trips")
    print(f"Nombre total de lignes dans RAW.yellow_taxi_trips : {cursor.fetchone()[0]}")

    cursor.close()
    conn.close()


if __name__ == "__main__":
    main()
