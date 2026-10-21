# Memo: Delivering on the Promise

**To:** Head of Operations
**From:** Justin Nelson Bigishiro, Analytics
**Re:** Delivery performance, Jan 2017 – Aug 2018 (96,203 delivered orders)

**Bottom line:** we keep 93% of delivery promises, but the 7% we break do most of the damage to
customer satisfaction. Late orders have two different causes with two different owners, and
our delivery estimates are padded where they don't need to be and too tight where they do.

## Findings

**1. Customers punish broken promises, not slow delivery.** Review scores stay at 4.0–4.3 while
orders arrive early, then fall to **3.3 at 1–3 days late, 2.1 at 4–7 days and 1.7 beyond a week**.
Orders still undelivered two days before their estimated date get **52% one- and two-star
reviews, vs 10% for all other orders**.

**2. Our delivery estimates are miscalibrated in both directions.** **79% of orders arrive a week
or more early**, so most promises are padded. Yet **Rio de Janeiro is 87.9% on time vs 95.5% for
São Paulo**, and the Northeast is worst. Carrier transit accounts for **87% of the extra time** in
late orders: most lateness happens after the seller hands off, so it has to be planned for in
the estimate.

**3. Lateness has two owners.** Of 803 active sellers, **47 chronic late shippers** miss 38% of
shipping deadlines (a missed deadline makes an order about **4× more likely** to be late).
A separate group of **135 sellers ship on time**, but their orders spend **10.6 days with the
carrier vs 8.7** for sellers with the same overall delivery time, and are promised **two days less**. An on-time-rate
scorecard blames both groups equally.

## Recommendations

**1. Test proactive delay notifications.** Message customers whose order is undelivered two days
before its estimated date, with an apology and a revised date. The trigger flags **176 orders a
week, 76% of which end up late**. A randomized test of **18 weeks (3,192 orders)** can detect a
drop in one- and two-star reviews from **52.4% to 47.4%**. Cost: one automated message.

**2. Recalibrate delivery estimates by route.** Set estimates from observed transit times per
seller-state/customer-state route: shorter where 79% of orders already arrive a week early,
longer on slow routes such as Rio de Janeiro and the Northeast. Our late-delivery model flags
**32% of late orders in its riskiest 10%** at approval time (vs 17% using seller history alone),
and can feed route-level adjustments.

**3. Manage sellers by segment, not by one on-time rate.**
- **Intervene** with the 47 chronic late shippers (5% of orders): performance plans and longer
  displayed handling times.
- **Stop penalizing** the 135 "ship on time, arrive late" sellers; take their routes to carriers.
- **Promote** the 320 reliable small sellers (96.6% on time, 4.38 reviews) and **protect** the
  167 core sellers who carry **59% of orders** with priority carrier capacity at peak.

*Methods, queries and dashboards: see the project [README](../README.md). Data: Olist public
dataset; carrier identity is not recorded, so carrier-level causes can't be separated.*