"""Score the assistant against the gold answers.

Usage (from the repo root):
    python assistant/evaluate.py --prompt v1                 # business rules, main test set
    python assistant/evaluate.py --prompt none               # schema only (ablation)
    python assistant/evaluate.py --prompt v2 --runs 3 \\
        --questions assistant/eval/questions_holdout.yaml     # v2 on held-out questions

A prediction is correct when it has the same number of rows as the gold answer and every gold
column has a matching column in the prediction (values compared after sorting, so row order,
column names and extra columns don't matter). Numbers match within 0.5%; whole-number columns
(counts) must match exactly; a rate returned as a percentage also counts.
"""
import argparse
import re
import warnings
import time
from pathlib import Path

import numpy as np
import pandas as pd
import yaml

warnings.filterwarnings("ignore", message="BigQuery Storage module not found")

from sql_assistant import MODEL, UnsafeQuery, generate_sql, run_sql

HERE = Path(__file__).parent
QUESTIONS = HERE / "eval" / "questions.yaml"
GOLD_DIR = HERE / "eval" / "gold"


def _numeric(col: pd.Series):
    if col.dtype == bool or col.astype(str).isin(["True", "False"]).all():
        return None  # compare booleans as text
    values = pd.to_numeric(col, errors="coerce")
    return values.to_numpy(dtype=float) if values.notna().all() else None


def _text(col: pd.Series) -> list[str]:
    out = []
    for v in col:
        s = "null" if pd.isna(v) else str(v).strip().lower()
        if re.match(r"^\d{4}-\d{2}-\d{2}", s):
            s = s[:10]  # dates and timestamps compare on the date
        out.append(s)
    return sorted(out)


def columns_match(gold: pd.Series, pred: pd.Series) -> bool:
    g = _numeric(gold)
    if g is None:
        return _text(gold) == _text(pred)
    p = _numeric(pred)
    if p is None:
        return False
    g, p = np.sort(g), np.sort(p)
    if np.all(g % 1 == 0):
        return np.array_equal(g, p)
    return any(np.allclose(np.sort(p * scale), g, rtol=0.005, atol=0.0005) for scale in (1, 0.01))


def results_match(gold: pd.DataFrame, pred: pd.DataFrame) -> bool:
    if len(gold) != len(pred):
        return False
    return all(any(columns_match(gold[g], pred[p]) for p in pred.columns) for g in gold.columns)


def evaluate_once(questions: list, version: str) -> pd.DataFrame:
    rows = []
    for q in questions:
        gold = pd.read_csv(GOLD_DIR / f"{q['id']}.csv")
        start = time.time()
        sql, status, error = "", "", ""
        try:
            sql = generate_sql(q["question"], version)
            pred = run_sql(sql)
            status = "correct" if results_match(gold, pred) else "wrong_result"
        except UnsafeQuery as e:
            status, error = "blocked", str(e)
        except Exception as e:  # SQL errors from BigQuery, API errors
            status, error = "sql_error", str(e).splitlines()[0][:200]
        rows.append({"id": q["id"], "difficulty": q["difficulty"], "question": q["question"],
                     "status": status, "seconds": round(time.time() - start, 1),
                     "error": error, "generated_sql": sql, "error_category": ""})
        print(f"{q['id']} [{q['difficulty']:<6}] {status}")
    return pd.DataFrame(rows)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--prompt", choices=["none", "v1", "v2"], default="v1",
                        help="none = schema only, v1 = business rules, v2 = + column semantics")
    parser.add_argument("--questions", default=str(QUESTIONS), help="questions YAML file")
    parser.add_argument("--runs", type=int, default=1, help="repeat to measure run-to-run variation")
    args = parser.parse_args()

    questions_file = Path(args.questions)
    questions = yaml.safe_load(questions_file.read_text())
    set_name = questions_file.stem

    accuracies = []
    for run in range(1, args.runs + 1):
        print(f"\n--- run {run}/{args.runs} | prompt {args.prompt} | {set_name} ---")
        results = evaluate_once(questions, args.prompt)
        out = HERE / "eval" / f"results_{MODEL}_{args.prompt}_{set_name}_run{run}.csv"
        results.to_csv(out, index=False)
        correct = results["status"].eq("correct")
        accuracies.append(correct.mean())
        print(f"Accuracy: {correct.mean():.0%} ({correct.sum()}/{len(results)})")
        print(results.assign(correct=correct).groupby("difficulty", sort=False)["correct"].mean().round(2).to_string())
        print(results["status"].value_counts().to_string())
        print(f"Saved {out}")

    acc = pd.Series(accuracies)
    print(f"\nModel: {MODEL} | prompt: {args.prompt} | questions: {set_name} | runs: {args.runs}")
    print(f"Accuracy mean {acc.mean():.0%}, min {acc.min():.0%}, max {acc.max():.0%}")


if __name__ == "__main__":
    main()