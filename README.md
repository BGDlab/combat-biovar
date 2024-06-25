# combat-biovar

Testing the ability of [ComBatLS](https://github.com/andy1764/ComBatFamily) to harmonize multisite imaging features while preserving biological variance in scale. 

## eda/
Directory containing .Rmd scripts to clean data and conduct exploratory analyses.

## cubic_scripts/
Directory containing scripts for conducting analyses on PennMedicine HPC.

## pheno_lists/
Directory containing .txt files listing brain features output by freesurfer, broken down by phenotype class (global Volumes & cortical regions CT, SA & Vol).

## ohbm_results.Rmd
Results & figs for OHBM 2024 abstract submission.

## paper_lbcc_results.Rmd
Analyses of LBCC data

## paper_main_results.Rmd
Compilation of main analyses of simulated sites created from UKB data. Includes Figure 2 and some components of Figure 1 (created in Canva) 

## paper_prop_results.Rmd
Analyses of sites simulated with varying M:F from UKB data.

## paper_replication_results.Rmd
Replicating analyses from `paper_main_results.Rmd` when sites are permuted 100 times.

## pull_stats.sh
Script for getting many of the derivatives output by scripts in `cubic_scripts/`.

*SOFTWARE*
All statistical analyses were done locally (R v.) or on the Penn HPC using a Singularity image of the container [mgardner457/r_gamlss:0.0.1](https://hub.docker.com/layers/mgardner457/r_gamlss/0.0.1/images/sha256-c3f3ea6c8bf8e84a467a4fea839dd23ab19a822ab3b3a814c8052d3fd0ecccf2?context=repo)
