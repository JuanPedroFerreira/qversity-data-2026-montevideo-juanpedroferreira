from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator


def hello_qversity():
    print("Hello from Qversity v2!")
    print("This is a placeholder DAG.")
    print("Replace this with your actual pipeline logic.")
    return "Pipeline started"


default_args = {
    "owner": "qversity",
    "depends_on_past": False,
    "start_date": datetime(2026, 1, 1),
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}

dag = DAG(
    "qversity_fintech_pipeline",
    default_args=default_args,
    description="Qversity v2 Fintech/Banking ELT Pipeline",
    schedule_interval=None,
    catchup=False,
    tags=["qversity", "fintech"],
)

# ---------------------------------------------------------------
# Task 1: Placeholder - Download JSON from S3 and load to Bronze
# ---------------------------------------------------------------
hello_task = PythonOperator(
    task_id="hello_qversity",
    python_callable=hello_qversity,
    dag=dag,
)

# ---------------------------------------------------------------
# Task 2: Placeholder - PySpark tasks
# Replace with your actual PySpark scripts
# ---------------------------------------------------------------
spark_placeholder = BashOperator(
    task_id="spark_placeholder",
    bash_command='echo "PySpark tasks go here"',
    dag=dag,
)

# ---------------------------------------------------------------
# Task 3: Placeholder - dbt run (Silver + Gold models)
# ---------------------------------------------------------------
dbt_placeholder = BashOperator(
    task_id="dbt_placeholder",
    bash_command='echo "dbt run goes here"',
    dag=dag,
)

# ---------------------------------------------------------------
# Task 4: Placeholder - dbt test
# ---------------------------------------------------------------
dbt_test_placeholder = BashOperator(
    task_id="dbt_test_placeholder",
    bash_command='echo "dbt test goes here"',
    dag=dag,
)

# Task dependencies: Bronze -> PySpark -> dbt run -> dbt test
hello_task >> spark_placeholder >> dbt_placeholder >> dbt_test_placeholder
