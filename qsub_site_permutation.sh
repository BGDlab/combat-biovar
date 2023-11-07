#!/bin/bash
# Permute site assignment simulations

#STEP 1 OF VALIDATION PIPELINE#

#######################################################################################
# SET PATHS
img=/cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif #singularity image
base=/cbica/home/gardnerm/combat-biovar #base path (cubic)
r_script=$base/R_scripts/permute_sites.R #path to .R script
og_data=$base/data/ukb_CN_data_agefilt.csv #path to original data for which site assignments should be permuted
save_path=$base/data/ukb_permute
#######################################################################################
cd $base #to source functions correctly
#######################################################################################
# GET ARGS
if [ $# -lt 1 ]
then
	echo 1>&2 "$0: provide # of permutations to run"
	exit 2
fi
#######################################################################################
# MAKE DIRECTORIES

if ! [ -d $save_path ]
	then
	mkdir $save_path
	fi

#study dir
study_dir=$base/ukb_permute
if ! [ -d $study_dir ]
	then
	mkdir $study_dir
	fi

#qsub script & outputs
bash_dir=$study_dir/perm_qsub_scripts
if ! [ -d $bash_dir ]
	then
	mkdir $bash_dir
	fi
	
#######################################################################################
echo "Prepping $1 permutations"

#write bash script
bash_script=$bash_dir/permute_site_${1}x.sh
touch $bash_script
	
echo "singularity run --cleanenv $img Rscript --save $r_script $og_data $save_path $1 TRUE" > $bash_script

#qsub bash script
qsub -N perm-${1}x -o $bash_dir/perm_${1}x_out.txt -e $bash_dir/perm_${1}x_err.txt $bash_script
