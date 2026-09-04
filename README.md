# Brazilian E-Commerce Analytics & ML Pipeline

> 🚧 **Work in Progress:** This is an ongoing project. Target date of completion: **End of October 2026**.

A containerized e-commerce data pipeline and machine learning workflow. Built with Snowflake, dbt, Dagster, and Docker, featuring predictive modeling and customer segmentation.

This project utilizes the [Kaggle Olist Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (100k+ anonymized orders from multiple marketplaces in Brazil) to demonstrate an end-to-end modern data stack setup alongside practical machine learning applications.

## 🏗️ Architecture & Tech Stack

- **Data Warehouse:** Snowflake (Secured with key-pair authentication)
- **Data Transformation:** dbt (Data Build Tool) for dimensional modeling
- **Orchestration:** Dagster (Software-defined assets)
- **Infrastructure:** Docker & Docker Compose
- **Machine Learning:** Python, Scikit-Learn, Pandas, NumPy
- **Environment Management:** Python `venv`

## 📊 Key Highlights

1. **Robust Data Pipeline:** Extracts raw Kaggle CSVs, loads them into Snowflake, and transforms them into analytics-ready tables using modular dbt models, CTEs, and window functions.
2. **Containerized Orchestration:** The entire dbt and Python execution environment is containerized via Docker and orchestrated via Dagster, ensuring reproducible builds and isolated dependencies.
3. **Machine Learning Integrations:**
   - **Customer Segmentation:** K-Means clustering to categorize customer purchasing behavior.
   - **Predictive Modeling:** Logistic Regression models evaluating order features to predict and recall bad reviews.

## 📂 Project Structure

```text
olist-dbt-portfolio/
├── dagster_olist/       # Dagster software-defined assets and pipeline orchestration
├── data_olist/          # Raw Kaggle CSVs (ignored in version control)
├── dbt_olist_github/    # dbt project, models, macros, testing, and Snowflake config
├── ml_olist/            # Jupyter notebooks for EDA, clustering, and regression models
├── _project_gist/       # Executive summaries, workflow documentation, and commands
├── docker-compose.yml   # Multi-container orchestration config
├── Dockerfile           # Base image definition for Dagster/dbt environment
└── requirements.txt     # Python dependencies
```
