#!/bin/bash

#rerunning varying ratio featurewise abs centile tests so i can get outputs for global vols

#######################################################################################
# SET PATHS
img=/cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif #singularity image
base=/cbica/home/gardnerm/combat-biovar #base path (cubic)
study_dir=$base/ukb_ratios
csv_path=$study_dir/perm_centile_csvs
r_base=$base/cubic_scripts/R_scripts # paths to R scripts
bash_dir=$study_dir/stats_qsubs
# make dir for subject outputs
if ! [ -d $bash_dir ]
	then
	mkdir $bash_dir
	fi
#######################################################################################
cd $base/cubic_scripts #to source functions correctly
#######################################################################################
# STATS TESTS OF ERRORS
# featurewise error tests
r_script=$r_base/ratio_results.R
bash_script=$bash_dir/centile_tests.sh
touch $bash_script

echo "singularity run --cleanenv $img Rscript --save $r_script $csv_path 'full'" > $bash_script
## qsub bash script
qsub -N prop_cent_tests -o $bash_dir/cent_test_out.txt -e $bash_dir/cent_test_err.txt -l h_vmem=60.5G,s_vmem=60.0G $bash_script