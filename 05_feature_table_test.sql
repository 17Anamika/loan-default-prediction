-- =============================================================================
-- Same as 05_feature_table_one_row_per_application but for application_test (no TARGET)
-- Use in Python: pd.read_sql(this_query, conn) to get test features for prediction.
-- =============================================================================

WITH
bureau_agg AS (
    SELECT b.SK_ID_CURR,
        COUNT(DISTINCT b.SK_ID_BUREAU) AS bureau_credit_count,
        COALESCE(SUM(b.AMT_CREDIT_SUM_DEBT), 0) AS bureau_total_debt,
        COALESCE(SUM(b.AMT_CREDIT_SUM_LIMIT), 0) AS bureau_total_limit,
        COALESCE(SUM(b.AMT_CREDIT_SUM_OVERDUE), 0) AS bureau_total_overdue
    FROM bureau b GROUP BY b.SK_ID_CURR
),
bureau_balance_agg AS (
    SELECT b.SK_ID_CURR,
        MAX(CASE WHEN bb.STATUS IN ('1','2','3','4','5') THEN CAST(bb.STATUS AS INT) ELSE 0 END) AS bureau_max_dpd_status
    FROM bureau b
    INNER JOIN bureau_balance bb ON b.SK_ID_BUREAU = bb.SK_ID_BUREAU
    GROUP BY b.SK_ID_CURR
),
prev_agg AS (
    SELECT p.SK_ID_CURR,
        COUNT(DISTINCT p.SK_ID_PREV) AS prev_app_count,
        SUM(CASE WHEN p.NAME_CONTRACT_STATUS = 'Approved' THEN 1 ELSE 0 END) AS prev_approved,
        SUM(CASE WHEN p.NAME_CONTRACT_STATUS = 'Refused' THEN 1 ELSE 0 END) AS prev_refused,
        SUM(CASE WHEN p.NAME_CONTRACT_STATUS = 'Canceled' THEN 1 ELSE 0 END) AS prev_canceled,
        COALESCE(SUM(p.AMT_CREDIT), 0) AS prev_total_amt_credit,
        COALESCE(SUM(p.AMT_ANNUITY), 0) AS prev_total_annuity
    FROM previous_application p GROUP BY p.SK_ID_CURR
),
inst_agg AS (
    SELECT ip.SK_ID_CURR,
        COUNT(ip.SK_ID_PREV) AS installment_rows,
        SUM(CASE WHEN ip.DAYS_ENTRY_PAYMENT > ip.DAYS_INSTALMENT THEN 1 ELSE 0 END) AS late_payment_count,
        SUM(ip.AMT_INSTALMENT) AS total_scheduled,
        SUM(ip.AMT_PAYMENT) AS total_paid
    FROM installments_payments ip GROUP BY ip.SK_ID_CURR
),
pos_agg AS (
    SELECT pos.SK_ID_CURR,
        COUNT(DISTINCT pos.SK_ID_PREV) AS pos_loan_count,
        COUNT(*) AS pos_monthly_rows,
        SUM(CASE WHEN pos.SK_DPD > 0 THEN 1 ELSE 0 END) AS pos_months_with_dpd,
        MAX(pos.SK_DPD) AS pos_max_dpd,
        MAX(pos.SK_DPD_DEF) AS pos_max_dpd_def,
        SUM(pos.CNT_INSTALMENT) AS pos_total_instalment_term,
        SUM(pos.CNT_INSTALMENT_FUTURE) AS pos_instalments_future,
        SUM(CASE WHEN pos.NAME_CONTRACT_STATUS = 'Active' THEN 1 ELSE 0 END) AS pos_active_months,
        SUM(CASE WHEN pos.NAME_CONTRACT_STATUS = 'Completed' THEN 1 ELSE 0 END) AS pos_completed_months
    FROM POS_CASH_balance pos GROUP BY pos.SK_ID_CURR
),
cc_agg AS (
    SELECT cc.SK_ID_CURR,
        COUNT(DISTINCT cc.SK_ID_PREV) AS cc_card_count,
        COUNT(*) AS cc_monthly_rows,
        SUM(cc.AMT_BALANCE) AS cc_total_balance,
        SUM(cc.AMT_CREDIT_LIMIT_ACTUAL) AS cc_total_limit,
        SUM(cc.AMT_DRAWINGS_CURRENT) AS cc_total_drawings,
        SUM(cc.AMT_PAYMENT_CURRENT) AS cc_total_payments,
        SUM(cc.AMT_RECIVABLE) AS cc_total_receivable,
        SUM(CASE WHEN cc.SK_DPD > 0 THEN 1 ELSE 0 END) AS cc_months_with_dpd,
        MAX(cc.SK_DPD) AS cc_max_dpd,
        MAX(cc.SK_DPD_DEF) AS cc_max_dpd_def,
        SUM(cc.CNT_DRAWINGS_ATM_CURRENT) AS cc_cnt_drawings_atm,
        SUM(cc.CNT_DRAWINGS_CURRENT) AS cc_cnt_drawings,
        SUM(cc.CNT_INSTALMENT_MATURE_CUM) AS cc_cnt_instalments_paid
    FROM credit_card_balance cc GROUP BY cc.SK_ID_CURR
)
SELECT
    a.SK_ID_CURR,
    a.NAME_CONTRACT_TYPE,
    a.CODE_GENDER,
    a.FLAG_OWN_CAR,
    a.FLAG_OWN_REALTY,
    a.CNT_CHILDREN,
    a.AMT_INCOME_TOTAL,
    a.AMT_CREDIT,
    a.AMT_ANNUITY,
    a.AMT_GOODS_PRICE,
    a.NAME_INCOME_TYPE,
    a.NAME_EDUCATION_TYPE,
    a.NAME_FAMILY_STATUS,
    a.NAME_HOUSING_TYPE,
    a.DAYS_BIRTH,
    a.DAYS_EMPLOYED,
    a.DAYS_REGISTRATION,
    a.DAYS_ID_PUBLISH,
    a.OWN_CAR_AGE,
    a.EXT_SOURCE_1,
    a.EXT_SOURCE_2,
    a.EXT_SOURCE_3,
    a.OCCUPATION_TYPE,
    a.CNT_FAM_MEMBERS,
    a.REGION_RATING_CLIENT,
    a.REGION_RATING_CLIENT_W_CITY,
    a.HOUR_APPR_PROCESS_START,
    COALESCE(b.bureau_credit_count, 0) AS bureau_credit_count,
    COALESCE(b.bureau_total_debt, 0) AS bureau_total_debt,
    COALESCE(b.bureau_total_limit, 0) AS bureau_total_limit,
    COALESCE(b.bureau_total_overdue, 0) AS bureau_total_overdue,
    COALESCE(bb.bureau_max_dpd_status, 0) AS bureau_max_dpd_status,
    COALESCE(p.prev_app_count, 0) AS prev_app_count,
    COALESCE(p.prev_approved, 0) AS prev_approved,
    COALESCE(p.prev_refused, 0) AS prev_refused,
    COALESCE(p.prev_canceled, 0) AS prev_canceled,
    COALESCE(p.prev_total_amt_credit, 0) AS prev_total_amt_credit,
    COALESCE(p.prev_total_annuity, 0) AS prev_total_annuity,
    COALESCE(i.installment_rows, 0) AS installment_rows,
    COALESCE(i.late_payment_count, 0) AS late_payment_count,
    COALESCE(i.total_scheduled, 0) AS total_scheduled,
    COALESCE(i.total_paid, 0) AS total_paid,
    COALESCE(pos.pos_loan_count, 0) AS pos_loan_count,
    COALESCE(pos.pos_monthly_rows, 0) AS pos_monthly_rows,
    COALESCE(pos.pos_months_with_dpd, 0) AS pos_months_with_dpd,
    COALESCE(pos.pos_max_dpd, 0) AS pos_max_dpd,
    COALESCE(pos.pos_max_dpd_def, 0) AS pos_max_dpd_def,
    COALESCE(pos.pos_total_instalment_term, 0) AS pos_total_instalment_term,
    COALESCE(pos.pos_instalments_future, 0) AS pos_instalments_future,
    COALESCE(pos.pos_active_months, 0) AS pos_active_months,
    COALESCE(pos.pos_completed_months, 0) AS pos_completed_months,
    COALESCE(cc.cc_card_count, 0) AS cc_card_count,
    COALESCE(cc.cc_monthly_rows, 0) AS cc_monthly_rows,
    COALESCE(cc.cc_total_balance, 0) AS cc_total_balance,
    COALESCE(cc.cc_total_limit, 0) AS cc_total_limit,
    COALESCE(cc.cc_total_drawings, 0) AS cc_total_drawings,
    COALESCE(cc.cc_total_payments, 0) AS cc_total_payments,
    COALESCE(cc.cc_total_receivable, 0) AS cc_total_receivable,
    COALESCE(cc.cc_months_with_dpd, 0) AS cc_months_with_dpd,
    COALESCE(cc.cc_max_dpd, 0) AS cc_max_dpd,
    COALESCE(cc.cc_max_dpd_def, 0) AS cc_max_dpd_def,
    COALESCE(cc.cc_cnt_drawings_atm, 0) AS cc_cnt_drawings_atm,
    COALESCE(cc.cc_cnt_drawings, 0) AS cc_cnt_drawings,
    COALESCE(cc.cc_cnt_instalments_paid, 0) AS cc_cnt_instalments_paid
FROM application_test a
LEFT JOIN bureau_agg      b   ON a.SK_ID_CURR = b.SK_ID_CURR
LEFT JOIN bureau_balance_agg bb ON a.SK_ID_CURR = bb.SK_ID_CURR
LEFT JOIN prev_agg        p   ON a.SK_ID_CURR = p.SK_ID_CURR
LEFT JOIN inst_agg        i   ON a.SK_ID_CURR = i.SK_ID_CURR
LEFT JOIN pos_agg         pos ON a.SK_ID_CURR = pos.SK_ID_CURR
LEFT JOIN cc_agg          cc  ON a.SK_ID_CURR = cc.SK_ID_CURR;
