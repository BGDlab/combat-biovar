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

for csv_file in "$save_data_path"/*.csv
do
	#append "raw" suffix to og, non-combatted dfs so that the csvs and models are easily searchable
	# Check if the filename ends with a number
    if [[ $csv_file =~ [0-9]+\.csv ]] 
	then
        # Append "_raw" after the number
        new_name="${csv_file/.csv/_raw.csv}"

        # Rename the file
        mv "$csv_file" "$new_name"
	echo "Renamed: $csv_file -> $new_name"
		csv_name=$(basename $new_name .csv)
	else
		csv_name=$(basename $csv_file .csv)
	fi
	csv_name=${csv_name//_/\-}
	echo "Pulling data from $csv_name"
done
