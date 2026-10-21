import sys
import pandas as pd

label = sys.argv[1] if len(sys.argv) > 1 else "rules"
df = pd.read_csv(f"assistant/eval/results_{label}.csv")
for _, r in df[df["status"] != "correct"].iterrows():
    print(f"===== {r['id']} [{r['difficulty']}] {r['status']}")
    print(f"Q: {r['question']}")
    if isinstance(r["error"], str):
        print(f"ERROR: {r['error']}")
    print(r["generated_sql"], "\n")