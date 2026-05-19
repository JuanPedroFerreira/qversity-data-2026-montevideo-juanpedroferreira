{{ config(materialized='table', schema='gold') }}

with account_counts as (
    select
        customer_id,
        count(*) as total_accounts
    from {{ ref('dim_accounts') }}
    group by customer_id
),

loan_counts as (
    select
        customer_id,
        count(*) as total_loans
    from {{ ref('fct_loans') }}
    group by customer_id
)

select
    c.customer_id,
    c.customer_segment,
    c.country,
    coalesce(a.total_accounts, 0)                           as total_accounts,
    coalesce(l.total_loans, 0)                              as total_loans,
    coalesce(a.total_accounts, 0) +
    coalesce(l.total_loans, 0)                              as total_products

from {{ ref('dim_customers') }} c
left join account_counts a on c.customer_id = a.customer_id
left join loan_counts l on c.customer_id = l.customer_id