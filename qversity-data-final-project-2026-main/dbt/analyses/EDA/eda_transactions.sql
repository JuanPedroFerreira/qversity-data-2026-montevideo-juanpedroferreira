-- Resultado: 87,686 transacciones
SELECT COUNT(*) as total_transactions
FROM silver.stg_transactions;

SELECT
    COUNT(CASE WHEN transaction_id IS NULL THEN 1 END)    as null_transaction_id,
    COUNT(CASE WHEN customer_id IS NULL THEN 1 END)       as null_customer_id,
    COUNT(CASE WHEN amount IS NULL THEN 1 END)            as null_amount,
    COUNT(CASE WHEN date IS NULL THEN 1 END)  as null_date,
    COUNT(CASE WHEN category IS NULL THEN 1 END)          as null_category,
    COUNT(CASE WHEN merchant IS NULL THEN 1 END)          as null_merchant,
    COUNT(CASE WHEN description IS NULL THEN 1 END)       as null_description
FROM silver.stg_transactions;

-- Resultado: 1.89 | 199,995,324 | 11,241,589 | 0 negativos | 0 ceros
-- Montos altos por dataset multi-moneda sin convertir a USD
SELECT
    MIN(amount)                             as min_amount,
    MAX(amount)                             as max_amount,
    ROUND(AVG(amount)::numeric, 2)          as avg_amount,
    COUNT(CASE WHEN amount < 0 THEN 1 END)  as negative_amounts,
    COUNT(CASE WHEN amount = 0 THEN 1 END)  as zero_amounts
FROM silver.stg_transactions;


SELECT type, COUNT(*) as total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM silver.stg_transactions
GROUP BY type
ORDER BY total DESC;


-- Problema: nulls disfrazados — 'NA', 'null', 'N/A', '' son todos NULL real
-- Además hay espacios extra en los nombres ('  investment', ' salary  ', etc.)
-- Los limpio en fct_transactions con TRIM + CASE para nulls disfrazados
SELECT category, COUNT(*) as total
FROM silver.stg_transactions
GROUP BY category
ORDER BY total DESC;

-- Resultado: atm: 17,679 | mobile: 17,611 | branch: 17,583 | pos: 17,552 | web: 17,261
-- Distribución muy balanceada, sin valores raros ni en español
SELECT channel, COUNT(*) as total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM silver.stg_transactions
GROUP BY channel
ORDER BY total DESC;


-- Problema: mayúsculas mezcladas — 'completed' y 'COMPLETED' son lo mismo
-- Lo normalizo en fct_transactions con LOWER(status)
SELECT status, COUNT(*) as total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM silver.stg_transactions
GROUP BY status
ORDER BY total DESC;

-- Resultado: USD domina con 46.5%, luego 7 monedas LATAM ~7% cada una + EUR 1%
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
