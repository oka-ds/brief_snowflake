# Brief Projet Data Engineering
## Pipeline NYC Taxi : Analyse de Données Massives avec Snowflake

---

## 📋 Contexte du Projet

### 🎯 Objectif Pédagogique
Maîtriser la construction d'un pipeline de données professionnel en traitant des données réelles volumineuses de NYC Taxi.

### 📊 Dataset : NYC Taxi Trip Data
- **Volume** : ~40 millions de trajets (année 2025)
- **Taille** : ~8 GB de données compressées
- **Source** : [NYC Taxi & Limousine Commission](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page)
- **Format** : Fichiers Parquet mensuels
- **Exemple de lien** : https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2025-01.parquet

### 🎓 Compétences Visées
- Ingestion de données depuis sources externes
- Architecture de data warehouse (RAW → STAGING → FINAL)
- Nettoyage et transformation de données
- Documentation et tests de qualité
- (Option) Orchestration de pipelines

### 🏗️ Architecture du Data Warehouse
```
📁 Fichiers Parquet → RAW → STAGING → FINAL
                      ↓        ↓         ↓
               Données brutes → Nettoyage → Tables analytiques
```

#### Schémas Snowflake Requis
1. **RAW** : Tables sources (données brutes importées)
2. **STAGING** : Tables de nettoyage et transformation
3. **FINAL** : Tables finales pour analyse et dataviz

---

## 📚 PARTIE 1 : TRONC COMMUN (OBLIGATOIRE)

### ✅ 1.1 Configuration Snowflake

**Créer l'infrastructure de base :**

**Warehouse (ressource de calcul) :**
- Nom : `NYC_TAXI_WH`
- Taille : MEDIUM (ajustable selon vos crédits)
- Auto-suspend : 60 secondes (économise les crédits)

**Base de données :**
- Nom : `NYC_TAXI_DB`

**Schémas à créer :**
- `RAW` : Pour stocker les données brutes importées
- `STAGING` : Pour les données nettoyées et transformées
- `FINAL` : Pour les tables finales d'analyse

### ✅ 1.2 Chargement des Données (2025)
**Objectif** : Charger tous les mois de janvier 2025 à fin 2025

**Option A : Via Snowflake directement (recommandé)**
- Utiliser les stages externes de Snowflake
- Charger directement depuis l'URL source
- Format des fichiers : `yellow_tripdata_YYYY-MM.parquet`
- URL de base : `https://d37ci6vzurychx.cloudfront.net/trip-data/`
- Exemple : `yellow_tripdata_2025-01.parquet`, `yellow_tripdata_2025-02.parquet`, etc.

**Table RAW à créer :**
- Nom : `RAW.yellow_taxi_trips`
- Contient : Toutes les données brutes sans modification
- Colonnes principales : dates pickup/dropoff, distances, montants, zones, etc.

### ✅ 1.3 Analyse et Nettoyage des Données
**Problèmes identifiés dans les données** :
- 15.54% de valeurs manquantes
- 4.15% de montants négatifs
- 2.62% de trajets avec distance zéro
- Valeurs extrêmes aberrantes (distance > 1000 miles)

**Actions de nettoyage requises** :
1. Filtrer les montants négatifs
2. Exclure les trajets avec dates incohérentes
3. Gérer les valeurs manquantes
4. Supprimer les outliers extrêmes

---

### ✅ 1.4 Transformations de Base

#### Tables à créer dans STAGING :

**Table principale nettoyée :**
- Nom : `STAGING.clean_trips`
- Source : `RAW.yellow_taxi_trips`
- Filtres à appliquer :
  - Éliminer les montants négatifs (fare_amount, total_amount)
  - Garder seulement les trajets avec pickup < dropoff
  - Filtrer les distances entre 0.1 et 100 miles
  - Exclure les zones NULL (PULocationID, DOLocationID)

**Enrichissements à ajouter :**
- Calcul de la durée du trajet (en minutes)
- Extraction des dimensions temporelles (heure, jour, mois)
- Calcul de la vitesse moyenne
- Calcul du pourcentage de pourboire

#### Tables à créer dans FINAL :

**Table de résumé quotidien :**
- Nom : `FINAL.daily_summary`
- Métriques par jour : nombre de trajets, distance moyenne, revenus totaux
- Groupement par date de pickup

**Table d'analyse par zone :**
- Nom : `FINAL.zone_analysis`
- Métriques par zone de départ : volume, revenus moyens, popularité

