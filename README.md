
# Supply Chain Analytics

![dbt CI](https://github.com/jbigishiro/supply-chain-analytics/actions/workflows/dbt-ci.yml/badge.svg)

End-to-end fulfillment analytics on 100k Olist e-commerce orders: a tested cloud data
warehouse, delivery-performance analysis, dashboards, and predictive models that answer
one question for a Head of Operations — **how reliably do we deliver on our promise,
and what should we change?**

## The business problem

On an e-commerce marketplace, what customers remember is whether the package arrived
when promised. Every order leaves a trail of timestamps — purchase, approval, handoff
to the carrier, delivery — compared against the date the customer was promised. This
project turns that trail into trusted metrics, explains where and why orders run late,
and connects delivery performance to customer satisfaction and repeat purchases.

Stakeholders, questions in scope, data limits, and every analysis decision are recorded
in the **[scoping document](docs/scoping.md)**.

## Dataset

[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
— about 99k real orders placed between 2016 and 2018, across nine linked tables
(orders, items, customers, sellers, products, payments, reviews, geolocation, category
translation). Licensed CC BY-NC-SA 4.0 by Olist.

## Architecture

```
Kaggle CSVs ──► BigQuery (olist_raw) ──► dbt: staging ──► intermediate ──► marts ──► SQL analysis / dashboards / models
                 all columns STRING        cast & rename    business logic    star schema
```

| Layer | Models | Purpose |
|---|---|---|
| Raw | 9 tables in `olist_raw` | Loaded by [`scripts/load_raw.py`](scripts/load_raw.py) with every column as STRING, so nothing is altered on the way in (e.g. leading zeros in zip codes survive) |
| Staging | 9 `stg_` views | One model per source table: types cast, columns renamed, nothing else |
| Intermediate | `int_orders_enriched`, `int_order_reviews_latest`, `int_geolocation_by_zip` | Stage durations, lateness, on-time and timeline-validity flags, review deduplication, coordinates per zip |
| Marts | `fact_orders`, `fact_order_items`, `dim_customers`, `dim_sellers`, `dim_products`, `dim_date` | Star schema read by analysis and dashboards — see the **[ERD](docs/erd.md)** |

**Stack:** Google BigQuery · dbt Core · Python · GitHub Actions

## Data quality

Data quality is enforced by dbt tests that run on every push through GitHub Actions
(keyless authentication via Workload Identity Federation — no service account keys).

- **Generic tests** — uniqueness and not-null on every primary key, accepted values for
  order status and review scores, and `relationships` tests on every foreign key in the
  star schema.
- **Custom timeline tests** — no delivery before purchase; no negative stage durations;
  and a threshold test that monitors known timeline anomalies (warns above 1,500 orders,
  fails above 3,000).
- **Grain checks** — row counts in the marts match the raw source exactly
  (99,441 orders, 112,650 items), confirming no joins fan out or drop rows.

Issues found and how they are handled:

| Issue | Orders | Handling |
|---|---|---|
| Handed to carrier before approval (incl. 166 before purchase) | 1,359 | Flagged; excluded from stage durations, kept for on-time rate |
| Delivered before carrier handoff | 23 | Same as above |
| Marked delivered but no delivery date | 8 | Excluded from delivery metrics |
| Multiple reviews for one order | — | Latest review kept per order |
| Thin data in 2016 and Sep–Oct 2018 | 349 | Analysis window set to Jan 2017 – Aug 2018 (99.6% of orders) |

## Early findings

- **Customers punish broken promises, not slow delivery.** Average review scores slide
  only gently while orders arrive before the estimated date (4.31 → 4.03), then fall
  sharply once an order is late: 3.29 at 1–3 days late, 2.10 at 4–7 days, 1.70 beyond
  a week.
- **The delivery promise is heavily padded.** 79% of delivered orders arrive a week or
  more before the estimated date — which keeps the on-time rate high (93.2%) but may
  cost conversions at checkout.

Full analysis, dashboards, and recommendations are in progress (see roadmap).

## Repository structure

```
supply-chain-analytics/
├── .github/workflows/dbt-ci.yml   # CI: build and test every model on every push
├── scripts/load_raw.py            # load the 9 CSVs into BigQuery
├── dbt/supply_chain/
│   ├── models/staging/            # 9 staging models + sources
│   ├── models/intermediate/       # business logic
│   ├── models/marts/              # star schema
│   ├── tests/                     # custom data quality tests
│   └── ci/profiles.yml            # CI connection (no secrets)
├── sql/                           # analysis queries
├── notebooks/                     # modeling and forecasting
├── dashboards/                    # Tableau, Power BI, Excel
└── docs/                          # scoping doc, ERD, memo
```

## How to run it

Requires Python 3.11+, the Google Cloud CLI, and a Google Cloud project with BigQuery.

```bash
# 1. environment
python3 -m venv .venv && source .venv/bin/activate
pip install dbt-bigquery pandas jupyter

# 2. authenticate
gcloud auth application-default login

# 3. load raw data (download the Kaggle CSVs into data/raw/ first)
python scripts/load_raw.py

# 4. build and test the warehouse
cd dbt/supply_chain
dbt build
```

Set your own project ID in `scripts/load_raw.py`, `models/staging/_sources.yml`, and
your dbt profile (`dbt init` creates one; choose the `oauth` method).

Note: the BigQuery free sandbox deletes tables after 60 days; re-run
`scripts/load_raw.py` and `dbt build` to restore them.

## Roadmap

- [x] Scoping and data profiling
- [x] Data warehouse: staging, intermediate, star schema, tests, CI
- [ ] Fulfillment performance analysis (SQL)
- [ ] Customer experience and business metrics
- [ ] Dashboards: Tableau, Power BI, Excel operations workbook
- [ ] Late-delivery prediction, demand forecasting, seller segmentation, A/B test design
- [ ] Text-to-SQL assistant
- [ ] Memo to the Head of Operations and five-slide readout

## Author

Justin Nelson Bigishiro — M.S. Data Science, Ball State University