{{ config(materialized='table', schema='silver') }}

select
    customer_id,
    mobile_app_registered,
    web_banking_registered,
    {{ parse_date('last_login_date') }}     as last_login_date,
    avg_monthly_logins,
    lower(preferred_channel)               as preferred_channel,
    push_notifications,
    paperless_statements,
    load_timestamp,
    current_timestamp                      as processed_at

from silver.stg_digital_engagement
where customer_id is not null