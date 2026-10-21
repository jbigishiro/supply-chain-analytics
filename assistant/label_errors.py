import pandas as pd

labels = {
    "rules": {
        "q07": "wrong population: rule over-applied",
        "q09": "wrong population: missing filter",
        "q17": "wrong population: missing filter",
        "q21": "schema ambiguity: duplicate column",
        "q22": "missing join",
        "q23": "null handling",
        "q24": "data semantics: negative days_late",
        "q13": "false negative: answer shape",
        "q18": "false negative: stale gold",
    },
    "no_rules": {
        "q08": "calendar logic", "q09": "wrong population: missing filter",
        "q10": "wrong population: missing filter", "q12": "wrong column meaning",
        "q13": "wrong population: missing filter", "q14": "wrong population: missing filter",
        "q15": "wrong population: missing filter", "q17": "wrong column meaning",
        "q18": "sql dialect", "q19": "wrong column meaning", "q20": "sql aggregation error",
        "q21": "hallucinated join", "q22": "missing join", "q23": "wrong table",
        "q24": "data semantics: negative days_late", "q25": "sql dialect",
    },
}
for label, cats in labels.items():
    path = f"assistant/eval/results_{label}.csv"
    df = pd.read_csv(path)
    df["error_category"] = df["id"].map(cats).fillna("")
    df["adjudicated_correct"] = df["status"].eq("correct") | df["error_category"].str.startswith("false negative")
    df.to_csv(path, index=False)
    print(label, f"adjudicated accuracy: {df['adjudicated_correct'].mean():.0%}")