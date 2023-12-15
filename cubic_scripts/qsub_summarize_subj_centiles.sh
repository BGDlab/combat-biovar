#!/bin/bash

#######################################################################################
# GET ARGS
if [ $# -lt 2 ]
then
	echo 1>&2 "$0: indicate 'prop' or 'perm' and number simulations to iterate"
	exit 2
fi
#######################################################################################
# SET PATHS
img=/cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif #singularity image
base=/cbica/home/gardnerm/combat-biovar #base path (cubic) - also path that output csvs will be saved to
r_script=$base/cubic_scripts/R_scripts/summarise_cent_subj-wise.R #path to .R script
#######################################################################################
# define study dir based on 1st arg
if [ $1 = "prop" ]
then
	study_dir=$base/ukb_ratios
elif [ $1 = "perm" ]
then
	study_dir=$base/ukb_permute
else
	echo "Help! Please indicate 'prop' or 'perm'"
fi
csv_path=$study_dir/perm_centile_csvs #path to csvs with predicted centile and z scores
bash_dir=$study_dir/centile_qsubs
#######################################################################################
cd $base/cubic_scripts #to source functions correctly
#######################################################################################
# MAKE DIRECTORY FOR OUTPUTS
if ! [ -d $csv_path/subject-wise ]
	then
	mkdir $csv_path/subject-wise
	fi
#######################################################################################
for n_prop in $(seq -f "%02g" 1 $2) #input number of simulations
do
	echo "Prepping prop-$n_prop"
	#write bash script
	bash_script=$bash_dir/prop-${n_prop}_cent_sum.sh
	touch $bash_script
	
	echo "singularity run --cleanenv $img Rscript --save $r_script $1 $n_prop $csv_path" > $bash_script

	#qsub bash script
	qsub -N prop-${n_prop}_sum -o $bash_dir/prop-${n_prop}_sum_out.txt -e $bash_dir/prop-${n_prop}_sum_err.txt -l h_vmem=64G,s_vmem=64G $bash_script
done
