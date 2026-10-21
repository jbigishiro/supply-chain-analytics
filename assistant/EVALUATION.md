# Ask-the-Data Assistant: Evaluation

A text-to-SQL assistant ([`sql_assistant.py`](sql_assistant.py)) lets an operations manager ask
questions of the warehouse in plain English. This document reports how accurate it is, where it
fails, and what would fix the failures.

## How it works

```
question ──► prompt (live schema + business rules + examples) ──► OpenAI model ──► SQL
                                                                                    │
                          safety: single SELECT/WITH only, write keywords blocked,  │
                          BigQuery dry run, 1 GB scan cap                           ▼
                                                                         BigQuery ──► answer
```

- **Schema** is read live from `INFORMATION_SCHEMA`, so the prompt never goes stale.
- **Prompt versions** (all include the schema and table paths):
  - `none`: schema only (ablation)
  - `v1`: business rules (grain, analysis window, delivered-only metrics, revenue exclusions,
    metric formulas) plus 3 worked examples that are not in any test set
  - `v2`: v1 plus column semantics and SQL hygiene, written after the v1 error analysis (filter
    checklist, negative `days_late`, NULLs in bands, alias-qualified columns, attributes from
    dimensions, one row per group)

## Test sets

| Set | Questions | Purpose |
|---|---|---|
| [`questions.yaml`](eval/questions.yaml) | 25 (8 easy, 10 medium, 7 hard) | Main set. Gold answers verified against numbers already confirmed in SQL analysis and dashboards (99,441 orders, 93.2% on-time, RJ 12,310 / 87.9% / 15.3 days, worst seller from query 08) |
| [`questions_holdout.yaml`](eval/questions_holdout.yaml) | 10 (2 easy, 4 medium, 4 hard) | Written **after** the v1 error analysis and never used to design prompts. Prompt v2 is judged on this set |

