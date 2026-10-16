#!/bin/bash

# Load configuration file
source bin/00_config.sh

echo "🍄 Step 7: Genome Annotation with Funannotate"

# Activate conda environment
conda activate "$CONDA_FUNANNOTATE"

mkdir -p "$FUNANNOTATE_DIR"

for ID in "${ALL_SAMPLES[@]}"; do
  echo "🔬 [FUNANNOTATE] Processing sample $ID..."

  SHORTENED="$ASSEMBLY_DIR/${ID}_spades/contigs_shortened.fasta"
  FILTERED="$ASSEMBLY_DIR/${ID}_spades/contigs_filtered.fasta"
  MASKED="$ASSEMBLY_DIR/${ID}_spades/contigs_masked.fasta"
  FINAL_OUT="$FUNANNOTATE_DIR/${ID}_funanno"

  # Step 1: Shorten headers
  awk 'BEGIN {OFS="\n"} /^>/ {print ">" substr($1, 2, 16)} !/^>/ {print $0}' \
    "$ASSEMBLY_DIR/${ID}_spades/contigs.fasta" > "$SHORTENED"

  # Step 2: Filter contigs
  python scripts/filter_contigs.py "$SHORTENED" "$FILTERED"

  # Step 3: Soft-mask repeats
  funannotate mask -i "$FILTERED" -o "$MASKED" --cpus "$THREADS"

  # Step 4: Predict genes
  funannotate predict -i "$MASKED" \
    -o "$FINAL_OUT" \
    --species "Fungus_sp_${ID}" \
    --cpus "$THREADS" \
    --busco_db "$BUSCO_LINEAGE" \
    --augustus_species "$AUGUSTUS_MODEL" \
    --busco_seed_species "$AUGUSTUS_MODEL" \
    -d "$FUNANNOTATE_DB"

  echo "✅ Sample $ID processed with Funannotate!"
done

echo "🎉 All samples processed with Funannotate!"