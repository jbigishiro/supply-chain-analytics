"""Ask-the-data assistant: plain-English question -> BigQuery SQL -> answer.

Usage (from the repo root):
    python assistant/sql_assistant.py "What is the on-time rate in Bahia?"

Needs OPENAI_API_KEY in the environment or in a .env file at the repo root (never commit it).
Optional: OPENAI_MODEL (default gpt-4o-mini).
"""
import os
import re
import sys
from functools import lru_cache

import openai
from dotenv import load_dotenv
from google.cloud import bigquery

load_dotenv()

PROJECT = "supply-chain-analytics-510105"
DATASET = f"{PROJECT}.dbt_dev_marts"
TABLES = ["fact_orders", "fact_order_items", "dim_customers", "dim_sellers", "dim_products", "dim_date"]
MODEL = os.environ.get("OPENAI_MODEL", "gpt-4o-mini")
MAX_BYTES = 1_000_000_000  # 1 GB cap per query (the marts are ~50 MB)

BUSINESS_RULES = f"""
Business rules (always follow unless the question explicitly says otherwise):
- Grain: fact_orders has one row per order; fact_order_items has one row per item.
  When counting orders from fact_order_items use count(distinct order_id), and when computing
  seller- or category-level averages of order fields (is_on_time, review_score, delivery days),
  first deduplicate to one row per (seller or category, order_id).
- Analysis window: metrics (rates, averages, revenue, review scores, anything by month) only use
  orders with is_in_analysis_window = true. Plain record counts (how many orders, sellers,
  customers, orders by status or by weekday) use all rows.
- Delivery metrics (on-time rate, late rate, delivery days, days_late, stage durations,
  missed shipping deadline) only use orders with is_delivered = true.
- On-time rate = avg(if(is_on_time, 1, 0)). A late order is a delivered order where is_on_time is false.
- Revenue: exclude order_status in ('canceled', 'unavailable'). GMV = sum(order_value) from
  fact_orders; product or category revenue = sum(price) from fact_order_items.
- Fulfillment stages: approval_days, seller_processing_days, carrier_transit_days, total_delivery_days.
- Distance per order = max(distance_km) over its items in fact_order_items.
- Category names are in English in dim_products.category_name.
- dim_customers has one row per person (customer_unique_id); is_repeat_customer flags people with
  more than one order.
- Months: use purchase_month (a DATE, first day of the month) from fact_orders.
- Return rates as fractions between 0 and 1, not percentages.
"""

EXAMPLES = f"""
Examples:

Question: What is the average carrier transit time for customers in São Paulo?
```sql
select avg(carrier_transit_days) as avg_transit_days
from `{DATASET}.fact_orders`
where customer_state = 'SP' and is_delivered and is_in_analysis_window
```

Question: How many delivered orders has each seller handled?
```sql
select i.seller_id, count(distinct i.order_id) as delivered_orders
from `{DATASET}.fact_order_items` as i
inner join `{DATASET}.fact_orders` as o using (order_id)
where o.is_delivered and o.is_in_analysis_window
group by i.seller_id
```

Question: What was the average order value each month in 2018?
```sql
select purchase_month, avg(order_value) as avg_order_value
from `{DATASET}.fact_orders`
where is_in_analysis_window
  and order_status not in ('canceled', 'unavailable')
  and extract(year from purchase_month) = 2018
group by purchase_month
order by purchase_month
```
"""

RULES_V2 = """
Column semantics and SQL hygiene (added in prompt v2 after error analysis):
- Before writing the query, decide which filters apply:
  (1) a delivery metric -> is_delivered = true;
  (2) any rate, average, total or anything by month -> is_in_analysis_window = true;
  (3) revenue, GMV or order value -> also exclude order_status in ('canceled', 'unavailable').
  Apply (3) only to money metrics, never to counts, review scores or delivery metrics.
- days_late = delivery date minus estimated date, in days. It is NEGATIVE when an order arrives
  early. An order is on time when days_late <= 0. Delivery columns are NULL for undelivered orders.
- When grouping values into bands with CASE, exclude NULLs in WHERE (or give them their own band);
  never let NULLs fall into the ELSE branch.
- fact_order_items repeats several order-level columns (is_delivered, is_on_time, days_late,
  is_in_analysis_window, customer_state, purchase_date, freight_value). When joining tables,
  prefix every column with its table alias and take order-level fields from fact_orders.
- Attributes live in dimensions: seller_state / seller_city only in dim_sellers (join on seller_id);
  category_name and product size only in dim_products (join on product_id). The customer
  location of an order is fact_orders.customer_state.
- When comparing groups (late vs on time, by state, by band), return one row per group.
- Use BigQuery Standard SQL functions only, and never use reserved words (current, order, group) as aliases.
"""

