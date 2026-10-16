#!/bin/bash

# Load configuration file
source bin/00_config.sh

echo "🧬 Step 9: Running OrthoFinder"

# Activate OrthoFinder environment
conda activate "$CONDA_ORTHOFINDER"

ORTHO_PROTEOMES_DIR="$ORTHOLOGY_DIR/proteomes"

if [ ! -d "$ORTHO_PROTEOMES_DIR" ]; then
    echo "❌ Error: Proteome directory not found: $ORTHO_PROTEOMES_DIR"
    exit 1
fi

echo "[ORTHOFINDER] Running OrthoFinder..."
orthofinder -f "$ORTHO_PROTEOMES_DIR" -t "$THREADS" -a "$THREADS"

echo "✅ OrthoFinder run complete. Check: $ORTHO_PROTEOMES_DIR/OrthoFinder"