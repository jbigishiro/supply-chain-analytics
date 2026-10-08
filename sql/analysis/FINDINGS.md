# Analysis Findings

Results of the sixteen analysis queries in this folder: fulfillment performance (01–11)
and customer experience and business metrics (12–16). Unless stated otherwise, delivery
metrics use **delivered orders purchased Jan 2017 – Aug 2018**; revenue metrics use all
orders in that window except canceled and unavailable. Definitions are in
[`docs/metric_definitions.md`](../../docs/metric_definitions.md).

## Summary

- **Customers react to broken promises, not to slow delivery.** Review scores fall
  sharply from the first day late.
- **About 7% of delivered orders arrive late, and a further 1.7% of all orders never
  arrive at all.** Counting those, about 91.6% of promises are kept, not the headline 93.2%.
- **Carriers cause most of the delay; sellers tip orders over the edge.** 87% of the
  extra time in late orders is carrier transit, while a missed seller deadline makes an
  order about 4× more likely to be late.
- **Lateness depends on *where* and *when*, not *what*.** Destination state, purchase
  month and seller deadlines swing the on-time rate by 16–19 points; product weight and
  category by 3–4 points.
- **Half of all late orders go to two states (SP, RJ), and Rio is late for reasons
  other than distance.** Rio and Bahia — the two large states with weak delivery —
  account for about 17% of GMV.
- **About a third of 1–2 star reviews come from late orders.** The other two-thirds come
  from orders that arrived on time, pointing to product and seller issues.
- **Almost no one buys twice.** Only 2% of customers order again within six months, and
  monthly cohort retention stays below 1%. Customers whose first order was late return
  less often (1.6% vs 2.0%), but the difference is not statistically significant
  (p ≈ 0.10). Better delivery pays off mainly through **reputation**, which every new
  customer sees, rather than through repeat purchases.

### What drives lateness — spread of the on-time rate across each factor

| Factor | On-time range | Swing | Query |
|---|---|---|---|
| Customer state | 78.5% – 97.2% | 19 pts | 06 |
| Purchase month | 81.0% – 98.8% | 18 pts | 01 |
| Seller missed shipping deadline | 78.9% vs 94.6% | 16 pts | 05 |
| Seller–customer distance | 88.1% – 95.5% | 7 pts | 07 |
| Product category | 92.0% – 95.8% | 4 pts | 09 |
| Product weight | 90.7% – 93.7% | 3 pts | 09 |

---

## 01 — On-time rate by month

- Normal performance is **95–97% on time**.
- **Two breakdowns with different shapes:**
  - **Nov 2017: 87.6%**, a volume shock — 7,288 delivered orders, 63% more than October.
  - **Feb–Mar 2018: 85.9% and 81.0%** — the worst months in the data, **with no volume
    spike** (volume flat versus January).
- Average delivery time improved from about **16–17 days (Feb–Mar 2018) to about 9 days
  (Jun–Jul 2018)**.
- Aug 2018 (7.7 days) is incomplete: slow orders bought late that month were still in
  transit when the data was extracted (right-censoring).

## 02 — Estimate accuracy by state

- On average, the delivery estimate is **cautious in every state**: deliveries arrive
  8.6 to 20.7 days before the promised date. Overall, **79% of delivered orders arrive a
  week or more early.**
- **The buffer is badly distributed:**
  - **North (AC, RO, AP, AM):** promised 39–47 days, delivered in 19–27; 96–97% on time,
    90–95% arrive a week early. Customers are told to wait about six weeks for something
    that arrives in three.
  - **Northeast (AL, MA, SE, CE, PI):** 79–86% on time — the worst in the country
    (Alagoas: 79%).
- Answer to the brief: estimates are **both too cautious and too optimistic, depending on
  the region**. The issue is calibration, not the average.
- Caution: RR (40 orders), AP (67) and AC (80) are too small for firm conclusions.

## 03 — Fulfillment stage durations

Delivered orders with valid timelines, in days:

| Stage | Average | Median | 90th pct | Share of average total |
|---|---|---|---|---|
| Approval | 0.4 | 0.0 | 1.4 | 3% |
| Seller processing | 2.8 | 1.8 | 6.0 | 22% |
| Carrier transit | 9.4 | 7.1 | 18.9 | 75% |
| **Total** | **12.6** | **10.3** | **23.1** | |

