#!/usr/bin/env python3
"""UpSet plot of orthogroup presence across samples (largest combinations only).

Usage: plot_orthogroup_upset.py Orthogroups.tsv output.png output.pdf
"""
import sys
import matplotlib.pyplot as plt
import pandas as pd

ORTHOGROUP_TSV = sys.argv[1]
OUTPUT_FILE_PNG = sys.argv[2]
OUTPUT_FILE_PDF = sys.argv[3]
MAX_BARS = 25

og_df = pd.read_csv(ORTHOGROUP_TSV, sep="\t", index_col=0)
presence = og_df.notna()
presence.columns = [c.replace("_proteins", "") for c in presence.columns]
samples = list(presence.columns)

# Count orthogroups for each exact combination of samples
counts = presence.value_counts().head(MAX_BARS)

fig, (top, matrix) = plt.subplots(2, 1, figsize=(max(10, 0.4 * len(counts)), 3 + 0.35 * len(samples) + 3),
                                  sharex=True, height_ratios=[3, 0.1 + 0.12 * len(samples)])
x = range(len(counts))
top.bar(x, counts.values, color="#334155")
for i, n in enumerate(counts.values):
    top.text(i, n, str(n), ha="center", va="bottom", fontsize=8)
top.set_ylabel("Orthogroups in this combination")
top.spines[["top", "right"]].set_visible(False)

for i, combo in enumerate(counts.index):
    in_combo = [row for row, present in enumerate(combo) if present]
    matrix.scatter([i] * len(samples), range(len(samples)), s=30, color="#e2e8f0")
    matrix.scatter([i] * len(in_combo), in_combo, s=30, color="#334155")
    matrix.plot([i, i], [min(in_combo), max(in_combo)], color="#334155", linewidth=1.5)
matrix.set_yticks(range(len(samples)), samples)
matrix.invert_yaxis()
matrix.set_xticks([])
matrix.spines[:].set_visible(False)

fig.suptitle(f"Orthogroup overlap across {len(samples)} samples (top {len(counts)} combinations)", weight="bold")
fig.tight_layout()
fig.savefig(OUTPUT_FILE_PNG, dpi=300)
fig.savefig(OUTPUT_FILE_PDF)
print(f"✅ UpSet plot saved to: {OUTPUT_FILE_PNG} and {OUTPUT_FILE_PDF}")
