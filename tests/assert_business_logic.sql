-- tests/assert_business_logic.sql
-- Test personnalisé : Logique business cohérente

SELECT 
  'Business logic inconsistency detected' as test_failure_reason,
  section,
  category,
  total_customers,
  orders_count,
  revenue,
  aov,
  completion_rate_pct
FROM {{ ref('analytics_executive_dashboard') }}
WHERE 
  -- AOV incohérent avec revenue/orders
  (orders_count > 0 AND ABS(aov - (revenue / orders_count)) > 0.01)
  OR
  -- Taux de completion impossible
  (completion_rate_pct < 0 OR completion_rate_pct > 100)
  OR  
  -- Clients actifs > total clients
  (active_customers_30d > total_customers)
  OR
  -- Orders négatifs
  (orders_count < 0)
