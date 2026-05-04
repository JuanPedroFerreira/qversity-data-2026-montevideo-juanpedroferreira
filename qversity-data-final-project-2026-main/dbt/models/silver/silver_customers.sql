{{ config(materialized='table') }}

-- Silver layer: Cleaned and standardized customer data
-- This is a placeholder. Replace with your actual silver model that:
--   1. Reads from the PySpark staging table (stg_customers)
--   2. Standardizes casing (UPPER/lower → Proper Case)
--   3. Normalizes date formats to YYYY-MM-DD
--   4. Cleans whitespace, fixes invalid values
--   5. Validates email format
--   6. Standardizes status values (activo → active)

select
    customer_id,
    initcap(data->>'first_name') as first_name,
    initcap(data->>'last_name') as last_name,
    load_timestamp as processed_at
from {{ ref('bronze_raw_fintech') }}