- Approval is not an issue. Carrier transit is three-quarters of the wait and has the
  longest tail. The median order takes about 10 days; 1 in 10 takes more than 3 weeks.

## 04 — Which stage makes orders late

- A late order takes **33.9 days vs 11.0** for an on-time one (+22.9 days):
  - carrier transit **+19.9 days (87% of the gap)**
  - seller processing +3.0 days (13%); the slowest 10% of seller handoffs more than
    double (5.7 → 14.0 days)
  - approval +0.1 days
- **By month:**
  - **Nov 2017:** both stages slowed — seller processing 3.6 days (the highest),
    carrier 11.1.
  - **Feb–Mar 2018:** a **carrier problem** — transit 13.4 and 13.0 days versus about 8.5
    normally, while seller processing stayed normal (3.2, 3.0).
  - **Jun–Jul 2018:** carrier transit fell to 6.7 and 6.1 days, the fastest in the data.

## 05 — Seller shipping deadline misses

| | Met deadline | Missed deadline |
|---|---|---|
| Orders | 87,621 (91.1%) | 8,581 (8.9%) |
| On-time rate | 94.6% | 78.9% |
| Late rate | 5.4% | 21.1% |
| Average delivery days | 11.9 | 19.5 |
| Average review score | 4.2 | 3.7 |

- An order whose seller misses the deadline is **about 4× as likely to arrive late**.
- Missed deadlines account for **about 28% of late orders from 9% of orders**.
- Interpretation with query 04: carriers cause most of the *delay*, but a late seller
  handoff uses up the buffer, so normal carrier variation pushes the order past its promise.
- Seller deadlines are the lever the marketplace controls most directly.

## 06 — Performance by state

**Customer states, ranked by number of late orders:**
- **SP (27.8%) and RJ (22.9%) receive half of all late orders.** With MG and BA, four
  states account for nearly two-thirds.
- **Rio de Janeiro:** 12,310 orders, 87.9% on time vs São Paulo's 95.5%. Raising Rio to
  São Paulo's rate would prevent about **935 late orders, roughly 14% of all late
  deliveries**.
- **Bahia:** 6.1% of late orders from about 3.4% of volume (87.8% on time).
- The states with the worst rates (AL, MA, SE) each contribute only 1–2% of late orders.

**Seller states:**
- Sellers in SP ship **more than 70% of orders**.
- SP sellers have the lowest on-time rate of the large seller states (92.7% vs
  94.7–96.9%), but they also ship to the most distant destinations — seller-state rates
  mix seller behaviour with destination (confounding).
- MA sellers (81.0%, 389 orders) are explained by a single seller (see query 08).

## 07 — Distance effects

| Distance | Avg freight | Freight % of price | Avg delivery days | On-time |
|---|---|---|---|---|
| under 100 km | R$11.75 | 11.8% | 6.5 | 95.5% |
| 100–300 km | R$16.39 | 14.2% | 9.9 | 94.9% |
| 300–600 km | R$19.50 | 16.7% | 12.5 | 93.5% |
| 600–1,000 km | R$21.70 | 17.8% | 14.6 | 93.1% |
| 1,000–2,000 km | R$29.26 | 19.3% | 17.9 | 90.6% |
| 2,000+ km | R$35.90 | 22.7% | 21.1 | 88.1% |

- Freight triples with distance, and nearly doubles as a share of price.
- On-time falls gently up to 1,000 km (estimates scale with distance), then more steeply.
- **Rio's lateness is not explained by distance:** orders in the 300–600 km band (typical
  for São Paulo → Rio) are 93.5% on time in 12.5 days; orders to Rio are 87.9% in 15.3
  days. Volume, seller behaviour and distance are all ruled out as explanations.

## 08 — Seller scorecard

Sellers with at least 50 delivered orders, ranked by late orders.

- **Lateness is not concentrated in a few bad sellers.** The top 20 cause about 25% of
  late orders while handling about 21% of orders.
- **Two kinds of seller among them:**
  - **Deadline-missers** — e.g. `7c67e144…` (30% missed deadlines, lowest review score at
    3.50), `06a2c3af…` (31% missed, 81.0% on time), `81602554…` (25% missed).
  - **Reliable shippers with carrier-driven lateness** — e.g. `6560211a…`, `cc419e06…`,
    `955fee92…` (under 1% missed deadlines).
