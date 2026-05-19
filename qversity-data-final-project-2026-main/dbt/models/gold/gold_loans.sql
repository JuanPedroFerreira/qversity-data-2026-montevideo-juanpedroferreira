{{ config(materialized='table', schema='gold') }}

select
    l.loan_id,
    l.customer_id,
    l.loan_type,
    l.currency,
    l.principal,
    l.outstanding_balance,
    (l.outstanding_balance * case l.currency
        when 'USD' then 1.0
        when 'ARS' then 0.001
        when 'BRL' then 0.18
        when 'CLP' then 0.001
        when 'COP' then 0.00024
        when 'MXN' then 0.05
        when 'PEN' then 0.27
        when 'UYU' then 0.025
        else 1.0
    end)::numeric(20,4)                                     as outstanding_balance_usd,
    l.interest_rate,
    l.term_months,
    l.monthly_payment,
    l.start_date,
    l.end_date,
    l.status,
    l.days_past_due,
    l.collateral_type,
    c.customer_segment,
    c.country,
    case
        when l.status in ('delinquent', 'default') then true
        when l.days_past_due > 0                   then true
        else false
    end                                                     as is_delinquent,
    case
        when l.days_past_due = 0               then 'current'
        when l.days_past_due between 1  and 30 then '1-30 days'
        when l.days_past_due between 31 and 60 then '31-60 days'
        when l.days_past_due between 61 and 90 then '61-90 days'
        else '90+ days'
    end                                                     as dpd_bucket,
    case
        when l.status = 'current'
         and l.outstanding_balance is not null
         and l.interest_rate is not null
        then (l.outstanding_balance * case l.currency
                when 'USD' then 1.0
                when 'ARS' then 0.001
                when 'BRL' then 0.18
                when 'CLP' then 0.001
                when 'COP' then 0.00024
                when 'MXN' then 0.05
                when 'PEN' then 0.27
                when 'UYU' then 0.025
                else 1.0
             end) * l.interest_rate / 100
        else 0
    end::numeric(20,4)                                      as interest_income_usd,
    case
        when l.principal > 0
        then round((l.outstanding_balance / l.principal * 100)::numeric, 2)
        else null
    end                                                     as pct_outstanding

from {{ ref('fct_loans') }} l
left join {{ ref('dim_customers') }} c on l.customer_id = c.customer_id