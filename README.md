# loan-default-prediction
AI-powered Loan Default Prediction System using XGBoost, SHAP, SQL, and Streamlit.

# Loan Default Prediction System

An AI-powered Loan Default Prediction System developed using Machine Learning, XGBoost, SHAP Explainability, SQL aggregation, and Streamlit deployment.

## Project Overview

This project predicts whether a loan applicant is likely to default using historical applicant and financial behavior data.

The system includes:
- Data preprocessing pipeline
- Feature engineering
- ML model training
- Explainable AI using SHAP
- Interactive Streamlit dashboard

---

Dataset Source:
Home Credit Default Risk Dataset from Kaggle[ https://www.kaggle.com/competitions/home-credit-default-risk/data?utm_source=chatgpt.com]

---

## Features

- Handles imbalanced datasets effectively
- Uses ROC-AUC and F1-score instead of misleading accuracy
- Real-time loan risk prediction
- Explainable predictions using SHAP values
- Interactive Streamlit dashboard
- Business-based approval thresholds

---

## Tech Stack

- Python
- Pandas
- NumPy
- Scikit-Learn
- XGBoost
- LightGBM
- Streamlit
- SHAP
- SQL
- Joblib

---

## Machine Learning Models Used

- Logistic Regression
- Random Forest
- ExtraTrees
- LightGBM
- XGBoost (Final Selected Model)

---

## Workflow

1. SQL Data Aggregation
2. Data Cleaning
3. Feature Engineering
4. Handling Missing Values
5. Model Training
6. Model Evaluation
7. SHAP Explainability
8. Streamlit Deployment

---

## Business Logic

| Default Probability | Decision |
|---|---|
| < 20% | Auto Approve |
| 20% - 40% | Under Review |
| > 40% | Auto Reject |

---

## Project Structure

```text
loan-default-prediction/
│
├── app.py
├── Loan_default.ipynb
├── model_pipeline.pkl
├── baseline_applicant.json
├── requirements.txt
├── README.md
│
├── data/
│   ├── application_train.csv
│   ├── bureau.csv
│   ├── bureau_balance.csv
│   ├── credit_card_balance.csv
│   ├── installments_payments.csv
│   ├── POS_CASH_balance.csv
│   ├── previous_application.csv
│   └── sample_submission.csv
│
├── sql/
│   ├── 05_feature_table_test.sql
│   └── 05_feature_table_one_row_per_application.sql
│
├── models/
│
├── notebooks/
│
├── screenshots/
│   ├── dashboard.png
│   ├── shap_summary.png
│   ├── roc_auc.png
│
└── src/
