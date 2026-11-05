#!/bin/bash

# Load configuration file
source bin/00_config.sh

echo "📊 Step 11: Making figures"

conda activate "$CONDA_PHYLO"
mkdir -p "$FIGURE_DIR"
GROUPS_FILE="${GROUPS_FILE:-}"   # optional: sample_id<TAB>group

MPLBACKEND=Agg python3 scripts/plot_quast_metrics.py "$QUAST_DIR/QUAST_summary.tsv" "$FIGURE_DIR"
MPLBACKEND=Agg python3 scripts/plot_mash_dendrogram.py "$MASH_DIR/distances.tab" \
  "$FIGURE_DIR/mash_dendrogram.png" "$FIGURE_DIR/mash_dendrogram.pdf" $GROUPS_FILE
MPLBACKEND=Agg python3 scripts/plot_mash_heatmap.py "$MASH_DIR/distances.tab" \
  "$FIGURE_DIR/mash_heatmap.png" "$FIGURE_DIR/mash_heatmap.pdf" $GROUPS_FILE
MPLBACKEND=Agg python3 scripts/plot_fastani_dendrogram.py "$FASTANI_DIR/fastani_all_vs_all.txt" \
  "$FIGURE_DIR/fastani_dendrogram.png" $GROUPS_FILE
MPLBACKEND=Agg python3 scripts/plot_orthogroup_upset.py "$ORTHOFINDER_RESULTS_DIR/Orthogroups/Orthogroups.tsv" \
  "$FIGURE_DIR/orthogroup_upset.png" "$FIGURE_DIR/orthogroup_upset.pdf"
MPLBACKEND=Agg python3 scripts/plot_tree.py "$PHYLO_DIR/supermatrix_tree.treefile" "$FIGURE_DIR/tree_supermatrix.png" \
  "Supermatrix tree (IQ-TREE)" $GROUPS_FILE
MPLBACKEND=Agg python3 scripts/plot_tree.py "$PHYLO_DIR/astral_tree.nwk" "$FIGURE_DIR/tree_astral.png" \
  "Species tree (ASTRAL)" $GROUPS_FILE

echo "✅ Figures saved to: $FIGURE_DIR"
