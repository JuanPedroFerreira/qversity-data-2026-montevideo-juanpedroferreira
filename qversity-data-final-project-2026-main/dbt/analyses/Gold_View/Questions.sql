-- =============================================================================
-- Gold Layer — Validation Queries
-- Autor: Juan Pedro Ferreira — Qversity 2026 Montevideo
-- Propósito: verificar que los modelos Gold responden las 24 preguntas de negocio
-- =============================================================================

-- =============================================================================
-- REVENUE & PROFITABILITY
-- =============================================================================

-- Q1: ¿Cuál es el revenue promedio por cliente por segmento?
-- avg_revenue_per_customer_usd ya está calculado en gold_revenue como
-- total_revenue_usd / customer_count para cada combinación segmento+canal+país
-- Acá promediamos esos valores por segmento
SELECT customer_segment,
       ROUND(SUM(total_revenue_usd) / SUM(customer_count)::numeric, 2) as avg_revenue_per_customer_usd
FROM gold.gold_revenue
GROUP BY customer_segment
ORDER BY avg_revenue_per_customer_usd DESC;

-- Q2: ¿Cuáles son los balances totales de cuentas por país?
SELECT country,
       ROUND(SUM(balance_usd)::numeric, 2) as total_balance_usd
FROM gold.gold_accounts
GROUP BY country
ORDER BY total_balance_usd DESC;

-- Q3: ¿Cuál es el revenue por canal de transacción?
SELECT channel,
       ROUND(SUM(total_revenue_usd)::numeric, 2)                           as total_revenue_usd,
       ROUND(SUM(total_revenue_usd) / SUM(customer_count)::numeric, 2)    as avg_revenue_per_customer_usd,
       SUM(transaction_count)                                               as total_transactions
FROM gold.gold_revenue
GROUP BY channel
ORDER BY total_revenue_usd DESC;

-- Q4: ¿Cuál es el interest income por tipo de préstamo?
-- interest_income_usd = outstanding_balance_usd * interest_rate / 100 para préstamos current
SELECT loan_type,
       ROUND(SUM(interest_income_usd)::numeric, 2) as total_interest_income_usd
FROM gold.gold_loans
WHERE status = 'current'
GROUP BY loan_type
ORDER BY total_interest_income_usd DESC;

-- =============================================================================
-- RISK & CREDIT
-- =============================================================================

-- Q5: ¿Cuál es la tasa de delinquency por segmento de cliente?
SELECT customer_segment,
       COUNT(CASE WHEN is_delinquent THEN 1 END)                                        as delinquent,
       COUNT(*)                                                                          as total,
       ROUND(COUNT(CASE WHEN is_delinquent THEN 1 END) * 100.0 / COUNT(*), 2)           as delinquency_rate
FROM gold.gold_risk
GROUP BY customer_segment
ORDER BY delinquency_rate DESC;

-- Q6: ¿Cuál es la distribución de credit scores por país?
SELECT country,
       credit_score_bucket,
       COUNT(*) as total
FROM gold.gold_risk
WHERE credit_score_bucket IS NOT NULL
GROUP BY country, credit_score_bucket
ORDER BY country, credit_score_bucket;

-- Q7: ¿Hay relación entre utilización de crédito y delinquency?
SELECT utilization_bucket,
       COUNT(CASE WHEN is_delinquent THEN 1 END)                                        as delinquent,
       COUNT(*)                                                                          as total,
       ROUND(COUNT(CASE WHEN is_delinquent THEN 1 END) * 100.0 / COUNT(*), 2)           as delinquency_rate
FROM gold.gold_risk
WHERE utilization_bucket IS NOT NULL
GROUP BY utilization_bucket
ORDER BY delinquency_rate DESC;

-- Q8: ¿Cuál es la distribución de days past due por tipo de préstamo?
SELECT loan_type,
       dpd_bucket,
       COUNT(*) as total_loans
FROM gold.gold_loans
GROUP BY loan_type, dpd_bucket
ORDER BY loan_type, dpd_bucket;

-- Q9: ¿Cómo se segmentan los clientes por risk score?
SELECT risk_bucket,
       COUNT(*) as total_customers,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM gold.gold_customers
GROUP BY risk_bucket
ORDER BY total_customers DESC;

-- =============================================================================
-- CUSTOMER DEMOGRAPHICS
-- =============================================================================

-- Q10: ¿Cuántos clientes hay por país y ciudad?
SELECT country,
       city,
       COUNT(*) as total_customers
FROM gold.gold_customers
GROUP BY country, city
ORDER BY country, total_customers DESC;

-- Q11: ¿Cuál es la distribución de edades por segmento?
SELECT customer_segment,
       age_bucket,
       COUNT(*) as total_customers
FROM gold.gold_customers
GROUP BY customer_segment, age_bucket
ORDER BY customer_segment, age_bucket;

