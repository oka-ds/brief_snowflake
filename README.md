# Pipeline NYC Taxi avec Snowflake

Projet : chargement des trajets des taxis jaunes de New York (année 2025, environ 40 millions de lignes) dans Snowflake, nettoyage et création de tables d'analyse.

## Architecture

```
Fichiers Parquet → RAW → STAGING → FINAL
```

- `RAW.yellow_taxi_trips` : données brutes
- `STAGING.clean_trips` : données nettoyées et enrichies
- `FINAL.daily_summary`, `FINAL.zone_analysis`, `FINAL.hourly_patterns` : tables d'analyse

## Structure du projet

```
├── docs/
│   ├── nyc_taxi_dbt_DEV_IA.md    # le brief
│   ├── design.md                 # architecture et description des tables
│   └── data_quality_report.md    # rapport qualité et KPIs
├── sql/                          # scripts SQL à exécuter dans Snowflake
├── src/load_data.py              # chargement des fichiers dans Snowflake
├── dbt_nyc_taxi/                 # projet dbt 
├── .env.example                  # modèle pour les credentials
└── pyproject.toml
```

## Installation

Prérequis : Python 3.12 et un compte Snowflake.

```bash
python -m venv venv
source venv/bin/activate
pip install -e ".[notebook]"
cp .env.example .env
```

Remplir ensuite le fichier `.env` avec ses identifiants Snowflake.

## Exécution

| Ordre | Quoi | Où |
|---|---|---|
| 1 | `sql/01_setup.sql` | Worksheet Snowflake |
| 2 | `python src/load_data.py` | Terminal |
| 3 | `sql/02_data_quality.sql` | Worksheet Snowflake |
| 4 | `sql/03_staging.sql` | Worksheet Snowflake |
| 5 | `sql/04_final.sql` | Worksheet Snowflake |
| 6 | `sql/05_kpis.sql` | Worksheet Snowflake |

Le détail de chaque étape est dans [docs/journal_de_bord.md](docs/journal_de_bord.md).

## dbt

Les transformations existent aussi en version dbt (dossier `dbt_nyc_taxi/`), avec des tests de qualité. Les modèles sont créés dans les schémas `DBT_STAGING`, `DBT_INTERMEDIATE` et `DBT_MARTS`.

```bash
set -a && source .env && set +a
cd dbt_nyc_taxi
dbt build                              # crée les modèles et lance les tests
dbt docs generate && dbt docs serve    # documentation et lignage
```

## Orchestration

Le workflow `.github/workflows/pipeline.yml` lance le chargement puis `dbt build` chaque 1er du mois, ou à la main depuis l'onglet Actions de GitHub. Les identifiants Snowflake sont à mettre dans les secrets du repo, avec les mêmes noms que dans `.env.example`.

## Source des données

[NYC Taxi & Limousine Commission](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page)