- Seller `06a2c3af…` (389 orders, 81.0% on time) matches Maranhão's seller-state figures
  exactly: the state's poor result is one seller.
- A fair seller scorecard should judge sellers on **deadline misses** (what they control),
  with on-time rate and reviews as context.

## 09 — Product weight and category

- **Weight drives cost, not lateness.** Freight rises from R$15.17 (under 0.5 kg) to
  R$54.22 (10+ kg); on-time stays at 92.8–93.7% until a dip to 90.7% for 10+ kg items.
- Freight as a share of price is highest for the **lightest** items (20.2%) and lowest at
  2–5 kg (12.7%).
- **Category barely affects lateness:** 92.0% (office furniture) to 95.8% (luggage)
  among categories with 1,000+ items.
- Office furniture is the heaviest (11.3 kg), most expensive to ship (R$40) and slowest
  (20.8 days), yet still 92% on time — its estimates account for it.
- **Electronics customers pay 29.5% of the item price in freight**, the highest share.

## 10 — Seasonality: Black Friday 2017

Weekly view, Oct 2017 – Jan 2018 (Black Friday: Nov 24).

| | Normal October week | Black Friday week (Nov 20) |
|---|---|---|
| Delivered orders | ~1,000 | 2,915 |
| On-time | ~96% | 82.7% |
| Missed seller deadlines | ~7–8% | 15.3% |
| Seller processing | ~3.0 days | 3.8 days |
| Carrier transit | ~8.3 days | 12.4 days |

- Sellers and carriers were both overwhelmed. Performance had already started slipping
  the week before (91.7%).
- On-time recovered within about three weeks (94.4% in the week of Dec 11).
- **Carrier transit never returned to normal:** about 12 days through mid-December,
  10–11 through January, then 13+ in Feb–Mar 2018. Hypothesis: carrier capacity was
  strained from Black Friday onward and then broke down. The data cannot confirm this
  (no carrier identity).

## 11 — Stuck orders

- **1,728 of the 1,729 orders still "in progress"** at extraction (~Oct 17, 2018) were
  more than 30 days past their estimated delivery date; the median order in each status
  had been placed 283–540 days earlier.
- They are failed fulfillments. The **true fulfillment failure rate is 3.0%**
  (2,962 orders), not the 1.2% implied by canceled and unavailable statuses.
- **1,107 had been handed to a carrier and never arrived** — invisible in on-time
  metrics, which only cover delivered orders.
- Counting them as broken promises, about **91.6%** of orders arrived on time, versus
  93.2% among delivered orders.

---

# Customer experience and business metrics

## 12 — Review scores vs lateness

Delivered orders with a review, by days late (capped at ±15):

| Delivered | Avg review score | 1–2 star share |
|---|---|---|
| 6–15+ days early | 4.25–4.34 | 8–10% |
| 1–5 days early | 4.12–4.19 | 11–12% |
| on the estimated day | 4.03 | 12.4% |
| **1 day late** | **3.73** | **19.7%** |
| **2 days late** | **3.18** | **34.3%** |
| **3 days late** | **2.68** | **50.4%** |
| 6+ days late | 1.6–1.9 | 75–83% |

- **Earliness barely matters**; the damage happens in the **first three days late**, each
  costing about half a star. By day 3, half of all reviews are 1–2 stars.
- After about a week late, scores bottom out around 1.7 — the customer has given up.
- About 9% of reviews are 1–2 stars even when orders arrive on time: a baseline of
  dissatisfaction unrelated to delivery.

**Where bad reviews come from:**

| Review score | Reviews | From late orders |
|---|---|---|
| 1 | 9,313 | 36.8% |
| 2 | 2,915 | 18.9% |
| 3 | 7,895 | 8.8% |
| 4 | 18,837 | 3.4% |
| 5 | 56,600 | 1.9% |

- Late orders are about 7% of reviewed orders but **36.8% of 1-star reviews** — more than
  five times their share.
- **About a third (33%) of all 1–2 star reviews come from late orders.** Fixing delivery
  would remove about a third of negative reviews, not all of them.

## 13 — Business metrics by month

Orders excluding canceled and unavailable; GMV = item prices + freight, in BRL.

- **2017 was a growth year:** monthly GMV rose from R$137k (Jan) to R$765k (Oct), 5.6×,
  peaking at **R$1.17M in November** (Black Friday).
