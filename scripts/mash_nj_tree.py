#!/usr/bin/env python3
"""Build a neighbour-joining tree from a Mash distance table.

Usage: mash_nj_tree.py distances.tab tree.nwk
"""
import re
import sys
import pandas as pd
from Bio import Phylo
from Bio.Phylo.TreeConstruction import DistanceMatrix, DistanceTreeConstructor

df = pd.read_csv(sys.argv[1], sep="\t", header=None,
                 names=["Sample1", "Sample2", "Distance", "Pvalue", "SharedHashes"])

def extract_id(path):
    match = re.search(r"/([^/]+)_spades/", path)
    return match.group(1) if match else path

df["Sample1"] = df["Sample1"].apply(extract_id)
df["Sample2"] = df["Sample2"].apply(extract_id)
matrix = df.pivot(index="Sample1", columns="Sample2", values="Distance")

names = sorted(matrix.index)
lower_triangle = [[float(matrix.loc[a, b]) for b in names[:i + 1]] for i, a in enumerate(names)]
tree = DistanceTreeConstructor().nj(DistanceMatrix(names, lower_triangle))
for clade in tree.get_nonterminals():
    clade.name = None
Phylo.write(tree, sys.argv[2], "newick")
print(f"Saved neighbour-joining tree to {sys.argv[2]}")
