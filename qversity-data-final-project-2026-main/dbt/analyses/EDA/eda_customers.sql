SELECT COUNT(*) as total_customers
FROM silver.stg_customers;

SELECT 
    COUNT(CASE WHEN customer_id IS NULL THEN 1 END)          as null_customer_id,
    COUNT(CASE WHEN email IS NULL THEN 1 END)                as null_email,
    COUNT(CASE WHEN country IS NULL THEN 1 END)              as null_country,
    COUNT(CASE WHEN date_of_birth IS NULL THEN 1 END)        as null_dob,
    COUNT(CASE WHEN registration_date IS NULL THEN 1 END)    as null_reg_date,
    COUNT(CASE WHEN risk_score IS NULL THEN 1 END)           as null_risk_score,
    COUNT(CASE WHEN gender IS NULL THEN 1 END)               as null_gender,
    COUNT(CASE WHEN relationship_manager IS NULL THEN 1 END) as null_rm
FROM silver.stg_customers;

SELECT country, COUNT(*) as total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM silver.stg_customers
GROUP BY country
ORDER BY total DESC;

SELECT customer_segment, COUNT(*) as total
FROM silver.stg_customers
GROUP BY customer_segment
ORDER BY total DESC;

SELECT status, COUNT(*) as total
FROM silver.stg_customers
GROUP BY status
ORDER BY total DESC;

SELECT kyc_status, COUNT(*) as total
FROM silver.stg_customers
GROUP BY kyc_status
ORDER BY total DESC;

SELECT 
    MIN(risk_score)                         as min_risk,
    MAX(risk_score)                         as max_risk,
    ROUND(AVG(risk_score)::numeric, 2)      as avg_risk,
    ROUND(STDDEV(risk_score)::numeric, 2)   as stddev_risk
FROM silver.stg_customers;

SELECT gender, COUNT(*) as total
FROM silver.stg_customers
GROUP BY gender
ORDER BY total DESC;

SELECT 
    COUNT(CASE WHEN is_valid_email THEN 1 END)      as valid_emails,
    COUNT(CASE WHEN NOT is_valid_email THEN 1 END)  as invalid_emails
FROM silver.stg_customers;

SELECT 
    COUNT(CASE WHEN phone_number ~ '^\+\d' THEN 1 END) as normalized_phones,
    COUNT(CASE WHEN phone_number IS NULL THEN 1 END)    as null_phones
FROM silver.stg_customers;

SELECT city, COUNT(*) as total
FROM silver.stg_customers
GROUP BY city
ORDER BY total DESC
LIMIT 20;

SELECT 
    MIN(registration_date)  as earliest_registration,
    MAX(registration_date)  as latest_registration,
    COUNT(CASE WHEN registration_date > current_date THEN 1 END) as future_dates,
    COUNT(CASE WHEN registration_date < date_of_birth THEN 1 END) as before_birth,
    COUNT(CASE WHEN registration_date < date_of_birth + interval '18 years' THEN 1 END) as underage
FROM silver.stg_customers;

SELECT 
    COUNT(CASE WHEN gender IS NULL THEN 1 END)               as null_gender,
    COUNT(CASE WHEN relationship_manager IS NULL THEN 1 END) as null_rm,
    COUNT(CASE WHEN phone_number IS NULL THEN 1 END)         as null_phone,
    COUNT(CASE WHEN nationality IS NULL THEN 1 END)          as null_nationality
FROM silver.stg_customers;