#!/usr/bin/env python3
import sys
import os
import pandas as pd
from Bio import SeqIO

# The script now expects paths as command line arguments
orthogroups_tsv = sys.argv[1]
fasta_base_dir = sys.argv[2]
out_dir = sys.argv[3]
sample_ids = sys.argv[4:]

og_df = pd.read_csv(orthogroups_tsv, sep='\t')
sco_list_file = "single_copy_orthogroups.txt"
sco_list = [line.strip() for line in open(sco_list_file)]

# Mapping sample name -> protein fasta path
sample_map = {
    sid: os.path.join(fasta_base_dir, f"{sid}_funanno", "predict_results", f"Fungus_sp_{sid}.proteins.fa")
    for sid in sample_ids
}

os.makedirs(out_dir, exist_ok=True)

missing = 0
written = 0

for og in sco_list:
    if og not in og_df["Orthogroup"].values:
        print(f"[WARNING] Orthogroup '{og}' not found in Orthogroups.tsv — skipping.")
        missing += 1
        continue
    row = og_df[og_df["Orthogroup"] == og].iloc[0]
    records = []
    for species, genes in row.items():
        if species == "Orthogroup" or pd.isna(genes):
            continue
        gene_id = genes.split(", ")[0]
        sample_id = species.split('_proteins')[0]
        fpath = sample_map.get(sample_id)

        if not fpath or not os.path.exists(fpath):
            continue

        found_gene = False
        for rec in SeqIO.parse(fpath, "fasta"):
            if rec.id == gene_id:
                rec.id = sample_id
                rec.description = ""
                records.append(rec)
                found_gene = True
                break
        if not found_gene:
            print(f"[WARN] gene_id {gene_id} NOT found in FASTA {fpath}")

    if len(records) >= len(sample_ids):
        with open(f"{out_dir}/{og}.faa", "w") as out:
            SeqIO.write(records, out, "fasta")
        written += 1

print(f"✅ Finished extracting sequences.\n✔️ Total written: {written}\n❌ Orthogroups missing from TSV: {missing}")