# IDOM Snowflake ハンズオン

## 概要

中古車販売データを使って、Snowflake のデータパイプライン構築から AI Agent 作成までを体験する 2日間のハンズオン教材です。

## 前提条件

- Snowflake アカウント（ACCOUNTADMIN ロール）
- ウェアハウス: `COMPUTE_WH`

## 構成（Day 1 / Day 2）

### Day 1 — データパイプライン & AI 分析基盤

| セクション | 内容 |
|-----------|------|
| 0. セットアップ | DB・スキーマ・テーブル・サンプルデータ作成 |
| 1. Dynamic Table | 宣言的データパイプライン構築、自動リフレッシュ体験 |
| 2. Cortex AI Functions | VARIANT/JSON 展開、CLASSIFY_TEXT / COMPLETE 体験 |
| 3. Marketplace | Weather Source（天気データ）の取得 |

### Day 2 — AI エージェント構築

| セクション | 内容 |
|-----------|------|
| 1. Cortex Search Service | 商談活動履歴のセマンティック検索 |
| 2. Cortex Analyst | Semantic View で構造化データに意味づけ層を定義 |
| 3. Cortex Agent | 構造化 × 非構造化データを統合した AI エージェント |

## ファイル一覧

| ファイル | 説明 |
|---------|------|
| `00_setup.sql` | 環境セットアップ（DB, 4テーブル, サンプルデータ, Git API Integration） |
| `DAY1_NOTEBOOK.ipynb` | Day 1 Notebook（Dynamic Table / AI Functions / Marketplace） |
| `DAY2_NOTEBOOK.ipynb` | Day 2 Notebook（Cortex Search / Cortex Analyst / Cortex Agent） |
| `streamlit_guide.md` | Cortex Code での Streamlit ダッシュボード作成ガイド |
| `streamlit_app.py` | 完成形の Streamlit アプリコード（参考用） |

## 実行順序

```
00_setup.sql → DAY1_NOTEBOOK.ipynb → (Streamlit) → DAY2_NOTEBOOK.ipynb
```

## 使用データ

`IDOM_HANDSON.RAW_DATA` スキーマに以下の4テーブルが作成されます:

| テーブル | 件数 | 内容 |
|---------|------|------|
| STORES | 50 | 店舗マスタ（東京・大阪・名古屋・仙台など全国） |
| CONTRACTS | 1,201 | 契約データ（車種・金額・ステータス） |
| INSURANCE | 625 | 保険付帯データ |
| ACTIVITY_LOGS | 2,000 | 商談活動履歴（VARIANT/JSON） |

## ハンズオンで構築するオブジェクト

| オブジェクト | スキーマ | 種別 |
|-------------|---------|------|
| V_ACTIVITY_LOGS | RAW_DATA | View（JSON展開） |
| DT_SALES_PERFORMANCE | DATA_MART | Dynamic Table |
| ACTIVITY_SEARCH | DATA_MART | Cortex Search Service |
| SV_SALES_PERFORMANCE | DATA_MART | Semantic View |
| IDOM_SALES_AGENT | AGENTS | Cortex Agent |

## クリーンアップ

```sql
DROP DATABASE IF EXISTS IDOM_HANDSON;
```
