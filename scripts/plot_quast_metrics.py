#!/usr/bin/env python3
import sys
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import os

# The script now expects paths as command line arguments
INPUT_FILE = sys.argv[1]
OUTPUT_DIR = sys.argv[2]
os.makedirs(OUTPUT_DIR, exist_ok=True)

# === LOAD DATA ===
df = pd.read_csv(INPUT_FILE, sep="\t")
df["Sample"] = df["Sample"].astype(str)

# === Define metrics to plot ===
metrics = {
    "# contigs": "Number of Contigs",
    "Total length": "Total Genome Size (bp)",
    "N50": "N50 (bp)",
    "GC (%)": "GC Content (%)"
}

# === Plot each metric ===
for col, label in metrics.items():
    plt.figure(figsize=(14, 6))
    sns.barplot(
        x="Sample",
        y=col,
        data=df,
        palette="crest",
        order=df.sort_values(col, ascending=False)["Sample"]
    )
    plt.title(label + " per Sample", fontsize=14)
    plt.ylabel(label)
    plt.xlabel("Sample")
    plt.xticks(rotation=90)
    plt.tight_layout()

    out_file = os.path.join(
        OUTPUT_DIR, f"quast_plot_{col.replace(' ', '_').replace('(', '').replace(')', '').replace('#', 'num')}.png"
    )
    plt.savefig(out_file, dpi=300)
    plt.show()
    print(f"✅ Saved: {out_file}")