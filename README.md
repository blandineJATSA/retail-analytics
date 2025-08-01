# 🛍️ Retail Analytics Platform with DBT & Snowflake

<div align="center">

![Project Banner](https://img.shields.io/badge/Retail_Analytics-Data_Engineering_Project-blue?style=for-the-badge)

**Plateforme d'analyse retail complète utilisant les meilleures pratiques de Data Engineering moderne**

[![DBT](https://img.shields.io/badge/DBT-FF694B?style=for-the-badge&logo=dbt&logoColor=white)](https://www.getdbt.com/)
[![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)](https://www.snowflake.com/)
[![SQL](https://img.shields.io/badge/SQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/)

</div>

---

## 🎭 **Contexte Business & Problématique**

### 🏢 **Situation d'entreprise**
Une **entreprise retail omnicanal** (en ligne + magasins physiques) avec :
- 📊 **+50K commandes/mois**
- 👥 **+10K clients actifs**
- 🛍️ **+500 produits** dans le catalogue
- 💰 **Millions d'euros** de chiffre d'affaires

### ❌ **Problèmes identifiés**
| Problème | Impact Business | Coût estimé |
|----------|----------------|-------------|
| 📈 **Données dispersées** | Décisions basées sur l'intuition | **30% de perte d'opportunités** |
| ⏱️ **Reporting manuel** | 2-3 jours pour un rapport | **80h/mois** de travail manuel |
| 🎯 **Pas de vision client 360°** | Marketing non ciblé | **25% budget marketing gaspillé** |
| 📉 **Métriques incohérentes** | Conflits entre départements | **Perte de confiance** dans les données |

### ✅ **Solution apportée**
Un **Data Warehouse moderne** avec :
- 🔄 **Pipeline automatisé** de transformation des données
- 📊 **Métriques unifiées** et cohérentes
- ⚡ **Reporting en temps réel**
- 🎯 **Vue client 360°** pour le marketing
- 📈 **Tableaux de bord exécutifs** pour la direction

---

## 🎯 **Objectifs & ROI Attendu**

### 🎯 **Objectifs Business**
1. **Augmenter le chiffre d'affaires** de 15% grâce à de meilleures décisions
2. **Réduire le temps de reporting** de 80% (de 3 jours à 2 heures)
3. **Optimiser les campagnes marketing** → +20% de conversion
4. **Identifier les produits sous-performants** → Optimisation du stock

### 📈 Objectif technique 

- **Automatiser** la collecte, transformation et consolidation de toutes les données retail dans un DataWarehouse performant (Snowflake)
- **Structurer les données** via DBT (data build tool) : norme, fiabilité, documentation intégrée
- **Fournir des dashboards exécutifs self-service** pour la prise de décision rapide
- **Industrialiser le pipeline avec des jobs automatisés**


## 🏆 QU'EST-CE QUE CE PROJET RÉSOUT ?

- **Gain de temps** 💡 (plus de reporting manuel)
- **Confiance dans la donnée** 🔒 (tests et monitoring automatiques)
- **Prise de décision accélérée** 🚀 (dashboards à jour)
- **Maitrise des coûts IT** 💰 (Snowflake = performance scalable, DBT = maintenance facilitée)
- **Collaboration technique et business** 🤝 (documentation technique ET métier au même endroit)


## 🏗️ **Architecture Technique**

<div align="center">

```mermaid
graph TB
    A[🏪 Systèmes Sources] --> B[🏔️ Snowflake Raw]
    B --> C[🛠️ DBT Transformations]
    C --> D[📊 Data Warehouse]
    D --> E[📈 Dashboards]
    D --> F[🤖 ML Models]
    
    subgraph "🔄 DBT Layer"
        C1[📥 Staging] --> C2[🧮 Analytics]
        C2 --> C3[📊 Marts]
    end


## 🛠️ STACK TECHNIQUE UTILISÉE

| Outil         | Rôle dans le projet                                       |
|:------------- |:----------------------------------------------------------|
| **Snowflake** | DataWarehouse cloud, stockage et exécution de requêtes    |
| **DBT Cloud** | Orchestration, transformation, test et documentation SQL  |
| **GitHub**    | Versionning du code, documentation collaborative          |
| **SQL**       | Langage de manipulation des données                       |
| **Bash**      | Automatisation des déploiements / vérifications           |
| **(Tableau/PowerBI)** | Consommation finale des datasets pour dashboards   |

---

## ⚙️ ARCHITECTURE GÉNÉRALE

```mermaid
flowchart LR
    Source[Sources Retail - CRM, POS, Ecom] -->|Extract| Snowflake[(DataWarehouse)]
    Snowflake -->|Transform (SQL)| DBT[DBT Cloud]
    DBT -->|Test, Doc, Orchestration| DataSet[Data Sets certified]
    DataSet -->|Visualisation| Dashboard[Dashboards (BI)]
    DBT --> GitHub[GitHub - Code & Docs]

📖 ÉTAPES DU PROJET
1️⃣ Connexion aux Données

Extraction des données brutes (commandes, clients, produits…) dans Snowflake.

2️⃣ Création des modèles de staging (DBT)

Nettoyage, normalisation des raw data → tables de staging claires.

3️⃣ Transformation analytique et modélisation métier

Écriture de modèles analytiques : cohortes, CLV, performance par produit, etc.

4️⃣ Tests automatisés sur chaque étape

Grâce à DBT : tests de qualité (unicité, non-null, relations...)

5️⃣ Documentation intégrée & collaborative

Doc technique et métier générée automatiquement via DBT Cloud.

6️⃣ Jobs planifiés et industrialisation

Automatisation des scripts : actualisation quotidienne, analyse ad hoc, monitoring...

7️⃣ Restitution visuelle & prise de décision

Consommation des datasets dans Tableau/PowerBI/dashboard.


🛠️ Outils, Concepts et Pratiques utilisées

- DBT CloudTransformation, orchestration et documentation de la data pipeline
- SnowflakeData Warehouse performant et scalable
- Git & CI/CDTraçabilité, collaboration, déploiement automatisé
- Tests automatisés (DBT tests)Garantit la fiabilité (tests d’unicité, non null, relations, …)
- Documentation intégréeChaque modèle DBT possède une doc business ET technique


💻 INSTALLATION & PREMIÈRES COMMANDES
# Cloner le repo
git clone https://github.com/VOTRE-USERNAME/retail-analytics-dbt
cd retail-analytics-dbt

# Installer les dépendances (DBT)
pip install dbt-snowflake

# Configurer Snowflake & DBT (credentials dans profiles.yml)
dbt debug

# Lancer un modèle complet :
dbt run

# Lancer les tests automatiques :
dbt test

# Générer la documentation interactive :
dbt docs generate

🏗️ STRUCTURE DU PROJET
retail-analytics-dbt/
├── models/
│   ├── staging/           # Données brutes nettoyées
│   └── analytics/         # Tables métier et KPIs clés
├── deploy/                # Recettes de déploiement et jobs automatisés
├── tests/                 # Tests avancés
├── macros/                # Fonctions personnalisées DBT
├── docs/                  # Compléments documentaires
├── dbt_project.yml        # Config DBT principale
├── profiles.yml           # Connexion à Snowflake
└── README.md              # La doc que vous lisez ;)

🕹️ PRINCIPALES COMMANDES & AUTOMATISATIONS

dbt run — Exécute tous les modèles  
dbt test — Exécute les tests de qualité  
dbt docs generate — Génère la documentation  
dbt seed — Charge les données de référence
Jobs YAML — Permet l'actualisation auto (voir deploy/jobs.yml)

🏗️ Déploiement et Automatisation
Étapes du pipeline :

Actualisation planifiée (via jobs.yml) chaque matin, sans action humaine
Tests et validation automatique à chaque déploiement
Mise à jour automatique de la documentation
Monitoring simple (alertes en cas d’échec)

Accès : tout est versionné sur GitHub pour retour arrière/blame/audit.

7. 🚦 Guide d’Onboarding / Prise en Main
Pour utiliser ou reprendre le projet :

Cloner le repo
Créer/adapter le fichier profiles.yml avec les credentials Snowflake/DBT
Installer DBT (pip install dbt-snowflake ou via Cloud)
Lancer les commandes de base :  
dbt deps      // Télécharger dépendances
dbt run     // Exécuter toutes les transformations
dbt test    // Vérifier l’intégrité des données
dbt docs generate && dbt docs serve // Générer/visualiser la documentation


## 📊 EXEMPLES DE KPIs & ANALYSES PRODUITES

| KPI                        | Description                                  |
|----------------------------|----------------------------------------------|
| Chiffre d'affaires mensuel | Évolution des ventes mois par mois          |
| Valeur Vie Client (CLV/LTV) | Valeur cumulée par segment client          |
| Analyse de cohortes        | Fidélité client et comportement             |
| Top Produits par CA        | Classement des articles                      |
| Conversion e-commerce      | Taux d'achat vs navigation                   |



📝 POURQUOI CE CHOIX DBT / SNOWFLAKE ?

"DBT et Snowflake sont devenus des standards car ils permettent d’automatiser, documenter, et fiabiliser tous les flux de données. Ce projet démontre comment passer de données brutes dispersées à des insights business 100 % industrialisés 🚀"


👨‍💻 QUESTIONS/RÉPONSES : POUR ALLER PLUS LOIN…
Q : Quel intérêt d’utiliser DBT ? : Standardisation, tests automatiques, doc intégrée, versionning Git, collaboration accrue.
Q : Pourquoi automatiser ? : Plus d’oubli humain, données toujours à jour, gain de temps massif.
Q : Snowflake, quels avantages ? : Performances, passage à l’échelle, coûts maîtrisés (pay-per-use), sécurité.




### Resources:
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [dbt community](https://getdbt.com/community) to learn from other analytics engineers
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices