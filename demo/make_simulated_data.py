#!/usr/bin/env python3
"""Simulate genomes, reads and proteins for the demo. Nothing here is real biology.

Two made-up groups of 6 isolates: about 6% divergence between groups, under 1% within.
Each genome has 250 protein-coding genes; 20 accessory genes are lost at random.

Usage: make_simulated_data.py WORK_DIR
"""
import gzip
import os
import random
import sys

work = sys.argv[1]
random.seed(7)
N_GENES, ACCESSORY = 250, 20
COVERAGE, READ_LEN, FRAGMENT = 30, 100, 400
CODONS = [a + b + c for a in "ACGT" for b in "ACGT" for c in "ACGT" if a + b + c not in ("TAA", "TAG", "TGA")]
TABLE = {}
for i, codon in enumerate(a + b + c for a in "TCAG" for b in "TCAG" for c in "TCAG"):
    TABLE[codon] = "FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG"[i]
COMPLEMENT = str.maketrans("ACGT", "TGCA")


def revcomp(seq):
    return seq.translate(COMPLEMENT)[::-1]


def translate(codons):
    return "".join(TABLE[c] for c in codons)


def mutate(genes, rate):
    return [[random.choice(CODONS) if random.random() < rate else c for c in gene] for gene in genes]


def random_dna(length):
    return "".join(random.choice("ACGT") for _ in range(length))


ancestor = [[random.choice(CODONS) for _ in range(random.randint(200, 350))] for _ in range(N_GENES)]
spacers = [random_dna(150) for _ in range(N_GENES)]
groups = {"A": mutate(ancestor, 0.06), "B": mutate(ancestor, 0.06)}

os.makedirs(f"{work}/reads", exist_ok=True)
samples = []
with open(f"{work}/groups.tsv", "w") as group_file:
    group_file.write("sample_id\tgroup\n")
    for group, base in groups.items():
        for n in range(1, 7):
            sample = f"sim{group}{n}"
            samples.append(sample)
            group_file.write(f"{sample}\tSimulated group {group}\n")
            genes = mutate(base, 0.008)
            lost = set(random.sample(range(N_GENES - ACCESSORY, N_GENES), random.randint(0, 8)))

            genome, proteins = "", []
            for g, gene in enumerate(genes):
                genome += spacers[g]
                if g in lost:
                    continue
                genome += "ATG" + "".join(gene) + "TAA"
                proteins.append((f"{sample}_g{g:04d}", "M" + translate(gene)))

            pred = f"{work}/results_funannotate/{sample}_funanno/predict_results"
            os.makedirs(pred, exist_ok=True)
            with open(f"{pred}/Fungus_sp_{sample}.proteins.fa", "w") as out:
                for name, protein in proteins:
                    out.write(f">{name}\n{protein}*\n")

            n_pairs = COVERAGE * len(genome) // (2 * READ_LEN)
            with gzip.open(f"{work}/reads/{sample}_1.fq.gz", "wt", compresslevel=1) as r1, \
                    gzip.open(f"{work}/reads/{sample}_2.fq.gz", "wt", compresslevel=1) as r2:
                for i in range(n_pairs):
                    start = random.randint(0, len(genome) - FRAGMENT)
                    fragment = genome[start:start + FRAGMENT]
                    qual = "".join(random.choices("FFFFFFFF:,", k=READ_LEN))
                    r1.write(f"@{sample}_{i}/1\n{fragment[:READ_LEN]}\n+\n{qual}\n")
                    r2.write(f"@{sample}_{i}/2\n{revcomp(fragment)[:READ_LEN]}\n+\n{qual}\n")

with open(f"{work}/samples.txt", "w") as out:
    out.write("\n".join(samples) + "\n")
with open(f"{work}/adapters.fa", "w") as out:
    out.write(">PrefixPE/1\nTACACTCTTTCCCTACACGACGCTCTTCCGATCT\n>PrefixPE/2\nGTGACTGGAGTTCAGACGTGTGCTCTTCCGATCT\n")
print(f"Simulated {len(samples)} isolates in {work}")
