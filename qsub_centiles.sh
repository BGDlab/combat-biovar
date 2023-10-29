#!/bin/bash
# Apply ComFam() with different arguments to specified dataset

#######################################################################################
# SET PATHS
img=/cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif #singularity image
base=/cbica/home/gardnerm/combat-biovar #base path (cubic) - also path that output csvs will be saved to
r_script=$base/R_scripts/fit_centiles.R #path to .R script
csv_path=$base/data/ukb_to_model #path to data csvs
mod_path=$vase/ukb_basic/gamlss_objs #path to gamlss .rds objs
#######################################################################################
cd $base #to source functions correctly
#######################################################################################
# MAKE DIRECTORY

#qsub script & outputs
bash_dir=$base/ukb_basic/centile_qsubs
if ! [ -d $bash_dir ]
	then
	mkdir $bash_dir
	fi
#######################################################################################
#LIST POSSIBLE CONFIGS, INCLUDING NAME OF ORIGINAL RAW DATA
#be sure to include "data" at the end of the string so refA options aren't confused
config_list="cf_data cf.lm_data cf.lm_refA_data cf.gam_data cf.gam_refA_data cf.gamlss_data cf.gamlss_refA_data ukb_CN_data"
#######################################################################################
for config in $config_list
do
	echo "Prepping $config"
	#write bash script
	bash_script=$bash_dir/${config}_cent.sh
	touch $bash_script
	
	echo "singularity run --cleanenv $img Rscript --save $r_script $csv_path $mod_path $base $config" > $bash_script

	#qsub bash script
	qsub -N $config -o $bash_dir/${config}_out.txt -e $bash_dir/${config}_err.txt $bash_script
done
