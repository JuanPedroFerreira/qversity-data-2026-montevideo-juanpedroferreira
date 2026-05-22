{{ config(materialized='table', schema='bronze') }}

select
    id,
    data,
    source_url,
    load_timestamp
from bronze.raw_fintech_data

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
