#!/usr/bin/env python3
import sys
import os
from Bio import AlignIO
from collections import defaultdict

# The script now expects directories as command line arguments
align_dir = sys.argv[1]
out_file = sys.argv[2]

species_seqs = defaultdict(str)

for fname in sorted(os.listdir(align_dir)):
    if not fname.endswith(".aln.faa"):
        continue
    aln_path = os.path.join(align_dir, fname)
    aln = AlignIO.read(aln_path, "fasta")
    length = aln.get_alignment_length()
    aln_map = {rec.id: str(rec.seq) for rec in aln}
    for sp in species_seqs.keys() | aln_map.keys():
        species_seqs[sp] += aln_map.get(sp, "-" * length)

with open(out_file, "w") as out:
    for sp, seq in species_seqs.items():
        out.write(f">{sp}\n{seq}\n")