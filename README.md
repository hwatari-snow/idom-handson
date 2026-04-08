# Snowflake ハンズオン

## 概要

2時間 Snowflake ハンズオン教材です。  
中古車販売データを使って、Snowflake のデータパイプライン構築から AI Agent 作成までを体験します。

## 前提条件

- Snowflake アカウント（ACCOUNTADMIN ロール）
- ウェアハウス: COMPUTE_WH

## タイムテーブル

| 時間 | セクション | 内容 | ファイル |
|------|-----------|------|---------|
| 0:00 - 0:10 | セットアップ | DB・テーブル・サンプルデータ作成 | `00_setup.sql` |
| 0:10 - 0:35 | 1.1 Dynamic Table | 段階的にDTを構築、target_lag体験 | `01_dynamic_table.sql` |
| 0:35 - 1:00 | 1.2 AI SQL | Cortex AI Functions 6種を体験 | `02_ai_sql.sql` |
| 1:00 - 1:10 | 1.3 Marketplace | 外部データ取得・結合 | `03_marketplace.md` |
| 1:10 - 1:30 | 2.1 Streamlit | Cortex Code で売上ダッシュボード作成 | `04_streamlit_guide.md` / `04_streamlit_app.py` |
| 1:30 - 1:45 | 3.1 Cortex Search | 検索サービス構築 | `05_cortex_search.sql` |
| 1:45 - 2:00 | 3.2 AI Agent | Semantic View + Agent 構築 | `06_agent.sql` |

## ファイル一覧

| ファイル | 説明 |
|---------|------|
| `00_setup.sql` | 環境セットアップ（DB, テーブル, サンプルデータ 約4300行） |
| `01_dynamic_table.sql` | Dynamic Table ハンズオン（4ステップ + おまけ） |
| `02_ai_sql.sql` | Cortex AI Functions ハンズオン（6関数） |
| `03_marketplace.md` | Marketplace 操作手順ガイド |
| `04_streamlit_guide.md` | Cortex Code でのStreamlit作成ガイド |
| `04_streamlit_app.py` | 完成形の Streamlit アプリコード |
| `05_cortex_search.sql` | Cortex Search Service 構築ハンズオン |
| `06_agent.sql` | Semantic View + Cortex Agent 構築ハンズオン |

## 実行順序

```
00_setup.sql → 01_dynamic_table.sql → 02_ai_sql.sql → 03_marketplace.md
→ 04_streamlit_guide.md → 05_cortex_search.sql → 06_agent.sql
```

## 使用データ

IDOM_HANDSON データベースに以下のテーブルが作成されます:

| テーブル | 件数 | 内容 |
|---------|------|------|
| STORES | 10 | 店舗マスタ（東京・大阪・名古屋・仙台等） |
| USERS | 20 | 営業担当者マスタ |
| RECEPTIONS | 500 | 来店受付データ |
| VISITS | 800 | 訪問・来店データ |
| NEGOTIATIONS | 600 | 商談データ |
| CONTRACTS | 231 | 契約データ |
| INSURANCE | 125 | 保険付帯データ |
| LINE_MESSAGES | 1500 | LINE メッセージデータ |
| ACTIVITY_LOGS | 79 | 商談活動履歴 |

## ハンズオンで構築するオブジェクト

| オブジェクト | スキーマ | 種別 |
|-------------|---------|------|
| DT_SALES_PERFORMANCE | DATA_MART | Dynamic Table |
| ACTIVITY_SEARCH_CHUNKS | DATA_MART | Table |
| ACTIVITY_SEARCH | DATA_MART | Cortex Search Service |
| SV_SALES_PERFORMANCE | DATA_MART | Semantic View |
| IDOM_SALES_AGENT | AGENTS | Cortex Agent |

## クリーンアップ

ハンズオン終了後、以下を実行して環境を削除できます:

```sql
DROP DATABASE IF EXISTS IDOM_HANDSON;
```
