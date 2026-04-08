-- ============================================================
-- ハンズオン 3: Cortex Search Service の構築
-- ============================================================
-- Cortex Search は全文検索＋セマンティック検索を提供する
-- マネージドサービスです。商談活動履歴を検索可能にします。
--
-- V_ACTIVITY_LOGS ビュー（VARIANT展開済み）を CONTRACTS / STORES
-- と結合し、SEARCH_TEXT を動的に生成して Cortex Search に投入します。
-- 専用テーブルへの INSERT は不要です。
--
-- ステップ:
--   Step 1: V_ACTIVITY_LOGS の確認
--   Step 2: Cortex Search Service の作成
--   Step 3: テスト検索
-- ============================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;
USE SCHEMA IDOM_HANDSON.DATA_MART;

-- ============================================================
-- Step 1: V_ACTIVITY_LOGS の確認
-- ============================================================
-- ACTIVITY_LOGS テーブル（VARIANT/JSON）を展開した View です。
-- Cortex Search のソースとして直接利用します。

SELECT * FROM IDOM_HANDSON.RAW_DATA.V_ACTIVITY_LOGS LIMIT 5;

-- 件数確認
SELECT COUNT(*) AS LOG_COUNT FROM IDOM_HANDSON.RAW_DATA.V_ACTIVITY_LOGS;

-- ============================================================
-- Step 2: Cortex Search Service の作成
-- ============================================================
-- V_ACTIVITY_LOGS を CONTRACTS / STORES と JOIN し、
-- 店舗名・地域・車種名・商談ステータスなどのメタデータを補完。
-- SEARCH_TEXT は CONCAT で動的に生成します。

CREATE OR REPLACE CORTEX SEARCH SERVICE IDOM_HANDSON.DATA_MART.ACTIVITY_SEARCH
    ON SEARCH_TEXT
    ATTRIBUTES NEGOTIATION_ID, STORE_NAME, REGION, CUSTOMER_NAME, CAR_NAME,
               CONTRACT_STATUS, ASSIGNED_USER_NAME, ACTIVITY_TYPE, SUBJECT
    WAREHOUSE = COMPUTE_WH
    TARGET_LAG = '1 hour'
AS (
    SELECT
        A.ACTIVITY_ID,
        A.NEGOTIATION_ID,
        A.STORE_ID,
        S.STORE_NAME,
        S.REGION,
        A.CUSTOMER_NAME,
        C.CAR_NAME,
        C.CONTRACT_STATUS,
        A.ASSIGNED_USER_NAME,
        A.ACTIVITY_TYPE,
        A.ACTIVITY_DATE,
        A.SUBJECT,
        CONCAT(
            '【商談ID】', A.NEGOTIATION_ID,
            ' 【顧客名】', A.CUSTOMER_NAME,
            ' 【車両】', COALESCE(C.CAR_NAME, '不明'),
            ' 【店舗】', COALESCE(S.STORE_NAME, '不明'), '(', COALESCE(S.REGION, ''), ')',
            ' 【担当】', A.ASSIGNED_USER_NAME,
            ' 【商談ステータス】', COALESCE(C.CONTRACT_STATUS, '不明'),
            ' 【活動種別】', A.ACTIVITY_TYPE,
            ' 【日時】', TO_VARCHAR(A.ACTIVITY_DATE, 'YYYY-MM-DD HH24:MI'),
            ' 【件名】', A.SUBJECT,
            ' 【内容】', A.BODY
        ) AS SEARCH_TEXT
    FROM IDOM_HANDSON.RAW_DATA.V_ACTIVITY_LOGS A
    LEFT JOIN IDOM_HANDSON.RAW_DATA.CONTRACTS C
        ON A.NEGOTIATION_ID = C.NEGOTIATION_ID
    LEFT JOIN IDOM_HANDSON.RAW_DATA.STORES S
        ON A.STORE_ID = S.STORE_ID
);

-- ============================================================
-- Step 3: テスト検索
-- ============================================================
-- Cortex Search Service をSQL関数で呼び出してみましょう

-- 検索1: 成約した案件の経緯を検索
SELECT PARSE_JSON(
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'IDOM_HANDSON.DATA_MART.ACTIVITY_SEARCH',
        '{
            "query": "成約した商談の経緯を教えてください",
            "columns": ["ACTIVITY_ID", "CUSTOMER_NAME", "SUBJECT", "CONTRACT_STATUS"],
            "limit": 5
        }'
    )
) AS SEARCH_RESULT;

-- 検索2: 価格交渉に関する活動を検索
SELECT PARSE_JSON(
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'IDOM_HANDSON.DATA_MART.ACTIVITY_SEARCH',
        '{
            "query": "価格交渉や値引き交渉の記録",
            "columns": ["ACTIVITY_ID", "CUSTOMER_NAME", "CAR_NAME", "SUBJECT"],
            "limit": 5
        }'
    )
) AS SEARCH_RESULT;

-- 検索3: 特定の顧客の活動を検索
SELECT PARSE_JSON(
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'IDOM_HANDSON.DATA_MART.ACTIVITY_SEARCH',
        '{
            "query": "上田浩二さんとのやりとり",
            "columns": ["ACTIVITY_ID", "SUBJECT", "ACTIVITY_TYPE", "CONTRACT_STATUS"],
            "limit": 5
        }'
    )
) AS SEARCH_RESULT;
