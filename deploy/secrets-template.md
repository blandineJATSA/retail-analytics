# 🔐 Configuration des Secrets GitHub

Pour que le CI/CD fonctionne, configurez ces secrets dans :
**GitHub Repository → Settings → Secrets and Variables → Actions**

## 📋 Secrets requis :

| Nom | Description | Exemple |
|-----|-------------|---------|
| `SNOWFLAKE_ACCOUNT` | Compte Snowflake | `abc123.us-east-1` |
| `SNOWFLAKE_USER` | Utilisateur Snowflake | `dbt_user` |
| `SNOWFLAKE_PASSWORD` | Mot de passe | `your-password` |
| `SNOWFLAKE_ROLE` | Rôle Snowflake | `DBT_ROLE` |
| `SNOWFLAKE_WAREHOUSE` | Warehouse | `COMPUTE_WH` |
| `SLACK_WEBHOOK` | Webhook Slack (optionnel) | `https://hooks.slack.com/...` |

## ⚙️ Configuration :
1. Allez dans votre repo GitHub
2. Settings → Secrets and Variables → Actions  
3. Cliquez "New repository secret"
4. Ajoutez chaque secret
