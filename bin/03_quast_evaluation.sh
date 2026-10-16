#!/bin/bash

# Load configuration file
source bin/00_config.sh

echo "🔬 Step 3: Assembly Evaluation with QUAST"

# Activate conda environment
conda activate "$CONDA_TRIM_QUALITY"

mkdir -p "$QUAST_DIR"

for ID in "${ALL_SAMPLES[@]}"; do
  echo "[QUAST] Evaluating assembly for $ID..."
  quast.py "$ASSEMBLY_DIR/${ID}_spades/contigs.fasta" \
           -o "$QUAST_DIR/${ID}_quast" \
           -t "$THREADS"
done

echo "✅ QUAST analysis complete"