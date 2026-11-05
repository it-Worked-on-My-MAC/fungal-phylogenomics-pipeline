#!/bin/bash

# Load configuration file
source bin/00_config.sh

echo "🧬 Step 1: Quality Control and Trimming with FastQC and Trimmomatic"

# Activate conda environment
conda activate "$CONDA_TRIM_QUALITY"

mkdir -p "$TRIM_DIR"

for ID in "${ALL_SAMPLES[@]}"; do
  echo "[TRIM] Processing sample $ID..."

  # Run FastQC on raw reads
  fastqc "$READS_DIR/${ID}_1.fq.gz" "$READS_DIR/${ID}_2.fq.gz" --outdir "$TRIM_DIR"

  # Run Trimmomatic
  trimmomatic PE -phred33 -threads "$THREADS" \
    "$READS_DIR/${ID}_1.fq.gz" "$READS_DIR/${ID}_2.fq.gz" \
    "$TRIM_DIR/${ID}_1.clean.fq.gz" "$TRIM_DIR/${ID}_1.unpaired.fq.gz" \
    "$TRIM_DIR/${ID}_2.clean.fq.gz" "$TRIM_DIR/${ID}_2.unpaired.fq.gz" \
    "ILLUMINACLIP:$ADAPTERS:2:30:10" SLIDINGWINDOW:4:20 MINLEN:50
done

echo "✅ Batch 1 complete: FastQC and Trimmomatic outputs saved to $TRIM_DIR"