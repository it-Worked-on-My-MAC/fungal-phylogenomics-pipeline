#!/usr/bin/env python3
import re
import sys
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from scipy.cluster.hierarchy import linkage, dendrogram
from scipy.spatial.distance import squareform
from group_utils import load_groups, label

# The script now expects paths as command line arguments
input_file = sys.argv[1]
output_pdf = sys.argv[2]
groups_tsv = sys.argv[3] if len(sys.argv) > 3 else None  # optional: sample_id<TAB>group

# === Load and Prepare Data ===
df = pd.read_csv(input_file, sep='\t', header=None,
                 names=['Query', 'Reference', 'ANI', 'Fragments', 'TotalFragments'])

def extract_id(path):
    match = re.search(r"/([^/]+)_spades/", path)
    return match.group(1) if match else path

df['Query'] = df['Query'].apply(extract_id)
df['Reference'] = df['Reference'].apply(extract_id)

# Build ANI matrix
ani_matrix = df.pivot(index='Query', columns='Reference', values='ANI')

# Fill diagonal with 100
for sample in ani_matrix.index:
    ani_matrix.loc[sample, sample] = 100

# Make symmetric and fill missing values
ani_matrix = ani_matrix.combine_first(ani_matrix.T)
ani_matrix = ani_matrix.fillna(0)
ani_matrix = (ani_matrix + ani_matrix.T) / 2

# Convert ANI to distance (100 - ANI)
distance_matrix = 100 - ani_matrix

# Convert to condensed format for linkage
condensed_dist = squareform(distance_matrix)

# Perform clustering
Z = linkage(condensed_dist, method='average')

# === Group labels (optional) ===
group_map = load_groups(groups_tsv)
labels_with_groups = [label(s, group_map) for s in ani_matrix.index]

# Plot dendrogram with labeled leaves
plt.figure(figsize=(12, 6))
dendrogram(Z, labels=labels_with_groups, leaf_rotation=90, leaf_font_size=10)
plt.title("Hierarchical Clustering Dendrogram (FastANI Distance)")
plt.ylabel("Distance (100 - ANI)")
plt.tight_layout()

plt.savefig(output_pdf)
print(f"✅ Dendrogram saved to {output_pdf}")