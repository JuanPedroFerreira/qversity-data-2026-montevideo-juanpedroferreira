# Qversity v2 — Fintech/Banking Data Engineering Project

A containerized ELT data platform using Docker Compose with Airflow, PostgreSQL, PySpark, dbt, and PowerBI.

## Architecture

This project implements a **Bronze-Silver-Gold** data lakehouse architecture for a LATAM Fintech/Banking dataset:

- **Bronze Layer**: Raw JSON ingestion from S3 into PostgreSQL (`jsonb`)
- **Silver Layer (PySpark)**: Flatten nested arrays, deduplicate
- **Silver Layer (dbt)**: Clean, standardize, and normalize PySpark output; flatten nested objects
- **Gold Layer (dbt)**: Business-ready analytics and aggregations answering 24 business questions
- **PowerBI**: 4-page dashboard connected to Gold layer tables

```
S3 (JSON) → Airflow → Bronze → PySpark (Silver) → dbt (Silver) → dbt (Gold) → PowerBI
```

## Project Structure

```
qversity-data-2026-<city>-<firstname><lastname>/
├── dags/                     # Airflow DAG definitions
│   └── example_dag.py        # Placeholder pipeline DAG
├── spark/                    # PySpark scripts (NEW in v2)
├── dbt/                      # dbt project
│   ├── models/
│   │   ├── bronze/           # Raw data staging
│   │   ├── silver/           # Cleaned and normalized data
│   │   └── gold/             # Business analytics
│   ├── tests/                # dbt tests
│   ├── dbt_project.yml       # dbt configuration
│   └── profiles.yml          # Database connections
├── powerbi/                  # PowerBI deliverables (NEW in v2)
│   ├── dashboard.pbix        # PowerBI file (you create this)
│   └── screenshots/          # Dashboard page screenshots
├── data/
│   └── raw/                  # Raw input data
├── docker-compose.yml        # Docker environment setup
├── env.example               # Environment variables template
├── requirements.txt          # Python dependencies
├── .gitignore
├── .pre-commit-config.yaml   # Code quality hooks
└── README.md                 # This file
```

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- At least 4GB RAM available
- PowerBI Desktop (for dashboard creation)

### Setup

1. **Clone the repository and setup environment**:
```bash
git clone <your-repo-url>
cd qversity-data-2026-<city>-<name>
cp env.example .env
```

2. **Start services**:
```bash
docker compose up -d --build
```

3. **Verify services are running**:
```bash
docker compose ps
```

4. **Access Airflow UI**: http://localhost:8080 (admin/admin)

5. **Trigger the pipeline** (once you've built it):
```bash
docker compose exec airflow airflow dags trigger qversity_fintech_pipeline
```

## Access Points

| Service | URL / Connection | Credentials |
|---------|-----------------|-------------|
| Airflow UI | http://localhost:8080 | admin / admin |
| PostgreSQL | localhost:5432 | qversity-admin / qversity-admin |
| Database | qversity | — |

## Common Commands

### Airflow
```bash
# View logs
docker compose logs -f airflow

# List DAGs
docker compose exec airflow airflow dags list

# Trigger DAG
docker compose exec airflow airflow dags trigger qversity_fintech_pipeline

# Check DAG run status
docker compose exec airflow airflow dags list-runs -d qversity_fintech_pipeline
```

### PySpark
```bash
# Test PySpark interactively
docker compose exec airflow python -c "from pyspark.sql import SparkSession; print('PySpark OK')"
```

### dbt
```bash
# Enter dbt container
docker compose exec dbt bash

# Run all models
dbt run

# Run specific layer
dbt run --models bronze
dbt run --models silver
dbt run --models gold

# Test data quality
dbt test

# List models
dbt ls --resource-type model
```

### Database Access
```bash
# Connect to PostgreSQL
docker compose exec postgres psql -U qversity-admin -d qversity

# View schemas
\dn

# View tables in a schema
\dt bronze.*
\dt silver.*
\dt gold.*

# Describe a table
\d <schema>.<table_name>
```

## Data Source

The dataset is a JSON file from an S3 public bucket:

- **URL**: `https://qversity-raw-public-data.s3.amazonaws.com/fintech_banking_dataset.json`
- **Records**: ~5,000 customers with nested accounts, transactions, loans, credit info, and digital engagement data
- **Countries**: CO, UY, AR, MX, CL, PE, BR

See the **Technical Project Guide** for full dataset documentation.

## Git Tags (Milestones)

Submit your work incrementally:

```bash
git tag -a v0.1.0-bronze -m "Bronze layer complete"
git tag -a v0.2.0-silver -m "Silver layer complete"
git tag -a v0.3.0-gold -m "Gold layer complete"
git tag -a v0.4.0-powerbi -m "PowerBI dashboard complete"
git tag -a v1.0.0 -m "Final submission"
```

## Cleanup

```bash
# Stop services
docker compose down

# Remove volumes (deletes all data)
docker compose down -v

# Remove images
docker compose down -v --rmi local
```

## Participant

- **Name**: [Your Full Name]
- **Email**: [your.email@example.com]
- **City**: [Your City]
- **Cohort**: Qversity 2026
