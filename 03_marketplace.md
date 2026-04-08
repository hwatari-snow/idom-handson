# ハンズオン 1.3: Snowflake Marketplace で外部データを取得

## 概要

Snowflake Marketplace から外部データセット（天気データ）を取得し、
売上実績 Dynamic Table と組み合わせて分析する体験です。

---

## Step 1: Marketplace にアクセス

1. Snowsight の左メニューから **「Data Products」** → **「Marketplace」** をクリック
2. 検索バーに **「Weather Source」** と入力

## Step 2: 無料データセットを取得

1. **「Weather Source LLC - Global Weather & Climate Data for BI」** を選択
   - (無料の "Standard" 版で OK)
2. **「Get」** ボタンをクリック
3. データベース名はデフォルトのまま **「Get」** で確定
4. 数秒で `WEATHERSOURCE` データベースが作成されます

> **注意**: Marketplace データの利用にはアカウントの Terms of Service への同意が必要です

## Step 3: 取得したデータを確認

```sql
-- Weather Source のテーブル一覧を確認
SHOW SCHEMAS IN DATABASE WEATHERSOURCE;

-- 天気データの中身を確認（テーブル名は取得したデータセットにより異なります）
-- 例: 日別の天気データ
SELECT *
FROM WEATHERSOURCE.STANDARD_TILE.HISTORY_DAY
WHERE COUNTRY = 'JP'
LIMIT 10;
```

## Step 4: 売上データと天気データを結合した Dynamic Table（参考）

```sql
-- 天気が売上に影響するかを分析するDynamic Tableの例
-- ※テーブル名・カラム名は実際のMarketplaceデータに合わせて調整してください

CREATE OR REPLACE DYNAMIC TABLE IDOM_HANDSON.DATA_MART.DT_SALES_WITH_WEATHER
    TARGET_LAG = '1 day'
    WAREHOUSE = COMPUTE_WH
AS
SELECT
    sp.*,
    w.AVG_TEMPERATURE_AIR_2M_F AS AVG_TEMP,
    w.TOT_PRECIPITATION_IN AS PRECIPITATION,
    w.TOT_SNOWFALL_IN AS SNOWFALL
FROM IDOM_HANDSON.DATA_MART.DT_SALES_PERFORMANCE sp
LEFT JOIN WEATHERSOURCE.STANDARD_TILE.HISTORY_DAY w
    ON w.DATE_VALID_STD = sp.CONTRACT_MONTH
    AND w.COUNTRY = 'JP'
    AND w.CITY_NAME = sp.PREFECTURE;
```

---

## Marketplace の活用ポイント

| カテゴリ | データ例 | 活用シーン |
|---------|---------|-----------|
| 天気 | Weather Source | 天候と来店数の相関分析 |
| 経済指標 | Cybersyn | 景気指標と売上トレンドの比較 |
| 人口統計 | Knoema | 店舗周辺の人口動態分析 |
| 自動車 | 各種リスティング | 中古車市場相場の参照 |

> Marketplace データは**コピーではなくライブ共有**のため、
> 提供元が更新すると自動で最新データが反映されます。
> Dynamic Table と組み合わせることで、外部データを含む
> エンドツーエンドのパイプラインを構築できます。
