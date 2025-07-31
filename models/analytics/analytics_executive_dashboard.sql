-- models/analytics/analytics_executive_dashboard.sql
{{
  config(
    materialized='view',
    description='Executive dashboard with key business metrics and KPIs'
  )
}}

WITH business_summary AS (
  -- KPIs généraux du business
  SELECT 
    'BUSINESS_OVERVIEW' as section,
    'Total Metrics' as category,
    
    COUNT(DISTINCT customer_id) as total_customers,
    COUNT(DISTINCT order_id) as total_orders,
    ROUND(SUM(total_order_amount), 2) as total_revenue,
    ROUND(AVG(total_order_amount), 2) as avg_order_value,
    
    -- Métriques de performance
    COUNT(DISTINCT CASE WHEN is_completed THEN order_id END) as completed_orders,
    ROUND(
      COUNT(DISTINCT CASE WHEN is_completed THEN order_id END) * 100.0 / 
      NULLIF(COUNT(DISTINCT order_id), 0), 2
    ) as completion_rate_pct,
    
    -- Activité récente (30 derniers jours depuis la date max)
    COUNT(DISTINCT CASE 
      WHEN order_date >= (SELECT MAX(order_date) - INTERVAL '30 days' FROM {{ ref('fact_orders') }})
      THEN customer_id 
    END) as active_customers_30d,
    
    COUNT(DISTINCT CASE 
      WHEN order_date >= (SELECT MAX(order_date) - INTERVAL '30 days' FROM {{ ref('fact_orders') }})
      THEN order_id 
    END) as orders_30d,
    
    ROUND(SUM(CASE 
      WHEN order_date >= (SELECT MAX(order_date) - INTERVAL '30 days' FROM {{ ref('fact_orders') }})
      THEN total_order_amount 
      ELSE 0 
    END), 2) as revenue_30d
    
  FROM {{ ref('fact_orders') }}
),

customer_segments AS (
  -- Répartition par segments clients
  SELECT 
    'CUSTOMER_SEGMENTS' as section,
    customer_segment as category,
    
    COUNT(*) as total_customers,
    ROUND(AVG(total_spent_usd), 2) as avg_customer_value,
    ROUND(SUM(total_spent_usd), 2) as segment_revenue,
    
    -- Pourcentage du segment
    ROUND(
      COUNT(*) * 100.0 / (SELECT COUNT(*) FROM {{ ref('dim_customers') }}), 2
    ) as customer_percentage,
    
    -- Status distribution
    COUNT(CASE WHEN customer_status = 'Active' THEN 1 END) as active_count,
    COUNT(CASE WHEN customer_status = 'Churned' THEN 1 END) as churned_count,
    COUNT(CASE WHEN customer_status = 'Never Ordered' THEN 1 END) as never_ordered_count
    
  FROM {{ ref('dim_customers') }}
  GROUP BY customer_segment
),

monthly_trends AS (
  -- Tendances mensuelles
  SELECT 
    'MONTHLY_TRENDS' as section,
    order_year || '-' || LPAD(order_month, 2, '0') as category,
    
    COUNT(DISTINCT customer_id) as monthly_customers,
    COUNT(DISTINCT order_id) as monthly_orders,
    ROUND(SUM(total_order_amount), 2) as monthly_revenue,
    ROUND(AVG(total_order_amount), 2) as monthly_aov,
    
    -- Croissance month-over-month
    LAG(SUM(total_order_amount)) OVER (ORDER BY order_year, order_month) as prev_month_revenue
    
  FROM {{ ref('fact_orders') }}
  GROUP BY order_year, order_month
),

payment_analysis AS (
  -- Analyse des méthodes de paiement (VOS VRAIES DONNÉES!)
  SELECT 
    'PAYMENT_METHODS' as section,
    CASE 
      WHEN amount_credit_card > 0 AND amount_bank_transfer = 0 AND amount_coupon = 0 THEN 'Credit Card Only'
      WHEN amount_bank_transfer > 0 AND amount_credit_card = 0 AND amount_coupon = 0 THEN 'Bank Transfer Only'
      WHEN amount_coupon > 0 AND amount_credit_card = 0 AND amount_bank_transfer = 0 THEN 'Coupon Only'
      WHEN amount_credit_card > 0 AND amount_coupon > 0 THEN 'Credit Card + Coupon'
      WHEN amount_bank_transfer > 0 AND amount_coupon > 0 THEN 'Bank Transfer + Coupon'
      WHEN payment_count > 1 THEN 'Mixed Payments'
      ELSE 'Other'
    END as category,
    
    COUNT(DISTINCT order_id) as orders_count,
    ROUND(SUM(total_order_amount), 2) as payment_revenue,
    ROUND(AVG(total_order_amount), 2) as avg_transaction,
    
    -- Pourcentage par méthode
    ROUND(
      COUNT(DISTINCT order_id) * 100.0 / 
      (SELECT COUNT(DISTINCT order_id) FROM {{ ref('fact_orders') }} WHERE total_order_amount > 0), 2
    ) as usage_percentage,
    
    -- Métriques spécifiques
    ROUND(SUM(amount_credit_card), 2) as cc_volume,
    ROUND(SUM(amount_bank_transfer), 2) as bt_volume,
    ROUND(SUM(amount_coupon), 2) as coupon_volume
    
  FROM {{ ref('fact_orders') }}
  WHERE total_order_amount > 0  -- Seulement les commandes payées
  GROUP BY 
    CASE 
      WHEN amount_credit_card > 0 AND amount_bank_transfer = 0 AND amount_coupon = 0 THEN 'Credit Card Only'
      WHEN amount_bank_transfer > 0 AND amount_credit_card = 0 AND amount_coupon = 0 THEN 'Bank Transfer Only'
      WHEN amount_coupon > 0 AND amount_credit_card = 0 AND amount_bank_transfer = 0 THEN 'Coupon Only'
      WHEN amount_credit_card > 0 AND amount_coupon > 0 THEN 'Credit Card + Coupon'
      WHEN amount_bank_transfer > 0 AND amount_coupon > 0 THEN 'Bank Transfer + Coupon'
      WHEN payment_count > 1 THEN 'Mixed Payments'
      ELSE 'Other'
    END
),

