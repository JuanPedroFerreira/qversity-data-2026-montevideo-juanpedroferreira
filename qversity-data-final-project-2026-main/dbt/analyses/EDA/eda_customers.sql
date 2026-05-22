-- 5,000 rows total, one per customer
SELECT COUNT(*) as total FROM silver.stg_credit_info;

-- Credit score range: found min=-99, max=999,999 — valid range per spec is 300-850
-- Filtering in dim_credit_info with WHERE credit_score BETWEEN 300 AND 850
-- 492 invalid records dropped, 4,508 remain
SELECT
    MIN(credit_score)                               as min_score,
    MAX(credit_score)                               as max_score,
    ROUND(AVG(credit_score)::numeric, 1)            as avg_score,
    PERCENTILE_CONT(0.5) WITHIN GROUP
        (ORDER BY credit_score)                     as median_score
FROM silver.stg_credit_info;

-- utilization_pct has two formats: 0.35 (decimal) and 35 (integer percent)
-- Normalizing everything to 0-1 in dim_credit_info with CASE WHEN utilization_pct > 1
SELECT
    MIN(utilization_pct)                            as min_util,
    MAX(utilization_pct)                            as max_util,
    ROUND(AVG(utilization_pct)::numeric, 4)         as avg_util,
    COUNT(CASE WHEN utilization_pct > 1 THEN 1 END) as above_1
FROM silver.stg_credit_info;

-- bankruptcy_flag: 568 nulls, 2263 false, 2169 true — fairly balanced
SELECT bankruptcy_flag, COUNT(*) as total
FROM silver.stg_credit_info
GROUP BY bankruptcy_flag;

-- late_payments_12m: range 0-12, no anomalies
SELECT
    MIN(late_payments_12m)                          as min_late,
    MAX(late_payments_12m)                          as max_late,
    ROUND(AVG(late_payments_12m)::numeric, 2)       as avg_late
FROM silver.stg_credit_info;

-- total_limit: 157 nulls, total_used: 152 nulls — keeping as NULL, no imputation
SELECT
    COUNT(CASE WHEN total_limit IS NULL THEN 1 END) as null_limit,
    COUNT(CASE WHEN total_used IS NULL THEN 1 END)  as null_used
FROM silver.stg_credit_info;

-- 7 LATAM currencies, evenly distributed
SELECT currency, COUNT(*) as total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM silver.stg_credit_info
GROUP BY currency
ORDER BY total DESC;

-- mobile ~49%, web ~49% — nearly identical adoption
SELECT
    COUNT(*) as total,
    COUNT(CASE WHEN mobile_app_registered THEN 1 END)   as mobile_users,
    COUNT(CASE WHEN web_banking_registered THEN 1 END)  as web_users,
    ROUND(COUNT(CASE WHEN mobile_app_registered THEN 1 END) * 100.0 / COUNT(*), 2) as mobile_pct,
    ROUND(COUNT(CASE WHEN web_banking_registered THEN 1 END) * 100.0 / COUNT(*), 2) as web_pct
FROM silver.stg_digital_engagement;

-- preferred_channel: found 'phone' not documented in the spec
-- classified as 'other' in gold_engagement since it's neither digital nor in-person
SELECT preferred_channel, COUNT(*) as total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM silver.stg_digital_engagement
GROUP BY preferred_channel
ORDER BY total DESC;

-- avg_monthly_logins: range 0-60, avg ~30, 374 nulls — keeping as NULL
SELECT
    MIN(avg_monthly_logins)                                 as min_logins,
    MAX(avg_monthly_logins)                                 as max_logins,
    ROUND(AVG(avg_monthly_logins)::numeric, 2)              as avg_logins,
    COUNT(CASE WHEN avg_monthly_logins IS NULL THEN 1 END)  as null_logins
FROM silver.stg_digital_engagement;

-- last_login_date stored as text — can't compare with current_date directly
-- parse_date macro in dim_digital_engagement casts it to DATE
SELECT
    MIN(last_login_date)   as min_login,
    MAX(last_login_date)   as max_login,
    COUNT(CASE WHEN last_login_date IS NULL THEN 1 END) as null_dates
FROM silver.stg_digital_engagement;
-- SQL Error [42883]: operator does not exist: text > date

-- push_notifications: 545 nulls, paperless_statements: 553 nulls, avg_monthly_logins: 374 nulls
-- keeping as NULL — assuming false without confirmation would be wrong
SELECT
    COUNT(CASE WHEN push_notifications IS NULL THEN 1 END)    as null_push,
    COUNT(CASE WHEN paperless_statements IS NULL THEN 1 END)  as null_paperless,
    COUNT(CASE WHEN avg_monthly_logins IS NULL THEN 1 END)    as null_logins
FROM silver.stg_digital_engagement;
-- 545  553  374
