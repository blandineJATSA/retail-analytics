-- models/marts/dim_customers.sql
{{
  config(
    materialized='table',
    description='Customer dimension with enriched data'
  )
}}

WITH customer_orders AS (
  SELECT 
    customer_id,  -- ✅ Corrigé : user_id → customer_id
    COUNT(*) as total_orders,
    COUNT(CASE WHEN order_status = 'completed' THEN 1 END) as completed_orders,  -- ✅ status → order_status
    MIN(order_date) as first_order_date,
    MAX(order_date) as last_order_date
  FROM {{ ref('stg_orders') }}
  GROUP BY customer_id
),

customer_payments AS (
  SELECT 
    o.customer_id,  -- ✅ Corrigé
    SUM(p.amount_usd) as total_spent_usd,
    AVG(p.amount_usd) as avg_order_value_usd,
    COUNT(DISTINCT p.payment_method) as payment_methods_used,
    
    -- Répartition par méthode de paiement
    SUM(CASE WHEN p.payment_method = 'credit_card' THEN p.amount_usd ELSE 0 END) as spent_credit_card,
    SUM(CASE WHEN p.payment_method = 'bank_transfer' THEN p.amount_usd ELSE 0 END) as spent_bank_transfer,
    SUM(CASE WHEN p.payment_method = 'coupon' THEN p.amount_usd ELSE 0 END) as spent_coupon
    
  FROM {{ ref('stg_orders') }} o
  JOIN {{ ref('stg_payments') }} p ON o.order_id = p.order_id  -- ✅ o.id → o.order_id
  WHERE o.order_status = 'completed'  -- ✅ status → order_status
  GROUP BY o.customer_id
)

SELECT 
  c.customer_id,  -- ✅ Corrigé : c.id → c.customer_id
  c.first_name,
  c.last_name,
  c.full_name,  -- ✅ Déjà calculé dans staging
  c.first_name_clean,  -- ✅ Bonus : utilisons les colonnes clean
  c.last_name_clean,   -- ✅ Bonus
  
  -- Métriques de commandes
  COALESCE(co.total_orders, 0) as total_orders,
  COALESCE(co.completed_orders, 0) as completed_orders,
  co.first_order_date,
  co.last_order_date,
  DATEDIFF(day, co.last_order_date, CURRENT_DATE()) as days_since_last_order,
  
  -- Métriques financières
  COALESCE(cp.total_spent_usd, 0) as total_spent_usd,
  COALESCE(cp.avg_order_value_usd, 0) as avg_order_value_usd,
  COALESCE(cp.payment_methods_used, 0) as payment_methods_used,
  
  -- Répartition des dépenses
  COALESCE(cp.spent_credit_card, 0) as spent_credit_card,
  COALESCE(cp.spent_bank_transfer, 0) as spent_bank_transfer,
  COALESCE(cp.spent_coupon, 0) as spent_coupon,
  
  -- Segmentation client
  CASE 
    WHEN COALESCE(cp.total_spent_usd, 0) >= 50 THEN 'High Value'
    WHEN COALESCE(cp.total_spent_usd, 0) >= 20 THEN 'Medium Value'
    WHEN COALESCE(cp.total_spent_usd, 0) > 0 THEN 'Low Value'
    ELSE 'No Purchase'
  END as customer_segment,
  
  -- Statut client
  CASE 
    WHEN co.last_order_date IS NULL THEN 'Never Ordered'
    WHEN DATEDIFF(day, co.last_order_date, CURRENT_DATE()) <= 30 THEN 'Active'
    WHEN DATEDIFF(day, co.last_order_date, CURRENT_DATE()) <= 90 THEN 'At Risk'
    ELSE 'Churned'
  END as customer_status,
  
  CURRENT_TIMESTAMP as created_at

FROM {{ ref('stg_customers') }} c
LEFT JOIN customer_orders co ON c.customer_id = co.customer_id  -- ✅ Corrigé
LEFT JOIN customer_payments cp ON c.customer_id = cp.customer_id  -- ✅ Corrigé
