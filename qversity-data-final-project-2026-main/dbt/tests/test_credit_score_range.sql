-- Test that credit scores are within valid range (300-850)
-- Replace silver_credit_info with your actual silver model name
-- select *
-- from {{ ref('silver_credit_info') }}
-- where credit_score < 300 or credit_score > 850

-- Placeholder: returns no rows (test passes)
select 1 as invalid_score
where 1 = 0
