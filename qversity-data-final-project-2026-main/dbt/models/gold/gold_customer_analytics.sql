{{ config(materialized='table') }}

-- Gold layer: Customer analytics
-- This is a placeholder. Replace with your actual gold models that
-- answer the 24 business questions from the project guide.
--
-- Example questions to answer:
--   - Average revenue per customer by segment
--   - Total account balances by country
--   - Loan delinquency rate by customer segment
--   - Credit score distribution by country
--   - Customer acquisition trend over time

select
    customer_id,
    first_name,
    last_name,
    current_timestamp as report_generated_at
from {{ ref('silver_customers') }}
