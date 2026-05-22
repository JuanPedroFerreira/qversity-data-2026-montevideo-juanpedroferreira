-- Total: 5000 registros, uno por cliente
SELECT COUNT(*) as total FROM silver.stg_credit_info;

-- Encontré valores raros: mínimo -99 y máximo 999,999
-- El rango válido según el PDF es 300-850
-- Lo soluciono filtrando en dim_credit_info con WHERE credit_score BETWEEN 300 AND 850
-- Se pierden 492 registros inválidos, quedan 4,508
SELECT
    MIN(credit_score)                               as min_score,
    MAX(credit_score)                               as max_score,
    ROUND(AVG(credit_score)::numeric, 1)            as avg_score,
    PERCENTILE_CONT(0.5) WITHIN GROUP
        (ORDER BY credit_score)                     as median_score
FROM silver.stg_credit_info;

-- Utilización de crédito
-- Problema: algunos valores vienen como 0.35 (decimal) y otros como 35 (porcentaje entero)
-- Lo normalizo todo a decimal 0-1 en dim_credit_info con CASE WHEN utilization_pct > 1
SELECT
    MIN(utilization_pct)                            as min_util,
    MAX(utilization_pct)                            as max_util,
    ROUND(AVG(utilization_pct)::numeric, 4)         as avg_util,
    COUNT(CASE WHEN utilization_pct > 1 THEN 1 END) as above_1
FROM silver.stg_credit_info;

-- Bankruptcy flag
-- 568 nulls, 2263 false, 2169 true — distribución bastante balanceada
SELECT bankruptcy_flag, COUNT(*) as total
FROM silver.stg_credit_info
GROUP BY bankruptcy_flag;

-- Pagos atrasados en los últimos 12 meses
-- Rango 0-12, sin valores raros
SELECT
    MIN(late_payments_12m)                          as min_late,
    MAX(late_payments_12m)                          as max_late,
    ROUND(AVG(late_payments_12m)::numeric, 2)       as avg_late
FROM silver.stg_credit_info;


-- Nulls en total_limit y total_used
-- 157 y 152 nulls respectivamente — los dejo como NULL, no tiene sentido imputar
SELECT
    COUNT(CASE WHEN total_limit IS NULL THEN 1 END) as null_limit,
    COUNT(CASE WHEN total_used IS NULL THEN 1 END)  as null_used
FROM silver.stg_credit_info;


-- 7 monedas LATAM, muy balanceadas
SELECT currency, COUNT(*) as total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM silver.stg_credit_info
GROUP BY currency
ORDER BY total DESC;

-- 49% mobile, 49% web — muy parejo
SELECT
    COUNT(*) as total,
    COUNT(CASE WHEN mobile_app_registered THEN 1 END)   as mobile_users,
    COUNT(CASE WHEN web_banking_registered THEN 1 END)  as web_users,
    ROUND(COUNT(CASE WHEN mobile_app_registered THEN 1 END) * 100.0 / COUNT(*), 2) as mobile_pct,
    ROUND(COUNT(CASE WHEN web_banking_registered THEN 1 END) * 100.0 / COUNT(*), 2) as web_pct
FROM silver.stg_digital_engagement;

-- Encontré 'phone' que no estaba en el PDF, lo agregué a los accepted_values en schema.yml
SELECT preferred_channel, COUNT(*) as total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM silver.stg_digital_engagement
GROUP BY preferred_channel
ORDER BY total DESC;

mobile	1058	21.16
branch	1005	20.10
atm	1002	20.04
web	971	19.42
phone	964	19.28

-- Rango 0-60, promedio 30, 374 nulls — los dejo como NULL
SELECT
    MIN(avg_monthly_logins)                                 as min_logins,
    MAX(avg_monthly_logins)                                 as max_logins,
    ROUND(AVG(avg_monthly_logins)::numeric, 2)              as avg_logins,
    COUNT(CASE WHEN avg_monthly_logins IS NULL THEN 1 END)  as null_logins
FROM silver.stg_digital_engagement;

-- Si intento comparar con current_date tira error: "operator does not exist: text > date"
-- Lo soluciono en dim_digital_engagement donde el macro parse_date lo convierte a DATE
-- Por eso acá solo consulto el mínimo y máximo como texto
SELECT
    MIN(last_login_date)                                        as min_login,
    MAX(last_login_date)                                        as max_login,
    COUNT(CASE WHEN last_login_date IS NULL THEN 1 END)         as null_dates,
    COUNT(CASE WHEN last_login_date > current_date THEN 1 END)  as future_dates
FROM silver.stg_digital_engagement;
SQL Error [42883]: ERROR: operator does not exist: text > date


-- push_notifications: 545 nulls, paperless_statements: 553 nulls, avg_monthly_logins: 374 nulls
-- Los dejo como NULL — no tiene sentido asumir false sin confirmación
SELECT
    COUNT(CASE WHEN push_notifications IS NULL THEN 1 END)    as null_push,
    COUNT(CASE WHEN paperless_statements IS NULL THEN 1 END)  as null_paperless,
    COUNT(CASE WHEN avg_monthly_logins IS NULL THEN 1 END)    as null_logins
FROM silver.stg_digital_engagement;
-- 545	553	374
