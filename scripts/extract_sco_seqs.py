#!/usr/bin/env python3
"""Write one protein FASTA per single-copy orthogroup, named by sample.

Usage: extract_sco_seqs.py Orthogroups.tsv sco_list.txt proteomes_dir out_dir sample1 sample2 ...
"""
import os
import sys
import pandas as pd
from Bio import SeqIO

orthogroups_tsv = sys.argv[1]
sco_list_file = sys.argv[2]
proteomes_dir = sys.argv[3]
out_dir = sys.argv[4]
sample_ids = sys.argv[5:]

os.makedirs(out_dir, exist_ok=True)
og_df = pd.read_csv(orthogroups_tsv, sep="\t", index_col=0)
sco_list = [line.strip() for line in open(sco_list_file) if line.strip()]

# Read each proteome once
proteins = {}
for sid in sample_ids:
    path = os.path.join(proteomes_dir, f"{sid}_proteins.fa")
    proteins[sid] = {rec.id: str(rec.seq).rstrip("*") for rec in SeqIO.parse(path, "fasta")}

for og in sco_list:
    with open(os.path.join(out_dir, f"{og}.faa"), "w") as out:
        for sid in sample_ids:
            gene_id = og_df.loc[og, f"{sid}_proteins"].strip()
            out.write(f">{sid}\n{proteins[sid][gene_id]}\n")

print(f"Wrote {len(sco_list)} orthogroup FASTA files to {out_dir}")
