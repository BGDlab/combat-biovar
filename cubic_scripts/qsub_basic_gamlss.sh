#!/bin/bash

#Fit GAMLSS growth chart models for each phenotype
#pass as argument EITHER path to .csv containing data OR directory of .csvs to iterate across

#STEP 3 OF ANALYSIS PIPELINE#

#######################################################################################
# SET PATHS
base=/cbica/home/gardnerm/combat-biovar #base path (cubic)
pheno_path=$base/pheno_lists #path to .txt files listing phenotypes (global & regional)
mod_script=$base/cubic_scripts/R_scripts/fit_basic_mod.R #path to .R script

cd $base/cubic_scripts #to source functions correctly
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
gamlss_dir=$study_dir/gamlss_objs
if ! [ -d $gamlss_dir ]
	then
	mkdir $gamlss_dir
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
			bash_script=$bash_dir/${pheno}_${csv_name}_basic_fit.sh
			touch $bash_script
			echo "singularity run --cleanenv /cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif Rscript --save $mod_script $1 $pheno $gamlss_dir" > $bash_script

			#qsub bash script
			qsub -N ${pheno}.${csv_name} -o $bash_dir/${pheno}_${csv_name}_out.txt -e $bash_dir/${pheno}_${csv_name}_err.txt $bash_script

		done < $list
	done
#if input directory of .csvs
elif [ -d $1 ]
then
	for csv_file in "$1"/*.csv #select JUST csvs
	do

	#append "raw" suffix to OG, non-combatted data
		#see if filename contains 'cf'
		if [[ $csv_file == *"cf"* ]]
		then
			#just take name as is
			csv_name=$(basename $csv_file .csv)
			csv_name=${csv_name//_/\-}
			csv_to_load=$csv_file
		else
			#append "_raw" at end
			new_name="${csv_file/.csv/_raw.csv}"

			#rename file
			mv "$csv_file" "$new_name"
			echo "Renamed: $csv_file -> $new_name"
			csv_name=$(basename $new_name .csv)
			csv_name=${csv_name//_/\-}
			csv_to_load=$new_name
		fi
		echo "Pulling data from $csv_name"
		#iterate through measure types (vol, SA, CT, global vols) for correct global corrections
		for list in "$pheno_path"/*
		do
			echo "Modelling phenotypes in $list"
			#iterate through list of phenotypes
			while read -r pheno
			do
				#write bash script
				bash_script=$bash_dir/${pheno}_${csv_name}_basic_fit.sh
				touch $bash_script
				echo "singularity run --cleanenv /cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif Rscript --save $mod_script $csv_to_load $pheno $gamlss_dir" > $bash_script

				#qsub bash script
				qsub -N ${pheno}.${csv_name} -o $bash_dir/${pheno}_${csv_name}_out.txt -e $bash_dir/${pheno}_${csv_name}_err.txt $bash_script

			done < $list
		done
	done
fi
