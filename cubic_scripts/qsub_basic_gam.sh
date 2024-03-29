#!/bin/bash

#Fit GAMLSS growth chart models for each phenotype
#pass as argument EITHER path to .csv containing data OR directory of .csvs to iterate across

#######################################################################################
# SET PATHS
base=/cbica/home/gardnerm/combat-biovar #base path (cubic)
#base=/Users/megardn/Desktop/BGD_Repos/combat_biovar #base path (local)
#data_csv=$base/data/ukb_CN_data_agefilt.csv #path to csv with CLEANED DATA (no duplicates, etc)
pheno_path=$base/pheno_lists #path to .txt files listing phenotypes (global & regional)
mod_script=$base/R_scripts/fit_basic_gam.R #path to .R script

cd $base #to source functions correctly
#######################################################################################
# GET ARGS
if [ $# -lt 1 ]
then
	echo 1>&2 "$0: provide path to data (either single .csv or dir)"
	exit 2
fi
#######################################################################################
# MAKE DIRECTORIES 

#study dir
study_dir=$base/ukb_basic
if ! [ -d $study_dir ]
	then
	mkdir $study_dir
	fi

#qsub script & outputs
bash_dir=$study_dir/qsub_scripts
if ! [ -d $bash_dir ]
	then
	mkdir $bash_dir
	fi

#model outputs
gam_dir=$study_dir/gam_objs
if ! [ -d $gam_dir ]
	then
	mkdir $gam_dir
	fi

#######################################################################################
# FIT MODELS

#if input .csv
if [ -f $1 ]
then
	csv_name=$(basename $1 .csv)
	csv_name=${csv_name//_/\-}
	echo "Pulling data from $csv_name"
	#iterate through measure types (vol, SA, CT, global vols) for correct global corrections
	for list in "$pheno_path"/*
	do
		echo "Modelling phenotypes in $list"
		#iterate through list of phenotypes
		while read -r pheno
		do
			#write bash script
			bash_script=$bash_dir/${pheno}_${csv_name}_gam_fit.sh
			touch $bash_script
			echo "singularity run --cleanenv /cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif Rscript --save $mod_script $1 $pheno $gam_dir" > $bash_script

			#qsub bash script
			qsub -N ${pheno}.${csv_name}.gam -o $bash_dir/${pheno}_${csv_name}_out.txt -e $bash_dir/${pheno}_${csv_name}_err.txt $bash_script

		done < $list
	done
#if input directory of .csvs
elif [ -d $1 ]
then
	for csv_file in "$1"/*.csv #select JUST csvs - need to test this
	do
		csv_name=$(basename $csv_file .csv)
		csv_name=${csv_name//_/\-}
		echo "Pulling data from $csv_name"
		#iterate through measure types (vol, SA, CT, global vols) for correct global corrections
		for list in "$pheno_path"/*
		do
			echo "Modelling phenotypes in $list"
			#iterate through list of phenotypes
			while read -r pheno
			do
				#write bash script
				bash_script=$bash_dir/${pheno}_${csv_name}_gam_fit.sh
				touch $bash_script
				echo "singularity run --cleanenv /cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif Rscript --save $mod_script $csv_file $pheno $gam_dir" > $bash_script

				#qsub bash script
				qsub -N ${pheno}.${csv_name}.gam -o $bash_dir/${pheno}_${csv_name}_gam_out.txt -e $bash_dir/${pheno}_${csv_name}_gam_err.txt $bash_script

			done < $list
		done
	done
fi
