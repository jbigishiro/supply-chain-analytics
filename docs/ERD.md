# Star Schema — Entity Relationship Diagram

The marts layer (`dbt/supply_chain/models/marts/`) is a star schema: two fact tables
in the middle, four dimension tables around them.

```mermaid
erDiagram
    dim_customers ||--o{ fact_orders : places
    dim_date ||--o{ fact_orders : "purchased on"
    fact_orders ||--o{ fact_order_items : contains
    dim_products ||--o{ fact_order_items : "sold as"
    dim_sellers ||--o{ fact_order_items : ships
    dim_customers ||--o{ fact_order_items : buys
    dim_date ||--o{ fact_order_items : "purchased on"

    fact_orders {
        string order_id PK
        string customer_id
        string customer_unique_id FK
        date purchase_date FK
        string order_status
        string customer_state
        string customer_zip_code_prefix
        date purchase_month
        timestamp purchased_at
        timestamp approved_at
        timestamp carrier_handoff_at
        timestamp delivered_at
        date estimated_delivery_date
        timestamp shipping_limit_at
        int n_items
        int n_sellers
        numeric items_value
        numeric freight_value
        numeric order_value
        float approval_days
        float seller_processing_days
        float carrier_transit_days
        float total_delivery_days
        int promised_days
        int days_late
        bool is_on_time
        bool missed_shipping_deadline
        int review_score
        bool has_review
        bool is_delivered
        bool has_valid_timeline
        bool is_in_analysis_window
    }

    fact_order_items {
        string order_item_key PK
        string order_id FK
        int order_item_id
        string product_id FK
        string seller_id FK
        string customer_unique_id FK
        date purchase_date FK
        numeric price
        numeric freight_value
        numeric item_value
        timestamp shipping_limit_at
        bool missed_shipping_deadline
        float distance_km
        bool is_delivered
        bool is_on_time
        int days_late
        bool is_in_analysis_window
    }

    dim_customers {
        string customer_unique_id PK
        string customer_zip_code_prefix
        string customer_city
        string customer_state
        float latitude
        float longitude
        timestamp first_order_at
        timestamp last_order_at
        date cohort_month
        int n_orders
        bool is_repeat_customer
    }

    dim_sellers {
        string seller_id PK
        string seller_zip_code_prefix
        string seller_city
        string seller_state
        float latitude
        float longitude
    }

    dim_products {
        string product_id PK
        string category_name
        int weight_g
        int length_cm
        int height_cm
        int width_cm
        int volume_cm3
    }

    dim_date {
        date date_day PK
        int year
        int quarter
        int month
        string month_name
        date month_start
        date week_start
        string day_name
        bool is_weekend
    }
```

## Grain and keys

| Table | Grain (one row per…) | Primary key | Rows |
|---|---|---|---|
| `fact_orders` | order | `order_id` | 99,441 |
| `fact_order_items` | item within an order | `order_item_key` (`order_id` + `order_item_id`) | 112,650 |
| `dim_customers` | person | `customer_unique_id` | — |
| `dim_sellers` | seller | `seller_id` | 3,095 |
| `dim_products` | product | `product_id` | 32,951 |
| `dim_date` | calendar day, Sep 2016 – Dec 2018 | `date_day` | — |

## Design decisions

- **Two fact tables at two grains.** Order-level questions (on-time rate, delivery time,
  reviews) use `fact_orders`; item-level questions (sellers, products, freight, distance)
  use `fact_order_items`. Item facts are aggregated to order level *before* joining in
  `int_orders_enriched`, so `fact_orders` never fans out — guarded by a `unique` test on
  `order_id`.
- **`dim_customers` is keyed on the person (`customer_unique_id`), not `customer_id`.**
  Olist issues a new `customer_id` for every order, which would make retention analysis
  impossible. Each person's latest address is kept.
- **No separate geography dimension.** Coordinates (averaged per zip prefix, points
  outside Brazil removed) are folded into `dim_customers` and `dim_sellers`.
- **Fact tables are safe by default.** Delivery metrics (`days_late`, `is_on_time`,
  `total_delivery_days`) are NULL unless the order was delivered; stage durations are NULL
  unless the timeline is in order. A plain `AVG()` in a dashboard is therefore correct
  without extra filters.
- **Distance** is the straight-line distance between seller and customer zip-prefix
  centres (`ST_DISTANCE`), a proxy for shipping distance; 555 items (0.5%) have no
  distance because a zip prefix has no coordinates.

## Relationship tests

Every foreign key above is covered by a dbt `relationships` test, so no fact row points
to a customer, seller, product, or date that does not exist.