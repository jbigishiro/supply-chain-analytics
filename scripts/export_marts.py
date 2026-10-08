"""Export the dbt mart tables from BigQuery to CSV for Tableau Public,
which cannot connect to BigQuery directly. Re-run after `dbt build` to refresh."""
from pathlib import Path

from google.cloud import bigquery

PROJECT = "supply-chain-analytics-510105"
DATASET = "dbt_dev_marts"
TABLES = [
    "fact_orders",
    "fact_order_items",
    "dim_customers",
    "dim_sellers",
    "dim_products",
    "dim_date",
]
OUT_DIR = Path(__file__).resolve().parents[1] / "data" / "exports"
OUT_DIR.mkdir(parents=True, exist_ok=True)

client = bigquery.Client(project=PROJECT)

for table in TABLES:
    df = client.query(f"select * from `{PROJECT}.{DATASET}.{table}`").to_dataframe()
    path = OUT_DIR / f"{table}.csv"
    df.to_csv(path, index=False)
    print(f"{table:<20} {len(df):>8,} rows -> {path.name}")