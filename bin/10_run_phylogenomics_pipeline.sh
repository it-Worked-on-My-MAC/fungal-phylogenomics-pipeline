#!/bin/bash

# Load configuration file
source bin/00_config.sh

echo "🌳 Step 10: Phylogenomics Pipeline"

# Activate conda environment
conda activate "$CONDA_PHYLO"

mkdir -p "$SCO_ALIGN_DIR" "$SCO_EXTRACT_DIR" "$GENE_TREE_DIR"

SCO_LIST="$PHYLO_DIR/single_copy_orthogroups.txt"

# Step 1: List single-copy orthogroups
echo "🔎 Finding single-copy orthogroups..."
python3 scripts/extract_scos.py \
  "$ORTHOFINDER_RESULTS_DIR/Orthogroups/Orthogroups.GeneCount.tsv" \
  "$SCO_LIST" \
  "${ALL_SAMPLES[@]}"

# Step 2: Extract their protein sequences
echo "📦 Extracting SCO sequences..."
python3 scripts/extract_sco_seqs.py \
  "$ORTHOFINDER_RESULTS_DIR/Orthogroups/Orthogroups.tsv" \
  "$SCO_LIST" \
  "$ORTHOLOGY_DIR/proteomes" \
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
# one thread per tree, THREADS trees at a time; existing trees are kept so a stopped run can resume
export GENE_TREE_DIR GENE_TREE_MODEL
ls "$SCO_ALIGN_DIR"/*.aln.faa | xargs -P "$THREADS" -I{} bash -c '
  base=$(basename "$1" .aln.faa)
  if [[ ! -s "$GENE_TREE_DIR/$base.treefile" ]]; then
    iqtree -quiet -redo -s "$1" -m "$GENE_TREE_MODEL" -T 1 -pre "$GENE_TREE_DIR/$base"
  fi
' _ {}

# Step 5: Build concatenated supermatrix
echo "🧩 Building concatenated supermatrix..."
python3 scripts/build_supermatrix.py "$SCO_ALIGN_DIR" "$SUPERMATRIX_FILE"

# Step 6: Maximum-likelihood tree from the supermatrix (ModelFinder, 1,000 ultrafast bootstraps)
echo "🧠 Inferring species tree from supermatrix..."
iqtree -quiet -redo -s "$SUPERMATRIX_FILE" -m "$SUPERMATRIX_MODEL" -bb 1000 -T "$THREADS" -pre "$PHYLO_DIR/supermatrix_tree"

# Step 7: Consensus tree from all gene trees
echo "🧠 Generating consensus tree from gene trees..."
cat "$GENE_TREE_DIR"/*.treefile > "$PHYLO_DIR/all_gene_trees.tre"
iqtree -quiet -redo -t "$PHYLO_DIR/all_gene_trees.tre" -con -pre "$PHYLO_DIR/consensus_tree"

# Step 8: ASTRAL species tree from randomly chosen gene trees (multispecies coalescent)
echo "🧠 Running ASTRAL on $ASTRAL_GENES randomly chosen gene trees..."
python3 -c "import random,sys; t=open(sys.argv[1]).readlines(); random.seed(1); random.shuffle(t); open(sys.argv[2],'w').writelines(t[:int(sys.argv[3])])" \
  "$PHYLO_DIR/all_gene_trees.tre" "$PHYLO_DIR/astral_input.tre" "$ASTRAL_GENES"
$ASTRAL_CMD -i "$PHYLO_DIR/astral_input.tre" -o "$PHYLO_DIR/astral_tree.nwk"

echo "✅ Pipeline completed."
echo "  - Supermatrix tree: $PHYLO_DIR/supermatrix_tree.treefile"
echo "  - Consensus tree:   $PHYLO_DIR/consensus_tree.contree"
echo "  - ASTRAL tree:      $PHYLO_DIR/astral_tree.nwk"
