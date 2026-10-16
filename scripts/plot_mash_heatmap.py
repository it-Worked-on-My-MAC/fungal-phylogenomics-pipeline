#!/usr/bin/env python3
import sys
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from scipy.cluster.hierarchy import linkage
from scipy.spatial.distance import squareform
import re
from group_utils import load_groups

# The script now expects paths as command line arguments
file_path = sys.argv[1]
output_png = sys.argv[2]
output_pdf = sys.argv[3]
groups_tsv = sys.argv[4] if len(sys.argv) > 4 else None  # optional: sample_id<TAB>group

# Load Mash distance file
df = pd.read_csv(file_path, sep='\t', header=None,
                 names=['Sample1', 'Sample2', 'Distance', 'Pvalue', 'SharedHashes'])

# Extract sample IDs from path
def extract_id(path):
    match = re.search(r"/([^/]+)_spades/", path)
    return match.group(1) if match else path

df['Sample1'] = df['Sample1'].apply(extract_id)
df['Sample2'] = df['Sample2'].apply(extract_id)

# Create distance matrix
dist_matrix = df.pivot(index='Sample1', columns='Sample2', values='Distance').fillna(0)
dist_matrix = (dist_matrix + dist_matrix.T) / 2

# Clustering
condensed_dist = squareform(dist_matrix.values)
linkage_matrix = linkage(condensed_dist, method='average')

# Optional group colouring
group_map = load_groups(groups_tsv)
if group_map:
    groups = dist_matrix.index.to_series().map(lambda s: group_map.get(s, "Unassigned"))
    levels = sorted(groups.unique())
    colors = dict(zip(levels, sns.color_palette("Set2", len(levels))))
    row_colors = groups.map(colors)
else:
    row_colors = None

g = sns.clustermap(dist_matrix,
                   row_linkage=linkage_matrix,
                   col_linkage=linkage_matrix,
                   row_colors=row_colors,
                   col_colors=row_colors,
                   cmap='viridis',
                   figsize=(12, 12))

plt.suptitle("Mash Distance Heatmap and Dendrogram", y=1.02)

g.savefig(output_png)
g.savefig(output_pdf)

print(f"Grouped heatmap saved as:\n{output_png}\n{output_pdf}")
plt.show()