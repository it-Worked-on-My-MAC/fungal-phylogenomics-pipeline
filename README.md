<p align="center">
  <img src="docs/banner.svg" alt="Fungal Phylogenomics Pipeline" width="100%">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white" alt="Bash">
  <img src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python">
  <img src="https://img.shields.io/badge/Conda-44A833?style=for-the-badge&logo=anaconda&logoColor=white" alt="Conda">
  <img src="https://img.shields.io/badge/SLURM-HPC-0f766e?style=for-the-badge" alt="SLURM HPC">
  <img src="https://img.shields.io/badge/data-none%20(code%20only)-64748b?style=for-the-badge" alt="Code only">
</p>

<p align="center"><b>A config-driven pipeline that takes paired-end reads all the way to assemblies, annotations, orthogroups and species trees.</b><br>
Built for comparing fungal isolates, reusable for any set of genomes.</p>

---

## Pipeline at a glance

<p align="center">
  <img src="docs/pipeline.svg" alt="Pipeline overview: QC and trim, assemble, compare, annotate, orthology, phylogeny" width="100%">
</p>

| Stage | What it does | Tools |
|:--|:--|:--|
| **1 · QC & Trim** | Read quality reports, adapter and quality trimming | FastQC, Trimmomatic |
| **2 · Assemble** | De novo assembly and assembly quality metrics | SPAdes, QUAST |
| **3 · Compare** | Genome-wide distances and average nucleotide identity | Mash, FastANI |
| **4 · Annotate** | Repeat masking and gene prediction | Funannotate |
| **5 · Orthology** | Orthogroups and gene-count tables | OrthoFinder |
| **6 · Phylogeny** | Single-copy ortholog trees, supermatrix and consensus species trees | MAFFT, IQ-TREE |

## Why this pipeline

- **One config, many steps.** Paths, thread counts, conda environments and sample lists all live in `bin/00_config.sh`.
- **Plain text samples.** List your IDs in `samples.txt`; nothing is hard-coded in the scripts.
- **Two tree methods.** Concatenated supermatrix tree and gene-tree consensus, side by side.
- **Publication-style plots.** Dendrograms, heatmaps, UpSet plots and QUAST bar charts, with optional group labels.
- **HPC friendly.** Plain Bash and Python, so it drops into a SLURM job script.

## Quick start

```bash
git clone https://github.com/it-Worked-on-My-MAC/fungal-phylogenomics-pipeline.git
cd fungal-phylogenomics-pipeline

# 1. reads go in ./reads as <ID>_1.fq.gz and <ID>_2.fq.gz
# 2. list your sample IDs
cp examples/samples.example.txt samples.txt

# 3. run the steps in order
bash bin/01_trimming_and_fastqc.sh
bash bin/02_assembly_spades.sh
# ... through bin/10_run_phylogenomics_pipeline.sh
```

Optional group labels for the plots: copy `examples/groups.example.tsv`, edit it, and pass it as the last argument to the plotting scripts.

## Repository layout

```text
├── bin/        numbered pipeline steps (00_config.sh, 01_… to 10_…)
├── scripts/    Python helpers: ortholog extraction, supermatrix, plots
├── examples/   dummy sample list and group file (no real data)
└── docs/       README images
```

<details>
<summary><b>Script reference</b></summary>

| Script | Purpose |
|:--|:--|
| `bin/01_trimming_and_fastqc.sh` | FastQC and Trimmomatic on raw paired reads |
| `bin/02_assembly_spades.sh` | SPAdes assembly of trimmed reads |
| `bin/03_quast_evaluation.sh` | QUAST report for each assembly |
| `bin/04_summarize_quast_results.sh` | Contigs, total length, N50 and GC into one table |
| `bin/05_mash_analysis.sh` | Mash sketches, distances and a quick tree |
| `bin/06_fastani_analysis.sh` | All-vs-all average nucleotide identity |
| `bin/07_funannotate_prediction.sh` | Contig filtering, repeat masking, gene prediction |
| `bin/08_prepare_proteomes_for_orthofinder.sh` | Collects protein FASTA files |
| `bin/09_run_orthofinder.sh` | Orthogroup inference |
| `bin/10_run_phylogenomics_pipeline.sh` | Single-copy orthologs, alignment, gene trees, supermatrix, species trees |
| `scripts/plot_quast_metrics.py` | Assembly quality bar plots |
| `scripts/plot_mash_dendrogram.py` · `plot_mash_heatmap.py` | Mash dendrogram and clustered heatmap |
| `scripts/plot_fastani_dendrogram.py` | ANI-based dendrogram |
| `scripts/plot_orthogroup_upset.py` | Orthogroup overlap across species |
| `scripts/extract_scos.py` · `extract_sco_seqs.py` · `build_supermatrix.py` | Phylogenomics helpers |

</details>

<details>
<summary><b>Required software</b></summary>

FastQC, Trimmomatic, SPAdes, QUAST, Mash, FastANI, Funannotate, OrthoFinder, MAFFT, IQ-TREE, plus Python packages Biopython, pandas, matplotlib, seaborn, scipy and upsetplot. Conda environment names are set in `bin/00_config.sh`.

</details>

## Data policy

This repository contains **code only**. No sequencing data, assemblies, results or sample metadata are included, and the files in `examples/` use dummy IDs.

---

<p align="center"><sub>Built by <a href="https://www.linkedin.com/in/mahmadtariq/">M. Ahmad Tariq</a> · MSc AgriGenomics, Kiel University</sub></p>
