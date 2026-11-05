#!/bin/bash

# Load configuration file
source bin/00_config.sh

echo "🧬 Step 8: Preparing Proteomes for OrthoFinder"

mkdir -p "$ORTHOLOGY_DIR/proteomes"

echo "[ORTHOLOGY] Copying protein FASTA files..."
for ID in "${ORTHO_SAMPLES[@]}"; do
  PROTEIN_IN=$(ls "$FUNANNOTATE_DIR/${ID}_funanno/predict_results/"*.proteins.fa 2>/dev/null | head -1 || true)
  PROTEIN_OUT="$ORTHOLOGY_DIR/proteomes/${ID}_proteins.fa"
  if [[ -n "$PROTEIN_IN" ]]; then
    cp "$PROTEIN_IN" "$PROTEIN_OUT"
  else
    echo "❌ Protein file not found for $ID" >&2
    exit 1
  fi
done

echo "✅ All proteomes prepared in: $ORTHOLOGY_DIR/proteomes"