#!/bin/bash
# cluster/run_all.sh
#
# Runs the whole pipeline on public Alternaria genomes on the CAU cluster, separately from
# any other project. On a login node it installs the conda environments, downloads the reads
# and databases, then submits itself; compute nodes have no internet. Finished steps are
# skipped, so a job that hits its time limit can be resubmitted the same way.
#
# Input:  cluster/public_samples.tsv (run accessions from ENA)
# Output: $PROJECT_ROOT/phylo_run/, results/public_data_figures/
#
# Run from the repo root on a login node: bash cluster/run_all.sh
#SBATCH --job-name=fungal_phylo
#SBATCH --partition=base
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=16:00:00
#SBATCH --output=%x_%j.out

set -eo pipefail
PROJECT_ROOT="${PROJECT_ROOT:-/work_beegfs/$USER/portfolio}"
export ENV_ROOT="$PROJECT_ROOT/conda"
export WORK_DIR="$PROJECT_ROOT/phylo_run"
export FUNANNOTATE_DB="$PROJECT_ROOT/funannotate_db"
export GROUPS_FILE="$WORK_DIR/groups.tsv"
export TARGET_BASES=1400000000     # about 40x of a 35 Mb genome

module load gcc12-env/12.1.0 miniconda3
eval "$(conda shell.bash hook)"

# make_env <name> <tool that must exist afterwards> <packages...>
make_env() {
  local name=$1 tool=$2; shift 2
  [[ -x "$ENV_ROOT/$name/bin/$tool" ]] && return 0
  rm -rf "$ENV_ROOT/$name"     # left over from an install that did not finish
  echo "Creating conda environment: $name"
  conda create -y -p "$ENV_ROOT/$name" --override-channels -c conda-forge -c bioconda "$@"
}

check_tool() {
  local env=$1; shift
  conda activate "$ENV_ROOT/$env"
  for tool in "$@"; do
    command -v "$tool" > /dev/null || { echo "❌ $tool is missing from $env" >&2; exit 1; }
  done
  conda deactivate
}

if [[ -z "${SLURM_JOB_ID:-}" ]]; then
  # ---------- login node: install, download, submit ----------
  mkdir -p "$ENV_ROOT" "$WORK_DIR/reads" "$FUNANNOTATE_DB"
  make_env download seqtk seqtk
  make_env trim_quality trimmomatic trimmomatic=0.39 fastqc
  make_env assembly spades.py spades
  make_env quast quast.py quast "python=3.11"   # QUAST imports distutils, removed in Python 3.12
  make_env fastani_env fastANI fastani
  make_env funannotate_env funannotate funannotate
  make_env orthofinder_env orthofinder orthofinder
  make_env phylo_env mash mash mafft iqtree astral-tree biopython pandas seaborn scipy matplotlib

  check_tool download seqtk
  check_tool trim_quality trimmomatic fastqc
  check_tool assembly spades.py
  check_tool quast quast.py
  "$ENV_ROOT/quast/bin/quast.py" --version
  check_tool fastani_env fastANI
  check_tool funannotate_env funannotate
  check_tool orthofinder_env orthofinder
  check_tool phylo_env mash mafft iqtree astral

  # sample list and group file
  tail -n +2 cluster/public_samples.tsv | cut -f1 > "$WORK_DIR/samples.txt"
  { echo -e "sample_id\tgroup"; tail -n +2 cluster/public_samples.tsv; } > "$GROUPS_FILE"

  # reads from ENA, reduced to about TARGET_BASES per isolate
  conda activate "$ENV_ROOT/download"
  for ID in $(cat "$WORK_DIR/samples.txt"); do
    [[ -s "$WORK_DIR/reads/${ID}_2.fq.gz" ]] && continue
    echo "Downloading $ID"
    info=$(curl -sf "https://www.ebi.ac.uk/ena/portal/api/filereport?accession=$ID&result=read_run&fields=base_count,fastq_ftp&format=tsv" | tail -1)
    bases=$(cut -f2 <<< "$info")
    urls=$(cut -f3 <<< "$info" | tr ';' '\n' | grep -E '_[12]\.fastq\.gz$')
    [[ $(wc -l <<< "$urls") -eq 2 ]] || { echo "❌ $ID does not have two FASTQ files" >&2; exit 1; }
    fraction=$(awk -v t="$TARGET_BASES" -v b="$bases" 'BEGIN { print (b > t) ? t / b : 1 }')
    n=1
    for url in $urls; do
      wget -q -c -O "$WORK_DIR/reads/${ID}_raw_$n.fastq.gz" "https://$url"
      seqtk sample -s 11 "$WORK_DIR/reads/${ID}_raw_$n.fastq.gz" "$fraction" | gzip > "$WORK_DIR/reads/${ID}_$n.part.gz"
      mv "$WORK_DIR/reads/${ID}_$n.part.gz" "$WORK_DIR/reads/${ID}_$n.fq.gz"
      rm "$WORK_DIR/reads/${ID}_raw_$n.fastq.gz"
      n=$((n + 1))
    done
  done
  conda deactivate

  # Funannotate databases
  if [[ ! -f "$FUNANNOTATE_DB/.setup_done" ]]; then
    conda activate "$ENV_ROOT/funannotate_env"
    funannotate setup -i all -b ascomycota -d "$FUNANNOTATE_DB"
    conda deactivate
    touch "$FUNANNOTATE_DB/.setup_done"
  fi

  sbatch cluster/run_all.sh
  echo "✅ Submitted. Follow it with: squeue -u $USER"
  exit 0
fi

# ---------- compute node: run every step in order ----------
cd "$SLURM_SUBMIT_DIR"
export THREADS="$SLURM_CPUS_PER_TASK"
export ADAPTERS
ADAPTERS=$(find "$ENV_ROOT/trim_quality/share" -name 'TruSeq3-PE-2.fa' | head -1)
export GENE_TREE_MODEL=LG+G4       # ModelFinder on thousands of gene trees would take days

mkdir -p "$WORK_DIR/.done"
for step in 01_trimming_and_fastqc 02_assembly_spades 03_quast_evaluation 04_summarize_quast_results \
            05_mash_analysis 06_fastani_analysis 07_funannotate_prediction \
            08_prepare_proteomes_for_orthofinder 09_run_orthofinder 10_run_phylogenomics_pipeline 11_make_figures; do
  [[ -f "$WORK_DIR/.done/$step" ]] && { echo "Skipping $step (already finished)"; continue; }
  echo "=== $step: $(date)"
  bash "bin/$step.sh"
  touch "$WORK_DIR/.done/$step"
done

mkdir -p results/public_data_figures
cp "$WORK_DIR"/results_figures/*.png results/public_data_figures/
echo "✅ Finished: $(date). Figures in results/public_data_figures/"
