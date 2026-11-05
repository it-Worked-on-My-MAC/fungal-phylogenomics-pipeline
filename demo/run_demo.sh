#!/bin/bash
# demo/run_demo.sh
#
# Runs the whole pipeline on simulated data. Gene prediction (step 7) is skipped:
# the simulator writes the known proteins where step 8 expects them.
#
# Input:  none; needs the tools from the README on PATH
# Output: demo/work/ (not tracked), results/demo_figures/
#
# Run from the repo root: NO_CONDA=1 bash demo/run_demo.sh

set -euo pipefail
# A fixed model replaces ModelFinder here only, to keep the demo short
export GENE_TREE_MODEL=LG+G4 SUPERMATRIX_MODEL=LG+G4
export WORK_DIR=demo/work ADAPTERS=demo/work/adapters.fa GROUPS_FILE=demo/work/groups.tsv
[[ -n "${RESUME:-}" ]] || rm -rf demo/work
mkdir -p demo/work

python3 demo/make_simulated_data.py demo/work
for step in 01_trimming_and_fastqc 02_assembly_spades 03_quast_evaluation 04_summarize_quast_results \
            05_mash_analysis 06_fastani_analysis 08_prepare_proteomes_for_orthofinder 09_run_orthofinder \
            10_run_phylogenomics_pipeline 11_make_figures; do
  bash "bin/$step.sh"
done
python3 demo/check_demo.py demo/work

mkdir -p results/demo_figures
cp demo/work/results_figures/*.png results/demo_figures/
