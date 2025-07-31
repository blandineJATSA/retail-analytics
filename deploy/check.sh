#!/bin/bash
echo "Test rapide DBT..."

# Test de base
if dbt compile; then
    echo "✅ Compilation OK"
else
    echo "❌ Erreur compilation"
    exit 1
fi

echo "🎉 Prêt pour production!"
