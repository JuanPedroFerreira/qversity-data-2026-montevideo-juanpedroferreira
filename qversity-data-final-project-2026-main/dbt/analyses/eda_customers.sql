-- Resultado: 5,000 clientes después de deduplicación (100 duplicados eliminados por PySpark)
SELECT COUNT(*) as total_customers
FROM silver.stg_customers;

-- Los campos críticos no tienen nulls
-- gender y relationship_manager tienen algunos — los manejo en dim_customers
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


-- PE: 737 | BR: 737 | UY: 730 | MX: 718 | AR: 708 | CO: 704 | CL: 666
SELECT country, COUNT(*) as total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM silver.stg_customers
GROUP BY country
ORDER BY total DESC;


-- Problema: valores mezclados en español, inglés y distintas mayúsculas
-- 'retail', 'Retail', 'RETAIL', 'minorista' son todos lo mismo
-- Lo normalizo en dim_customers con CASE LOWER(customer_segment)
SELECT customer_segment, COUNT(*) as total
FROM silver.stg_customers
GROUP BY customer_segment
ORDER BY total DESC;

-- Problema: mismo caso — 'active', 'Active', 'ACTIVE', 'activo' son todos lo mismo
-- Lo normalizo en dim_customers con CASE LOWER(status)
SELECT status, COUNT(*) as total
FROM silver.stg_customers
GROUP BY status
ORDER BY total DESC;

-- Problema: 'pending', 'PENDING' mezclados — mismo tratamiento con LOWER()
SELECT kyc_status, COUNT(*) as total
FROM silver.stg_customers
GROUP BY kyc_status
ORDER BY total DESC;

-- Resultado: 0.04 | 100.0 | 49.81 | 28.67
-- Rango 0-100 como dice el PDF, distribución centrada, sin valores raros
SELECT 
    MIN(risk_score)                         as min_risk,
    MAX(risk_score)                         as max_risk,
    ROUND(AVG(risk_score)::numeric, 2)      as avg_risk,
    ROUND(STDDEV(risk_score)::numeric, 2)   as stddev_risk
FROM silver.stg_customers;


-- Resultado: F: 1,646 | M: 1,573 | Other: 1,510 | null: 70 | N/A: 57 | '': 50 | ' ': 47 | NA: 47
-- Los valores 'null', 'N/A', '', ' ', 'NA' son nulls disfrazados
-- Los convierto a NULL real en dim_customers con CASE UPPER(TRIM(gender)) podria ser cambiados por other
SELECT gender, COUNT(*) as total
FROM silver.stg_customers
GROUP BY gender
ORDER BY total DESC;

-- Resultado: 4,669 ya tienen prefijo | 0 nulls
-- Los 331 restantes vienen sin prefijo o con formato (+XX) o con guiones
-- Los normalizo en dim_customers con CASE + regexp_replace
SELECT 
    COUNT(CASE WHEN phone_number ~ '^\+\d' THEN 1 END) as normalized_phones,
    COUNT(CASE WHEN phone_number IS NULL THEN 1 END)    as null_phones
FROM silver.stg_customers;

-- Resultado: ciudades con nombres correctos en staging
-- Los errores tipográficos (Cusc, Lma, Santiag) aparecen en grupos más pequeños
-- Los corrijo en dim_customers con CASE TRIM(INITCAP(city))
SELECT city, COUNT(*) as total
FROM silver.stg_customers
GROUP BY city
ORDER BY total DESC
LIMIT 20;

-- Error: "operator does not exist: text > date"
-- registration_date y date_of_birth son TEXT en staging, no DATE
-- No se puede comparar directamente con fechas sin castear
-- La validación de fechas se hace en dim_customers donde el macro parse_date los convierte a DATE
SELECT 
    MIN(registration_date)  as earliest_registration,
    MAX(registration_date)  as latest_registration,
    COUNT(CASE WHEN registration_date > current_date THEN 1 END) as future_dates,
    COUNT(CASE WHEN registration_date < date_of_birth THEN 1 END) as before_birth,
    COUNT(CASE WHEN registration_date < date_of_birth + interval '18 years' THEN 1 END) as underage
FROM silver.stg_customers;

-- Resultado: 47 | 111 | 0 | 0
-- gender y relationship_manager tienen nulls reales — se mantienen como NULL en dim_customers
-- phone y nationality no tienen nulls en staging
SELECT 
    COUNT(CASE WHEN gender IS NULL THEN 1 END)               as null_gender,
    COUNT(CASE WHEN relationship_manager IS NULL THEN 1 END) as null_rm,
    COUNT(CASE WHEN phone_number IS NULL THEN 1 END)         as null_phone,
    COUNT(CASE WHEN nationality IS NULL THEN 1 END)          as null_nationality
FROM silver.stg_customers;