order_value_segments AS (
  -- Analyse par segment de valeur de commande
  SELECT 
    'ORDER_VALUE_SEGMENTS' as section,
    order_value_segment as category,
    
    COUNT(DISTINCT customer_id) as customers_in_segment,
    COUNT(DISTINCT order_id) as orders_count,
    ROUND(SUM(total_order_amount), 2) as segment_revenue,
    ROUND(AVG(total_order_amount), 2) as avg_order_value,
    
    -- Pourcentage des commandes
    ROUND(
      COUNT(DISTINCT order_id) * 100.0 / 
      (SELECT COUNT(DISTINCT order_id) FROM {{ ref('fact_orders') }}), 2
    ) as orders_percentage,
    
    -- Indicateurs qualité
    ROUND(
      COUNT(CASE WHEN is_completed THEN 1 END) * 100.0 / 
      NULLIF(COUNT(*), 0), 2
    ) as completion_rate
    
  FROM {{ ref('fact_orders') }}
  GROUP BY order_value_segment
),

top_customers AS (
  -- Top 5 clients par CA
  SELECT 
    'TOP_CUSTOMERS' as section,
    customer_name || ' (ID: ' || customer_id || ')' as category,
    
    1 as total_customers,
    COUNT(DISTINCT order_id) as orders_count,
    ROUND(SUM(total_order_amount), 2) as revenue,
    ROUND(AVG(total_order_amount), 2) as aov,
    
    -- Dernière activité  
    MAX(order_date) as last_order_date,
    customer_segment as segment
    
  FROM {{ ref('fact_orders') }}
  WHERE customer_name IS NOT NULL
  GROUP BY customer_id, customer_name, customer_segment
  ORDER BY SUM(total_order_amount) DESC
  LIMIT 5
)

-- Union de tous les insights avec structure standardisée
SELECT 
  section,
  category,
  total_customers,
  total_orders as orders_count,
  total_revenue as revenue,
  avg_order_value as aov,
  completion_rate_pct,
  active_customers_30d,
  orders_30d,
  revenue_30d,
  NULL as revenue_growth_pct,
  NULL as additional_metric_1,
  NULL as additional_metric_2,
  CURRENT_TIMESTAMP as generated_at
FROM business_summary

UNION ALL

SELECT 
  section,
  category,
  total_customers,
  0 as orders_count,
  segment_revenue as revenue,
  avg_customer_value as aov,
  customer_percentage as completion_rate_pct,
  active_count as active_customers_30d,
  churned_count as orders_30d,
  never_ordered_count as revenue_30d,
  NULL as revenue_growth_pct,
  NULL as additional_metric_1,
  NULL as additional_metric_2,
  CURRENT_TIMESTAMP as generated_at
FROM customer_segments

UNION ALL

SELECT 
  section,
  category,
  monthly_customers as total_customers,
  monthly_orders as orders_count,
  monthly_revenue as revenue,
  monthly_aov as aov,
  NULL as completion_rate_pct,
  NULL as active_customers_30d,
  NULL as orders_30d,
  NULL as revenue_30d,
  ROUND(
    (monthly_revenue - prev_month_revenue) * 100.0 / NULLIF(prev_month_revenue, 0), 2
  ) as revenue_growth_pct,
  NULL as additional_metric_1,
  NULL as additional_metric_2,
  CURRENT_TIMESTAMP as generated_at
FROM monthly_trends

UNION ALL

SELECT 
  section,
  category,
  NULL as total_customers,
  orders_count,
  payment_revenue as revenue,
  avg_transaction as aov,
  usage_percentage as completion_rate_pct,
  NULL as active_customers_30d,
  NULL as orders_30d,
  NULL as revenue_30d,
  NULL as revenue_growth_pct,
  cc_volume as additional_metric_1,
  bt_volume as additional_metric_2,
  CURRENT_TIMESTAMP as generated_at
FROM payment_analysis

UNION ALL

SELECT 
  section,
  category,
  customers_in_segment as total_customers,
  orders_count,
  segment_revenue as revenue,
  avg_order_value as aov,
  completion_rate as completion_rate_pct,
  NULL as active_customers_30d,
  NULL as orders_30d,
  NULL as revenue_30d,
  orders_percentage as revenue_growth_pct,
  NULL as additional_metric_1,
  NULL as additional_metric_2,
  CURRENT_TIMESTAMP as generated_at
FROM order_value_segments

UNION ALL

SELECT 
  section,
  category,
  total_customers,
  orders_count,
  revenue,
  aov,
  NULL as completion_rate_pct,
  NULL as active_customers_30d,
  NULL as orders_30d,
  NULL as revenue_30d,
  NULL as revenue_growth_pct,
  NULL as additional_metric_1,
  NULL as additional_metric_2,
  CURRENT_TIMESTAMP as generated_at
FROM top_customers

ORDER BY 
  CASE section 
    WHEN 'BUSINESS_OVERVIEW' THEN 1
    WHEN 'CUSTOMER_SEGMENTS' THEN 2 
    WHEN 'MONTHLY_TRENDS' THEN 3
    WHEN 'PAYMENT_METHODS' THEN 4
    WHEN 'ORDER_VALUE_SEGMENTS' THEN 5
    WHEN 'TOP_CUSTOMERS' THEN 6
  END,
  revenue DESC NULLS LAST
