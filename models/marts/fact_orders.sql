-- models/marts/fact_orders.sql
{{
  config(
    materialized='table',
    description='Orders fact table with all business metrics'
  )
}}

WITH order_payments AS (
  SELECT 
    p.order_id,
    SUM(p.amount_usd) as total_order_amount,
    COUNT(p.payment_id) as payment_count,
    
    -- Métriques par méthode de paiement
    SUM(CASE WHEN p.payment_method = 'credit_card' THEN p.amount_usd ELSE 0 END) as amount_credit_card,
    SUM(CASE WHEN p.payment_method = 'bank_transfer' THEN p.amount_usd ELSE 0 END) as amount_bank_transfer,
    SUM(CASE WHEN p.payment_method = 'coupon' THEN p.amount_usd ELSE 0 END) as amount_coupon,
    
    -- Méthodes de paiement utilisées
    LISTAGG(DISTINCT p.payment_method, ', ') as payment_methods_used,
    
    -- Indicateurs
    MAX(CASE WHEN p.payment_method = 'coupon' THEN 1 ELSE 0 END) as used_coupon,
    MAX(CASE WHEN p.payment_method = 'credit_card' THEN 1 ELSE 0 END) as used_credit_card
    
  FROM {{ ref('stg_payments') }} p
  GROUP BY p.order_id
)

SELECT 
  o.order_id,
  o.customer_id,
  o.order_date,
  o.order_date_ts,
  o.order_status,
  o.is_completed,
  o.is_returned,
  
  -- Infos client (enrichissement)
  c.full_name as customer_name,
  c.customer_segment,
  c.customer_status,
  
  -- Métriques financières
  COALESCE(op.total_order_amount, 0) as total_order_amount,
  COALESCE(op.payment_count, 0) as payment_count,
  COALESCE(op.amount_credit_card, 0) as amount_credit_card,
  COALESCE(op.amount_bank_transfer, 0) as amount_bank_transfer,
  COALESCE(op.amount_coupon, 0) as amount_coupon,
  
  -- Méthodes de paiement
  op.payment_methods_used,
  COALESCE(op.used_coupon, 0) as used_coupon,
  COALESCE(op.used_credit_card, 0) as used_credit_card,
  
  -- Dimensions temporelles
  EXTRACT(YEAR FROM o.order_date) as order_year,
  EXTRACT(MONTH FROM o.order_date) as order_month,
  EXTRACT(DAY FROM o.order_date) as order_day,
  DAYNAME(o.order_date) as order_day_name,
  EXTRACT(QUARTER FROM o.order_date) as order_quarter,
  
  -- Segmentation des commandes
  CASE 
    WHEN COALESCE(op.total_order_amount, 0) >= 30 THEN 'High Value Order'
    WHEN COALESCE(op.total_order_amount, 0) >= 15 THEN 'Medium Value Order'
    WHEN COALESCE(op.total_order_amount, 0) > 0 THEN 'Low Value Order'
    ELSE 'No Payment'
  END as order_value_segment,
  
  CURRENT_TIMESTAMP as created_at

FROM {{ ref('stg_orders') }} o
LEFT JOIN order_payments op ON o.order_id = op.order_id
LEFT JOIN {{ ref('dim_customers') }} c ON o.customer_id = c.customer_id
