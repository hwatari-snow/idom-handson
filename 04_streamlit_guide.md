# ハンズオン 2.1: Cortex Code で Streamlit ダッシュボードを作成

## 概要

Snowflake の AI コーディングアシスタント **Cortex Code** を使って、
売上実績ダッシュボードを自然言語の指示だけで作成する体験です。

---

## Step 1: Streamlit in Snowflake を開く

1. Snowsight の左メニューから **「Projects」** → **「Streamlit」** をクリック
2. 右上の **「+ Streamlit App」** をクリック
3. 以下を設定:
   - **App title**: `IDOM Sales Dashboard`
   - **App location**: `IDOM_HANDSON` → `DATA_MART`
   - **Warehouse**: `COMPUTE_WH`
4. **「Create」** をクリック

## Step 2: Cortex Code でコードを生成

エディタが開いたら、左下の **Cortex Code（AI アシスタント）** チャットに
以下のプロンプトを入力してください：

```
IDOM_HANDSON.DATA_MART.DT_SALES_PERFORMANCE テーブルのデータを使って、
以下の要素を含む売上ダッシュボードを作成してください:

1. サイドバーに地域（REGION）のフィルター
2. 上部に KPI カード（総売上、総契約件数、平均保険付帯率）
3. 月別売上推移の折れ線グラフ
4. 店舗別の売上・契約件数・保険付帯率のテーブル

テーブルは STORE_NAME, REGION, PREFECTURE, CONTRACT_MONTH, CONTRACT_COUNT,
TOTAL_SALES, AVG_CONTRACT_PRICE, INSURANCE_ATTACH_RATE, TARGET_MONTHLY_SALES
等のカラムを持っています。

Snowpark session は from snowflake.snowpark.context import get_active_session で取得してください。
```

## Step 3: 生成されたコードを確認・実行

1. Cortex Code が生成したコードを確認
2. 必要に応じて微調整
3. 右上の **「Run」** ボタンでプレビュー

## Step 4: カスタマイズ（時間があれば）

追加のプロンプト例：
- 「目標達成率のプログレスバーを追加して」
- 「地域別の売上構成比の円グラフを追加して」
- 「テーブルを並び替え可能にして」

---

## 完成形の参考コード

うまく生成されない場合は、同梱の `04_streamlit_app.py` を
エディタに貼り付けて使用してください。
