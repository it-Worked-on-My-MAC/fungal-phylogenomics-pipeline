#!/bin/bash

# ==============================================================================
# CONFIGURATION FILE for Fungal Phylogenomics Pipeline
# Defines all global variables, paths, and sample lists for use across scripts.
# ==============================================================================

# --- CONDA ENVIRONMENTS ---
# You can define your conda environments here to ensure consistency.
# Use the names you have already created or plan to create.
# Example: conda create -n trim_quality fastqc trimmomatic
CONDA_TRIM_QUALITY="trim_quality"
CONDA_ASSEMBLY="assembly"
CONDA_FUNANNOTATE="funannotate_env"
CONDA_ORTHOFINDER="orthofinder_env"
CONDA_PHYLO="phylo_env"
CONDA_FASTANI="fastani_env"

# --- THREADS ---
# Number of threads/cores to use for multi-threaded tools.
THREADS=8

# --- SAMPLE LISTS ---
# Sample IDs are read from a plain-text file (one ID per line, '#' = comment).
# Raw reads must be named <ID>_1.fq.gz / <ID>_2.fq.gz inside $READS_DIR.
# Copy examples/samples.example.txt to samples.txt and edit it for your own data.
SAMPLES_FILE="${SAMPLES_FILE:-./samples.txt}"
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
READS_DIR="./reads"
TRIM_DIR="./results_trimmed"
ASSEMBLY_DIR="./results_assembly"
QUAST_DIR="./results_quast"
MASH_DIR="./results_mash"
FASTANI_DIR="./results_fastani"
FUNANNOTATE_DIR="./results_funannotate"
ORTHOLOGY_DIR="./results_orthology"

# Paths for the phylogenomics sub-pipeline
SCO_ALIGN_DIR="./aligned_single_copy"
SCO_EXTRACT_DIR="./sco_sequences"
GENE_TREE_DIR="./gene_trees"
SUPERMATRIX_FILE="supermatrix.fasta"
# OrthoFinder names its output folder Results_<date>; set this to your run's folder.
ORTHOFINDER_RESULTS_DIR="${ORTHOFINDER_RESULTS_DIR:-${ORTHOLOGY_DIR}/proteomes/OrthoFinder/Results_YYYYMMDD}"

# --- FUNANNOTATE SETTINGS ---
# Annotation-specific parameters
AUGUSTUS_MODEL="botrytis_cinerea"
BUSCO_LINEAGE="ascomycota"
FUNANNOTATE_DB="~/.funannotate_db"