# Journal de bord

Ce fichier liste ce qui a été fait dans le projet, dans l'ordre, et ce qu'il reste à faire à la main côté Snowflake.

## Etat d'avancement

| Etape | Etat |
|---|---|
| Environnement Python (`pyproject.toml`, venv) | Fait et vérifié |
| `.env`, `.env.example`, `.gitignore` | Fait, connexion Snowflake OK |
| `sql/01_setup.sql` | Exécuté : warehouse, base, schémas, stage et table RAW créés |
| Script de chargement `src/load_data.py` | Exécuté : **48 722 602 lignes** dans `RAW.yellow_taxi_trips` (12 mois, entre 3,5 et 4,6 millions par mois) |
| Scripts SQL `sql/02` à `05` | Exécutés : `STAGING.clean_trips` (43 888 653 lignes, 90,08 % gardées), `FINAL.daily_summary` (365), `FINAL.zone_analysis` (262), `FINAL.hourly_patterns` (24) |
| Rapport qualité | Rempli avec les résultats Snowflake de l'année complète |
| Partie 2 : dbt | Fait : 6 modèles et 22 tests, `dbt build` passe (28/28) |
| Partie 2 : GitHub Actions | Workflow écrit, **pas encore lancé sur GitHub** |

## 1. Ce qui a été fait

### 1.1 `pyproject.toml`

- Projet renommé `my_project` → `brief_snowflake`.
- **Retiré** : `psycopg2-binary` et `sqlalchemy`. Ils servent pour PostgreSQL, pas pour ce brief. En plus la version demandée (`psycopg2-binary>=3.3.6`) n'existe pas (psycopg2 est en 2.9.x), donc l'installation aurait planté.
- **Ajouté** :
  - `snowflake-connector-python` : connexion à Snowflake depuis Python
  - `dbt-core` et `dbt-snowflake` : pour la partie 2 du brief
  - `requests` : téléchargement des fichiers parquet
- **Gardé** : `pandas`, `duckdb` (pratique pour regarder un parquet en local), `python-dotenv`.
- Les numéros de version minimum ont été retirés pour laisser pip choisir des versions compatibles entre elles (dbt impose déjà sa version du connecteur Snowflake).
- Ajout de `[tool.setuptools] py-modules = []` : `src/` contient des scripts et pas un package, ça évite une erreur de setuptools à l'installation.

Installation lancée et vérifiée :

```bash
source venv/bin/activate
pip install -e ".[notebook]"
```

Versions installées : dbt-core 1.12.5, dbt-snowflake 1.12.1, snowflake-connector-python 4.8.0, pandas 3.0.6, duckdb 1.5.6.

### 1.2 Fichiers de configuration

- `.env.example` : modèle avec les variables Snowflake (sans les valeurs).
- `.env` : copie du modèle, **à remplir** (voir partie 2).
- `.gitignore` : ignore `.env`, `venv/`, `data/` et les dossiers générés par dbt.

### 1.3 Scripts SQL (dossier `sql/`)

| Fichier | Rôle |
|---|---|
| `01_setup.sql` | Warehouse, base, 3 schémas, stage, format parquet, table `RAW.yellow_taxi_trips` |
| `02_data_quality.sql` | Requêtes d'analyse de la qualité des données brutes |
| `03_staging.sql` | Table `STAGING.clean_trips` (nettoyage + enrichissement) |
| `04_final.sql` | Tables `FINAL.daily_summary`, `FINAL.zone_analysis`, `FINAL.hourly_patterns` |
| `05_kpis.sql` | Requêtes des KPIs demandés |

### 1.4 Script Python `src/load_data.py`

Pour chaque mois de 2025 : télécharge le parquet dans `data/`, l'envoie dans le stage Snowflake (`PUT`), puis le copie dans la table RAW (`COPY INTO`).

**Pourquoi pas l'option A du brief (stage externe sur l'URL) ?** Un stage externe Snowflake ne sait lire que S3, Google Cloud Storage ou Azure. L'URL du brief est une adresse HTTPS classique (CloudFront), donc ça ne marche pas directement. On passe par un stage **interne** : c'est le script Python qui fait le lien.

Points à retenir :
- `MATCH_BY_COLUMN_NAME` : Snowflake associe les colonnes du parquet à celles de la table par leur nom.
- Snowflake retient les fichiers déjà copiés, donc on peut relancer le script sans créer de doublons.
- Les 12 fichiers font environ 60-75 Mo chacun (~800 Mo au total, pas 8 Go).

### 1.5 Vérifications faites en local

- Les 12 fichiers 2025 sont bien disponibles en ligne et ont tous les mêmes 20 colonnes.
- Le téléchargement fonctionne (janvier est déjà dans `data/`).
- Les filtres de nettoyage ont été testés sur janvier avec duckdb : 93,13 % des lignes gardées.
- `ruff check` passe sur `src/`.

