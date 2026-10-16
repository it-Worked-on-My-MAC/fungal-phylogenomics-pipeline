#!/bin/bash

# Load configuration file
source bin/00_config.sh

echo "🧬 Step 8: Preparing Proteomes for OrthoFinder"

mkdir -p "$ORTHOLOGY_DIR/proteomes"

echo "[ORTHOLOGY] Copying protein FASTA files..."
for ID in "${ORTHO_SAMPLES[@]}"; do
  PROTEIN_IN="$FUNANNOTATE_DIR/${ID}_funanno/predict_results/Fungus_sp_${ID}.proteins.fa"
  PROTEIN_OUT="$ORTHOLOGY_DIR/proteomes/${ID}_proteins.fa"
  if [[ -f "$PROTEIN_IN" ]]; then
    cp "$PROTEIN_IN" "$PROTEIN_OUT"
  else
    echo "⚠️  Protein file not found for $ID, skipping..."
  fi
done

echo "✅ All proteomes prepared in: $ORTHOLOGY_DIR/proteomes"