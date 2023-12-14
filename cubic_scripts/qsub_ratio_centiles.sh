#!/bin/bash
# Apply ComFam() with different arguments to specified dataset

#######################################################################################
# GET ARGS
if [ $# -lt 1 ]
then
	echo 1>&2 "$0: provide # of M:F ratios modeled"
	exit 2
fi
#######################################################################################
# SET PATHS
img=/cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif #singularity image
base=/cbica/home/gardnerm/combat-biovar #base path (cubic) - also path that output csvs will be saved to
r_script=$base/cubic_scripts/R_scripts/fit_centiles.R #path to .R script
csv_path=$base/data/ukb_ratios #path to data csvs
mod_path=$base/ukb_ratios/gamlss_objs #path to gamlss .rds objs
#######################################################################################
cd $base/cubic_scripts #to source functions correctly
#######################################################################################
# MAKE DIRECTORY

#qsub script & job outputs
bash_dir=$base/ukb_ratios/centile_qsubs
if ! [ -d $bash_dir ]
	then
	mkdir $bash_dir
	else
	#remove old error messages if necessary
	rm -rf $bash_dir/*.txt
	fi

#csv outputs outputs
save_dir=$base/ukb_ratios/perm_centile_csvs
if ! [ -d $save_dir ]
	then
	mkdir $save_dir
	else
	#remove old error outputs if necessary
	rm -rf $bash_dir/*.*
	fi

#######################################################################################
#LIST POSSIBLE CONFIGS, INCLUDING NAME OF ORIGINAL RAW DATA
#be sure to include "data" at the end of the string so refA options aren't confused
config_list="cf_data cf.lm_data cf.gam_data cf.gamlss_data raw" #cf.lm_refA_data cf.gam_refA_data cf.gamlss_refA_data ukb_CN_data
#######################################################################################
#LIST permutations
for p in $(seq -f "%02g" 1 $1)
do
	#iterate through combat configs
	for config in $config_list
	do
		f_string=prop-${p}-${config}
		echo "Prepping $f_string"
		#write bash script
		bash_script=$bash_dir/${f_string}_cent.sh
		touch $bash_script
		
		echo "singularity run --cleanenv $img Rscript --save $r_script $csv_path $mod_path $save_dir $f_string" > $bash_script

		#qsub bash script
		qsub -N $f_string -o $bash_dir/${f_string}_out.txt -e $bash_dir/${f_string}_err.txt $bash_script
	done
done