FORBIDDEN = re.compile(r"\b(insert|update|delete|merge|drop|create|alter|truncate|grant|revoke)\b", re.I)


class UnsafeQuery(Exception):
    """Raised when generated SQL is not a single read-only query or would scan too much data."""


bq = bigquery.Client(project=PROJECT)
llm = openai.OpenAI()


@lru_cache(maxsize=1)
def schema_text() -> str:
    """Table and column list, read live from BigQuery so it never goes stale."""
    sql = f"""
        select table_name, column_name, data_type
        from `{DATASET}.INFORMATION_SCHEMA.COLUMNS`
        where table_name in unnest(@tables)
        order by table_name, ordinal_position
    """
    cfg = bigquery.QueryJobConfig(query_parameters=[bigquery.ArrayQueryParameter("tables", "STRING", TABLES)])
    df = bq.query(sql, job_config=cfg).to_dataframe()
    lines = []
    for table, cols in df.groupby("table_name", sort=False):
        lines.append(f"{table}(" + ", ".join(f"{c} {t}" for c, t in zip(cols.column_name, cols.data_type)) + ")")
    return "\n".join(lines)


PROMPTS = {
    "none": "",                                   # schema only (ablation)
    "v1": BUSINESS_RULES + EXAMPLES,              # business rules
    "v2": BUSINESS_RULES + RULES_V2 + EXAMPLES,   # + column semantics and SQL hygiene
}


def system_prompt(version: str = "v2") -> str:
    return (
        "You translate questions from an operations manager into one BigQuery Standard SQL query "
        "against an e-commerce fulfillment star schema.\n\n"
        f"Always reference tables with their full path: `{DATASET}.<table>`.\n\n"
        f"Tables:\n{schema_text()}\n"
        + PROMPTS[version]
        + "\nAnswer with a single read-only SQL query in a ```sql code block and nothing else."
    )


def generate_sql(question: str, version: str = "v2") -> str:
    messages = [
        {"role": "system", "content": system_prompt(version)},
        {"role": "user", "content": question},
    ]
    try:
        resp = llm.chat.completions.create(model=MODEL, messages=messages, temperature=0)
    except openai.BadRequestError:
        # some newer models don't accept a temperature setting
        resp = llm.chat.completions.create(model=MODEL, messages=messages)
    text = resp.choices[0].message.content or ""
    match = re.search(r"```(?:sql)?\s*(.*?)```", text, re.S | re.I)
    return (match.group(1) if match else text).strip().rstrip(";").strip()


def check_safe(sql: str) -> None:
    """Allow only one SELECT/WITH statement, then let BigQuery validate it with a free dry run."""
    if not re.match(r"^\s*(select|with)\b", sql, re.I):
        raise UnsafeQuery("query must start with SELECT or WITH")
    if ";" in sql:
        raise UnsafeQuery("multiple statements are not allowed")
    if FORBIDDEN.search(sql):
        raise UnsafeQuery("query contains a write or DDL keyword")
    job = bq.query(sql, job_config=bigquery.QueryJobConfig(dry_run=True, use_query_cache=False))
    if job.total_bytes_processed > MAX_BYTES:
        raise UnsafeQuery(f"query would scan {job.total_bytes_processed:,} bytes")


def run_sql(sql: str):
    check_safe(sql)
    cfg = bigquery.QueryJobConfig(maximum_bytes_billed=MAX_BYTES)
    return bq.query(sql, job_config=cfg).to_dataframe()


def ask(question: str, version: str = "v2"):
    sql = generate_sql(question, version)
    return sql, run_sql(sql)


if __name__ == "__main__":
    question = " ".join(sys.argv[1:]) or "What is the on-time rate?"
    sql, df = ask(question)
    print(sql, "\n")
    print(df.to_string(index=False))