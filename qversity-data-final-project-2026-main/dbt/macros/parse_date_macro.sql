{% macro parse_date(field) %}
    case
        when {{ field }} ~ '^\d{4}-\d{2}-\d{2}$' then {{ field }}::date
        when {{ field }} ~ '^\d{2}/\d{2}/\d{4}$' then to_date({{ field }}, 'DD/MM/YYYY')
        when {{ field }} ~ '^\d{8}$'              then to_date({{ field }}, 'YYYYMMDD')
        when {{ field }} ~ '^\d{2}-\d{2}-\d{4}$' then to_date({{ field }}, 'MM-DD-YYYY')
        else null
    end
{% endmacro %}