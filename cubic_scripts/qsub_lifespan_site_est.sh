#!/bin/bash

#######################################################################################
# SET PATHS
img=/cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif #singularity image
base=/cbica/home/gardnerm/combat-biovar #base path (cubic) - also path that output csvs will be saved to
r_script=$base/cubic_scripts/R_scripts/get_lifespan_summaries.R #path to .R script
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
	fi

#csv outputs
save_path=$base/lifespan/centile_csvs
if ! [ -d $save_path ]
	then
	mkdir $save_path
	fi
sleep 3
#######################################################################################
#LIST POSSIBLE CONFIGS TO SEARCH FOR
config_list="lifespan-CN-imp-sites-euler-log-cf-cf.gamlss-batch.study-data_site.est lifespan-CN-imp-sites-euler-log-cf-cf.gam-batch.study-data_site.est"  
#######################################################################################
for config in $config_list
do
	echo "Prepping $config"
	#write bash script
	bash_script=$bash_dir/${config}_site_est.sh
	touch $bash_script
	
	echo "singularity run --cleanenv $img Rscript --save $r_script $csv_path $mod_path $save_path $config" > $bash_script

	#qsub bash script
	qsub -N $config -o $bash_dir/${config}_site_est_out.txt -e $bash_dir/${config}_site_est_err.txt $bash_script
done
