-- ============================================================
-- ハンズオン 1.2: Cortex AI Functions で商談データを分析
-- ============================================================
-- Snowflake Cortex の AI 関数を使って、
-- 商談活動履歴（ACTIVITY_LOGS）をSQL だけで AI 分析します。
--
-- ACTIVITY_LOGS は半構造化データ（VARIANT型・JSON）で格納されています。
-- まず JSON からカラムを展開する方法を学び、その後 AI 分析を行います。
--
-- 体験する内容:
--   Step 0: 半構造化データの確認と展開
--   Step 1: CLASSIFY_TEXT - テキスト分類
--   Step 2: COMPLETE    - AI 営業コーチ（次のアクション提案）
-- ============================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;
USE SCHEMA IDOM_HANDSON.RAW_DATA;

-- ============================================================
-- Step 0: 半構造化データの確認と展開
-- ============================================================
-- ACTIVITY_LOGS テーブルは VARIANT 型の RAW_DATA カラム1列に
-- JSON オブジェクトとしてデータが格納されています。
-- まずそのまま中身を確認してみましょう。

SELECT RAW_DATA
FROM ACTIVITY_LOGS
LIMIT 3;

-- VARIANT 型からは「:」でキーを指定してアクセスできます
SELECT
    RAW_DATA:activity_id::VARCHAR AS ACTIVITY_ID,
    RAW_DATA:customer_name::VARCHAR AS CUSTOMER_NAME,
    RAW_DATA:activity_type::VARCHAR AS ACTIVITY_TYPE,
    RAW_DATA:subject::VARCHAR AS SUBJECT,
    LEFT(RAW_DATA:body::VARCHAR, 100) || '...' AS BODY_PREVIEW
FROM ACTIVITY_LOGS
ORDER BY ACTIVITY_ID
LIMIT 10;

-- 便利なビューを作成しておきましょう
CREATE OR REPLACE VIEW IDOM_HANDSON.RAW_DATA.V_ACTIVITY_LOGS AS
SELECT
    RAW_DATA:activity_id::VARCHAR AS ACTIVITY_ID,
    RAW_DATA:negotiation_id::VARCHAR AS NEGOTIATION_ID,
    RAW_DATA:store_id::VARCHAR AS STORE_ID,
    RAW_DATA:customer_name::VARCHAR AS CUSTOMER_NAME,
    RAW_DATA:assigned_user_name::VARCHAR AS ASSIGNED_USER_NAME,
    RAW_DATA:activity_type::VARCHAR AS ACTIVITY_TYPE,
    RAW_DATA:activity_date::TIMESTAMP_NTZ AS ACTIVITY_DATE,
    RAW_DATA:subject::VARCHAR AS SUBJECT,
    RAW_DATA:body::VARCHAR AS BODY,
    RAW_DATA:created_at::TIMESTAMP_NTZ AS CREATED_AT
FROM ACTIVITY_LOGS;

-- ビュー経由で確認
SELECT * FROM V_ACTIVITY_LOGS ORDER BY ACTIVITY_ID LIMIT 10;

-- ============================================================
-- Step 1: CLASSIFY_TEXT - 商談フェーズの自動分類
-- ============================================================
-- 活動内容を事前定義のカテゴリに自動分類

SELECT
    ACTIVITY_ID,
    CUSTOMER_NAME,
    SUBJECT,
    BODY,
    SNOWFLAKE.CORTEX.CLASSIFY_TEXT(
        BODY,
        ['初回問合せ', '商談進行中', '価格交渉', '成約', '失注・見送り']
    ):label::VARCHAR AS CLASSIFIED_PHASE
FROM V_ACTIVITY_LOGS
ORDER BY ACTIVITY_ID;

-- ============================================================
-- Step 2: COMPLETE - AI 営業コーチ
-- ============================================================
-- LLM が商談活動を読み取り、担当営業へ「次にやるべきアクション」を
-- 具体的にアドバイスしてくれます。まるで AI コーチが隣にいるような体験！

SELECT
    ACTIVITY_ID,
    CUSTOMER_NAME,
    SUBJECT,
    SNOWFLAKE.CORTEX.COMPLETE(
        'llama3.1-70b',
        'あなたは中古車販売のトップ営業コンサルタントです。' ||
        '以下の商談活動記録を読んで、担当営業マンへ次にやるべき具体的なアクションを' ||
        '3つ箇条書き（各30文字以内）で日本語でアドバイスしてください。' ||
        '絵文字を1つずつ付けてください。\n\n' ||
        '【件名】' || SUBJECT || '\n' ||
        '【内容】' || BODY
    ) AS AI_COACHING
FROM V_ACTIVITY_LOGS
WHERE ACTIVITY_ID IN ('ACT0001', 'ACT0006', 'ACT0011', 'ACT0016', 'ACT0020')
ORDER BY ACTIVITY_ID;
