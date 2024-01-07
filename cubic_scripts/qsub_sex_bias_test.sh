#!/bin/bash
#######################################################################################
# SET PATHS
img=/cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif #singularity image
base=/cbica/home/gardnerm/combat-biovar #base path (cubic)
r_script=$base/R_scripts/featurewise_sex_bias_test.R
#######################################################################################
cd $base/cubic_scripts #to source functions correctly
#######################################################################################
# GET ARGS
if [ $# -lt 1 ]
then
	echo 1>&2 "$0: indicate 'prop', 'perm' or 'basic'"
	exit 2
fi
#######################################################################################
# define study dir based on 1st arg
if [ $1 = "prop" ]
then
	study_dir=$base/ukb_ratios
	csv_path=$study_dir/perm_centile_csvs #path to summary csvs
elif [ $1 = "perm" ]
then
	study_dir=$base/ukb_permute
	csv_path=$study_dir/perm_centile_csvs #path to summary csvs
elif [ $1 = "basic" ]
then
	study_dir=$base/ukb_basic
	csv_path=$study_dir/centile_csvs #path to summary csvs
else
	echo "Help! Please indicate 'prop' or 'perm'"
fi
bash_dir=$study_dir/centile_qsubs
#######################################################################################
#write bash script
bash_script=$bash_dir/sex_bias_test.sh
touch $bash_script
		
echo "singularity run --cleanenv $img Rscript --save $r_script $csv_path" > $bash_script

#qsub bash script
qsub -N ${1}_sex-bias -o $bash_dir/sex_bias_test_out.txt -e $bash_dir/sex_bias_test_err.txt -l h_vmem=60.5G,s_vmem=60.0G -pe threaded 31 $bash_script