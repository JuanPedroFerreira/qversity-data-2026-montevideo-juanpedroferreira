{{ config(materialized='table', schema='silver') }}

select
    transaction_id,
    account_id,
    customer_id,
    {{ parse_date('date') }}                                    as transaction_date,
    amount::numeric(15,2)                                       as amount,
    upper(currency)                                             as currency,

    case lower(type)
        when 'deposito'      then 'deposit'
        when 'retiro'        then 'withdrawal'
        when 'transferencia' then 'transfer'
        when 'pago'          then 'payment'
        when 'reembolso'     then 'refund'
        when 'comision'      then 'fee'
        else lower(type)
    end                                                         as transaction_type,

    case
        when trim(lower(category)) in ('n/a', 'na', 'null', '') then null
        else trim(lower(category))
    end                                                         as category,

    case
        when trim(lower(merchant)) in ('n/a', 'na', 'null', '') then null
        else trim(merchant)
    end                                                         as merchant,

    case lower(channel)
        when 'movil'    then 'mobile'
        when 'sucursal' then 'branch'
        else lower(channel)
    end                                                         as channel,

    case lower(status)
        when 'completado' then 'completed'
        when 'pendiente'  then 'pending'
        when 'fallido'    then 'failed'
        when 'revertido'  then 'reversed'
        else lower(status)
    end                                                         as status,

    case
        when trim(lower(description)) in ('n/a', 'na', 'null', '') then null
        else trim(description)
    end                                                         as description,

    load_timestamp,
    current_timestamp                                           as processed_at

from silver.stg_transactions
where transaction_id is not null
  and customer_id is not null
  and amount is not null