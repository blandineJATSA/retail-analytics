-- tests/assert_cohorts_has_data.sql
-- Test simple : vérifier que cohortes a des données

SELECT 
  'No data found in customer cohorts' as test_failure_reason
FROM {{ ref('analytics_customer_cohorts') }}
HAVING COUNT(*) = 0
