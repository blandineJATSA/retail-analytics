# 🔄 Guide du Workflow CI/CD

## 📋 Processus automatisé :

### 1. **Développement** 
```bash
git checkout -b feature/nouvelle-metrique
# Développez vos modèles
dbt run --models +nouvelle_metrique
dbt test --models +nouvelle_metrique
git add .
git commit -m "feat: nouvelle métrique de retention"
git push origin feature/nouvelle-metrique
