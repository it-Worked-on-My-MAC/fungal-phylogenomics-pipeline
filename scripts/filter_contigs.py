#!/usr/bin/env python3
import sys
from Bio import SeqIO

# The script now expects paths as command line arguments
input_fasta = sys.argv[1]
output_fasta = sys.argv[2]
min_len = 500

def valid_contig(seq):
    return len(seq) >= min_len and len(set(seq.upper())) >= 4

with open(output_fasta, "w") as out:
    for record in SeqIO.parse(input_fasta, "fasta"):
        if valid_contig(str(record.seq)):
            SeqIO.write(record, out, "fasta")