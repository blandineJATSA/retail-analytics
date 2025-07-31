-- models/marts/mart_business_summary.sql
{{
  config(
    materialized='table',
    description='Executive business summary dashboard'
  )
}}

WITH monthly_metrics AS (
  SELECT 
    order_year,
    order_month,
    order_year || '-' || LPAD(order_month, 2, '0') as year_month,
    
    -- Métriques de commandes
    COUNT(*) as total_orders,
    COUNT(CASE WHEN is_completed = true THEN 1 END) as completed_orders,
    COUNT(CASE WHEN is_returned = true THEN 1 END) as returned_orders,
    COUNT(DISTINCT customer_id) as unique_customers,
    
    -- Métriques financières
    SUM(total_order_amount) as total_revenue,
    AVG(total_order_amount) as avg_order_value,
    SUM(amount_coupon) as total_coupon_used,
    
    -- Taux de conversion
    ROUND(
      (COUNT(CASE WHEN is_completed = true THEN 1 END) * 100.0) / COUNT(*), 
      2
    ) as completion_rate_pct,
    
    -- Méthodes de paiement populaires
    SUM(used_credit_card) as orders_with_credit_card,
    SUM(used_coupon) as orders_with_coupon
    
  FROM {{ ref('fact_orders') }}
  GROUP BY order_year, order_month
),

customer_acquisition AS (
  SELECT 
    EXTRACT(YEAR FROM first_order_date) as acquisition_year,
    EXTRACT(MONTH FROM first_order_date) as acquisition_month,
    COUNT(*) as new_customers
  FROM {{ ref('dim_customers') }}
  WHERE first_order_date IS NOT NULL
  GROUP BY acquisition_year, acquisition_month
),

top_customers AS (
  SELECT 
    customer_id,
    full_name,
    customer_segment,
    total_spent_usd,
    total_orders,
    RANK() OVER (ORDER BY total_spent_usd DESC) as revenue_rank
  FROM {{ ref('dim_customers') }}
  WHERE total_spent_usd > 0
  LIMIT 10
)

-- Rapport final
SELECT 
  'MONTHLY_PERFORMANCE' as report_type,
  mm.year_month as period,
  mm.total_orders,
  mm.completed_orders,
  mm.returned_orders,
  mm.unique_customers,
  mm.total_revenue,
  mm.avg_order_value,
  mm.completion_rate_pct,
  mm.total_coupon_used,
  ca.new_customers,
  
  -- Calcul du Customer Lifetime Value approximatif
  CASE 
    WHEN mm.unique_customers > 0 
    THEN ROUND(mm.total_revenue / mm.unique_customers, 2)
    ELSE 0 
  END as customer_ltv_estimate,
  
  CURRENT_TIMESTAMP as report_generated_at

FROM monthly_metrics mm
LEFT JOIN customer_acquisition ca 
  ON mm.order_year = ca.acquisition_year 
  AND mm.order_month = ca.acquisition_month

UNION ALL

-- Résumé des top clients
SELECT 
  'TOP_CUSTOMERS' as report_type,
  tc.full_name as period,
  tc.total_orders as total_orders,
  0 as completed_orders,
  0 as returned_orders,
  1 as unique_customers,
  tc.total_spent_usd as total_revenue,
  ROUND(tc.total_spent_usd / NULLIF(tc.total_orders, 0), 2) as avg_order_value,
  tc.revenue_rank as completion_rate_pct,
  0 as total_coupon_used,
  0 as new_customers,
  tc.total_spent_usd as customer_ltv_estimate,
  CURRENT_TIMESTAMP as report_generated_at

FROM top_customers tc

ORDER BY report_type, period
