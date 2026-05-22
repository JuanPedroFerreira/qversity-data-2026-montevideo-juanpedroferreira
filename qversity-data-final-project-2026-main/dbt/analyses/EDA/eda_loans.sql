-- Resultado: 7,663 préstamos (0-3 por cliente como dice el PDF)
SELECT COUNT(*) as total_loans --7663
FROM silver.stg_loans;

SELECT loan_type, COUNT(*) as total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM silver.stg_loans
GROUP BY loan_type
ORDER BY total DESC;


SELECT status, COUNT(*) as total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM silver.stg_loans
GROUP BY status
ORDER BY total DESC;

-- Resultado: 0 | 365 | 3,868 | 627 | 633 | 645 | 1,890
-- Rango 0-365 días, sin negativos
-- 1,890 préstamos con más de 90 días de mora
SELECT
    MIN(days_past_due)                                      as min_dpd,
    MAX(days_past_due)                                      as max_dpd,
    COUNT(CASE WHEN days_past_due = 0 THEN 1 END)           as current_loans,
    COUNT(CASE WHEN days_past_due BETWEEN 1 AND 30 THEN 1 END)  as dpd_1_30,
    COUNT(CASE WHEN days_past_due BETWEEN 31 AND 60 THEN 1 END) as dpd_31_60,
    COUNT(CASE WHEN days_past_due BETWEEN 61 AND 90 THEN 1 END) as dpd_61_90,
    COUNT(CASE WHEN days_past_due > 90 THEN 1 END)          as dpd_90_plus
FROM silver.stg_loans;

-- Montos muy altos por dataset multi-moneda (ARS, BRL, etc. sin convertir a USD)
-- 215 y 219 nulls respectivamente — los dejo como NULL en fct_loans, no tiene sentido imputar
SELECT
    MIN(principal)                                              as min_principal,
    MAX(principal)                                              as max_principal,
    COUNT(CASE WHEN principal IS NULL THEN 1 END)               as null_principal,
    MIN(outstanding_balance)                                    as min_outstanding,
    MAX(outstanding_balance)                                    as max_outstanding,
    COUNT(CASE WHEN outstanding_balance IS NULL THEN 1 END)     as null_outstanding
FROM silver.stg_loans;


-- Resultado: 3.01% | 35.0% | 18.97% promedio
SELECT
    MIN(interest_rate)                          as min_rate,
    MAX(interest_rate)                          as max_rate,
    ROUND(AVG(interest_rate)::numeric, 4)       as avg_rate
FROM silver.stg_loans;


-- Problema: nulls disfrazados — '', 'N/A', 'NA', 'null' son todos NULL real
-- Los convierto en fct_loans con CASE WHEN TRIM(LOWER(collateral_type)) IN ('n/a','na','null','')
SELECT collateral_type, COUNT(*) as total
FROM silver.stg_loans
GROUP BY collateral_type
ORDER BY total DESC;


-- Resultado: USD: 3,893 (50.8%) + 7 monedas LATAM
-- Las monedas LATAM se distribuyen el otro 50%
SELECT currency, COUNT(*) as total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM silver.stg_loans
GROUP BY currency
ORDER BY total DESC;


-- Resultado: 215 | 219 | 160
-- Todos se mantienen como NULL en fct_loans
SELECT
    COUNT(CASE WHEN principal IS NULL THEN 1 END)               as null_principal,
    COUNT(CASE WHEN outstanding_balance IS NULL THEN 1 END)     as null_outstanding,
    COUNT(CASE WHEN collateral_type IS NULL THEN 1 END)         as null_collateral
FROM silver.stg_loans;