Ce qui **n'a pas** pu être testé : tout ce qui touche à Snowflake (les 5 fichiers SQL et la partie `PUT` / `COPY INTO` du script). Il peut y avoir des petites corrections à faire à la première exécution.

## 2. Ce qu'il faut faire à la main

### Etape 1 - Créer le compte Snowflake

1. Aller sur https://signup.snowflake.com (essai gratuit 30 jours, 400 $ de crédits).
2. Choisir l'édition **Standard** et n'importe quel cloud / région (par exemple AWS, Europe).
3. Valider l'email et se connecter à Snowsight (l'interface web).

### Etape 2 - Remplir le `.env`

Dans Snowsight : cliquer sur son nom en bas à gauche → **Account** → **View account details**. Copier le champ **Account identifier** (format `ORGANISATION-COMPTE`).

```
SNOWFLAKE_ACCOUNT=ABCDEFG-XY12345
SNOWFLAKE_USER=MON.EMAIL@EXEMPLE.COM
SNOWFLAKE_PASSWORD='mon_mot_de_passe'
SNOWFLAKE_ROLE=ACCOUNTADMIN
SNOWFLAKE_WAREHOUSE=NYC_TAXI_WH
SNOWFLAKE_DATABASE=NYC_TAXI_DB
```

Ne jamais commiter ce fichier (il est dans le `.gitignore`).

### Etape 3 - Créer l'infrastructure

Dans Snowsight : **Projects → Worksheets → + (SQL Worksheet)**. Coller le contenu de `sql/01_setup.sql` et tout exécuter (tout sélectionner puis Ctrl+Entrée, ou la flèche à côté de Run → *Run All*).

Vérifier que les schémas `RAW`, `STAGING` et `FINAL` apparaissent dans le résultat.

### Etape 4 - Charger les données

```bash
source venv/bin/activate
python src/load_data.py
```

Compter quelques minutes. A la fin le script affiche le nombre total de lignes (attendu : autour de 40 millions).

Si la connexion échoue :
- `Incorrect username or password` / compte introuvable → vérifier `SNOWFLAKE_ACCOUNT` (avec un tiret, sans `.snowflakecomputing.com`).
- Erreur liée au **MFA** (double authentification) → Snowflake l'impose de plus en plus pour les connexions par mot de passe. Dans ce cas, créer un *Programmatic Access Token* dans Snowsight (son nom → **Settings → Authentication → Programmatic access tokens**) et le mettre à la place du mot de passe dans `SNOWFLAKE_PASSWORD`.

### Etape 5 - Analyser la qualité

Exécuter `sql/02_data_quality.sql` **requête par requête** (la dernière ne marchera qu'après l'étape 6). Reporter les résultats dans `docs/data_quality_report.md`.

A vérifier en particulier sur la première requête : les colonnes `TPEP_PICKUP_DATETIME` doivent afficher de vraies dates en 2025. Si on voit des dates absurdes, me le dire, c'est un problème connu de lecture des timestamps parquet.

### Etape 6 - Créer les tables STAGING et FINAL

Exécuter `sql/03_staging.sql` puis `sql/04_final.sql`.

### Etape 7 - KPIs

Exécuter `sql/05_kpis.sql` et reporter les résultats dans le rapport.

### Etape 8 - Economiser les crédits

Le warehouse se met en pause tout seul après 60 secondes. On peut suivre la consommation dans **Admin → Cost Management**.

## Problèmes rencontrés

### Connexion refusée au lancement de `load_data.py`

Deux problèmes l'un derrière l'autre :

1. **`Password is empty`** : le mot de passe dans le `.env` contient des guillemets doubles `"`. `python-dotenv` n'arrive pas à lire la ligne (message `could not parse statement starting at line 7`) et renvoie un mot de passe vide. Solution : entourer le mot de passe de guillemets **simples** :

   ```
   SNOWFLAKE_PASSWORD='mon"mot>de"passe'
   ```

2. **`Incorrect username or password was specified`** : le mot de passe était bon, c'est `SNOWFLAKE_USER` qui ne l'était pas. Le nom affiché dans Snowsight est `ronan.pele1`, mais le **login name** attendu par le connecteur est l'adresse email complète. Snowflake renvoie le même message que l'erreur vienne du login ou du mot de passe, donc ça ne se voit pas.

   La bonne valeur se trouve dans Snowsight : son nom en bas à gauche → **Connect a tool to Snowflake** (ou *Account → View account details → Config File*), qui affiche un bloc `[connections...]` avec `account` et `user` prêts à copier.

   ```
   SNOWFLAKE_ACCOUNT=WPHRTPF-FY85367
   SNOWFLAKE_USER=RONAN.PELE1@GMAIL.COM
   ```

   Attention : après plusieurs échecs de suite Snowflake bloque le compte une quinzaine de minutes.

