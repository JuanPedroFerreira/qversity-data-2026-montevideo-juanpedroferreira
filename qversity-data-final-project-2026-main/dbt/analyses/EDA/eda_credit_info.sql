SELECT COUNT(*) as total FROM silver.stg_credit_info;

SELECT 
    MIN(credit_score)                               as min_score,
    MAX(credit_score)                               as max_score,
    ROUND(AVG(credit_score)::numeric, 1)            as avg_score,
    PERCENTILE_CONT(0.5) WITHIN GROUP 
        (ORDER BY credit_score)                     as median_score
FROM silver.stg_credit_info;

SELECT 
    MIN(utilization_pct)                            as min_util,
    MAX(utilization_pct)                            as max_util,
    ROUND(AVG(utilization_pct)::numeric, 4)         as avg_util,
    COUNT(CASE WHEN utilization_pct > 1 THEN 1 END) as above_1
FROM silver.stg_credit_info;

SELECT bankruptcy_flag, COUNT(*) as total
FROM silver.stg_credit_info
GROUP BY bankruptcy_flag;

SELECT 
    MIN(late_payments_12m)                          as min_late,
    MAX(late_payments_12m)                          as max_late,
    ROUND(AVG(late_payments_12m)::numeric, 2)       as avg_late
FROM silver.stg_credit_info;

SELECT 
    COUNT(CASE WHEN total_limit IS NULL THEN 1 END) as null_limit,
    COUNT(CASE WHEN total_used IS NULL THEN 1 END)  as null_used
FROM silver.stg_credit_info;

SELECT currency, COUNT(*) as total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM silver.stg_credit_info
GROUP BY currency
ORDER BY total DESC;

-- =============================================================================
-- DIGITAL ENGAGEMENT (stg_digital_engagement)
-- =============================================================================

SELECT 
    COUNT(*) as total,
    COUNT(CASE WHEN mobile_app_registered THEN 1 END)   as mobile_users,
    COUNT(CASE WHEN web_banking_registered THEN 1 END)  as web_users,
    ROUND(COUNT(CASE WHEN mobile_app_registered THEN 1 END) * 100.0 / COUNT(*), 2) as mobile_pct,
    ROUND(COUNT(CASE WHEN web_banking_registered THEN 1 END) * 100.0 / COUNT(*), 2) as web_pct
FROM silver.stg_digital_engagement;

SELECT preferred_channel, COUNT(*) as total,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct
FROM silver.stg_digital_engagement
GROUP BY preferred_channel
ORDER BY total DESC;

SELECT 
    MIN(avg_monthly_logins)                                 as min_logins,
    MAX(avg_monthly_logins)                                 as max_logins,
    ROUND(AVG(avg_monthly_logins)::numeric, 2)              as avg_logins,
    COUNT(CASE WHEN avg_monthly_logins IS NULL THEN 1 END)  as null_logins
FROM silver.stg_digital_engagement;

SELECT 
    MIN(last_login_date)                                        as min_login,
    MAX(last_login_date)                                        as max_login,
    COUNT(CASE WHEN last_login_date IS NULL THEN 1 END)         as null_dates,
    COUNT(CASE WHEN last_login_date > current_date THEN 1 END)  as future_dates
FROM silver.stg_digital_engagement;

SELECT 
    COUNT(CASE WHEN push_notifications IS NULL THEN 1 END)    as null_push,
    COUNT(CASE WHEN paperless_statements IS NULL THEN 1 END)  as null_paperless,
    COUNT(CASE WHEN avg_monthly_logins IS NULL THEN 1 END)    as null_logins
FROM silver.stg_digital_engagement;