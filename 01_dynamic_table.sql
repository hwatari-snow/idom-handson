-- ============================================================
-- ハンズオン 1.1: Dynamic Table で売上実績パイプラインを構築
-- ============================================================
-- Dynamic Table は宣言的にデータパイプラインを定義する機能です。
-- ソーステーブルが更新されると、自動的にリフレッシュされます。
--
-- このハンズオンでは3ステップで構築します:
--   Step 1: Dynamic Table を作成（3テーブル結合 + KPI集計）
--   Step 2: 状態確認（リフレッシュ履歴）
--   Step 3: ソースデータを更新して自動リフレッシュを体験
-- ============================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;
USE SCHEMA IDOM_HANDSON.DATA_MART;

-- ============================================================
-- Step 1: Dynamic Table を作成
-- ============================================================
-- CONTRACTS × STORES × INSURANCE を結合し、
-- 店舗別・月別の売上KPIを集計する Dynamic Table を作成します。
--
-- ポイント:
--   - target_lag: データの鮮度（ここでは1時間以内に更新）
--   - refresh_mode: AUTO（Snowflakeが最適な方式を選択）
--   - initialize: ON_CREATE（作成時に即座にデータ投入）

CREATE OR REPLACE DYNAMIC TABLE IDOM_HANDSON.DATA_MART.DT_SALES_PERFORMANCE
    TARGET_LAG = '1 hour'
    REFRESH_MODE = AUTO
    INITIALIZE = ON_CREATE
    WAREHOUSE = COMPUTE_WH
AS
SELECT
    s.STORE_ID,
    s.STORE_NAME,
    s.REGION,
    s.PREFECTURE,
    s.STORE_TYPE,
    s.TARGET_MONTHLY_SALES,
    s.TARGET_MONTHLY_CONTRACTS,
    DATE_TRUNC('month', c.CONTRACT_DATE) AS CONTRACT_MONTH,
    COUNT(DISTINCT c.CONTRACT_ID) AS CONTRACT_COUNT,
    SUM(c.CONTRACT_PRICE) AS TOTAL_SALES,
    AVG(c.CONTRACT_PRICE) AS AVG_CONTRACT_PRICE,
    SUM(c.TAX_AMOUNT) AS TOTAL_TAX,
    SUM(c.LOAN_AMOUNT) AS TOTAL_LOAN_AMOUNT,
    COUNT(CASE WHEN c.CONTRACT_STATUS = '納車済' THEN 1 END) AS DELIVERED_COUNT,
    COUNT(CASE WHEN c.CONTRACT_STATUS = '手続中' THEN 1 END) AS PROCESSING_COUNT,
    COUNT(CASE WHEN c.CONTRACT_STATUS = 'キャンセル' THEN 1 END) AS CANCELLED_COUNT,
    COUNT(DISTINCT i.INSURANCE_ID) AS INSURANCE_COUNT,
    SUM(i.PREMIUM_AMOUNT) AS TOTAL_INSURANCE_PREMIUM,
    ROUND(COUNT(DISTINCT i.INSURANCE_ID) * 100.0 / NULLIF(COUNT(DISTINCT c.CONTRACT_ID), 0), 1) AS INSURANCE_ATTACH_RATE
FROM IDOM_HANDSON.RAW_DATA.CONTRACTS c
JOIN IDOM_HANDSON.RAW_DATA.STORES s ON c.STORE_ID = s.STORE_ID
LEFT JOIN IDOM_HANDSON.RAW_DATA.INSURANCE i ON c.CONTRACT_ID = i.CONTRACT_ID
WHERE c.CONTRACT_DATE IS NOT NULL
GROUP BY s.STORE_ID, s.STORE_NAME, s.REGION, s.PREFECTURE, s.STORE_TYPE,
         s.TARGET_MONTHLY_SALES, s.TARGET_MONTHLY_CONTRACTS,
         DATE_TRUNC('month', c.CONTRACT_DATE);

-- 確認: 作成されたデータを見てみましょう
SELECT STORE_NAME, CONTRACT_MONTH, CONTRACT_COUNT, TOTAL_SALES, INSURANCE_ATTACH_RATE
FROM IDOM_HANDSON.DATA_MART.DT_SALES_PERFORMANCE
ORDER BY CONTRACT_MONTH DESC, TOTAL_SALES DESC
LIMIT 20;

-- ============================================================
-- Step 2: Dynamic Table の状態確認
-- ============================================================
-- リフレッシュの状態や履歴を確認できます

SHOW DYNAMIC TABLES IN SCHEMA IDOM_HANDSON.DATA_MART;

SELECT *
FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY(
    NAME => 'IDOM_HANDSON.DATA_MART.DT_SALES_PERFORMANCE'
))
ORDER BY REFRESH_START_TIME DESC
LIMIT 5;

-- ============================================================
-- Step 3: ソースデータを更新して自動リフレッシュを体験
-- ============================================================
-- 新しい契約データを追加すると、Dynamic Table が自動で更新されます

-- 更新前の東京本店の件数を確認
SELECT STORE_NAME, CONTRACT_MONTH, CONTRACT_COUNT
FROM IDOM_HANDSON.DATA_MART.DT_SALES_PERFORMANCE
WHERE STORE_NAME = 'ガリバー東京本店'
ORDER BY CONTRACT_MONTH DESC LIMIT 3;

-- テスト用データを INSERT
INSERT INTO IDOM_HANDSON.RAW_DATA.CONTRACTS
(CONTRACT_ID, NEGOTIATION_ID, STORE_ID, CUSTOMER_NAME, CAR_NAME,
 CONTRACT_TYPE, CONTRACT_PRICE, TAX_AMOUNT, PAYMENT_METHOD,
 LOAN_AMOUNT, LOAN_TERM_MONTHS, CONTRACT_DATE, DELIVERY_DATE, CONTRACT_STATUS)
VALUES
('C9999', 'N9999', 'S001', 'テスト太郎', 'トヨタ プリウス',
 '現金一括', 3000000, 300000, '銀行振込',
 0, 0, '2026-04-08', '2026-04-20', '手続中');

-- 手動でリフレッシュ（target_lag を待たずに確認したい場合）
ALTER DYNAMIC TABLE IDOM_HANDSON.DATA_MART.DT_SALES_PERFORMANCE REFRESH;

-- 更新後の件数を確認（リフレッシュ完了後に実行）
SELECT STORE_NAME, CONTRACT_MONTH, CONTRACT_COUNT
FROM IDOM_HANDSON.DATA_MART.DT_SALES_PERFORMANCE
WHERE STORE_NAME = 'ガリバー東京本店'
ORDER BY CONTRACT_MONTH DESC LIMIT 3;
