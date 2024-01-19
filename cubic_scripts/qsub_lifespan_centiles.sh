#!/bin/bash

#STEP 4 OF ANALYSIS PIPELINE#

#######################################################################################
# SET PATHS
img=/cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif #singularity image
base=/cbica/home/gardnerm/combat-biovar #base path (cubic) - also path that output csvs will be saved to
r_script=$base/cubic_scripts/R_scripts/fit_lifespan_centiles.R #path to .R script
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

#csv outputs
save_path=$base/lifespan/centile_csvs
if ! [ -d $save_path ]
	then
	mkdir $save_path
	else
	#remove old error messages if necessary
	rm -rf $save_path/*.*
	fi
sleep 60
#######################################################################################
#LIST POSSIBLE CONFIGS TO SEARCH FOR
config_list="imp-sites_log-cf_cf.gam_data imp-sites_log-cf_cf.gamlss_data"
#######################################################################################
for config in $config_list
do
	echo "Prepping $config"
	#write bash script
	bash_script=$bash_dir/${config}_cent.sh
	touch $bash_script
	
	echo "singularity run --cleanenv $img Rscript --save $r_script $csv_path $mod_path $save_path $config" > $bash_script

	#qsub bash script
	qsub -N $config -o $bash_dir/${config}_out.txt -e $bash_dir/${config}_err.txt $bash_script
done
