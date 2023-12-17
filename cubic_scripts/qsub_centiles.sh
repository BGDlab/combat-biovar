#!/bin/bash

#STEP 4 OF ANALYSIS PIPELINE#

#######################################################################################
# SET PATHS
img=/cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif #singularity image
base=/cbica/home/gardnerm/combat-biovar #base path (cubic) - also path that output csvs will be saved to
r_script=$base/cubic_scripts/R_scripts/fit_centiles.R #path to .R script
csv_path=$base/data/lifespan #path to data csvs
mod_path=$base/lifespan/gamlss_objs #path to gamlss .rds objs
#######################################################################################
cd $base/cubic_scripts #to source functions correctly
#######################################################################################
# MAKE DIRECTORY

#qsub script & outputs
bash_dir=$base/lifespan/centile_qsubs
if ! [ -d $bash_dir ]
	then
	mkdir $bash_dir
	else
	#remove old error messages if necessary
	rm -rf $bash_dir/*.txt
	fi
#######################################################################################
#LIST POSSIBLE CONFIGS, INCLUDING NAME OF ORIGINAL RAW DATA
#be sure to include "data" at the end of the string so refA options aren't confused
config_list="cf.gam cf.gamlss" #cf_data cf.lm_data cf.gam_data cf.gamlss_data #cf.lm_refA_data cf.gam_refA_data cf.gamlss_refA_data ukb_CN_data
#######################################################################################
for config in $config_list
do
	echo "Prepping $config"
	#write bash script
	bash_script=$bash_dir/${config}_cent.sh
	touch $bash_script
	
	echo "singularity run --cleanenv $img Rscript --save $r_script $csv_path $mod_path $base/lifespan $config" > $bash_script

	#qsub bash script
	qsub -N $config -o $bash_dir/${config}_out.txt -e $bash_dir/${config}_err.txt $bash_script
done
