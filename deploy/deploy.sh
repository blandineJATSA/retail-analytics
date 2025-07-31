#!/bin/bash

# Script de déploiement automatisé
set -e

echo "🚀 Démarrage du déploiement..."

# Configuration
ENVIRONMENT=${1:-prod}
DBT_PROFILES_DIR="./deploy"

echo "📋 Environnement: $ENVIRONMENT"

# 1. Vérification des prérequis
echo "✅ Vérification de l'environnement..."
dbt --version
dbt deps --profiles-dir $DBT_PROFILES_DIR

# 2. Tests sur l'environnement de staging
echo "🧪 Tests sur staging..."
dbt run --target dev --profiles-dir $DBT_PROFILES_DIR
dbt test --target dev --profiles-dir $DBT_PROFILES_DIR

# 3. Déploiement en production
if [ "$ENVIRONMENT" == "prod" ]; then
    echo "🎯 Déploiement en production..."
    
    # Sauvegarde
    echo "💾 Sauvegarde des données actuelles..."
    dbt run-operation backup_current_state --target prod
    
    # Déploiement
    dbt run --target prod --profiles-dir $DBT_PROFILES_DIR
    dbt test --target prod --profiles-dir $DBT_PROFILES_DIR
    
    # Documentation
    dbt docs generate --target prod --profiles-dir $DBT_PROFILES_DIR
    
    echo "✅ Déploiement réussi !"
else
    echo "✅ Tests validés sur staging !"
fi

echo "📊 Génération du rapport de déploiement..."
echo "Timestamp: $(date)" > deploy/last_deployment.log
echo "Environment: $ENVIRONMENT" >> deploy/last_deployment.log
echo "Status: SUCCESS" >> deploy/last_deployment.log
