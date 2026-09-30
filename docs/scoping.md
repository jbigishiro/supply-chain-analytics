# Project Scoping: Supply Chain Analytics

## Purpose
Measure how reliably the Olist marketplace delivers on its delivery promise,
explain where and why orders run late, show how delays affect customers, and
recommend operational changes backed by numbers.

## Stakeholders and decisions supported

| Stakeholder | Decisions this project supports |
|---|---|
| Head of Operations | Where to focus improvement (stage, region, season); whether estimated delivery dates should change |
| Seller-relations team | Which sellers to coach, warn, or promote, based on shipping reliability and customer reviews |
| Customer service | When to contact customers proactively about likely delays; where complaints will come from |

## Questions the data can answer
- On-time delivery rate overall and by month, state, seller, and category
- Accuracy of the estimated delivery date (too cautious vs too optimistic)
- Duration of each fulfillment stage: purchase → approval → carrier handoff → delivery
- How often sellers miss their shipping deadline, and the effect on delivery
- The link between lateness and review scores, and between a late first order and repeat purchases
- Revenue (GMV), average order value, and freight share by month, category, and state
- Whether lateness can be predicted at approval time

## Data limits
- **No carrier or warehouse detail.** The carrier stage (handoff → delivery) is a black box: we can measure how long it takes, not why.
- **Location is approximate.** Geolocation is keyed on 5-digit zip prefixes with many coordinates per prefix; seller–customer distance will be an estimate.
- **One Black Friday.** Only November 2017 is available, so seasonal conclusions rest on a single peak.
- **Not every order has a review**, and reviews may be written before delivery.
- **Repeat purchases require `customer_unique_id`**; `customer_id` is unique per order, not per person.
- Prices and freight are in Brazilian reais (BRL).

## Data profile (raw layer)
| Table | Rows |
|---|---|
| orders | 99,441 |
| order_items | 112,650 |
| order_payments | 103,886 |
| order_reviews | 99,224 |
| customers | 99,441 |
| products | 32,951 |
| sellers | 3,095 |
| geolocation | 1,000,163 |
| product_category_name_translation | 71 |

Order status: 96,478 delivered (97.0%), 1,234 canceled or unavailable (1.2%),
1,729 still in progress at the time of the extract (1.7%).

## Analysis decisions
1. **Analysis window: January 2017 – August 2018.** 2016 (329 orders, launch period,
   November missing) and Sep–Oct 2018 (20 orders, end of extract) are excluded from
   trend analysis. The window keeps 99,092 orders (99.6%).
2. **Delivery metrics use delivered orders with a delivery date.** 8 orders marked
   `delivered` have no delivery date and are excluded.
3. **Canceled and unavailable orders** are reported separately as a fulfillment failure rate.
4. **In-progress orders** will be checked for age; long-overdue orders will be treated
   as failed deliveries rather than silently dropped.
5. **Timeline anomalies:** 166 orders were handed to the carrier before purchase. They
   are flagged (`has_valid_timeline = false`), kept for on-time rate, and excluded from
   stage-duration analysis. 0 orders were delivered before purchase.

## Out of scope
- Carrier-level performance (no carrier data)
- Profitability (no cost data beyond freight)
- Real-time or post-2018 data