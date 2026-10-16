#!/bin/bash

# Load configuration file
source bin/00_config.sh

echo "🌳 Step 10: Phylogenomics Pipeline"

# Activate conda environment
conda activate "$CONDA_PHYLO"

mkdir -p "$SCO_ALIGN_DIR" "$SCO_EXTRACT_DIR" "$GENE_TREE_DIR"

# Step 1: Extract single-copy orthogroups
echo "🔎 Extracting single-copy orthogroups..."
python3 scripts/extract_scos.py \
  "$ORTHOFINDER_RESULTS_DIR/Orthogroups/Orthogroups.GeneCount.tsv" \
  "${ALL_SAMPLES[@]}" \
  "single_copy_orthogroups.txt"

# Step 2: Extract SCO sequences
echo "📦 Extracting SCO sequences..."
python3 scripts/extract_sco_seqs.py \
  "$ORTHOFINDER_RESULTS_DIR/Orthogroups/Orthogroups.tsv" \
  "$FUNANNOTATE_DIR" \
  "$SCO_EXTRACT_DIR" \
  "${ALL_SAMPLES[@]}"

# Step 3: Align sequences with MAFFT
echo "🧬 Aligning protein sequences with MAFFT..."
for faa in "$SCO_EXTRACT_DIR"/*.faa; do
  base=$(basename "$faa" .faa)
  mafft --quiet --auto "$faa" > "$SCO_ALIGN_DIR/$base.aln.faa"
done

# Step 4: Build gene trees with IQ-TREE
echo "🌳 Building gene trees with IQ-TREE..."
for aln in "$SCO_ALIGN_DIR"/*.aln.faa; do
  base=$(basename "$aln" .aln.faa)
  iqtree -quiet -s "$aln" -m MFP -nt AUTO -pre "$GENE_TREE_DIR/$base"
done

# Step 5: Build concatenated supermatrix
echo "🧩 Building concatenated supermatrix..."
python3 scripts/build_supermatrix.py "$SCO_ALIGN_DIR" "$SUPERMATRIX_FILE"

# Step 6: Infer species tree from supermatrix
echo "🧠 Inferring species tree from supermatrix..."
iqtree -quiet -s "$SUPERMATRIX_FILE" -m MFP -bb 1000 -nt AUTO -pre "tree_run"

# Step 7: Build consensus tree from gene trees
echo "🧠 Generating consensus tree from gene trees..."
cat "$GENE_TREE_DIR"/*.treefile > all_gene_trees.tre
iqtree -quiet -t all_gene_trees.tre --consensus -pre "consensus_tree"

echo "✅ Pipeline completed."
echo "  - Supermatrix tree: tree_run.treefile"
echo "  - Consensus tree:   consensus_tree.treefile"