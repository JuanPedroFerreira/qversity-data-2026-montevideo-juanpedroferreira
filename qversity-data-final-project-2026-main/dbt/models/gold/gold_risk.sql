{{ config(materialized='table', schema='gold') }}
select
    c.customer_id,
    c.customer_segment,
    c.country,
    c.risk_score,
    case
        when c.risk_score between 0  and 25 then 'low'
        when c.risk_score between 26 and 50 then 'medium'
        when c.risk_score between 51 and 75 then 'high'
        else 'critical'
    end                                                     as risk_bucket,
    ci.credit_score,
    case
        when ci.credit_score between 300 and 579 then 'poor'
        when ci.credit_score between 580 and 669 then 'fair'
        when ci.credit_score between 670 and 739 then 'good'
        when ci.credit_score between 740 and 799 then 'very_good'
        when ci.credit_score between 800 and 850 then 'exceptional'
    end                                                     as credit_score_bucket,
    ci.utilization_pct,
    case
        when ci.utilization_pct <= 0.10 then 'low'
        when ci.utilization_pct <= 0.30 then 'moderate'
        when ci.utilization_pct <= 0.50 then 'high'
        else 'very_high'
    end                                                     as utilization_bucket,
    l.loan_id,
    l.loan_type,
    l.status                                                as loan_status,
    l.days_past_due,
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
    case
        when l.status in ('delinquent', 'default') then true
        when l.days_past_due > 0                   then true
        else false
    end                                                     as is_delinquent,

    case
        when l.days_past_due is null            then null
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
    end::numeric(20,4)                                      as interest_income_usd

from {{ ref('dim_customers') }} c
left join {{ ref('dim_credit_info') }} ci on c.customer_id = ci.customer_id
left join {{ ref('fct_loans') }} l on c.customer_id = l.customer_id