**Table des patterns horaires :**
- Nom : `FINAL.hourly_patterns`
- Métriques par heure : demande, revenus, vitesse moyenne

---

## 🚀 PARTIE 2 : AVANCÉES

### 🌟 ETAPE A : Transformation avec DBT Core

**📺 Ressources recommandées** :
- [DBT Core vs DBT Cloud](https://www.youtube.com/watch?v=ZbLzOgAMAwk)
- [DBT + Snowflake Guide](https://dipikajiandani.medium.com/dbt-snowflake-2831681b67f9)

#### Qu'est-ce que DBT ?
DBT (Data Build Tool) est l'outil moderne pour transformer les données dans votre data warehouse. Il vous permet de :

- **Écrire des transformations** en SQL pur
- **Tester automatiquement** la qualité des données
- **Documenter** vos modèles automatiquement
- **Versionner** vos transformations avec Git

#### Structure DBT pour ce projet :

**Modèles Staging (dossier staging/) :**
- `stg_yellow_taxi_trips.sql` : Nettoyage des données brutes
  - Filtrage des valeurs aberrantes
  - Standardisation des formats
  - Tests de qualité intégrés

**Modèles Intermediate (dossier intermediate/) :**
- `int_trip_metrics.sql` : Enrichissement des données
  - Ajout de catégories (distance, période temporelle)
  - Calcul de métriques (vitesse, pourboires)
  - Dimensions business créées

**Modèles Marts (dossier marts/) :**
- `fact_trips.sql` : Table de faits principale
- `daily_summary.sql` : Résumés quotidiens
- `zone_analysis.sql` : Analyses par zone géographique
- `hourly_patterns.sql` : Patterns de demande horaire

#### Avantages de DBT :
- **Tests intégrés** : Validation automatique de la qualité
- **Documentation auto-générée** : Site web avec description des tables
- **Lignage des données** : Visualisation des dépendances entre tables
- **Modularité** : Réutilisation des transformations


### 🌟 ETAPE B : Orchestration avec GitHub Actions

#### Qu'est-ce que GitHub Actions ?
GitHub Actions permet d'automatiser vos workflows directement depuis votre repository Git.

#### Fonctionnalités du pipeline :
- **Déclenchement automatique** : Chaque 1er du mois ou manuellement
- **Environnement contrôlé** : Utilise Ubuntu avec Python
- **Secrets sécurisés** : Identifiants Snowflake stockés de manière sécurisée
- **Notifications** : Succès/échec visible dans GitHub

#### Idéal pour :
- Projets étudiants (gratuit)
- Simplicité de mise en place
- Intégration avec votre code versioning



---

## 📝 LIVRABLES ATTENDUS

### Pour le Tronc Commun :
1. **Architecture Snowflake** : Création des schémas RAW/STAGING/FINAL
2. **Scripts SQL/DBT** : Tables et transformations documentées
3. **Documentation** : README avec instructions d'exécution
4. **Analyse** : Rapport sur la qualité des données et KPIs calculés

### Pour les Options Avancées :
5. **Script Python** : Automatisation du chargement des données (si option choisie)
6. **Orchestration** : Pipeline automatisé (Airflow/Dagster/GitHub Actions)
7. **DBT Core** : Modèles de transformation avec tests et documentation
8. **Dashboard** : Visualisations interactives des KPIs principaux


---

## 📊 CRITÈRES D'ÉVALUATION

### Tronc Commun 
- ✅ Chargement complet des données 2025
- ✅ Architecture RAW/STAGING/FINAL respectée
- ✅ Nettoyage des données efficace
- ✅ Documentation claire et complète
- ✅ Code Python et SQL fonctionnels

### Options Avancées
- 🌟 Orchestration automatisée
- 🌟 Transformations DBT Core
- 🌟 Dashboard de visualisation
- 🌟 Tests de qualité des données
- 🌟 Optimisation des performances

---

## 🔧 TRANSFORMATIONS À IMPLÉMENTER

### 📊 Catégorisations Nécessaires :

#### Distances des Trajets :
- **Courts trajets** : ≤ 1 mile (déplacements locaux)
- **Trajets moyens** : 1-5 miles (trajets urbains typiques)
- **Longs trajets** : 5-10 miles (traversée d'arrondissements)
- **Très longs trajets** : > 10 miles (aéroports, banlieue)

#### Périodes Temporelles :
- **Rush Matinal** : 6h-9h (pic de trafic vers le travail)
- **Journée** : 10h-15h (trafic normal)
- **Rush Soir** : 16h-19h (retour du travail)
- **Soirée** : 20h-23h (sorties, restaurants)
- **Nuit** : 0h-5h (trafic réduit)

#### Types de Jours :
- **Jours de semaine** : Lundi-Vendredi (patterns professionnels)
- **Weekend** : Samedi-Dimanche (patterns loisirs)

### 🧮 Métriques Calculées :
- **Durée des trajets** : Temps entre prise en charge et dépose
- **Vitesse moyenne** : Distance divisée par durée
- **Taux de pourboire** : Pourcentage du pourboire vs tarif de base

---

## 💡 CONSEILS ET RESSOURCES

### Outils Recommandés :
- **Snowflake** : Essai gratuit 30 jours (400$ de crédits)
- **VS Code** : Avec extensions Python et SQL
- **DBT Core** : Installation via pip (optionnel)
- **GitHub** : Pour versionner votre code

### Ressources Essentielles :

#### 📺 Tutoriels Vidéo Recommandés :
- [**DBT + Snowflake End-to-End**](https://www.youtube.com/watch?v=l-CpmeTFqoI) - Tutorial complet sur l'intégration DBT et Snowflake
- [**DBT Core vs DBT Cloud**](https://www.youtube.com/watch?v=ZbLzOgAMAwk) - Comprendre les différences et choisir la bonne approche
- [**Airflow + NYC Taxi Data**](https://www.youtube.com/watch?v=OLXkGB7krGo&t=518s) - Pipeline d'orchestration avec Airflow

#### 📖 Articles Techniques :
- [**DBT + Snowflake Guide Pratique**](https://dipikajiandani.medium.com/dbt-snowflake-2831681b67f9) - Configuration et bonnes pratiques
- [**Modern ELT Architecture**](https://mayursurani.medium.com/modern-elt-with-dbt-snowflake-and-aws-building-modular-testable-and-governed-data-pipeline-cda2616ad96a) - Architecture complète avec gouvernance des données

#### 📚 Documentation Officielle :
- [Documentation Snowflake](https://docs.snowflake.com)
- [NYC TLC Data Dictionary](https://www.nyc.gov/assets/tlc/downloads/pdf/data_dictionary_trip_records_yellow.pdf)
- [DBT Core Docs](https://docs.getdbt.com)
- [Airflow Documentation](https://airflow.apache.org/docs/)

### Types d'Analyses à Implémenter :

#### 🔍 Analyses de Volume :
- **Top 10 des zones de départ** : Identifier les zones les plus populaires pour les prises en charge
- **Évolution mensuelle** : Suivre les tendances du nombre de trajets dans le temps
- **Distribution horaire** : Comprendre les pics de demande selon l'heure de la journée

#### 💰 Analyses Financières :
- **Revenus par jour de la semaine** : Comparer la rentabilité entre semaine et weekend
- **Analyse des pourboires** : Étudier les patterns de pourboires selon le type de paiement
- **Rentabilité par zone** : Identifier les zones les plus lucratives

#### 🚗 Analyses Opérationnelles :
- **Vitesse moyenne par période** : Analyser la fluidité du trafic selon les heures
- **Distance moyenne des trajets** : Comprendre les patterns de mobilité
- **Temps d'attente estimés** : Calculer les durées moyennes par zone

---

## 🎯 RÉSULTATS ATTENDUS

### À la fin des 3 jours, vous devez avoir :

1. **Un Data Warehouse fonctionnel** avec 3 schémas (RAW, STAGING, FINAL)
2. **Minimum 12 mois de données** chargées et nettoyées (année 2024 complète)
3. **Au minimum 3 tables d'analyse** dans le schéma FINAL
4. **Documentation README** avec instructions d'exécution

### KPIs à calculer (minimum) :
- Nombre total de trajets par mois
- Revenu moyen par trajet
- Distance moyenne parcourue
- Top 10 des zones les plus populaires
- Analyse des heures de pointe

---

## 🎓 CONCLUSION

Ce projet vous permettra de :
- ✅ Maîtriser l'architecture d'un data warehouse moderne
- ✅ Gérer des volumes de données réels (plusieurs GB)
- ✅ Appliquer les bonnes pratiques de data engineering
- ✅ Créer un portfolio professionnel avec un projet concret

**Bon courage et n'hésitez pas à poser des questions !**