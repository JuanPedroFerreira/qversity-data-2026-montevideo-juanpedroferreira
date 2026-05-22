-- 7,663 loans total (0-3 per customer as per spec)
SELECT COUNT(*) as total_loans
FROM silver.stg_loans;

-- Evenly distributed across 5 loan types
SELECT loan_type, COUNT(*) as total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM silver.stg_loans
GROUP BY loan_type
ORDER BY total DESC;

-- Status distribution across current/delinquent/default/paid_off
SELECT status, COUNT(*) as total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM silver.stg_loans
GROUP BY status
ORDER BY total DESC;

-- dpd range 0-365, no negatives
-- 1,890 loans over 90 days past due
SELECT
    MIN(days_past_due)                                          as min_dpd,
    MAX(days_past_due)                                          as max_dpd,
    COUNT(CASE WHEN days_past_due = 0 THEN 1 END)               as current_loans,
    COUNT(CASE WHEN days_past_due BETWEEN 1 AND 30 THEN 1 END)  as dpd_1_30,
    COUNT(CASE WHEN days_past_due BETWEEN 31 AND 60 THEN 1 END) as dpd_31_60,
    COUNT(CASE WHEN days_past_due BETWEEN 61 AND 90 THEN 1 END) as dpd_61_90,
    COUNT(CASE WHEN days_past_due > 90 THEN 1 END)              as dpd_90_plus
FROM silver.stg_loans;

-- Large amounts expected — multi-currency dataset (ARS, BRL, etc. not yet converted to USD)
-- 215 null principals, 219 null outstanding_balance — kept as NULL, no imputation
SELECT
    MIN(principal)                                              as min_principal,
    MAX(principal)                                              as max_principal,
    COUNT(CASE WHEN principal IS NULL THEN 1 END)               as null_principal,
    MIN(outstanding_balance)                                    as min_outstanding,
    MAX(outstanding_balance)                                    as max_outstanding,
    COUNT(CASE WHEN outstanding_balance IS NULL THEN 1 END)     as null_outstanding
FROM silver.stg_loans;

-- min=3.01%, max=35.0%, avg=18.97%
SELECT
    MIN(interest_rate)                          as min_rate,
    MAX(interest_rate)                          as max_rate,
    ROUND(AVG(interest_rate)::numeric, 4)       as avg_rate
FROM silver.stg_loans;

-- Disguised nulls: '', 'N/A', 'NA', 'null' — converted to NULL in fct_loans
SELECT collateral_type, COUNT(*) as total
FROM silver.stg_loans
GROUP BY collateral_type
ORDER BY total DESC;

-- USD: 3,893 (50.8%) + 7 LATAM currencies making up the rest
SELECT currency, COUNT(*) as total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM silver.stg_loans
GROUP BY currency
ORDER BY total DESC;

-- null_principal: 215 | null_outstanding: 219 | null_collateral: 160
-- all kept as NULL in fct_loans
SELECT
    COUNT(CASE WHEN principal IS NULL THEN 1 END)               as null_principal,
    COUNT(CASE WHEN outstanding_balance IS NULL THEN 1 END)     as null_outstanding,
    COUNT(CASE WHEN collateral_type IS NULL THEN 1 END)         as null_collateral
FROM silver.stg_loans;
