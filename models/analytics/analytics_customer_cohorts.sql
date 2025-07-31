-- models/analytics/analytics_customer_cohorts.sql
{{
  config(
    materialized='table',
    description='Customer cohort analysis showing retention and behavior patterns'
  )
}}

WITH customer_first_order AS (
  -- Date de première commande par client
  SELECT 
    customer_id,
    MIN(order_date) as first_order_date,
    DATE_TRUNC('month', MIN(order_date)) as cohort_month,
    COUNT(DISTINCT order_id) as total_orders,
    SUM(total_order_amount) as total_spent,
    MAX(order_date) as last_order_date
  FROM {{ ref('fact_orders') }}
  WHERE is_completed = TRUE
  GROUP BY customer_id
),

cohort_data AS (
  -- Données de cohorte avec périodes d'activité
  SELECT 
    cfo.customer_id,
    cfo.cohort_month,
    cfo.first_order_date,
    cfo.total_orders,
    cfo.total_spent,
    cfo.last_order_date,
    
    -- Calcul des périodes depuis la première commande
    o.order_date,
    o.total_order_amount,
    DATE_TRUNC('month', o.order_date) as order_month,
    
    -- Période relative (mois depuis première commande)
    DATEDIFF('month', cfo.cohort_month, DATE_TRUNC('month', o.order_date)) as period_number,
    
    -- Indicateurs d'activité
    CASE WHEN o.order_date IS NOT NULL THEN 1 ELSE 0 END as is_active
    
  FROM customer_first_order cfo
  LEFT JOIN {{ ref('fact_orders') }} o 
    ON cfo.customer_id = o.customer_id 
    AND o.is_completed = TRUE
),

cohort_table AS (
  -- Table de cohorte avec rétention
  SELECT 
    cohort_month,
    period_number,
    
    -- Métriques de cohorte
    COUNT(DISTINCT customer_id) as customers_active,
    SUM(total_order_amount) as revenue_period,
    COUNT(DISTINCT CASE WHEN total_order_amount > 0 THEN customer_id END) as paying_customers,
    
    -- Première cohorte (période 0)
    FIRST_VALUE(COUNT(DISTINCT customer_id)) 
      OVER (PARTITION BY cohort_month ORDER BY period_number) as cohort_size,
    
    -- Calcul du taux de rétention
    ROUND(
      COUNT(DISTINCT customer_id) * 100.0 / 
      FIRST_VALUE(COUNT(DISTINCT customer_id)) 
        OVER (PARTITION BY cohort_month ORDER BY period_number), 2
    ) as retention_rate,
    
    -- Revenue per customer dans la période
    ROUND(
      SUM(total_order_amount) / NULLIF(COUNT(DISTINCT customer_id), 0), 2
    ) as avg_revenue_per_customer
    
  FROM cohort_data
  WHERE order_date IS NOT NULL
  GROUP BY cohort_month, period_number
),

cohort_summary AS (
  -- Résumé par cohorte
  SELECT 
    cohort_month,
    COUNT(DISTINCT customer_id) as cohort_size,
    
    -- Métriques de performance
    ROUND(AVG(total_orders), 2) as avg_orders_per_customer,
    ROUND(AVG(total_spent), 2) as avg_ltv,
    ROUND(SUM(total_spent), 2) as total_cohort_revenue,
    
    -- Analyse temporelle
    ROUND(AVG(DATEDIFF('day', first_order_date, last_order_date)), 1) as avg_customer_lifespan_days,
    
    -- Segmentation de la cohorte
    COUNT(CASE WHEN total_orders = 1 THEN 1 END) as one_time_buyers,
    COUNT(CASE WHEN total_orders BETWEEN 2 AND 4 THEN 1 END) as regular_buyers,
    COUNT(CASE WHEN total_orders >= 5 THEN 1 END) as power_buyers,
    
    -- Pourcentages
    ROUND(COUNT(CASE WHEN total_orders = 1 THEN 1 END) * 100.0 / COUNT(*), 2) as one_time_buyer_pct,
    ROUND(COUNT(CASE WHEN total_orders >= 2 THEN 1 END) * 100.0 / COUNT(*), 2) as repeat_buyer_pct
    
  FROM customer_first_order
  GROUP BY cohort_month
)

-- Résultat final combinant analyse de cohorte et métriques
SELECT 
  'COHORT_RETENTION' as analysis_type,
  ct.cohort_month,
  ct.period_number,
  'Period ' || ct.period_number || ' (' || 
    CASE 
      WHEN ct.period_number = 0 THEN 'Acquisition'
      WHEN ct.period_number = 1 THEN 'Month 1'
      WHEN ct.period_number <= 3 THEN 'Early Retention'
      WHEN ct.period_number <= 6 THEN 'Mid Retention'
      ELSE 'Long-term'
    END || ')' as period_description,
    
  ct.cohort_size,
  ct.customers_active,
  ct.retention_rate,
  ct.revenue_period,
  ct.paying_customers,
  ct.avg_revenue_per_customer,
  
  CURRENT_TIMESTAMP as generated_at

FROM cohort_table ct

UNION ALL

SELECT 
  'COHORT_SUMMARY' as analysis_type,
  cs.cohort_month,
  NULL as period_number,
  'Cohort Overview' as period_description,
  
  cs.cohort_size,
  NULL as customers_active,
  cs.repeat_buyer_pct as retention_rate,
  cs.total_cohort_revenue as revenue_period,
  cs.cohort_size - cs.one_time_buyers as paying_customers,
  cs.avg_ltv as avg_revenue_per_customer,
  
  CURRENT_TIMESTAMP as generated_at

FROM cohort_summary cs

ORDER BY cohort_month, period_number NULLS FIRST
