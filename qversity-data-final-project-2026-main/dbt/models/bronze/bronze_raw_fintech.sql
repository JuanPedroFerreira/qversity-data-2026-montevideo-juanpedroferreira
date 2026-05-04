{{ config(materialized='table') }}

-- Bronze layer: Raw fintech/banking data
-- This is a placeholder. Replace with your actual bronze model that
-- reads from the raw JSON table loaded by the Airflow DAG.
--
-- Your actual model should reference the table where raw JSON records
-- are stored as jsonb. For example:
--
--   SELECT
--       id,
--       data,          -- jsonb column with full customer record
--       load_timestamp -- when the record was ingested
--   FROM {{ source('raw', 'fintech_raw') }}

select
    'CUST-0000001' as customer_id,
    '{"first_name": "Maria", "last_name": "Garcia"}'::jsonb as data,
    current_timestamp as load_timestamp

union all

select
    'CUST-0000002' as customer_id,
    '{"first_name": "Carlos", "last_name": "Rodriguez"}'::jsonb as data,
    current_timestamp as load_timestamp

union all

select
    'CUST-0000003' as customer_id,
    '{"first_name": "Ana", "last_name": "Martinez"}'::jsonb as data,
    current_timestamp as load_timestamp
