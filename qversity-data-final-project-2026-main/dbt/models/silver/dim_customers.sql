{{ config(materialized='table', schema='silver') }}

select
    customer_id,
    initcap(trim(regexp_replace(first_name, '\s+', ' ', 'g')))  as first_name,
    initcap(trim(regexp_replace(last_name,  '\s+', ' ', 'g')))  as last_name,
    lower(email)                                                  as email,

    case
        when email is null                   then false
        when email ~ '@@'                    then false
        when email !~ '@'                    then false
        when email ~ '\.\.'                  then false
        when email !~ '\.[a-zA-Z]{2,}$'     then false
        else true
    end                                                           as is_valid_email,

    case
        when phone_number ~ '^\+' or phone_number ~ '^\(\+' then
            regexp_replace(
                regexp_replace(phone_number, '[\(\)\s\-]', '', 'g'),
                '^\+\+', '+', 'g'
            )
        when phone_number ~ '^\d' then
            case upper(country)
                when 'CO' then '+57'
                when 'UY' then '+598'
                when 'AR' then '+54'
                when 'MX' then '+52'
                when 'CL' then '+56'
                when 'PE' then '+51'
                when 'BR' then '+55'
                else '+'
            end || regexp_replace(phone_number, '[\s\-]', '', 'g')
        else regexp_replace(phone_number, '[\s\-]', '', 'g')
    end                                                           as phone_number,

    {{ parse_date('date_of_birth') }}                             as date_of_birth,

    case upper(trim(gender))
        when 'M'     then 'M'
        when 'F'     then 'F'
        when 'OTHER' then 'Other'
        when 'N/A'   then null
        when 'NA'    then null
        when 'NULL'  then null
        when ''      then null
        else trim(gender)
    end                                                           as gender,

    nationality,

    case trim(initcap(city))
        when 'Arequpa'         then 'Arequipa'
        when 'Barranquila'     then 'Barranquilla'
        when 'Bogta'           then 'Bogota'
        when 'Brasila'         then 'Brasilia'
        when 'Buenos Aire'     then 'Buenos Aires'
        when 'Cai'             then 'Cali'
        when 'Cartagna'        then 'Cartagena'
        when 'Ciudd De Mexico' then 'Ciudad De Mexico'
        when 'Concepcin'       then 'Concepcion'
        when 'Cordba'          then 'Cordoba'
        when 'Cusc'            then 'Cusco'
        when 'Fortalza'        then 'Fortaleza'
        when 'Guadalajra'      then 'Guadalajara'
        when 'La Serna'        then 'La Serena'
        when 'Lma'             then 'Lima'
        when 'Maldonad'        then 'Maldonado'
        when 'Medelin'         then 'Medellin'
        when 'Mendza'          then 'Mendoza'
        when 'Monterry'        then 'Monterrey'
        when 'Montevide'       then 'Montevideo'
        when 'Paysand'         then 'Paysandu'
        when 'Piua'            then 'Piura'
        when 'Puebl'           then 'Puebla'
        when 'Rio De Janero'   then 'Rio De Janeiro'
        when 'Rivra'           then 'Rivera'
        when 'Rosaro'          then 'Rosario'
        when 'Saltp'           then 'Salto'
        when 'Salvdor'         then 'Salvador'
        when 'Santiag'         then 'Santiago'
        when 'Sao Paulp'       then 'Sao Paulo'
        when 'Temco'           then 'Temuco'
        when 'Tijana'          then 'Tijuana'
        when 'Trujllo'         then 'Trujillo'
        when 'Tucman'          then 'Tucuman'
        else trim(initcap(city))
    end                                                           as city,

    upper(country)                                                as country,
    address,
    lat::numeric(10,6)                                            as lat,
    lon::numeric(10,6)                                            as lon,
    {{ parse_date('registration_date') }}                         as registration_date,

    case lower(kyc_status)
        when 'verificado' then 'verified'
        when 'pendiente'  then 'pending'
        when 'expirado'   then 'expired'
        when 'rechazado'  then 'rejected'
        else lower(kyc_status)
    end                                                           as kyc_status,

    risk_score::numeric(5,2)                                      as risk_score,

    case lower(customer_segment)
        when 'minorista'     then 'retail'
        when 'pyme'          then 'sme'
        when 'banca_privada' then 'private_banking'
        when 'banca privada' then 'private_banking'
        else lower(customer_segment)
    end                                                           as customer_segment,

    case upper(trim(relationship_manager))
        when 'N/A'  then null
        when 'NA'   then null
        when 'NULL' then null
        when ''     then null
        else trim(relationship_manager)
    end                                                           as relationship_manager,

    case lower(status)
        when 'activo'     then 'active'
        when 'inactivo'   then 'inactive'
        when 'suspendido' then 'suspended'
        when 'cerrado'    then 'closed'
        else lower(status)
    end                                                           as status,

    load_timestamp,
    current_timestamp                                             as processed_at

from silver.stg_customers
where customer_id is not null