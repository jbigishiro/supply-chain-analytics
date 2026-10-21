# Experiment Design: Proactive Delay Notification

**Status:** proposal (not run). Baselines come from the warehouse
([`sql/analysis/17_experiment_baseline.sql`](../sql/analysis/17_experiment_baseline.sql));
the sample size is computed in [`notebooks/experiment_design.ipynb`](../notebooks/experiment_design.ipynb).

## Why this test

- **Customers punish broken promises, not slow delivery.** Review scores stay above 4 while
  orders arrive before the estimated date, then drop to 3.29 at 1–3 days late, 2.10 at 4–7 days
  and 1.70 beyond a week ([findings](../sql/analysis/FINDINGS.md)).
- **Many late orders aren't the seller's fault.** Seller segmentation found 135 sellers who hand
  off in 2.1 days but whose orders spend the longest time with the carrier (10.6 days) and are
  promised the shortest window (23.6 days). Seller relations can't fix that, but how the delay is
  communicated can be changed.
- **The damage is concentrated in a group that is easy to detect.** An order with no delivery
  scan 2 days before its estimated date is a strong warning sign, and those orders get most of
  the 1–2 star reviews.

Why not test a shorter estimated date at checkout? Its primary metric would be checkout
conversion, and the Olist data contains only completed orders, with no browsing or checkout
events. A notification test can be measured with data the warehouse already has.

## Hypothesis

- **H₀:** a proactive delay notification does not change the share of 1–2 star reviews among
  at-risk orders.
- **H₁:** it changes that share (two-sided test; we expect a decrease).

## Design

| Element | Choice |
|---|---|
| **Trigger** (eligibility) | Order not yet delivered 2 days before its estimated delivery date |
| **Treatment** | Message at trigger time: apology, revised delivery date, link to order tracking |
| **Control** | No message (current experience) |
| **Unit of randomization** | Customer (`customer_unique_id`), hashed into a 50/50 split, so a repeat customer always sees the same experience. Repeat customers are about 3%, so the analysis can treat orders as independent |
| **Allocation** | 50% treatment / 50% control |

### Trigger quality (Jan–Jun 2018)

| | Triggered | Not triggered |
|---|---|---|
| Orders | 4,567 (11.3%) | 35,703 |
| Orders per week | 176 | 1,373 |
| End up late | **76.1%** | 0.0% |
| Leave a review | 98.3% | 99.5% |
| 1–2 star share (reviewed) | **52.4%** | 9.6% |
| Average review | 2.58 | 4.28 |

The trigger has 76% precision and catches every late order (an order delivered more than 2 days
before its estimate cannot be late). It flags 11% of orders, which account for most low reviews.

## Metrics

| Type | Metric | Baseline | Why |
|---|---|---|---|
| **Primary** | Share of 1–2 star reviews among reviewed triggered orders | 52.4% | Directly measures the damage the notification is meant to reduce |
| Secondary | Average review score (triggered orders) | 2.58 | Shows movement across the whole scale, not just the bottom |
| Secondary | Repeat purchase within 180 days | from `dim_customers` | The long-term outcome; too rare to power, so reported descriptively |
| **Guardrail** | Review rate (triggered orders) | 98.3% | The message must not discourage reviewing, which would bias the primary metric |
| **Guardrail** | Cancellation / refund requests after trigger | from `fact_orders` | A delay warning could prompt cancellations |
| **Guardrail** | 1–2 star share among triggered orders that end up **on time** (24%) | from query 17 | These customers get a warning they didn't need; it must not make them less happy |
| Sanity check | On-time rate by arm | 23.9% on time | The message cannot change delivery; a difference means randomization is broken |
| Sanity check | Sample ratio mismatch (chi-square on arm sizes) | 50/50 | Detects assignment or logging bugs |

## Sample size

Two-sided two-proportion test, α = 0.05, power = 0.80, effect size as Cohen's h, inflated by the
98.3% review rate to convert reviews into orders.

| MDE (absolute) | Treated rate | Orders per arm | Total orders | Weeks at 176/week |
|---|---|---|---|---|
| 3 pp | 49.4% | 4,434 | 8,868 | 50.4 |
| **5 pp** | **47.4%** | **1,596** | **3,192** | **18.1** |
| 7.5 pp | 44.9% | 708 | 1,416 | 8.0 |
| 10 pp | 42.4% | 397 | 794 | 4.5 |

**Chosen MDE: 5 percentage points** (52.4% → 47.4%, about a 10% relative reduction).
- A notification can't make the parcel arrive sooner; it only removes the surprise. A 5 pp effect
  recovers about one-ninth of the 43-point gap between triggered and non-triggered orders, which
  is a realistic claim.
- Powering for 10 pp would finish in under 5 weeks but would likely miss a real, smaller effect.
- 3 pp would take about a year.

**Duration: 18 weeks** at 2018 volume (round up to full weeks so every weekday is equally
represented). The test will run through peak season; randomization balances it across arms.
If a faster decision is needed, a 7.5 pp MDE (8 weeks) is the fallback, with the explicit
caveat that smaller effects will not be detectable.

## Analysis plan

Fixed before launch:

1. **Validity first:** sample ratio mismatch test and on-time rate by arm. If either fails,
   stop and fix the assignment; don't read the results.
2. **Primary:** two-proportion z-test on the 1–2 star share; report the difference with a 95%
   confidence interval.
3. **Guardrails:** each with a 95% CI. A guardrail fails if it moves significantly in the
   harmful direction.
4. **No peeking:** results are read once, at the planned sample size. If interim looks are
   required, use a sequential design (e.g. O'Brien–Fleming boundaries) agreed in advance.
5. **Segments (exploratory):** effect by days late and by seller segment. Not used for the
   launch decision.

## Decision rule

| Result | Decision |
|---|---|
| Primary significantly lower, no guardrail fails | **Roll out** to all triggered orders |
| Primary significantly lower, a guardrail fails | Iterate on the message (wording, timing) and re-test |
| No significant difference | Don't roll out; the CI shows the largest effect that can be ruled out |
| Primary significantly higher | Stop; the message makes things worse |

## Risks and limits

- **Baselines are from 2018 Olist volume.** A current marketplace with more orders reaches the
  sample size faster; recompute the duration with current trigger volume before launch.
- **Reviews are a proxy for satisfaction.** Repeat purchases are the business outcome but are too
  rare (about 3%) to power a test of this size.
- **Novelty effect.** Early responses to a new message can differ from long-run responses;
  compare the first and second half of the test.
- **Revised dates must be honest.** If the revised date is missed too, the notification becomes a
  second broken promise. The revised date should come from observed transit times, not a guess.
- **No carrier data.** Olist does not record the carrier, so the test can't target specific
  carriers or lanes.