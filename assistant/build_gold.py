"""Run every gold query in a questions file and save its result as the expected answer.

Usage (from the repo root):
    python assistant/build_gold.py                                   # eval/questions.yaml
    python assistant/build_gold.py assistant/eval/questions_holdout.yaml
"""
import sys
import warnings
from pathlib import Path

import yaml
from google.cloud import bigquery

warnings.filterwarnings("ignore", message="BigQuery Storage module not found")

PROJECT = "supply-chain-analytics-510105"
MARTS = f"`{PROJECT}.dbt_dev_marts`"

HERE = Path(__file__).parent
GOLD_DIR = HERE / "eval" / "gold"


def main() -> None:
    questions_file = Path(sys.argv[1]) if len(sys.argv) > 1 else HERE / "eval" / "questions.yaml"
    client = bigquery.Client(project=PROJECT)
    GOLD_DIR.mkdir(parents=True, exist_ok=True)

    for q in yaml.safe_load(questions_file.read_text()):
        sql = q["gold_sql"].replace("{marts}", MARTS)
        df = client.query(sql).to_dataframe()
        df.to_csv(GOLD_DIR / f"{q['id']}.csv", index=False)
        first = df.iloc[0].to_dict() if len(df) else {}
        print(f"{q['id']} [{q['difficulty']:<6}] rows={len(df):<3} {first}")


if __name__ == "__main__":
    main()