#!/bin/bash

# Ensure conda activate works in scripts
__conda_setup="$('/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
eval "$__conda_setup"

# Load configuration file
source bin/00_config.sh

echo "🧬 Step 2: De Novo Assembly with SPAdes"

# Activate conda environment
conda activate "$CONDA_ASSEMBLY"

mkdir -p "$ASSEMBLY_DIR"

for ID in "${ALL_SAMPLES[@]}"; do
  echo "[ASSEMBLY] Assembling sample $ID..."

  spades.py -1 "$TRIM_DIR/${ID}_1.clean.fq.gz" -2 "$TRIM_DIR/${ID}_2.clean.fq.gz" \
            -o "$ASSEMBLY_DIR/${ID}_spades" --careful -t "$THREADS"
done

echo "✅ Batch 2 complete: Assemblies saved to $ASSEMBLY_DIR"