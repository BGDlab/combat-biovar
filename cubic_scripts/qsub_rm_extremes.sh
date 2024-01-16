#!/bin/bash

#######################################################################################
# GET ARGS
if [ $# -lt 1 ]
then
	echo 1>&2 "$0: indicate 'prop' or 'perm'"
	exit 2
fi
#######################################################################################
# SET PATHS
img=/cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif #singularity image
base=/cbica/home/gardnerm/combat-biovar #base path (cubic) - also path that output csvs will be saved to
r_script=$base/cubic_scripts/R_scripts/remove_extremes.R #path to .R script
#######################################################################################
# define study dir based on 1st arg
if [ $1 = "prop" ]
then
	study_dir=$base/ukb_ratios
	csv_path=$study_dir/perm_centile_csvs #path to csvs with predicted centile and z scores
elif [ $1 = "perm" ]
then
	study_dir=$base/ukb_permute
	csv_path=$study_dir/perm_centile_csvs #path to csvs with predicted centile and z scores
else
	echo "Help! Please indicate 'prop' or 'perm'"
fi
bash_dir=$study_dir/centile_qsubs
#######################################################################################
cd $base/cubic_scripts #to source functions correctly
#######################################################################################
#write bash script
bash_script=$bash_dir/${1}_rm_ext.sh
touch $bash_script
	
echo "singularity run --cleanenv $img Rscript --save $r_script $csv_path $1" > $bash_script

#qsub bash script
qsub -N ${1}_rm_ext -o $bash_dir/${1}_rm_ext_out.txt -e $bash_dir/${1}_rm_ext_err.txt -l h_vmem=64G,s_vmem=64G $bash_script