Piège Snowsight rencontré au passage : Ctrl+Entrée n'exécute que la requête sous le curseur. Pour lancer un fichier entier, tout sélectionner (Ctrl+A) avant, ou utiliser *Run All*.

La variable `SNOWFLAKE_PRIVATE_KEY_PATH` ajoutée dans le `.env` n'est pas utilisée par le script, et le fichier `/home/oka/.snowflake/rsa_key.p8` n'existe pas. On peut la retirer (ou passer à une connexion par clé, mais il faut alors créer la clé et l'associer à l'utilisateur dans Snowflake).

### `02_data_quality.sql` en erreur

C'est une conséquence du point précédent : la table `RAW.yellow_taxi_trips` est vide tant que le chargement n'a pas tourné, donc les pourcentages font une division par zéro. La dernière requête du fichier ne marche qu'après `03_staging.sql`. A relancer une fois les données chargées.

## 3. Choix de nettoyage (à savoir expliquer)

| Règle | Raison |
|---|---|
| `fare_amount >= 0` et `total_amount >= 0` | Les montants négatifs sont des remboursements / erreurs |
| `pickup < dropoff` | Un trajet ne peut pas finir avant d'avoir commencé |
| Année du pickup = 2025 | Quelques lignes ont des dates hors période (erreur de compteur) |
| Distance entre 0.1 et 100 miles | Enlève les distances nulles et les valeurs aberrantes (max vu en janvier : 276 423 miles) |
| Zones non NULL | Demandé par le brief (en pratique il n'y en a pas en janvier) |
| `passenger_count` NULL → 1 | On garde la ligne car le reste est exploitable. C'est une hypothèse, on peut la changer |

Le pourcentage de pourboire est laissé à NULL quand `fare_amount = 0` pour éviter une division par zéro.

## 4. Remarques sur le brief

- Le brief parle de l'année 2025 partout sauf dans "Résultats attendus" où il est écrit 2024. On a pris **2025**. Pour changer, modifier `YEAR` dans `src/load_data.py` et le filtre sur l'année dans `sql/03_staging.sql`.
- Les périodes temporelles du brief ont des trous si on les lit en heures pleines (9h-10h par exemple). On a pris : 6-9, 10-15, 16-19, 20-23, 0-5 sur l'heure de départ.

## 5. Partie 2 - dbt

### 5.1 Ce qui a été fait

Le projet dbt est dans le dossier `dbt_nyc_taxi/`. Il refait les mêmes transformations que les scripts `sql/03` et `sql/04`, mais découpées en modèles qui dépendent les uns des autres.

```
dbt_nyc_taxi/
├── dbt_project.yml          # configuration du projet
├── profiles.yml             # connexion Snowflake (lit les variables du .env)
└── models/
    ├── staging/
    │   ├── sources.yml                  # déclare la table RAW.yellow_taxi_trips
    │   ├── stg_yellow_taxi_trips.sql    # nettoyage
    │   └── schema.yml                   # descriptions + tests
    ├── intermediate/
    │   ├── int_trip_metrics.sql         # métriques et catégories
    │   └── schema.yml
    └── marts/
        ├── fact_trips.sql
        ├── daily_summary.sql
        ├── zone_analysis.sql
        ├── hourly_patterns.sql
        └── schema.yml
```

| Modèle | Type | Schéma Snowflake | Rôle |
|---|---|---|---|
| `stg_yellow_taxi_trips` | vue | `DBT_STAGING` | Renomme les colonnes et applique les filtres de nettoyage |
| `int_trip_metrics` | vue | `DBT_INTERMEDIATE` | Ajoute durée, vitesse, pourboire, dimensions temporelles, catégories |
| `fact_trips` | table | `DBT_MARTS` | Table de faits, une ligne par trajet (43 888 653 lignes) |
| `daily_summary` | table | `DBT_MARTS` | Résumé par jour (365 lignes) |
| `zone_analysis` | table | `DBT_MARTS` | Analyse par zone de départ (262 lignes) |
| `hourly_patterns` | table | `DBT_MARTS` | Patterns par heure (24 lignes) |

Choix à savoir expliquer :

- **Schémas `DBT_...`** : dbt écrit dans des schémas séparés pour ne pas écraser les tables faites à la main dans `STAGING` et `FINAL`. Le nom vient du schéma du profil (`DBT`) + le schéma du dossier (`staging`, `intermediate`, `marts`).
- **Vues puis tables** : staging et intermediate sont des vues (rien n'est stocké, c'est juste une requête enregistrée). Les marts sont des tables, car ce sont elles qu'on interroge pour l'analyse.
- **`source()` et `ref()`** : `{{ source('raw', 'yellow_taxi_trips') }}` pointe vers la table brute, `{{ ref('...') }}` vers un autre modèle. C'est grâce à ça que dbt connaît l'ordre d'exécution et dessine le lignage.
- **Tests** (dans les fichiers `schema.yml`) : `not_null` sur les colonnes importantes, `unique` sur la clé de chaque table d'analyse, `accepted_values` sur les 3 catégories.

Vérifications faites :

- `dbt debug` : connexion OK.
- `dbt build` : 6 modèles créés et 22 tests passés (28/28), en 20 secondes environ.
- Les 3 tables de `DBT_MARTS` sont **strictement identiques** aux tables de `FINAL` faites à la main (comparaison ligne à ligne avec `MINUS`, 0 différence).

### 5.2 Comment lancer dbt

dbt ne lit pas le fichier `.env` tout seul, il faut charger les variables dans le terminal avant :

```bash
source venv/bin/activate
set -a && source .env && set +a
cd dbt_nyc_taxi
```

Puis :

| Commande | Rôle |
|---|---|
| `dbt debug` | Vérifie la connexion à Snowflake |
| `dbt run` | Crée les vues et les tables |
| `dbt test` | Lance les tests |
| `dbt build` | Fait `run` + `test` dans l'ordre des dépendances |
| `dbt run --select daily_summary` | Lance un seul modèle |
| `dbt docs generate` puis `dbt docs serve` | Génère et ouvre le site de documentation (avec le graphe de lignage) |

A faire soi-même pour bien comprendre : lancer `dbt docs serve` et regarder le graphe de lignage (bouton bleu en bas à droite), puis aller voir les schémas `DBT_...` dans Snowsight.

## 6. Partie 2 - GitHub Actions

### 6.1 Ce qui a été fait

Un seul fichier : `.github/workflows/pipeline.yml`. GitHub repère tout seul les fichiers de ce dossier.

| Partie du fichier | Rôle |
|---|---|
| `on: schedule` | Lancement automatique chaque 1er du mois à 6h UTC (`cron: "0 6 1 * *"`) |
| `on: workflow_dispatch` | Ajoute un bouton pour lancer le pipeline à la main |
| `env:` | Récupère les identifiants Snowflake dans les secrets du dépôt et les met en variables d'environnement |
| `runs-on: ubuntu-latest` | GitHub prête une machine Ubuntu vide le temps de l'exécution |
| `steps:` | Les étapes, dans l'ordre : récupérer le code, installer Python 3.12, installer les dépendances, `python src/load_data.py`, puis `dbt build` |

Ce sont exactement les commandes lancées en local. Pas besoin de `.env` sur GitHub : `load_dotenv()` ne trouve pas de fichier et le script lit directement les variables d'environnement, comme dbt.

Si une étape échoue (connexion, chargement, test dbt), le pipeline s'arrête et apparaît en rouge dans l'onglet Actions, et GitHub envoie un email.

### 6.2 Ce qu'il faut faire à la main

1. Vérifier que les 6 secrets existent avec **exactement** ces noms (dépôt GitHub → **Settings → Secrets and variables → Actions**) : `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_PASSWORD`, `SNOWFLAKE_ROLE`, `SNOWFLAKE_WAREHOUSE`, `SNOWFLAKE_DATABASE`. Les valeurs sont celles du `.env`, **sans les guillemets** autour du mot de passe.
2. Envoyer le fichier sur GitHub :

   ```bash
   git add .github/workflows/pipeline.yml docs/ README.md
   git commit -m "Ajout du pipeline GitHub Actions"
   git push
   ```

3. Sur GitHub : onglet **Actions** → **Pipeline NYC Taxi** → **Run workflow**. Compter quelques minutes.

### 6.3 A savoir

- Le planning (`schedule`) ne fonctionne que si le fichier est sur la branche principale du dépôt.
- Les données 2025 sont déjà chargées : Snowflake reconnaît les fichiers déjà copiés et ne les recharge pas. Le pipeline sert donc surtout à reconstruire les tables dbt et relancer les tests. Pour charger une nouvelle année, changer `YEAR` dans `src/load_data.py` et le filtre sur l'année dans `stg_yellow_taxi_trips.sql`.
- Chaque exécution retélécharge les 12 fichiers (environ 800 Mo), car la machine GitHub repart de zéro à chaque fois.

## 7. Prochaines étapes

1. Lancer le workflow une première fois sur GitHub et corriger ce qui ne passe pas.
2. Option : dashboard de visualisation des KPIs.
