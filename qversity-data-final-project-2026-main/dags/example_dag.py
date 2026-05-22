import os
import sys
from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator

sys.path.insert(0, "/opt/airflow/scripts")
from load_bronze import run_bronze_ingestion  # noqa: E402

default_args = {
    "owner": "juan.ferreira",
    "depends_on_past": False,
    "start_date": datetime(2026, 1, 1),
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}

DBT_PROJECT_DIR = "/opt/airflow/dbt"
DBT_PROFILES_DIR = "/opt/airflow/dbt"
SPARK_DIR = "/opt/airflow/spark"

with DAG(
    dag_id="qversity_fintech_pipeline",
    default_args=default_args,
    description="Pipeline ELT Fintech/Banking: S3 → Bronze → Silver (PySpark) → Silver/Gold (dbt)",
    schedule_interval=None,
    catchup=False,
    tags=["qversity", "fintech", "elt"],
    doc_md="""
    ## Qversity Fintech ELT Pipeline

    Pipeline end-to-end para procesar datos de clientes de una fintech LATAM.

    ### Capas
    | Capa   | Herramienta | Descripción |
    |--------|-------------|-------------|
    | Bronze | Airflow + Python | JSON crudo de S3 → PostgreSQL jsonb |
    | Silver | PySpark | Flatten arrays, dedup → tablas relacionales |
    | Silver | dbt | Limpieza, normalización, dimensiones y facts |
    | Gold   | dbt | Modelos analíticos para las 24 preguntas de negocio |

    ### Cómo triggerear
    ```bash
    docker compose exec airflow airflow dags trigger qversity_fintech_pipeline
    ```
    """,
) as dag:

    ingest_bronze = PythonOperator(
        task_id="ingest_bronze",
        python_callable=run_bronze_ingestion,
        doc_md="""
        Descarga `fintech_banking_dataset.json` desde S3 e inserta cada registro
        como una fila JSONB en `bronze.raw_fintech_data`.
        La tabla se trunca antes de insertar para garantizar idempotencia.
        """,
    )
    spark_flatten = BashOperator(
        task_id="spark_flatten",
        bash_command=f"""
            echo "Iniciando PySpark flatten job..." &&
            python {SPARK_DIR}/flatten_bronze.py
        """,
        doc_md="""
        Corre el script PySpark `flatten_bronze.py` que:
        - Lee `bronze.raw_fintech_data` vía JDBC
        - Aplana los arrays: accounts[], transactions[], loans[]
        - Aplana los objetos: credit_info{}, digital_engagement{}
        - Aplica deduplicación por customer_id / transaction_id / account_id
        - Escribe las staging tables en el schema silver vía JDBC
        """,
    )
    dbt_run_silver = BashOperator(
        task_id="dbt_run_silver",
        bash_command=f"""
            cd {DBT_PROJECT_DIR} &&
            dbt run --profiles-dir {DBT_PROFILES_DIR} --select silver --target dev
        """,
        doc_md="""
        Ejecuta los modelos dbt de la capa Silver:
        - Normaliza tipos y formatos (fechas, numéricos, categorías)
        - Aplana credit_info{} y digital_engagement{}
        - Construye dimensiones: dim_customers, dim_accounts, dim_geography
        - Construye facts: fct_transactions, fct_loans
        """,
    )

    dbt_run_gold = BashOperator(
        task_id="dbt_run_gold",
        bash_command=f"""
            cd {DBT_PROJECT_DIR} &&
            dbt run --profiles-dir {DBT_PROFILES_DIR} --select gold --target dev
        """,
        doc_md="""
        Ejecuta los modelos dbt de la capa Gold:
        - Revenue & Profitability (preguntas 1-4)
        - Risk & Credit (preguntas 5-9)
        - Customer Demographics (preguntas 10-14)
        - Transaction Patterns (preguntas 15-19)
        - Digital Engagement (preguntas 20-21)
        - Product Analysis (preguntas 22-24)
        """,
    )

    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command=f"""
            cd {DBT_PROJECT_DIR} &&
            dbt test --profiles-dir {DBT_PROFILES_DIR} --target dev
        """,
        doc_md="""
        Ejecuta todos los tests de dbt:
        - Unicidad de primary keys
        - Not-null en campos críticos
        - Valores aceptados (statuses, segmentos, canales)
        - Integridad referencial entre facts y dimensiones
        """,
    )

    (
        ingest_bronze
        >> spark_flatten
        >> dbt_run_silver
        >> dbt_run_gold
        >> dbt_test
    )
