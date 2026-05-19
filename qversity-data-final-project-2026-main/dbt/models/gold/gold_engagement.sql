{{ config(materialized='table', schema='gold') }}

-- =============================================================================
-- Gold: Digital Engagement
-- Grain: one row per customer
-- Answers: Q20, Q21
-- Business logic:
--   - Fully digital: mobile AND web registered
--   - Digital preference: mobile or web vs branch/atm
-- =============================================================================

select
    c.customer_id,
    c.customer_segment,
    c.country,
    date_part('year', age(current_date, c.date_of_birth))::int as age,
    case
        when date_part('year', age(current_date, c.date_of_birth)) between 18 and 25 then '18-25'
        when date_part('year', age(current_date, c.date_of_birth)) between 26 and 35 then '26-35'
        when date_part('year', age(current_date, c.date_of_birth)) between 36 and 45 then '36-45'
        when date_part('year', age(current_date, c.date_of_birth)) between 46 and 55 then '46-55'
        when date_part('year', age(current_date, c.date_of_birth)) between 56 and 65 then '56-65'
        else '65+'
    end                                                         as age_bucket,
    de.mobile_app_registered,
    de.web_banking_registered,
    de.preferred_channel,
    de.avg_monthly_logins,
    de.push_notifications,
    de.paperless_statements,
    de.last_login_date,
    case
        when de.mobile_app_registered = true
         and de.web_banking_registered = true then true
        else false
    end                                                         as is_fully_digital,
    case
        when de.preferred_channel in ('mobile', 'web') then 'digital'
        when de.preferred_channel in ('branch', 'atm')  then 'physical'
        else 'other'
    end                                                         as channel_preference,
    (current_date - de.last_login_date)::int                   as days_since_last_login

from {{ ref('dim_customers') }} c
left join {{ ref('dim_digital_engagement') }} de on c.customer_id = de.customer_id