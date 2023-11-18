#!/bin/bash
# Apply ComFam() with different arguments to specified dataset

#STEP 4 OF VALIDATION PIPELINE#
#######################################################################################
# GET ARGS
if [ $# -lt 1 ]
then
	echo 1>&2 "$0: provide # of permutations to run"
	exit 2
fi
#######################################################################################
# SET PATHS
img=/cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif #singularity image
base=/cbica/home/gardnerm/combat-biovar #base path (cubic) - also path that output csvs will be saved to
r_script=$base/R_scripts/fit_centiles.R #path to .R script
csv_path=$base/data/ukb_permute #path to data csvs
mod_path=$base/ukb_basic/gamlss_objs #path to gamlss .rds objs
#######################################################################################
cd $base #to source functions correctly
#######################################################################################
# MAKE DIRECTORY

#qsub script & job outputs
bash_dir=$base/ukb_permute/centile_qsubs
if ! [ -d $bash_dir ]
	then
	mkdir $bash_dir
	fi

#csv outputs outputs
save_dir=$base/ukb_permute/perm_centile_csvs
if ! [ -d $save_dir ]
	then
	mkdir $save_dir
	fi
#######################################################################################
#LIST POSSIBLE CONFIGS, INCLUDING NAME OF ORIGINAL RAW DATA
#be sure to include "data" at the end of the string so refA options aren't confused
config_list="cf_data cf.lm_data cf.gam_data cf.gamlss_data raw" #cf.lm_refA_data cf.gam_refA_data cf.gamlss_refA_data ukb_CN_data
#######################################################################################
#LIST permutations
for p in $(seq -f "%03g" 1 $1)
do
	#iterate through combat configs
	for config in $config_list
	do
		f_string=perm-${p}-${config}
		echo "Prepping $f_string"
		#write bash script
		bash_script=$bash_dir/${f_string}_cent.sh
		touch $bash_script
		
		echo "singularity run --cleanenv $img Rscript --save $r_script $csv_path $mod_path $save_dir $f_string" > $bash_script

		#qsub bash script
		qsub -N $f_string -o $bash_dir/${f_string}_out.txt -e $bash_dir/${f_string}_err.txt $bash_script
	done
done
