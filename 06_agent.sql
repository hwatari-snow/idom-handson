-- ============================================================
-- ハンズオン 3: AI Agent の構築
-- ============================================================
-- Semantic View で構造化データを自然言語クエリ可能にし、
-- Cortex Agent で Semantic View + Cortex Search を統合します。
--
-- 構成:
--   - Semantic View: SV_SALES_PERFORMANCE（売上実績分析）
--   - Cortex Agent: 2ツール構成
--     1. sales_performance_analyst（構造化データ分析）
--     2. activity_search（商談活動履歴の検索）
-- ============================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;

-- ============================================================
-- Step 1: Semantic View の作成
-- ============================================================
-- Semantic View は Dynamic Table の上に「意味付け」を行うレイヤーです。
-- カラムを facts（数値）、dimensions（分析軸）、metrics（集計指標）に分類し、
-- AI が自然言語から正しいSQLを生成できるようにします。

USE SCHEMA IDOM_HANDSON.DATA_MART;

CREATE OR REPLACE SEMANTIC VIEW IDOM_HANDSON.DATA_MART.SV_SALES_PERFORMANCE
    tables (
        SALES as IDOM_HANDSON.DATA_MART.DT_SALES_PERFORMANCE
            primary key (STORE_ID, CONTRACT_MONTH)
            comment = '店舗別月別の売上実績データ'
    )
    facts (
        SALES.CONTRACT_COUNT_FACT as CONTRACT_COUNT comment = '成約件数',
        SALES.TOTAL_SALES_FACT as TOTAL_SALES comment = '売上合計金額（円）',
        SALES.AVG_CONTRACT_PRICE_FACT as AVG_CONTRACT_PRICE comment = '平均契約単価（円）',
        SALES.TOTAL_LOAN_AMOUNT_FACT as TOTAL_LOAN_AMOUNT comment = 'ローン総額',
        SALES.DELIVERED_COUNT_FACT as DELIVERED_COUNT comment = '納車済み件数',
        SALES.PROCESSING_COUNT_FACT as PROCESSING_COUNT comment = '手続中件数',
        SALES.CANCELLED_COUNT_FACT as CANCELLED_COUNT comment = 'キャンセル件数',
        SALES.INSURANCE_COUNT_FACT as INSURANCE_COUNT comment = '保険付帯件数',
        SALES.TOTAL_INSURANCE_PREMIUM_FACT as TOTAL_INSURANCE_PREMIUM comment = '保険料合計',
        SALES.INSURANCE_ATTACH_RATE_FACT as INSURANCE_ATTACH_RATE comment = '保険付帯率',
        SALES.TARGET_MONTHLY_SALES_FACT as TARGET_MONTHLY_SALES comment = '月間売上目標',
        SALES.TARGET_MONTHLY_CONTRACTS_FACT as TARGET_MONTHLY_CONTRACTS comment = '月間成約目標件数'
    )
    dimensions (
        SALES.STORE_ID_DIM as STORE_ID comment = '店舗ID',
        SALES.STORE_NAME_DIM as STORE_NAME with synonyms = ('店舗') comment = '店舗名',
        SALES.REGION_DIM as REGION with synonyms = ('エリア') comment = '地域',
        SALES.PREFECTURE_DIM as PREFECTURE comment = '都道府県',
        SALES.STORE_TYPE_DIM as STORE_TYPE comment = '店舗タイプ',
        SALES.CONTRACT_MONTH_DIM as CONTRACT_MONTH with synonyms = ('月', '年月') comment = '契約月'
    )
    metrics (
        SALES.TOTAL_MONTHLY_SALES as SUM(total_sales_fact) comment = '月間売上合計',
        SALES.TOTAL_MONTHLY_CONTRACTS as SUM(contract_count_fact) comment = '月間成約数合計',
        SALES.AVG_INSURANCE_RATE as AVG(insurance_attach_rate_fact) comment = '平均保険付帯率'
    )
    comment = 'IDOM売上実績分析用セマンティックビュー';

-- 確認: Semantic View の構造を表示
DESCRIBE SEMANTIC VIEW IDOM_HANDSON.DATA_MART.SV_SALES_PERFORMANCE;

-- ============================================================
-- Step 2: Cortex Agent の作成
-- ============================================================
-- 2つのツールを組み合わせた AI エージェントを作成:
--   1. sales_performance_analyst: 売上の数値分析（Semantic View経由）
--   2. activity_search: 商談活動履歴の全文検索（Cortex Search経由）

USE SCHEMA IDOM_HANDSON.AGENTS;

CREATE OR REPLACE AGENT IDOM_HANDSON.AGENTS.IDOM_SALES_AGENT
FROM SPECIFICATION
$$
models:
  orchestration: "auto"
orchestration:
  budget:
    seconds: 900
    tokens: 400000
instructions:
  response: "日本語で回答してください。数値データはテーブル形式で見やすく表示し、活動履歴の引用時は具体的な日時と内容を含めてください。"
  orchestration: >
    あなたはIDOMガリバーの営業分析アシスタントです。
    構造化データ（売上実績）と非構造化データ（商談活動履歴）の両方を活用して、
    営業チームの意思決定を支援します。

    質問の種類に応じて適切なツールを使い分けてください：
    - 売上実績・契約件数・保険付帯率などの数値分析 → sales_performance_analyst
    - 顧客との商談経緯・対応履歴・やり取りの詳細 → activity_search

    特にactivity_searchは以下のような質問に使ってください：
    - 「○○さんの商談の経緯を教えて」
    - 「価格交渉はどのように進んだ？」
    - 「なぜ失注したのか詳しく教えて」
    - 「LINEでのやり取りの内容は？」
    - 「担当者の対応内容を確認したい」

    数値データと活動履歴を組み合わせて回答することで、より深いインサイトを提供してください。
tools:
  - tool_spec:
      type: "cortex_analyst_text_to_sql"
      name: "sales_performance_analyst"
      description: >
        店舗別・月別の売上実績、契約件数、平均契約単価、保険付帯率、
        目標達成率などの構造化データを分析します。
        売上トレンド、地域別実績比較、保険クロスセル分析に使用してください。
  - tool_spec:
      type: "cortex_search"
      name: "activity_search"
      description: >
        商談の活動履歴（電話メモ、メール内容、来店対応記録、LINE対話、
        社内メモ、契約手続き記録）を全文検索します。
        顧客名、車種名、店舗名、担当者名、商談ステータスで絞り込めます。
tool_resources:
  sales_performance_analyst:
    execution_environment:
      query_timeout: 299
      type: "warehouse"
      warehouse: ""
    semantic_view: "IDOM_HANDSON.DATA_MART.SV_SALES_PERFORMANCE"
  activity_search:
    execution_environment:
      query_timeout: 299
      type: "warehouse"
      warehouse: ""
    search_service: "IDOM_HANDSON.DATA_MART.ACTIVITY_SEARCH"
$$;

-- ============================================================
-- Step 3: Agent をテスト
-- ============================================================
-- Snowsight の Agents ページからテストできます:
--   左メニュー → AI & ML → Agents → IDOM_SALES_AGENT

-- サンプル質問:
-- 「売上が一番高い店舗はどこ？」
-- 「地域別の契約件数を教えて」
-- 「上田浩二さんの商談はどのように進みましたか？」
-- 「価格交渉で失注した案件の詳細を教えて」
-- 「東京本店の保険付帯率は？」
