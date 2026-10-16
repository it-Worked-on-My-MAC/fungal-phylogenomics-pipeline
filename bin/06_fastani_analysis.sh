#!/bin/bash

# Load configuration file
source bin/00_config.sh

echo "🔬 Step 6: Average Nucleotide Identity with FastANI"

# Activate conda environment
conda activate "$CONDA_FASTANI"

# Check if fastANI is available
command -v fastANI >/dev/null 2>&1 || { echo "Error: fastANI not found in PATH."; exit 1; }

QUERY_LIST="$FASTANI_DIR/query_list.txt"
REF_LIST="$FASTANI_DIR/ref_list.txt"
FASTANI_OUT="$FASTANI_DIR/fastani_all_vs_all.txt"

mkdir -p "$FASTANI_DIR"
: > "$QUERY_LIST"
: > "$REF_LIST"

echo "📦 Generating query and reference list..."
for SAMPLE in "${FASTANI_SAMPLES[@]}"; do
    CONTIG="$ASSEMBLY_DIR/${SAMPLE}_spades/contigs.fasta"
    if [[ -f "$CONTIG" ]]; then
        echo "$CONTIG" >> "$QUERY_LIST"
        echo "$CONTIG" >> "$REF_LIST"
    else
        echo "⚠️  Warning: $CONTIG not found!"
    fi
done

if [[ ! -s "$QUERY_LIST" ]] || [[ ! -s "$REF_LIST" ]]; then
  echo "❌ Error: No valid contig files found to run FastANI."
  exit 1
fi

echo "✅ Found $(wc -l < "$QUERY_LIST") contigs for analysis."

echo "🚀 Running FastANI with $THREADS threads..."
fastANI \
  --ql "$QUERY_LIST" \
  --rl "$REF_LIST" \
  -o "$FASTANI_OUT" \
  -t "$THREADS"

echo "✅ FastANI complete!"
echo "📄 Output saved to: $FASTANI_OUT"