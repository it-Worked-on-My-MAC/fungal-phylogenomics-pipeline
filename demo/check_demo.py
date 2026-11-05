#!/usr/bin/env python3
"""Fail if the demo does not recover the simulated groups.

Usage: check_demo.py WORK_DIR
"""
import re
import sys
import pandas as pd
from Bio import Phylo

work = sys.argv[1]


def sample(path):
    return re.search(r"/([^/]+)_spades/", path).group(1)


def split(df, a, b, value):
    x, y = df[a].map(sample), df[b].map(sample)
    pairs = x != y
    same = x.str[3] == y.str[3]
    return df[value][pairs & same], df[value][pairs & ~same]


ani = pd.read_csv(f"{work}/results_fastani/fastani_all_vs_all.txt", sep="\t", header=None)
within, between = split(ani, 0, 1, 2)
print(f"ANI within groups: {within.min():.2f}-{within.max():.2f}; between: {between.min():.2f}-{between.max():.2f}")
assert within.min() > between.max()

mash = pd.read_csv(f"{work}/results_mash/distances.tab", sep="\t", header=None)
within, between = split(mash, 0, 1, 2)
print(f"Mash within groups: max {within.max():.4f}; between: min {between.min():.4f}")
assert within.max() < between.min()

summary = pd.read_csv(f"{work}/results_quast/QUAST_summary.tsv", sep="\t")
print(f"Assembly length: {summary['Total length'].min()}-{summary['Total length'].max()} bp")
assert len(summary) == 12

for name in ("results_phylogeny/supermatrix_tree.treefile", "results_phylogeny/astral_tree.nwk",
             "results_phylogeny/consensus_tree.contree", "results_mash/tree.nwk"):
    tree = Phylo.read(f"{work}/{name}", "newick")
    tips = {t.name for t in tree.get_terminals()}
    assert len(tips) == 12, name
    group_a = [t for t in tips if t.startswith("simA")]
    # An unrooted split: A tips form a clade once the tree is rooted on a B tip
    tree.root_with_outgroup(next(t for t in tree.get_terminals() if t.name.startswith("simB")))
    assert tree.is_monophyletic([t for t in tree.get_terminals() if t.name in group_a]), name
    print(f"Groups separate in {name}")
print("All checks passed")
