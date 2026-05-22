-- 87,686 transactions total
SELECT COUNT(*) as total_transactions
FROM silver.stg_transactions;

-- Null check on critical fields
SELECT
    COUNT(CASE WHEN transaction_id IS NULL THEN 1 END)    as null_transaction_id,
    COUNT(CASE WHEN customer_id IS NULL THEN 1 END)       as null_customer_id,
    COUNT(CASE WHEN amount IS NULL THEN 1 END)            as null_amount,
    COUNT(CASE WHEN date IS NULL THEN 1 END)              as null_date,
    COUNT(CASE WHEN category IS NULL THEN 1 END)          as null_category,
    COUNT(CASE WHEN merchant IS NULL THEN 1 END)          as null_merchant,
    COUNT(CASE WHEN description IS NULL THEN 1 END)       as null_description
FROM silver.stg_transactions;

-- min=1.89, max=199,995,324, avg=11,241,589 — large amounts expected, multi-currency not yet in USD
-- no negative or zero amounts
SELECT
    MIN(amount)                             as min_amount,
    MAX(amount)                             as max_amount,
    ROUND(AVG(amount)::numeric, 2)          as avg_amount,
    COUNT(CASE WHEN amount < 0 THEN 1 END)  as negative_amounts,
    COUNT(CASE WHEN amount = 0 THEN 1 END)  as zero_amounts
FROM silver.stg_transactions;

-- Transaction types evenly distributed
SELECT type, COUNT(*) as total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM silver.stg_transactions
GROUP BY type
ORDER BY total DESC;

-- Disguised nulls: 'NA', 'null', 'N/A', '' and extra whitespace ('  investment', ' salary  ')
-- Cleaned in fct_transactions with TRIM + CASE
SELECT category, COUNT(*) as total
FROM silver.stg_transactions
GROUP BY category
ORDER BY total DESC;

-- atm: 17,679 | mobile: 17,611 | branch: 17,583 | pos: 17,552 | web: 17,261
-- evenly distributed, no Spanish values, no anomalies
SELECT channel, COUNT(*) as total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM silver.stg_transactions
GROUP BY channel
ORDER BY total DESC;

-- Mixed casing: 'completed' and 'COMPLETED' — normalized in fct_transactions with LOWER(status)
SELECT status, COUNT(*) as total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM silver.stg_transactions
GROUP BY status
ORDER BY total DESC;

-- USD dominates at 46.5%, then 7 LATAM currencies ~7% each, EUR ~1%
SELECT currency, COUNT(*) as total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM silver.stg_transactions
GROUP BY currency
ORDER BY total DESC;

-- Date range and future date check
SELECT
    MIN(transaction_date)                                        as earliest,
    MAX(transaction_date)                                        as latest,
    COUNT(CASE WHEN transaction_date IS NULL THEN 1 END)         as null_dates,
    COUNT(CASE WHEN transaction_date > current_date THEN 1 END)  as future_dates
FROM silver.stg_transactions;
