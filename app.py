
import streamlit as st
import pandas as pd
import numpy as np
import joblib
import json
import warnings

# Suppress sklearn warnings about feature names
warnings.filterwarnings("ignore")

# Configure Webpage Layout
st.set_page_config(page_title="AI Credit Risk Dashboard", layout="wide")
st.title("🏦 AI Credit Risk Predictor")
st.markdown("This dashboard uses our optimized XGBoost model to predict loan defaults in real-time.")

# --- 1. Load Data & Model safely ---
@st.cache_resource
def load_assets():
    xgb_model = joblib.load("model_pipeline.pkl")
    with open("baseline_applicant.json", "r") as f:
        base_data = json.load(f)
    return xgb_model, base_data

try:
    model, baseline = load_assets()
except Exception as e:
    st.error(f"Missing model files. Did you run the Jupyter export cell? Error: {e}")
    st.stop()

# --- 2. Interactive UI Sliders ---
st.sidebar.header("Applicant Profile")

income = st.sidebar.number_input("Total Income ($)", 10000, 5000000, 300000, step=10000)
credit = st.sidebar.number_input("Requested Loan Amount ($)", 10000, 5000000, 100000, step=10000)
annuity = st.sidebar.number_input("Monthly Annuity ($)", 1000, 200000, 8000, step=1000)

st.sidebar.markdown("---")
age_years = st.sidebar.slider("Age (Years)", 20, 70, 40)
employed_years = st.sidebar.slider("Years Employed", 0, 45, 5)

st.sidebar.markdown("---")
ext_1 = st.sidebar.slider("Bureau Score 1", 0.0, 1.0, 0.5)
ext_2 = st.sidebar.slider("Bureau Score 2", 0.0, 1.0, 0.5)
ext_3 = st.sidebar.slider("Bureau Score 3", 0.0, 1.0, 0.5)

# --- 3. Process Data (Feature Engineering Bridge) ---
input_data = baseline.copy()

# Override baseline with UI inputs
input_data["AMT_INCOME_TOTAL"] = income
input_data["AMT_CREDIT"] = credit
input_data["AMT_ANNUITY"] = annuity
input_data["DAYS_BIRTH"] = - (age_years * 365.25)
input_data["DAYS_EMPLOYED"] = - (employed_years * 365.25)
input_data["EXT_SOURCE_1"] = ext_1
input_data["EXT_SOURCE_2"] = ext_2
input_data["EXT_SOURCE_3"] = ext_3

df = pd.DataFrame([input_data])

# Calculate Business Ratios (must match notebook exactly)
EPS = 1e-6
df["credit_income_ratio"] = df["AMT_CREDIT"] / (df["AMT_INCOME_TOTAL"] + EPS)
ratio= df['credit_income_ratio'].iloc[0]

if ratio > 1:
    st.warning("⚠️ Loan is higher than income → High risk")
elif ratio > 0.5:
    st.info("ℹ️ Moderate loan burden")
else:
    st.success("✅ Healthy loan level")
df["annuity_income_ratio"] = df["AMT_ANNUITY"] / (df["AMT_INCOME_TOTAL"] + EPS)
df["credit_annuity_ratio"] = df["AMT_CREDIT"] / (df["AMT_ANNUITY"] + EPS)

if "bureau_total_debt" in df.columns:
    df["bureau_debt_income_ratio"] = df["bureau_total_debt"] / (df["AMT_INCOME_TOTAL"] + EPS)

df["AGE_YEARS"] = (-df["DAYS_BIRTH"]) / 365.25
df["DAYS_EMPLOYED_CLEAN"] = df["DAYS_EMPLOYED"]  
df["EMPLOYED_YEARS"] = (-df["DAYS_EMPLOYED_CLEAN"]) / 365.25

# Log Transforms
log_cols = ["AMT_INCOME_TOTAL", "AMT_CREDIT", "AMT_ANNUITY", "bureau_total_debt", "total_scheduled"]
for c in log_cols:
    if c in df.columns:
        s = df[c].iloc[0]
        if s >= 0:
            df[f'log_{c}'] = np.log1p(s)
        else:
            df[f'log_{c}'] = np.sign(s) * np.log1p(np.abs(s))

# --- 4. Predictive Engine ---
# Add missing columns with 0 manually if correlation drop broke the shapes
try:
    for name, transformer, columns in model.named_steps["prep"].transformers_:
        if name != "remainder":
            for col in columns:
                if col not in df.columns:
                    df[col] = 0
except:
    pass

# Run Model
probability = model.predict_proba(df)[0][1]

# --- 5. Render Output ---
col1, col2 = st.columns([1, 1])

with col1:
    st.subheader("Model Assessment")
    if probability >= 0.40:
        st.error(f"🚨 High Risk of Default: {probability*100:.1f}%")
        st.markdown("**Action:** Auto-Reject Application")
    elif probability >= 0.20:
        st.warning(f"⚠️ Medium Risk of Default: {probability*100:.1f}%")
        st.markdown("**Action:** Route to Human Underwriter")
    else:
        st.success(f"✅ Low Risk of Default: {probability*100:.1f}%")
        st.markdown("**Action:** Auto-Approve Application")

with col2:
    st.subheader("Financial Context")
    st.write(f"- **Debt-to-Income:** {df['credit_income_ratio'][0]:.2f}x")
    st.write(f"- **Disposable Income (After Annuity):** ${(income - annuity):,.0f} / year")
    st.write(f"- **External Source Mean Score:** {((ext_1 + ext_2 + ext_3)/3):.2f}")
