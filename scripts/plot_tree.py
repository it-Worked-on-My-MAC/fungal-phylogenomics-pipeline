#!/usr/bin/env python3
"""Draw a Newick tree, optionally colouring sample labels by group.

Usage: plot_tree.py tree.nwk output.png "Title" [groups.tsv]
"""
import sys
import matplotlib.pyplot as plt
from Bio import Phylo
from group_utils import load_groups

tree = Phylo.read(sys.argv[1], "newick")
tree.ladderize()
output_png = sys.argv[2]
title = sys.argv[3]
groups = load_groups(sys.argv[4] if len(sys.argv) > 4 else None)

levels = sorted(set(groups.values()))
palette = dict(zip(levels, plt.get_cmap("Set2").colors))
colours = {sample: palette[group] for sample, group in groups.items()}
for clade in tree.get_nonterminals():
    clade.name = None

fig, ax = plt.subplots(figsize=(8, 0.4 * tree.count_terminals() + 1.5))
Phylo.draw(tree, axes=ax, do_show=False, label_colors=colours, show_confidence=False)
ax.set_title(title)
ax.set_yticks([])
ax.set_ylabel("")
ax.spines[["top", "right", "left"]].set_visible(False)
fig.tight_layout()
fig.savefig(output_png, dpi=300)
print(f"Saved: {output_png}")
