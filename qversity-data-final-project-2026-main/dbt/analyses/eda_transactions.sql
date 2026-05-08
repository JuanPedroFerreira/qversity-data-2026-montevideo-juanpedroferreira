SELECT COUNT(*) as total_transactions
FROM silver.stg_transactions;

SELECT 
    COUNT(CASE WHEN transaction_id IS NULL THEN 1 END)    as null_transaction_id,
    COUNT(CASE WHEN customer_id IS NULL THEN 1 END)       as null_customer_id,
    COUNT(CASE WHEN amount IS NULL THEN 1 END)            as null_amount,
    COUNT(CASE WHEN transaction_date IS NULL THEN 1 END)  as null_date,
    COUNT(CASE WHEN category IS NULL THEN 1 END)          as null_category,
    COUNT(CASE WHEN merchant IS NULL THEN 1 END)          as null_merchant,
    COUNT(CASE WHEN description IS NULL THEN 1 END)       as null_description
FROM silver.stg_transactions;

SELECT 
    MIN(amount)                             as min_amount,
    MAX(amount)                             as max_amount,
    ROUND(AVG(amount)::numeric, 2)          as avg_amount,
    COUNT(CASE WHEN amount < 0 THEN 1 END)  as negative_amounts,
    COUNT(CASE WHEN amount = 0 THEN 1 END)  as zero_amounts
FROM silver.stg_transactions;

SELECT transaction_type, COUNT(*) as total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM silver.stg_transactions
GROUP BY transaction_type
ORDER BY total DESC;

SELECT category, COUNT(*) as total
FROM silver.stg_transactions
GROUP BY category
ORDER BY total DESC;

SELECT channel, COUNT(*) as total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM silver.stg_transactions
GROUP BY channel
ORDER BY total DESC;

SELECT status, COUNT(*) as total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM silver.stg_transactions
GROUP BY status
ORDER BY total DESC;

SELECT currency, COUNT(*) as total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM silver.stg_transactions
GROUP BY currency
ORDER BY total DESC;

SELECT 
    MIN(transaction_date)                                        as earliest,
    MAX(transaction_date)                                        as latest,
    COUNT(CASE WHEN transaction_date IS NULL THEN 1 END)         as null_dates,
    COUNT(CASE WHEN transaction_date > current_date THEN 1 END)  as future_dates
FROM silver.stg_transactions;