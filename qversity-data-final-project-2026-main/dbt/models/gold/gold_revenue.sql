{{ config(materialized='table', schema='gold') }}

with revenue as (
    select
        c.customer_segment,
        c.country,
        t.channel,
        count(distinct t.customer_id)                       as customer_count,
        sum(t.amount * case t.currency
            when 'USD' then 1.0
            when 'ARS' then 0.001
            when 'BRL' then 0.18
            when 'CLP' then 0.001
            when 'COP' then 0.00024
            when 'MXN' then 0.05
            when 'PEN' then 0.27
            when 'UYU' then 0.025
            when 'EUR' then 1.08
            else 1.0
        end)                                                as total_revenue_usd,
        count(t.transaction_id)                             as transaction_count,
        avg(t.amount * case t.currency
            when 'USD' then 1.0
            when 'ARS' then 0.001
            when 'BRL' then 0.18
            when 'CLP' then 0.001
            when 'COP' then 0.00024
            when 'MXN' then 0.05
            when 'PEN' then 0.27
            when 'UYU' then 0.025
            when 'EUR' then 1.08
            else 1.0
        end)                                                as avg_ticket_usd
    from {{ ref('fct_transactions') }} t
    left join {{ ref('dim_customers') }} c on t.customer_id = c.customer_id
    where t.status = 'completed'
      and t.transaction_type in ('payment', 'fee')
    group by c.customer_segment, c.country, t.channel
)

select
    r.customer_segment,
    r.country,
    r.channel,
    r.customer_count,
    r.total_revenue_usd,
    r.transaction_count,
    r.avg_ticket_usd,
    case
        when r.customer_count > 0
        then r.total_revenue_usd / r.customer_count
        else 0
    end::numeric(20,4)                                      as avg_revenue_per_customer_usd

from revenue r