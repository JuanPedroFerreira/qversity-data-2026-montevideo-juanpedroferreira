-- 1. Record count
-- Finding: 17529
SELECT COUNT(*) as total_accounts
FROM silver.stg_accounts;

-- 2. Null summary
-- Finding: 486 null balances, 13,068 null credit_limit (expected — only credit_card has credit_limit)
SELECT  
    COUNT(CASE WHEN account_id IS NULL THEN 1 END)      as null_account_id,
    COUNT(CASE WHEN customer_id IS NULL THEN 1 END)     as null_customer_id,
    COUNT(CASE WHEN balance IS NULL THEN 1 END)         as null_balance,
    COUNT(CASE WHEN opened_date IS NULL THEN 1 END)     as null_opened_date,
    COUNT(CASE WHEN credit_limit IS NULL THEN 1 END)    as null_credit_limit
FROM silver.stg_accounts;

-- 3. Account type distribution
-- Finding: whitespace trimmed, 4 valid types, balanced distribution
SELECT account_type, COUNT(*) as total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM silver.stg_accounts
GROUP BY account_type
ORDER BY total DESC;

-- 4. Status distribution
-- Finding: Spanish values normalized (ACTIVE→active -activo→active, cerrado→closed, congelado→frozen)
SELECT status, COUNT(*) as total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM silver.stg_accounts
GROUP BY status
ORDER BY total DESC;

-- 5. Balance distribution
-- Finding: min=$237.85, max=$1,999,231,120 (multi-currency), avg=$108,395,331
-- Finding: 0 negative balances, 486 null balances
SELECT 
    MIN(balance)                                        as min_balance,
    MAX(balance)                                        as max_balance,
    ROUND(AVG(balance)::numeric, 2)                     as avg_balance,
    COUNT(CASE WHEN balance < 0 THEN 1 END)             as negative_balances,
    COUNT(CASE WHEN balance IS NULL THEN 1 END)         as null_balances
FROM silver.stg_accounts;

-- 6. Balance by account type
-- Finding: account_type has leading/trailing whitespace — normalized with TRIM() in dim_accounts
-- Finding: balances vary widely due to multi-currency dataset (no FX conversion applied)
-- Finding: 4 valid account types after trimming
SELECT account_type,
    ROUND(AVG(balance)::numeric, 2)     as avg_balance,
    MIN(balance)                        as min_balance,
    MAX(balance)                        as max_balance
FROM silver.stg_accounts
GROUP BY account_type
ORDER BY avg_balance DESC;

-- 7. Credit limit (credit_card only)
-- Finding: only credit_card has credit_limit — as per PDF spec
-- Finding: whitespace variants of credit_card also have credit_limit (normalized with TRIM in dim_accounts)
SELECT account_type,
    COUNT(CASE WHEN credit_limit IS NOT NULL THEN 1 END) as has_credit_limit
FROM silver.stg_accounts
GROUP BY account_type;

-- 8. Interest rate distribution
-- Finding: range 0.5%-25%, avg 12.68%, 0 nulls — valid for all account types
SELECT 
    MIN(interest_rate)                          as min_rate,
    MAX(interest_rate)                          as max_rate,
    ROUND(AVG(interest_rate)::numeric, 4)       as avg_rate,
    COUNT(CASE WHEN interest_rate IS NULL THEN 1 END) as null_rate
FROM silver.stg_accounts;

-- 9. Opened date range
-- Finding: range 01/01/2023 to 31/12/2024, 0 nulls
SELECT 
    MIN(opened_date)                                        as earliest,
    MAX(opened_date)                                        as latest,
    COUNT(CASE WHEN opened_date IS NULL THEN 1 END)         as null_dates
FROM silver.stg_accounts;

-- 10. Currency distribution
-- Finding: multiple currencies across LATAM
SELECT currency, COUNT(*) as total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM silver.stg_accounts
GROUP BY currency
ORDER BY total DESC;

-- 11. Branch distribution
-- Finding: 900 distinct branches, 0 nulls
SELECT 
    COUNT(DISTINCT branch_code)                         as distinct_branches,
    COUNT(CASE WHEN branch_code IS NULL THEN 1 END)     as null_branches
FROM silver.stg_accounts;