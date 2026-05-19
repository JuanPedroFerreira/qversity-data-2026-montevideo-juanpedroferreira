{{ config(materialized='table', schema='gold') }}

-- =============================================================================
-- Gold: Customer Demographics
-- Grain: one row per customer
-- Answers: Q9, Q10, Q11, Q12, Q13, Q14
-- Business logic:
--   - Age calculated from date_of_birth to current_date
--   - Age buckets: 18-25, 26-35, 36-45, 46-55, 56-65, 65+
--   - Risk buckets: low (0-25), medium (26-50), high (51-75), critical (76-100)
--   - Tenure in months from registration_date to current_date
-- =============================================================================

select
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.country,
    c.city,
    c.gender,
    c.nationality,
    c.customer_segment,
    c.status,
    c.kyc_status,
    c.risk_score,
    c.registration_date,
    c.date_of_birth,
    case
        when c.risk_score between 0  and 25 then 'low'
        when c.risk_score between 26 and 50 then 'medium'
        when c.risk_score between 51 and 75 then 'high'
        else 'critical'
    end                                                     as risk_bucket,
    date_part('year', age(current_date, c.date_of_birth))::int as age,
    case
        when date_part('year', age(current_date, c.date_of_birth)) between 18 and 25 then '18-25'
        when date_part('year', age(current_date, c.date_of_birth)) between 26 and 35 then '26-35'
        when date_part('year', age(current_date, c.date_of_birth)) between 36 and 45 then '36-45'
        when date_part('year', age(current_date, c.date_of_birth)) between 46 and 55 then '46-55'
        when date_part('year', age(current_date, c.date_of_birth)) between 56 and 65 then '56-65'
        else '65+'
    end                                                     as age_bucket,
    to_char(c.registration_date, 'YYYY-MM')                as registration_month,
    date_part('year', c.registration_date)::int            as registration_year,
    date_part('month', age(current_date, c.registration_date))::int +
    date_part('year',  age(current_date, c.registration_date))::int * 12 as tenure_months

from {{ ref('dim_customers') }} c