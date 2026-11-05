#!/bin/bash

# ==============================================================================
# CONFIGURATION FILE for Fungal Phylogenomics Pipeline
# Defines all global variables, paths, and sample lists for use across scripts.
# ==============================================================================

set -eo pipefail   # stop at the first failed command

# Make "conda activate" work inside scripts. Set NO_CONDA=1 if all tools are already on PATH.
if [[ -n "${NO_CONDA:-}" ]]; then
  conda() { :; }
else
  eval "$(conda shell.bash hook)"
fi

# All outputs go under WORK_DIR (default: this folder).
WORK_DIR="${WORK_DIR:-.}"

# --- CONDA ENVIRONMENTS ---
# You can define your conda environments here to ensure consistency.
# Use the names you have already created or plan to create.
# Example: conda create -n trim_quality fastqc trimmomatic
# ENV_ROOT is optional: set it to keep the environments in one folder.
ENV_PREFIX="${ENV_ROOT:+$ENV_ROOT/}"
CONDA_TRIM_QUALITY="${ENV_PREFIX}trim_quality"
CONDA_ASSEMBLY="${ENV_PREFIX}assembly"
CONDA_QUAST="${ENV_PREFIX}quast"
CONDA_FUNANNOTATE="${ENV_PREFIX}funannotate_env"
CONDA_ORTHOFINDER="${ENV_PREFIX}orthofinder_env"
CONDA_PHYLO="${ENV_PREFIX}phylo_env"
CONDA_FASTANI="${ENV_PREFIX}fastani_env"

# --- THREADS ---
# Number of threads/cores to use for multi-threaded tools.
THREADS="${THREADS:-8}"

# --- SAMPLE LISTS ---
# Sample IDs are read from a plain-text file (one ID per line, '#' = comment).
# Raw reads must be named <ID>_1.fq.gz / <ID>_2.fq.gz inside $READS_DIR.
# Copy examples/samples.example.txt to samples.txt and edit it for your own data.
SAMPLES_FILE="${SAMPLES_FILE:-$WORK_DIR/samples.txt}"
if [[ -f "$SAMPLES_FILE" ]]; then
  mapfile -t ALL_SAMPLES < <(grep -vE '^[[:space:]]*(#|$)' "$SAMPLES_FILE")
else
  echo "Warning: $SAMPLES_FILE not found (see examples/samples.example.txt)" >&2
  ALL_SAMPLES=()
fi
# Per-step subsets default to all samples; override here if a step needs fewer.
MASH_SAMPLES=("${ALL_SAMPLES[@]}")
FASTANI_SAMPLES=("${ALL_SAMPLES[@]}")
ORTHO_SAMPLES=("${ALL_SAMPLES[@]}")

# --- DIRECTORY PATHS ---
# Define all input and output directories to keep the pipeline organized.
READS_DIR="$WORK_DIR/reads"
TRIM_DIR="$WORK_DIR/results_trimmed"
ASSEMBLY_DIR="$WORK_DIR/results_assembly"
QUAST_DIR="$WORK_DIR/results_quast"
MASH_DIR="$WORK_DIR/results_mash"
FASTANI_DIR="$WORK_DIR/results_fastani"
FUNANNOTATE_DIR="$WORK_DIR/results_funannotate"
ORTHOLOGY_DIR="$WORK_DIR/results_orthology"

# Paths for the phylogenomics sub-pipeline
PHYLO_DIR="$WORK_DIR/results_phylogeny"
SCO_ALIGN_DIR="$PHYLO_DIR/aligned_single_copy"
SCO_EXTRACT_DIR="$PHYLO_DIR/sco_sequences"
GENE_TREE_DIR="$PHYLO_DIR/gene_trees"
SUPERMATRIX_FILE="$PHYLO_DIR/supermatrix.fasta"
FIGURE_DIR="$WORK_DIR/results_figures"
# The default is the folder made by step 9, which names its run "pipeline".
ORTHOFINDER_RESULTS_DIR="${ORTHOFINDER_RESULTS_DIR:-${ORTHOLOGY_DIR}/proteomes/OrthoFinder/Results_pipeline}"

# --- FUNANNOTATE SETTINGS ---
# Annotation-specific parameters
AUGUSTUS_MODEL="botrytis_cinerea"
BUSCO_LINEAGE="ascomycota"
FUNANNOTATE_DB="${FUNANNOTATE_DB:-$HOME/.funannotate_db}"

# --- TOOL SETTINGS ---
ADAPTERS="${ADAPTERS:-TruSeq3-PE-2.fa}"   # Trimmomatic adapter file
GENE_TREE_MODEL="${GENE_TREE_MODEL:-MFP}"          # MFP = ModelFinder; slow with thousands of genes
SUPERMATRIX_MODEL="${SUPERMATRIX_MODEL:-MFP}"
MASH_K=21
MASH_SKETCH=10000
ASTRAL_GENES=100                          # gene trees sampled at random for ASTRAL
ASTRAL_CMD="${ASTRAL_CMD:-astral}"
