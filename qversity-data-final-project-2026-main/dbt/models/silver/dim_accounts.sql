{{ config(materialized='table', schema='silver') }}

select
    account_id,
    customer_id,
    trim(lower(account_type))               as account_type,
    upper(currency)                         as currency,
    balance::numeric(15,2)                  as balance,
    credit_limit::numeric(15,2)             as credit_limit,
    interest_rate::numeric(8,4)             as interest_rate,
    {{ parse_date('opened_date') }}         as opened_date,

    case trim(lower(status))
        when 'activo'    then 'active'
        when 'cerrado'   then 'closed'
        when 'congelado' then 'frozen'
        else trim(lower(status))
    end                                     as status,

    branch_code,
    load_timestamp,
    current_timestamp                       as processed_at

from silver.stg_accounts
where account_id is not null
  and customer_id is not null