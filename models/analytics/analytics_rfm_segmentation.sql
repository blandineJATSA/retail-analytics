-- models/analytics/analytics_rfm_segmentation.sql
{{
  config(
    materialized='table',
    description='RFM (Recency, Frequency, Monetary) customer segmentation analysis'
  )
}}

WITH customer_rfm_metrics AS (
  -- Calcul des métriques RFM de base
  SELECT 
    fo.customer_id,
    dc.full_name as customer_name,
    dc.customer_segment,
    dc.customer_status,
    
    -- RECENCY: Jours depuis la dernière commande
    DATEDIFF('day', MAX(fo.order_date), CURRENT_DATE) as recency_days,
    MAX(fo.order_date) as last_order_date,
    MIN(fo.order_date) as first_order_date,
    
    -- FREQUENCY: Nombre de commandes
    COUNT(DISTINCT fo.order_id) as frequency_orders,
    COUNT(DISTINCT DATE_TRUNC('month', fo.order_date)) as frequency_months_active,
    
    -- MONETARY: Valeur monétaire
    ROUND(SUM(fo.total_order_amount), 2) as monetary_total,
    ROUND(AVG(fo.total_order_amount), 2) as monetary_avg_order,
    
    -- Métriques complémentaires
    DATEDIFF('day', MIN(fo.order_date), MAX(fo.order_date)) + 1 as customer_lifespan_days,
    
    -- Indicateurs de comportement
    COUNT(CASE WHEN fo.used_coupon = 1 THEN 1 END) as coupon_usage_count,
    COUNT(CASE WHEN fo.order_value_segment = 'High Value Order' THEN 1 END) as high_value_orders,
    
    -- Dernière activité
    MAX(fo.order_year) || '-' || LPAD(MAX(fo.order_month), 2, '0') as last_activity_month,
    
    -- Métriques par méthode de paiement
    ROUND(SUM(fo.amount_credit_card), 2) as total_credit_card,
    ROUND(SUM(fo.amount_coupon), 2) as total_coupon_value
    
  FROM {{ ref('fact_orders') }} fo
  INNER JOIN {{ ref('dim_customers') }} dc ON fo.customer_id = dc.customer_id
  WHERE fo.is_completed = TRUE
  GROUP BY fo.customer_id, dc.full_name, dc.customer_segment, dc.customer_status
),

rfm_percentiles AS (
  -- Calcul des quintiles pour chaque dimension RFM
  SELECT 
    *,
    -- Recency: Plus faible = meilleur (inversé)
    NTILE(5) OVER (ORDER BY recency_days DESC) as recency_score,
    
    -- Frequency: Plus élevé = meilleur
    NTILE(5) OVER (ORDER BY frequency_orders ASC) as frequency_score,
    
    -- Monetary: Plus élevé = meilleur  
    NTILE(5) OVER (ORDER BY monetary_total ASC) as monetary_score,
    
    -- Score RFM combiné
    CAST(NTILE(5) OVER (ORDER BY recency_days DESC) AS VARCHAR) ||
    CAST(NTILE(5) OVER (ORDER BY frequency_orders ASC) AS VARCHAR) ||
    CAST(NTILE(5) OVER (ORDER BY monetary_total ASC) AS VARCHAR) as rfm_score
    
  FROM customer_rfm_metrics
),

