{{ config(materialized='table', schema='gold') }}

-- =============================================================================
-- Gold: Customer Demographics
-- Answers business questions: 10, 11, 12, 13, 14
-- Grain: one row per customer with all demographic attributes
-- =============================================================================

select
    c.customer_id,
    c.first_name,
    c.last_name,
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

    -- Q9: Risk score bucket
    case
        when c.risk_score between 0  and 25 then 'low'
        when c.risk_score between 26 and 50 then 'medium'
        when c.risk_score between 51 and 75 then 'high'
        else 'critical'
    end                                         as risk_bucket,

    -- Q11: Age in years
    date_part('year', age(current_date, c.date_of_birth))::int as age,

    -- Q11: Age bucket
    case
        when date_part('year', age(current_date, c.date_of_birth)) between 18 and 25 then '18-25'
        when date_part('year', age(current_date, c.date_of_birth)) between 26 and 35 then '26-35'
        when date_part('year', age(current_date, c.date_of_birth)) between 36 and 45 then '36-45'
        when date_part('year', age(current_date, c.date_of_birth)) between 46 and 55 then '46-55'
        when date_part('year', age(current_date, c.date_of_birth)) between 56 and 65 then '56-65'
        else '65+'
    end                                         as age_bucket,

    -- Q12: Registration year-month for acquisition trend
    to_char(c.registration_date, 'YYYY-MM')     as registration_month,

    -- Q12: Registration year
    date_part('year', c.registration_date)::int as registration_year,

    -- Tenure in months
    date_part('month', age(current_date, c.registration_date))::int +
    date_part('year',  age(current_date, c.registration_date))::int * 12 as tenure_months

from silver.dim_customers c