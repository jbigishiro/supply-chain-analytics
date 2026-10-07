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
4. **In-progress orders are treated as failed fulfillments.** At extraction (~Oct 17, 2018),
   1,728 of 1,729 orders still marked shipped/invoiced/processing/created/approved were more
   than 30 days past their estimated delivery date (median 9–18 months since purchase).
   Including them, the true fulfillment failure rate is 3.0% (2,962 orders), not the 1.2%
   implied by canceled/unavailable statuses alone. 1,107 of them had been handed to a carrier.
5. **Timeline anomalies:** 1,382 orders (1.4%) have timestamps out of sequence:
   - 1,359 were handed to the carrier before approval (including 166 before purchase),
     likely because approval records payment confirmation, which can lag shipping.
   - 23 were delivered before the carrier handoff.
   - 0 were approved before purchase; 0 were delivered before purchase.

   These orders are flagged (`has_valid_timeline = false` in `int_orders_enriched`),
   kept for on-time rate and delivery time (purchase and delivery dates are sound),
   and excluded from stage-duration analysis.
## Out of scope
- Carrier-level performance (no carrier data)
- Profitability (no cost data beyond freight)
- Real-time or post-2018 data