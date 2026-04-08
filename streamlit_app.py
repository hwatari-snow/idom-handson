import streamlit as st
import pandas as pd
from snowflake.snowpark.context import get_active_session

session = get_active_session()

st.set_page_config(page_title="IDOM 売上ダッシュボード", layout="wide")
st.title("IDOM 売上ダッシュボード")

df = session.table("IDOM_HANDSON.DATA_MART.DT_SALES_PERFORMANCE").to_pandas()

regions = ["全て"] + sorted(df["REGION"].unique().tolist())
selected_region = st.sidebar.selectbox("地域フィルター", regions)

if selected_region != "全て":
    df = df[df["REGION"] == selected_region]

col1, col2, col3 = st.columns(3)
col1.metric("総売上", f"¥{df['TOTAL_SALES'].sum():,.0f}")
col2.metric("総契約件数", f"{df['CONTRACT_COUNT'].sum():,.0f} 件")
col3.metric("平均保険付帯率", f"{df['INSURANCE_ATTACH_RATE'].mean():.1f}%")

st.subheader("月別売上推移")
monthly = (
    df.groupby("CONTRACT_MONTH")
    .agg({"TOTAL_SALES": "sum", "CONTRACT_COUNT": "sum"})
    .reset_index()
    .sort_values("CONTRACT_MONTH")
)
st.line_chart(monthly, x="CONTRACT_MONTH", y="TOTAL_SALES")

st.subheader("店舗別実績")
store_summary = (
    df.groupby(["STORE_NAME", "REGION", "PREFECTURE"])
    .agg({
        "CONTRACT_COUNT": "sum",
        "TOTAL_SALES": "sum",
        "AVG_CONTRACT_PRICE": "mean",
        "INSURANCE_ATTACH_RATE": "mean",
        "TARGET_MONTHLY_SALES": "first",
    })
    .reset_index()
    .sort_values("TOTAL_SALES", ascending=False)
)
store_summary["目標達成率"] = (
    store_summary["TOTAL_SALES"] / store_summary["TARGET_MONTHLY_SALES"] * 100
).round(1)

st.dataframe(
    store_summary.rename(columns={
        "STORE_NAME": "店舗名",
        "REGION": "地域",
        "PREFECTURE": "都道府県",
        "CONTRACT_COUNT": "契約件数",
        "TOTAL_SALES": "売上合計",
        "AVG_CONTRACT_PRICE": "平均単価",
        "INSURANCE_ATTACH_RATE": "保険付帯率",
    })[["店舗名", "地域", "都道府県", "契約件数", "売上合計", "平均単価", "保険付帯率", "目標達成率"]],
    use_container_width=True,
    hide_index=True,
)
