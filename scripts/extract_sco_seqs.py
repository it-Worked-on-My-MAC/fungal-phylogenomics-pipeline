#!/usr/bin/env python3
import sys
import pandas as pd

# The script now expects paths as command line arguments
input_tsv = sys.argv[1]
output_file = sys.argv[3]
sample_ids = sys.argv[2:]

df = pd.read_csv(input_tsv, sep='\t', index_col=0)
sample_cols = [col for col in df.columns if any(col.startswith(f"{sid}_") for sid in sample_ids)]
sco = df[sample_cols][(df[sample_cols] == 1).all(axis=1)]

print(f"Found {sco.shape[0]} single-copy orthogroups across all {len(sample_ids)} samples")

sco.index.to_series().to_csv(output_file, index=False, header=False)