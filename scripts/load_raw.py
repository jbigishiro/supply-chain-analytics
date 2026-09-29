"""Load the 9 Olist CSVs from data/raw into BigQuery dataset olist_raw.

Every column is loaded as STRING on purpose: the raw layer mirrors the source
files exactly, and types are cast later in the dbt staging models.
Safe to re-run: each table is replaced.
"""
import csv
from pathlib import Path

from google.cloud import bigquery

PROJECT = "supply-chain-analytics-510105"
DATASET = "olist_raw"
RAW_DIR = Path(__file__).resolve().parents[1] / "data" / "raw"

client = bigquery.Client(project=PROJECT)

for csv_path in sorted(RAW_DIR.glob("*.csv")):
    # olist_orders_dataset.csv -> orders
    table = csv_path.stem.removeprefix("olist_").removesuffix("_dataset")

    with open(csv_path, encoding="utf-8-sig", newline="") as f:
        header = next(csv.reader(f))
    schema = [bigquery.SchemaField(col.strip(), "STRING") for col in header]

    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=1,
        schema=schema,
        allow_quoted_newlines=True,  # review comments contain line breaks
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
    )

    table_id = f"{PROJECT}.{DATASET}.{table}"
    with open(csv_path, "rb") as f:
        client.load_table_from_file(f, table_id, job_config=job_config).result()

    rows = client.get_table(table_id).num_rows
    print(f"{table:<35} {rows:>10,} rows")