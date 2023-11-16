#!/bin/bash
img=/cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif #singularity image
base=/cbica/home/gardnerm/combat-biovar #base path (cubic)
og_data=$base/data/ukb_CN_data_agefilt.csv #path to original data for which site assignments should be permuted
save_data_path=$base/data/ukb_permute
pheno_path=$base/pheno_lists #path to .txt files listing phenotypes (global & regional)
# paths to R scripts
permute_script=$base/R_scripts/permute_sites.R
cf_script=$base/R_scripts/combat_apply.R
mod_script=$base/R_scripts/fit_basic_mod.R

config_list="cf cf.lm cf.gam cf.gamlss"

#expect # csvs in save_data_path = # permutations called for * (# combat permutations + 1)
cf_len=`echo ${config_list[@]} | wc -w`
combat_counts=$(($1*(${cf_len}+1)))
echo "submitted ${cf_len} combat configurations, looking for ${combat_counts} output csvs"
