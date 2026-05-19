    {{ config(materialized='table', schema='gold') }}

    select
        t.transaction_id,
        t.account_id,
        t.customer_id,
        t.transaction_date,
        t.amount,
        (t.amount * case t.currency
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
        end)::numeric(20,4)                                     as amount_usd,
        t.currency,
        t.transaction_type,
        t.category,
        t.merchant,
        t.channel,
        t.status,
        c.country,
        c.customer_segment,
        date_part('dow', t.transaction_date)::int               as day_of_week,
        trim(to_char(t.transaction_date, 'Day'))                as day_name,
        to_char(t.transaction_date, 'YYYY-MM')                  as year_month,
        date_part('year', t.transaction_date)::int              as year,
        date_part('month', t.transaction_date)::int             as month,
        case when t.status = 'failed' then true else false end  as is_failed,
        case
            when t.status = 'completed'
            and t.transaction_type in ('payment', 'fee') then true
            else false
        end                                                     as is_revenue,
        case
            when t.currency != case c.country
                when 'CO' then 'COP'
                when 'UY' then 'UYU'
                when 'AR' then 'ARS'
                when 'MX' then 'MXN'
                when 'CL' then 'CLP'
                when 'PE' then 'PEN'
                when 'BR' then 'BRL'
                else null
            end then true
            else false
        end                                                     as is_international,
        case c.country
            when 'CO' then 'COP'
            when 'UY' then 'UYU'
            when 'AR' then 'ARS'
            when 'MX' then 'MXN'
            when 'CL' then 'CLP'
            when 'PE' then 'PEN'
            when 'BR' then 'BRL'
            else null
        end                                                     as local_currency

    from {{ ref('fct_transactions') }} t
    left join {{ ref('dim_customers') }} c on t.customer_id = c.customer_id