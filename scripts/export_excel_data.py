"""Export data for the Excel operations workbook.
Grain: one row per delivered order per seller, Jan 2017 - Aug 2018."""
from pathlib import Path

from google.cloud import bigquery

PROJECT = "supply-chain-analytics-510105"
MARTS = f"{PROJECT}.dbt_dev_marts"
OUT_DIR = Path(__file__).resolve().parents[1] / "data" / "exports"
OUT_DIR.mkdir(parents=True, exist_ok=True)

client = bigquery.Client(project=PROJECT)

SELLER_ORDERS = f"""
select
    i.order_id,
    i.seller_id,
    s.seller_state,
    o.customer_state,
    o.purchase_date,
    d.week_start,
    if(o.is_on_time, 1, 0)                                 as on_time,
    if(o.is_on_time, 0, 1)                                 as late,
    if(logical_or(i.missed_shipping_deadline), 1, 0)       as missed_deadline,
    o.review_score,
    round(o.total_delivery_days, 1)                        as delivery_days

from `{MARTS}.fact_order_items` as i
inner join `{MARTS}.fact_orders` as o using (order_id)
inner join `{MARTS}.dim_sellers` as s using (seller_id)
inner join `{MARTS}.dim_date` as d on o.purchase_date = d.date_day
where o.is_delivered
  and o.is_in_analysis_window
group by 1, 2, 3, 4, 5, 6, 7, 8, 10, 11
"""

SELLERS = f"""
select seller_id, seller_city, seller_state
from `{MARTS}.dim_sellers`
"""

for name, sql in [("excel_seller_orders", SELLER_ORDERS), ("excel_sellers", SELLERS)]:
    df = client.query(sql).to_dataframe()
    df.to_csv(OUT_DIR / f"{name}.csv", index=False)
    print(f"{name:<22} {len(df):>8,} rows")