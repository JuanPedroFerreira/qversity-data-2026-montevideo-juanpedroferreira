-- =============================================================================
-- Qversity Data Warehouse — Schema Initialization
-- Se ejecuta automáticamente al levantar el contenedor de PostgreSQL
-- =============================================================================

-- Crear los 3 schemas de la arquitectura medallion
CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;

-- =============================================================================
-- BRONZE LAYER
-- Almacena el JSON crudo tal como viene de S3, sin transformaciones
-- Una fila por customer record
-- =============================================================================
CREATE TABLE IF NOT EXISTS bronze.raw_fintech_data (
    id              SERIAL          PRIMARY KEY,
    data            JSONB           NOT NULL,
    source_url      TEXT            NOT NULL,
    load_timestamp  TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

-- Índice GIN para queries sobre el JSONB (útil en EDA y debugging)
CREATE INDEX IF NOT EXISTS idx_bronze_data_gin
    ON bronze.raw_fintech_data USING GIN (data);

-- Índice sobre customer_id dentro del JSON (para dedup en PySpark)
CREATE INDEX IF NOT EXISTS idx_bronze_customer_id
    ON bronze.raw_fintech_data ((data->>'customer_id'));

COMMENT ON TABLE bronze.raw_fintech_data IS
    'Raw customer records ingested from S3 fintech_banking_dataset.json. One row per customer record. No transformations applied.';

COMMENT ON COLUMN bronze.raw_fintech_data.data IS
    'Full original JSON record as jsonb. Contains nested arrays: accounts[], transactions[], loans[] and nested objects: credit_info{}, digital_engagement{}.';

COMMENT ON COLUMN bronze.raw_fintech_data.source_url IS
    'URL from which the record was ingested (S3 public URL).';

COMMENT ON COLUMN bronze.raw_fintech_data.load_timestamp IS
    'UTC timestamp when this record was inserted into the bronze layer.';
