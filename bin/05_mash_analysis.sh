#!/bin/bash

# Load configuration file
source bin/00_config.sh

echo "🔬 Step 5: Comparative Genomics with Mash"

# Activate conda environment
conda activate "$CONDA_ASSEMBLY"

SKETCH_DIR="$MASH_DIR/sketches"
mkdir -p "$SKETCH_DIR"

# Step 1: Sketch all samples
for ID in "${MASH_SAMPLES[@]}"; do
  echo "[MASH] Sketching sample $ID..."
  mash sketch -p "$THREADS" -o "$SKETCH_DIR/${ID}" \
    "$ASSEMBLY_DIR/${ID}_spades/contigs.fasta"
done

# Step 2: Combine all sketches
echo "[MASH] Combining sketches..."
mash paste "$MASH_DIR/all_samples" "$SKETCH_DIR"/*.msh

# Step 3: Compute pairwise distances
echo "[MASH] Calculating pairwise distances..."
mash dist "$MASH_DIR/all_samples.msh" "$MASH_DIR/all_samples.msh" > "$MASH_DIR/distances.tab"

# Step 4: Create tree file (Newick format)
echo "[MASH] Building tree..."
mash tree "$MASH_DIR/all_samples.msh" > "$MASH_DIR/tree.nwk"

echo "✅ Mash analysis complete. Tree saved to: $MASH_DIR/tree.nwk"