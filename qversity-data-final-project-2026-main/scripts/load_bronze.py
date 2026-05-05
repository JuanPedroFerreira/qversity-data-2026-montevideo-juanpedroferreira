"""
load_bronze.py - Bronze ingestion with S3 + local fallback
"""
import json, logging, os
from datetime import datetime, timezone
import psycopg2, requests

logging.basicConfig(level=logging.INFO)
log = logging.getLogger(__name__)

S3_DATASET_URL = os.getenv("S3_DATASET_URL", "https://qversity-raw-public-data.s3.amazonaws.com/fintech_banking_dataset.json")
LOCAL_DATASET_PATH = os.getenv("LOCAL_DATASET_PATH", "/opt/airflow/data/raw/fintech_banking_dataset.json")

DB_CONFIG = {
    "host":     os.getenv("POSTGRES_HOST", "postgres"),
    "port":     int(os.getenv("POSTGRES_PORT", 5432)),
    "dbname":   os.getenv("POSTGRES_DB", "qversity"),
    "user":     os.getenv("POSTGRES_USER", "qversity-admin"),
    "password": os.getenv("POSTGRES_PASSWORD", "qversity-admin"),
}

BATCH_SIZE = 500

def _parse_payload(payload):
    if isinstance(payload, list):
        return payload
    elif isinstance(payload, dict):
        for key, value in payload.items():
            if isinstance(value, list):
                log.info(f"Registros bajo clave: '{key}'")
                return value
    raise ValueError(f"Formato inesperado: {type(payload)}")

def download_dataset(url: str):
    try:
        log.info(f"Descargando desde S3: {url}")
        r = requests.get(url, timeout=120)
        r.raise_for_status()
        log.info("Descarga S3 exitosa.")
        return _parse_payload(r.json())
    except Exception as e:
        log.warning(f"S3 falló ({e}). Probando archivo local...")

    if os.path.exists(LOCAL_DATASET_PATH):
        log.info(f"Leyendo desde: {LOCAL_DATASET_PATH}")
        with open(LOCAL_DATASET_PATH, "r", encoding="utf-8") as f:
            return _parse_payload(json.load(f))

    raise FileNotFoundError(
        f"Dataset no disponible. Colocá el archivo en: data/raw/fintech_banking_dataset.json"
    )

def truncate_bronze(conn):
    with conn.cursor() as cur:
        cur.execute("TRUNCATE TABLE bronze.raw_fintech_data RESTART IDENTITY;")
    conn.commit()
    log.info("Tabla bronze truncada.")

def insert_records(conn, records, source_url):
    load_ts = datetime.now(timezone.utc)
    total = 0
    with conn.cursor() as cur:
        for i in range(0, len(records), BATCH_SIZE):
            batch = records[i:i+BATCH_SIZE]
            cur.executemany(
                "INSERT INTO bronze.raw_fintech_data (data, source_url, load_timestamp) VALUES (%s::jsonb, %s, %s)",
                [(json.dumps(r), source_url, load_ts) for r in batch]
            )
            conn.commit()
            total += len(batch)
            log.info(f"Insertados {total}/{len(records)}...")
    return total

def validate_bronze(conn):
    with conn.cursor() as cur:
        cur.execute("SELECT COUNT(*) FROM bronze.raw_fintech_data;")
        count = cur.fetchone()[0]
        log.info(f"Registros en bronze: {count}")
        if count < 1000:
            raise ValueError(f"Solo {count} registros. Se requieren >= 1000.")
        cur.execute("SELECT COUNT(*) FROM bronze.raw_fintech_data WHERE data->>'customer_id' IS NULL;")
        nulls = cur.fetchone()[0]
        if nulls > 0:
            log.warning(f"{nulls} registros sin customer_id.")

def run_bronze_ingestion(**context):
    log.info("=== INICIANDO INGESTA BRONZE ===")
    records = download_dataset(S3_DATASET_URL)
    conn = psycopg2.connect(**DB_CONFIG)
    try:
        truncate_bronze(conn)
        total = insert_records(conn, records, S3_DATASET_URL)
        validate_bronze(conn)
        summary = f"Bronze complete. {total} records loaded."
        log.info(f"=== {summary} ===")
        return summary
    except Exception as e:
        conn.rollback()
        log.error(f"Error: {e}")
        raise
    finally:
        conn.close()

if __name__ == "__main__":
    run_bronze_ingestion()