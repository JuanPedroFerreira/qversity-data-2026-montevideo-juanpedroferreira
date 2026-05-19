SELECT COUNT(*) as total_loans
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

SELECT 
    MIN(days_past_due)                                      as min_dpd,
    MAX(days_past_due)                                      as max_dpd,
    COUNT(CASE WHEN days_past_due = 0 THEN 1 END)           as current_loans,
    COUNT(CASE WHEN days_past_due BETWEEN 1 AND 30 THEN 1 END)  as dpd_1_30,
    COUNT(CASE WHEN days_past_due BETWEEN 31 AND 60 THEN 1 END) as dpd_31_60,
    COUNT(CASE WHEN days_past_due BETWEEN 61 AND 90 THEN 1 END) as dpd_61_90,
    COUNT(CASE WHEN days_past_due > 90 THEN 1 END)          as dpd_90_plus
FROM silver.stg_loans;

SELECT 
    MIN(principal)                                              as min_principal,
    MAX(principal)                                              as max_principal,
    COUNT(CASE WHEN principal IS NULL THEN 1 END)               as null_principal,
    MIN(outstanding_balance)                                    as min_outstanding,
    MAX(outstanding_balance)                                    as max_outstanding,
    COUNT(CASE WHEN outstanding_balance IS NULL THEN 1 END)     as null_outstanding
FROM silver.stg_loans;

SELECT 
    MIN(interest_rate)                          as min_rate,
    MAX(interest_rate)                          as max_rate,
    ROUND(AVG(interest_rate)::numeric, 4)       as avg_rate
FROM silver.stg_loans;

SELECT collateral_type, COUNT(*) as total
FROM silver.stg_loans
GROUP BY collateral_type
ORDER BY total DESC;

SELECT currency, COUNT(*) as total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM silver.stg_loans
GROUP BY currency
ORDER BY total DESC;

SELECT 
    COUNT(CASE WHEN principal IS NULL THEN 1 END)               as null_principal,
    COUNT(CASE WHEN outstanding_balance IS NULL THEN 1 END)     as null_outstanding,
    COUNT(CASE WHEN collateral_type IS NULL THEN 1 END)         as null_collateral
FROM silver.stg_loans;