-- macros/business_metrics.sql
-- Macros utilitaires pour les calculs business

{% macro calculate_growth_rate(current_value, previous_value) %}
  CASE 
    WHEN {{ previous_value }} = 0 OR {{ previous_value }} IS NULL THEN NULL
    ELSE ROUND(({{ current_value }} - {{ previous_value }}) * 100.0 / {{ previous_value }}, 2)
  END
{% endmacro %}

{% macro get_date_spine(start_date, end_date) %}
  WITH RECURSIVE date_spine AS (
    SELECT {{ start_date }} as date_day
    UNION ALL
    SELECT DATEADD('day', 1, date_day)
    FROM date_spine
    WHERE date_day < {{ end_date }}
  )
  SELECT * FROM date_spine
{% endmacro %}

{% macro segment_customers_by_value(revenue_column, frequency_column) %}
  CASE 
    WHEN {{ revenue_column }} >= 500 AND {{ frequency_column }} >= 5 THEN 'VIP'
    WHEN {{ revenue_column }} >= 200 AND {{ frequency_column }} >= 3 THEN 'Premium'  
    WHEN {{ revenue_column }} >= 50 AND {{ frequency_column }} >= 2 THEN 'Regular'
    ELSE 'Basic'
  END
{% endmacro %}

{% macro safe_divide(numerator, denominator, default_value=0) %}
  CASE 
    WHEN {{ denominator }} = 0 OR {{ denominator }} IS NULL THEN {{ default_value }}
    ELSE {{ numerator }} / {{ denominator }}
  END
{% endmacro %}