- **2018 was flat:** GMV stayed around R$1.0–1.16M a month, drifting slightly down after
  April. (This is a public extract and may not contain every Olist order.)
- **Growth came from more orders, not bigger baskets:** average order value stayed
  between R$147 and R$174 with no trend; November's AOV dipped (R$158 vs R$168 in October).
- **Freight's share of order value rose** from about 12–13.5% in early 2017 to 15.4–15.6%
  in mid-2018, even as deliveries got faster.
- Month-over-month growth is affected by month length: February 2018 shows GMV −11.1%,
  but orders per day actually rose versus January (about 237 vs 232).

## 14 — Revenue vs delivery performance

**By customer state:**
- **Three states make 62.5% of GMV:** SP (37.4%), RJ (13.4%), MG (11.7%).
- **Rio is the second-largest revenue state and among the worst for delivery** (87.9% on
  time). With Bahia (87.8%), the two account for **R$2.7M, about 17% of GMV**.
- **Review scores follow delivery across states:** the lowest-scoring states (RR 3.70,
  AL 3.77, MA 3.78, BA 3.88, CE 3.88, RJ 3.91) all have low on-time rates; the highest
  (AM 4.22, SP and PR 4.21) have high ones.
- Customers far from sellers spend more per order (Paraíba about R$265, Alagoas about
  R$235, São Paulo about R$143), so each late order there affects a relatively valuable
  customer.

**By category (top 15 by revenue):**
- Revenue is spread out: the largest category (health & beauty) is 9.1%; the top 15
  make up about 76%.
- On-time rates are uniform (92–95%), but **review scores are not**: office furniture
  scores 3.50 despite 92% on time; bed/bath/table (3.90), furniture/decor (3.92),
  computers accessories and telephony (3.95) are also low. Their dissatisfaction is not
  about delivery — likely product quality, damage or assembly.

## 15 — Repeat purchases after a late first delivery

Customers whose first order was purchased Jan 2017 – Feb 2018 and delivered; a return is
another order 1–180 days after the first.

| First delivery | Customers | Returned | Repeat rate |
|---|---|---|---|
| On time | 51,558 | 1,030 | 2.00% |
| 1–3 days late | 987 | 18 | 1.82% |
| 4+ days late | 2,682 | 41 | 1.53% |

- The gradient points the expected way: the later the first order, the less likely a
  return (−24% relative for 4+ days late).
- **It is not statistically significant.** Two-proportion z-test: on time vs all late,
  p ≈ 0.10; on time vs 4+ days late, p ≈ 0.09. The 95% confidence interval for the
  difference includes zero (see `notebooks/15_repeat_significance`).
- Conclusion: the data suggests late first deliveries reduce repeat purchases, but the
  evidence is not conclusive.
- **The bigger finding is the level: only 2% of customers return within six months**,
  regardless of delivery.

## 16 — Cohort retention

Share of each first-purchase cohort ordering again 1, 2, 3, 6 and 12 months later.

- **Retention is near zero for every cohort at every point:** between about 0.1% and
  0.7% a month. No loyal core forms in any cohort.
- Individual cells are too small to rank cohorts (e.g. 0.66% of the Jan 2017 cohort is 5
  customers).
- **A hypothesis that did not hold:** cohorts that started during the carrier problems
  (Dec 2017 – Mar 2018) had low month-1 retention, but at months 2–3 they matched other
  cohorts.
- **A weak hint:** the Black Friday cohort (Nov 2017) has the lowest month-6 retention
  (0.11%, about 8 customers), consistent with sale-driven customers not returning. Not
  conclusive.

---

## Recommendations these findings support (draft)

1. **Recalibrate delivery estimates by region** — shorten heavily padded promises (North,
   São Paulo), widen or fix those that keep breaking (Northeast).
2. **Judge and coach sellers on shipping-deadline misses**, and treat a missed deadline
   as the trigger for a proactive delay notification — before the promised date passes,
   since review scores collapse within the first three days late.
3. **Investigate carrier and last-mile performance for Rio de Janeiro** (the
   second-largest revenue state), and the carrier strain from Black Friday through March
   2018.
4. **Plan for peak season** — longer estimates, seller deadline reminders and reserved
   carrier capacity before Black Friday.
5. **Report the true failure rate**, including orders stuck in transit.
6. **Treat delivery as a reputation lever.** With almost no repeat buyers, growth depends
   on new customers, who judge the marketplace by its reviews.