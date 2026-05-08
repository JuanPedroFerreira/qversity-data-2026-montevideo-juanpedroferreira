{{ config(materialized='table', schema='silver') }}

select
    loan_id,
    customer_id,
    upper(currency)                             as currency,
    lower(type)                                 as loan_type,
    principal::numeric(15,2)                    as principal,
    outstanding_balance::numeric(15,2)          as outstanding_balance,
    interest_rate::numeric(8,4)                 as interest_rate,
    term_months,
    monthly_payment::numeric(15,2)              as monthly_payment,
    {{ parse_date('start_date') }}              as start_date,
    {{ parse_date('end_date') }}                as end_date,
    lower(status)                               as status,
    days_past_due,

    case
        when trim(lower(collateral_type)) in ('n/a', 'na', 'null', '') then null
        else trim(lower(collateral_type))
    end                                         as collateral_type,

    load_timestamp,
    current_timestamp                           as processed_at

from silver.stg_loans
where loan_id is not null
  and customer_id is not null