{{ config(materialized='table', schema='gold') }}

select
    a.account_id,
    a.customer_id,
    a.account_type,
    a.currency,
    a.balance,
    (a.balance * case a.currency
        when 'USD' then 1.0
        when 'ARS' then 0.001
        when 'BRL' then 0.18
        when 'CLP' then 0.001
        when 'COP' then 0.00024
        when 'MXN' then 0.05
        when 'PEN' then 0.27
        when 'UYU' then 0.025
        else 1.0
    end)::numeric(20,4)                                     as balance_usd,
    a.credit_limit,
    a.interest_rate,
    a.opened_date,
    a.status                                                as account_status,
    a.branch_code,
    c.customer_segment,
    c.country,
    c.status                                                as customer_status,

    date_part('month', age(current_date, a.opened_date))::int +
    date_part('year',  age(current_date, a.opened_date))::int * 12 as account_age_months,

    case when a.account_type = 'credit_card' then true else false end as is_credit_card

from {{ ref('dim_accounts') }} a
left join {{ ref('dim_customers') }} c on a.customer_id = c.customer_id