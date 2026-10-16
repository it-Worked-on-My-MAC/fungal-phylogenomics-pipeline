#!/usr/bin/env python3
import sys
import pandas as pd
import matplotlib.pyplot as plt
from scipy.cluster.hierarchy import linkage, dendrogram
from scipy.spatial.distance import squareform
import re
from group_utils import load_groups, label

# The script now expects paths as command line arguments
file_path = sys.argv[1]
output_png = sys.argv[2]
output_pdf = sys.argv[3]
groups_tsv = sys.argv[4] if len(sys.argv) > 4 else None  # optional: sample_id<TAB>group

# === Load file ===
print(f"Reading: {file_path}")
df = pd.read_csv(file_path, sep='\t', header=None,
                 names=['Sample1', 'Sample2', 'Distance', 'Pvalue', 'SharedHashes'])

# === Extract numeric sample ID from paths ===
def extract_id(path):
    match = re.search(r"/([^/]+)_spades/", path)
    return match.group(1) if match else path

df['Sample1'] = df['Sample1'].apply(extract_id)
df['Sample2'] = df['Sample2'].apply(extract_id)

# === Create symmetric distance matrix ===
print("Creating distance matrix...")
dist_matrix = df.pivot(index='Sample1', columns='Sample2', values='Distance').fillna(0)
dist_matrix = dist_matrix.reindex(sorted(dist_matrix.columns), axis=1).reindex(sorted(dist_matrix.columns), axis=0)
dist_matrix = (dist_matrix + dist_matrix.T) / 2 # Force symmetry

# === Linkage calculation ===
print("Calculating linkage matrix...")
condensed_dist = squareform(dist_matrix.values)
linkage_matrix = linkage(condensed_dist, method='average')

# === Group labels (optional) ===
groups = load_groups(groups_tsv)

# === Build labels ===
print("Assigning group labels...")
sample_order = dist_matrix.index.tolist()
new_labels = [label(sid, groups) for sid in sample_order]

# === Plot dendrogram ===
print("Plotting dendrogram...")
plt.figure(figsize=(14, 8))
dendrogram(linkage_matrix, labels=new_labels, leaf_rotation=90)
plt.title("Mash Distance Dendrogram")
plt.xlabel("Sample ID (Group, if provided)")
plt.ylabel("Mash Distance")
plt.tight_layout()

# === Save outputs ===
plt.savefig(output_png)
plt.savefig(output_pdf)
print(f"Saved:\n- {output_png}\n- {output_pdf}")
plt.show()