rfm_segmentation AS (
  -- Segmentation business basée sur les scores RFM
  SELECT 
    *,
    CASE 
      -- Champions: Meilleurs clients (scores élevés partout)
      WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 
        THEN 'Champions'
      
      -- Loyal Customers: Achètent régulièrement et récemment
      WHEN recency_score >= 3 AND frequency_score >= 4 AND monetary_score >= 3
        THEN 'Loyal Customers'
      
      -- Potential Loyalists: Récents avec bon potentiel
      WHEN recency_score >= 4 AND frequency_score >= 2 AND monetary_score >= 2
        THEN 'Potential Loyalists'
      
      -- New Customers: Récents mais peu d'historique  
      WHEN recency_score >= 4 AND frequency_score <= 2
        THEN 'New Customers'
      
      -- Promising: Dépensent bien mais pas très récents
      WHEN recency_score >= 2 AND frequency_score <= 3 AND monetary_score >= 4
        THEN 'Promising'
      
      -- Need Attention: Étaient bons mais déclinent
      WHEN recency_score >= 2 AND frequency_score >= 3 AND monetary_score >= 3
        THEN 'Need Attention'
      
      -- About to Sleep: Risque de partir
      WHEN recency_score <= 3 AND frequency_score <= 3 AND monetary_score <= 3
        THEN 'About to Sleep'
      
      -- At Risk: Bons clients historiques mais inactifs
      WHEN recency_score <= 2 AND frequency_score >= 3 AND monetary_score >= 3
        THEN 'At Risk'
      
      -- Cannot Lose Them: Meilleurs clients mais très inactifs
      WHEN recency_score <= 2 AND frequency_score >= 4 AND monetary_score >= 4
        THEN 'Cannot Lose Them'
      
      -- Hibernating: Longtemps inactifs
      WHEN recency_score <= 2 AND frequency_score <= 2 AND monetary_score >= 2
        THEN 'Hibernating'
      
      ELSE 'Lost'
    END as rfm_segment,
    
    -- Priorité d'action
    CASE 
      WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'P1 - Retain & Reward'
      WHEN recency_score <= 2 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'P1 - Win Back'
      WHEN recency_score >= 4 AND frequency_score <= 2 THEN 'P2 - Develop'
      WHEN recency_score <= 2 AND frequency_score <= 2 THEN 'P3 - Re-engage'
      ELSE 'P2 - Monitor'
    END as action_priority,
    
    -- Score de valeur client (0-100)
    ROUND((recency_score + frequency_score + monetary_score) * 100.0 / 15, 1) as customer_value_score
    
  FROM rfm_percentiles
),

segment_summary AS (
  -- Résumé par segment RFM
  SELECT 
    rfm_segment,
    action_priority,
    
    -- Métriques du segment
    COUNT(*) as customers_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM rfm_segmentation), 2) as customers_percentage,
    
    -- Métriques financières moyennes
    ROUND(AVG(monetary_total), 2) as avg_monetary_value,
    ROUND(SUM(monetary_total), 2) as total_segment_value,
    ROUND(AVG(frequency_orders), 1) as avg_frequency,
    ROUND(AVG(recency_days), 1) as avg_recency_days,
    ROUND(AVG(customer_value_score), 1) as avg_value_score,
    
    -- Potentiel et comportement
    ROUND(AVG(customer_lifespan_days), 1) as avg_lifespan_days,
    ROUND(AVG(coupon_usage_count), 1) as avg_coupon_usage,
    ROUND(SUM(high_value_orders) * 100.0 / NULLIF(SUM(frequency_orders), 0), 2) as high_value_order_rate
    
  FROM rfm_segmentation
  GROUP BY rfm_segment, action_priority
)

-- Résultat final avec détails clients et résumés segments
SELECT 
  'CUSTOMER_DETAIL' as analysis_type,
  rfm_segment as segment_name,
  action_priority,
  customer_id,
  customer_name,
  customer_segment as original_segment,
  customer_status,
  
  recency_days,
  frequency_orders,
  monetary_total as monetary_value,
  customer_value_score,
  rfm_score,
  
  last_order_date,
  customer_lifespan_days,
  coupon_usage_count,
  high_value_orders,
  total_credit_card,
  total_coupon_value,
  
  CURRENT_TIMESTAMP as generated_at

FROM rfm_segmentation

UNION ALL

SELECT 
  'SEGMENT_SUMMARY' as analysis_type,
  rfm_segment as segment_name,
  action_priority,
  NULL as customer_id,
  'SEGMENT OVERVIEW' as customer_name,
  NULL as original_segment,
  NULL as customer_status,
  
  avg_recency_days as recency_days,
  avg_frequency as frequency_orders,
  avg_monetary_value as monetary_value,
  avg_value_score as customer_value_score,
  NULL as rfm_score,
  
  NULL as last_order_date,
  avg_lifespan_days as customer_lifespan_days,
  avg_coupon_usage as coupon_usage_count,
  customers_count as high_value_orders,
  total_segment_value as total_credit_card,
  customers_percentage as total_coupon_value,
  
  CURRENT_TIMESTAMP as generated_at

FROM segment_summary

ORDER BY 
  analysis_type,
  CASE action_priority
    WHEN 'P1 - Retain & Reward' THEN 1
    WHEN 'P1 - Win Back' THEN 2  
    WHEN 'P2 - Develop' THEN 3
    WHEN 'P2 - Monitor' THEN 4
    WHEN 'P3 - Re-engage' THEN 5
  END,
  customer_value_score DESC NULLS LAST