Questions are phrased the way a manager would ask, without spelling out filters ("What is the
on-time rate?"). Getting the population right is part of the test.

## Scoring

**Execution accuracy:** the generated query is run, and its result is compared with the gold
result. A result is correct when it has the same number of rows and every gold column has a
matching column (values sorted; column names, order and extra columns ignored). Numbers must
match within 0.5%, counts exactly, and rates may be returned as fractions or percentages.

Failures are then reviewed by hand and labelled with an error category. Results that the scorer
got wrong are reported as **false negatives** (right answer marked wrong) or **false positives**
(wrong answer marked right).

## Results

Model `gpt-4o-mini` unless noted. Several runs per configuration, because the API is not fully
deterministic even at temperature 0.

| Prompt | Model | Main set (25) | Held-out (10) |
|---|---|---|---|
| none | gpt-4o-mini | 36% (1 run) | — |
| v1 | gpt-4o-mini | 59% (56–64%, 3 runs) | 37% (30–40%, 3 runs) |
| v2 | gpt-4o-mini | 75% (72–76%, 3 runs)\* | **55% (40–70%, 6 runs)** |
| v2 | gpt-4o | — | **60% (60–60%, 3 runs)** |

\* Optimistic: v2's rules were written from failures on this set.

By difficulty (main set, single run of each):

| Prompt | Easy | Medium | Hard |
|---|---|---|---|
| none | 88% | 20% | 0% |
| v1 | 88% | 60% | 43% |

### What the results show

1. **Business context matters more than SQL skill.** Adding business rules raises accuracy
   from 36% to 59–64%. The gain is entirely on medium and hard questions; easy questions
   ("how many sellers?") score 88% either way. Without rules the model writes valid SQL but
   doesn't know that on-time rate means delivered orders only, or that seller metrics need
   deduplication.
2. **The v2 rules generalize.** On held-out questions, v2 beats v1 by about 18 points
   (37% → 55%), comparable to its 16-point gain on the main set. The rules are general
   knowledge rather than memorized answers.
3. **Held-out accuracy is the realistic number.** v2 drops from 75% on the main set to 55–60%
   on new questions. Questions that combine several traps (growth across a year boundary,
   category deduplication plus a minimum count) remain hard.
4. **A bigger model removes noise, not the hard failures.** gpt-4o eliminates SQL syntax errors
   and gives identical results on every run (60%), but fails the same hard questions as
   gpt-4o-mini. The remaining errors are about context and data design, not model capacity.
5. **Ten held-out questions is a small sample.** Each question is worth 10 points, and
   gpt-4o-mini ranged from 40% to 70%. "About 55–60%" is the fair summary.

## Error analysis

Every failure of the v1 main-set run and the v2 held-out runs was reviewed by hand.
Results with all generated SQL and labels are in `eval/results_*.csv`.

| Category | Example | Prompts affected | Fixed by v2? |
|---|---|---|---|
| **Wrong population: missing filter** | Monthly on-time rate without `is_delivered`, so undelivered orders count as late (q09) | none, v1 | Mostly |
| **Wrong population: rule over-applied** | Revenue exclusion (canceled orders) applied to a review average (q07) and an order count (h07) | v1, v2 | Partly |
| **Fan-out** | Averaging an order-level field across item rows, so multi-item orders count several times (h08, h05; category delivery time) | all | **No** |
| **Data semantics** | `days_late = 0` treated as on time, but early orders have negative `days_late`, so most orders land in "more than 7 days late" (q24) | none, v1 | Yes |
| **NULL handling** | Orders without a distance fall into the `ELSE 'over 1000 km'` band (q23) | v1 | Yes |
| **Schema ambiguity** | `is_on_time` exists in both fact tables, so an unqualified column is ambiguous (q21) | v1 | Mostly |
| **Missing join** | `seller_state` taken from a fact table instead of joining `dim_sellers` (q22) | none, v1 | Mostly |
| **Temporal scope** | Filtered to 2018 before computing month-over-month growth, so January has no previous month (h07) | v1, v2 | No |
| **Hallucinated join / wrong column** | `customer_unique_id = seller_id` (q21); `item_value` for "revenue from item prices" (q17); `COUNT(n_orders)` (q19) | none | Yes |
| **SQL dialect / syntax** | MySQL `FIELD()` (q18); `current` as an alias (q25); `count(if(..., distinct ...))` (h03) | none, v2 (mini) | With gpt-4o |

### Scoring errors found in review

| Type | Case | Cause |
|---|---|---|
| False negative | q13, h10: correct values in a wide layout (1 row × 2 columns) instead of long | Scorer requires the same row count |
| False negative | q18 (first run): gold answer stale after the question was corrected | Gold not rebuilt; fixed |
| **False positive** | h05: fan-out SQL returned 0.05281 vs gold 0.05349 and was marked correct | Absolute tolerance (0.0005) is too loose for small rates |

Adjudicated accuracy for the first v1 main-set run: 64% automated → **72%** after review.
For v2 held-out (gpt-4o-mini, run 1): one false negative and one false positive cancel out (60%).

## Recommendations

Ordered by expected impact on accuracy:

1. **Fix fan-out in the data model, not the prompt.** The grain rule has been in the prompt since
   v1 and still fails with both models. Add marts at the grains managers ask about,
   `order_sellers` (order × seller) and `order_categories` (order × category), each with the
   order-level fields already attached. A seller or category question then needs no
   deduplication, and the trap disappears.
2. **Remove duplicated order-level columns from `fact_order_items`** (or rename them, e.g.
   `order_is_on_time`). They cause ambiguous-column errors and make the wrong table look right.
   Dashboards that need them can join to `fact_orders`.
3. **Add a SQL linter before execution.** Flag queries that join `fact_order_items` and
   average an order-level column without `distinct`, and window functions computed after a
   date filter. Return the warning to the model for one retry.
4. **Always show the generated SQL** next to the answer, so a manager or analyst can spot a
   wrong filter. At 55–60% held-out accuracy, the assistant is a drafting tool for analysts,
   not a self-service tool for managers.
5. **Use the larger model in production.** gpt-4o is stable across runs and makes no syntax
   errors; the cost is negligible at operations-team volume.

Evaluation improvements:
- Use a **relative-only tolerance** for numbers (the h05 false positive).
- Accept **wide or long layouts** for group comparisons (the q13 and h10 false negatives).
- Grow the held-out set to **50+ questions** for a tighter accuracy estimate.

## Reproduce

```bash
pip install openai python-dotenv pyyaml
echo "OPENAI_API_KEY=sk-..." > .env               # never commit; .env is in .gitignore

python assistant/build_gold.py                     # gold answers, main set
python assistant/build_gold.py assistant/eval/questions_holdout.yaml

python assistant/evaluate.py --prompt none
python assistant/evaluate.py --prompt v1 --runs 3
python assistant/evaluate.py --prompt v2 --runs 3 --questions assistant/eval/questions_holdout.yaml
OPENAI_MODEL=gpt-4o python assistant/evaluate.py --prompt v2 --runs 3 --questions assistant/eval/questions_holdout.yaml

python assistant/sql_assistant.py "What is the on-time rate in Bahia?"
```