#!/usr/bin/env python3
"""List orthogroups with exactly one gene in every sample.

Usage: extract_scos.py Orthogroups.GeneCount.tsv output.txt sample1 sample2 ...
"""
import sys
import pandas as pd

gene_count_tsv = sys.argv[1]
output_file = sys.argv[2]
sample_ids = sys.argv[3:]

df = pd.read_csv(gene_count_tsv, sep="\t", index_col=0)
sample_cols = [f"{sid}_proteins" for sid in sample_ids]
sco = df[(df[sample_cols] == 1).all(axis=1)]

print(f"Found {sco.shape[0]} single-copy orthogroups across all {len(sample_ids)} samples")
sco.index.to_series().to_csv(output_file, index=False, header=False)
