{{ config(materialized='table', schema='silver') }}

select
    customer_id,
    credit_score,
    upper(currency)                         as currency,
    case 
        when utilization_pct > 1 then (utilization_pct / 100)::numeric(8,4)
        else utilization_pct::numeric(8,4)
    end                                     as utilization_pct,
    total_limit::numeric(15,2)              as total_limit,
    total_used::numeric(15,2)               as total_used,
    num_credit_accounts,
    oldest_account_age_months,
    late_payments_12m,
    inquiries_6m,
    bankruptcy_flag,
    load_timestamp,
    current_timestamp                       as processed_at

from silver.stg_credit_info
where customer_id is not null
  and credit_score between 300 and 850