-- Q12: ¿Cuál es la tendencia de adquisición de clientes en el tiempo (mensual)?
SELECT registration_month,
       COUNT(*) as new_customers
FROM gold.gold_customers
GROUP BY registration_month
ORDER BY registration_month;

-- Q13: ¿Cuál es la distribución de status de clientes?
SELECT status,
       COUNT(*) as total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM gold.gold_customers
GROUP BY status
ORDER BY total DESC;

-- Q14: ¿Cuál es la distribución de KYC status?
SELECT kyc_status,
       COUNT(*) as total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM gold.gold_customers
GROUP BY kyc_status
ORDER BY total DESC;

-- =============================================================================
-- TRANSACTION PATTERNS
-- =============================================================================

-- Q15: ¿Cuáles son las categorías de transacción más comunes por volumen y valor?
SELECT category,
       COUNT(*)                                as volume,
       ROUND(SUM(amount_usd)::numeric, 2)      as total_value_usd,
       ROUND(AVG(amount_usd)::numeric, 2)      as avg_value_usd
FROM gold.gold_transactions
WHERE category IS NOT NULL
GROUP BY category
ORDER BY volume DESC;

-- Q16: ¿Cuál es el volumen de transacciones por día de la semana?
SELECT day_name,
       day_of_week,
       COUNT(*) as total_transactions
FROM gold.gold_transactions
GROUP BY day_name, day_of_week
ORDER BY day_of_week;

-- Q17: ¿Cuál es el ticket promedio por canal?
SELECT channel,
       ROUND(AVG(amount_usd)::numeric, 2)  as avg_ticket_usd,
       COUNT(*)                             as total_transactions
FROM gold.gold_transactions
GROUP BY channel
ORDER BY avg_ticket_usd DESC;

-- Q18: ¿Cuál es la tasa de transacciones fallidas por canal?
SELECT channel,
       COUNT(CASE WHEN is_failed THEN 1 END)                                   as failed,
       COUNT(*)                                                                 as total,
       ROUND(COUNT(CASE WHEN is_failed THEN 1 END) * 100.0 / COUNT(*), 2)      as failure_rate_pct
FROM gold.gold_transactions
GROUP BY channel
ORDER BY failure_rate_pct DESC;

-- Q19: ¿Cuáles son los patrones de transferencias internacionales por moneda y país?
SELECT country,
       currency,
       is_international,
       COUNT(*)                                as total_transactions,
       ROUND(SUM(amount_usd)::numeric, 2)      as total_amount_usd
FROM gold.gold_transactions
GROUP BY country, currency, is_international
ORDER BY country, is_international DESC;

-- =============================================================================
-- DIGITAL ENGAGEMENT
-- =============================================================================

-- Q20: ¿Cuál es la tasa de adopción de mobile app por segmento?
SELECT customer_segment,
       COUNT(CASE WHEN mobile_app_registered THEN 1 END)                                as mobile_users,
       COUNT(*)                                                                          as total,
       ROUND(COUNT(CASE WHEN mobile_app_registered THEN 1 END) * 100.0 / COUNT(*), 2)  as adoption_pct
FROM gold.gold_engagement
GROUP BY customer_segment
ORDER BY adoption_pct DESC;

-- Q21: ¿Cuál es la preferencia digital vs presencial por grupo de edad?
SELECT age_bucket,
       channel_preference,
       COUNT(*)                                                                     as total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY age_bucket), 2)  as pct
FROM gold.gold_engagement
GROUP BY age_bucket, channel_preference
ORDER BY age_bucket, channel_preference;

-- =============================================================================
-- PRODUCT ANALYSIS
-- =============================================================================

-- Q22: ¿Cuáles son los tipos de cuenta más populares?
SELECT account_type,
       COUNT(*)                                                 as total_accounts,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)       as pct,
       ROUND(AVG(balance_usd)::numeric, 2)                     as avg_balance_usd
FROM gold.gold_accounts
GROUP BY account_type
ORDER BY total_accounts DESC;

-- Q23: ¿Cuál es la composición del portfolio de préstamos por tipo y estado?
SELECT loan_type,
       status,
       COUNT(*)                                            as total_loans,
       ROUND(SUM(outstanding_balance_usd)::numeric, 2)    as total_outstanding_usd,
       ROUND(AVG(outstanding_balance_usd)::numeric, 2)    as avg_outstanding_usd
FROM gold.gold_loans
GROUP BY loan_type, status
ORDER BY loan_type, status;

-- Q24: ¿Cuál es el promedio de productos por cliente por segmento?
SELECT customer_segment,
       ROUND(AVG(total_products)::numeric, 2)  as avg_products,
       ROUND(AVG(total_accounts)::numeric, 2)  as avg_accounts,
       ROUND(AVG(total_loans)::numeric, 2)     as avg_loans,
       COUNT(*)                                as total_customers
FROM gold.gold_products
GROUP BY customer_segment
ORDER BY avg_products DESC;