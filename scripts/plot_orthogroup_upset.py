#!/usr/bin/env python3
import sys
import os
import pandas as pd
from upsetplot import UpSet, from_memberships
import matplotlib.pyplot as plt
import warnings

warnings.simplefilter(action='ignore', category=FutureWarning)

# The script now expects paths as command line arguments
ORTHOGROUP_TSV = sys.argv[1]
OUTPUT_FILE_PNG = sys.argv[2]
OUTPUT_FILE_PDF = sys.argv[3]

# === VALIDATION ===
if not os.path.isfile(ORTHOGROUP_TSV):
    raise FileNotFoundError(f"❌ Input file not found: {ORTHOGROUP_TSV}")

# === LOAD DATA ===
og_df = pd.read_csv(ORTHOGROUP_TSV, sep="\t")

# Extract species columns (excluding 'Orthogroup')
species_cols = og_df.columns[1:]

# Convert to presence/absence matrix
presence_absence = og_df[species_cols].notna() & (og_df[species_cols] != '')

# Convert each orthogroup row to a list of species where it appears
memberships = presence_absence.apply(lambda row: [col.replace("_proteins", "") for col in species_cols if row[col]], axis=1)

# Create UpSet-compatible data
upset_data = from_memberships(memberships)

# === PLOT ===
fig = plt.figure(figsize=(18, 10))
ax = fig.add_subplot(1, 1, 1)

upset = UpSet(
    upset_data,
    subset_size='count',
    show_counts=True,
    sort_by='cardinality',
    orientation='horizontal'
)
upset.plot(fig=fig)

fig.suptitle(f"Orthogroup Overlap Across {len(species_cols)} Species", fontsize=18, weight='bold')
fig.tight_layout(rect=[0, 0, 1, 0.96])

# === EXPORT ===
plt.savefig(OUTPUT_FILE_PNG, dpi=300)
plt.savefig(OUTPUT_FILE_PDF)
plt.show()

print(f"✅ UpSet plot saved to: {OUTPUT_FILE_PNG} and {OUTPUT_FILE_PDF}")