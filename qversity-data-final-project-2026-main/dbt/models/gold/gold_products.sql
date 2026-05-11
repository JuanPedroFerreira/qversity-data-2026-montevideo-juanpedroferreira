{{ config(materialized='table', schema='gold') }}

-- Gold: Product Analysis
-- Answers business questions: 22, 23, 24
-- Q22: Most popular account types
-- Q24: Average number of products per customer by segment
-- Grain: one row per customer-account combination
select
    a.account_id,
    a.customer_id,
    a.account_type,
    a.currency,
    a.balance,
    a.credit_limit,
    a.interest_rate,
    a.opened_date,
    a.status                                        as account_status,
    c.customer_segment,
    c.country,
    c.status                                        as customer_status,

    -- Q23: Loan portfolio fields (joined via customer)
    l.loan_id,
    l.loan_type,
    l.currency                                      as loan_currency,
    l.principal,
    l.outstanding_balance,
    l.status                                        as loan_status,
    l.days_past_due,

    -- Delinquency flag
    case
        when l.status in ('delinquent', 'default') then true
        when l.days_past_due > 0                   then true
        else false
    end                                             as is_delinquent,

    -- Days past due bucket
    case
        when l.days_past_due is null                    then null
        when l.days_past_due = 0                        then 'current'
        when l.days_past_due between 1 and 30           then '1-30 days'
        when l.days_past_due between 31 and 60          then '31-60 days'
        when l.days_past_due between 61 and 90          then '61-90 days'
        else '90+ days'
    end                                             as dpd_bucket

from silver.dim_accounts a
left join silver.dim_customers c on a.customer_id = c.customer_id
left join silver.fct_loans l on a.customer_id = l.customer_id