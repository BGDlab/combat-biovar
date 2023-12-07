#!/bin/bash

#Fit GAMLSS growth chart models for each phenotype

#######################################################################################
# SET PATHS
base=/cbica/home/gardnerm/combat-biovar #base path (cubic)
pheno_path=$base/pheno_lists #path to .txt files listing phenotypes (global & regional)
mod_script=$base/cubic_scripts/R_scripts/fit_lifespan_mod.R #path to .R script
#######################################################################################
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
study_dir=$base/lifespan
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
	#iterate through measure types (vol, SA, CT, global vols) for correct global corrections
	for list in "$pheno_path"/*
	do
		if [ $list = $pheno_path/"Vol_list_global.txt" ]
		then
			glob_pheno="TBV"
			echo "Submitting models for global volumes corrected by $glob_pheno"

			#iterate through list of phenotypes
			while read -r pheno
			do
				#write bash script
				bash_script=$bash_dir/${pheno}_${csv_name}_fit.sh
				touch $bash_script
				echo "Rscript --save $mod_script $1 $pheno $glob_pheno $gamlss_dir" > $bash_script

				#qsub bash script
				qsub -N ${pheno}.${csv_name} -o $bash_dir/${pheno}_${csv_name}_out.txt -e $bash_dir/${pheno}_${csv_name}_err.txt $bash_script

			done < $list

		elif [ $list = $pheno_path/"Vol_list_regions.txt" ]
		then
			glob_pheno="Vol_total"
			echo "Submitting models for regional volumes corrected by $glob_pheno"

			#iterate through list of phenotypes
			while read -r pheno
			do
				#write bash script
				bash_script=$bash_dir/${pheno}_${csv_name}_fit.sh
				touch $bash_script
				echo "Rscript --save $mod_script $1 $pheno $glob_pheno $gamlss_dir" > $bash_script

				#qsub bash script
				qsub -N ${pheno}.${csv_name} -o $bash_dir/${pheno}_${csv_name}_out.txt -e $bash_dir/${pheno}_${csv_name}_err.txt $bash_script

			done < $list

		elif [ $list = $pheno_path/"SA_list.txt" ]
		then
			glob_pheno="SA_total"
			echo "Submitting models for regional SA corrected by $glob_pheno"

			#iterate through list of phenotypes
			while read -r pheno
			do
				#write bash script
				bash_script=$bash_dir/${pheno}_${csv_name}_fit.sh
				touch $bash_script
				echo "Rscript --save $mod_script $1 $pheno $glob_pheno $gamlss_dir" > $bash_script

				#qsub bash script
				qsub -N ${pheno}.${csv_name} -o $bash_dir/${pheno}_${csv_name}_out.txt -e $bash_dir/${pheno}_${csv_name}_err.txt $bash_script

			done < $list

		elif [ $list = $pheno_path/"CT_list.txt" ]
		then
			glob_pheno="CT_total"
			echo "Submitting models for regional CT corrected by $glob_pheno"

			#iterate through list of phenotypes
			while read -r pheno
			do
				#write bash script
				bash_script=$bash_dir/${pheno}_${csv_name}_fit.sh
				touch $bash_script
				echo "Rscript --save $mod_script $1 $pheno $glob_pheno $gamlss_dir" > $bash_script

				#qsub bash script
				qsub -N ${pheno}.${csv_name} -o $bash_dir/${pheno}_${csv_name}_out.txt -e $bash_dir/${pheno}_${csv_name}_err.txt $bash_script

			done < $list
		else
			echo "Help! I don't know what to do with this list."
		fi
	done
#if input directory of .csvs
elif [ -d $1 ]
then
	for csv_file in "$1"/*
	do
		csv_name=$(basename $csv_file .csv)
		csv_name=${csv_name//_/\-}
		echo "Pulling data from $csv_name"
		#iterate through measure types (vol, SA, CT, global vols) for correct global corrections
		for list in "$pheno_path"/*
		do
			if [ $list = $pheno_path/"Vol_list_global.txt" ]
			then
				glob_pheno="TBV"
				echo "Submitting models for global volumes corrected by $glob_pheno"

				#iterate through list of phenotypes
				while read -r pheno
				do
					#write bash script
					bash_script=$bash_dir/${pheno}_${csv_name}_fit.sh
					touch $bash_script
					echo "Rscript --save $mod_script $csv_file $pheno $glob_pheno $gamlss_dir" > $bash_script

					#qsub bash script
					qsub -N ${pheno}.${csv_name} -o $bash_dir/${pheno}_${csv_name}_out.txt -e $bash_dir/${pheno}_${csv_name}_err.txt $bash_script

				done < $list

			elif [ $list = $pheno_path/"Vol_list_regions.txt" ]
			then
				glob_pheno="Vol_total"
				echo "Submitting models for regional volumes corrected by $glob_pheno"

				#iterate through list of phenotypes
				while read -r pheno
				do
					#write bash script
					bash_script=$bash_dir/${pheno}_${csv_name}_fit.sh
					touch $bash_script
					echo "Rscript --save $mod_script $csv_file $pheno $glob_pheno $gamlss_dir" > $bash_script

					#qsub bash script
					qsub -N ${pheno}.${csv_name} -o $bash_dir/${pheno}_${csv_name}_out.txt -e $bash_dir/${pheno}_${csv_name}_err.txt $bash_script

				done < $list

			elif [ $list = $pheno_path/"SA_list.txt" ]
			then
				glob_pheno="SA_total"
				echo "Submitting models for regional SA corrected by $glob_pheno"

				#iterate through list of phenotypes
				while read -r pheno
				do
					#write bash script
					bash_script=$bash_dir/${pheno}_${csv_name}_fit.sh
					touch $bash_script
					echo "Rscript --save $mod_script $csv_file $pheno $glob_pheno $gamlss_dir" > $bash_script

					#qsub bash script
					qsub -N ${pheno}.${csv_name} -o $bash_dir/${pheno}_${csv_name}_out.txt -e $bash_dir/${pheno}_${csv_name}_err.txt $bash_script

				done < $list

			elif [ $list = $pheno_path/"CT_list.txt" ]
			then
				glob_pheno="CT_total"
				echo "Submitting models for regional CT corrected by $glob_pheno"

				#iterate through list of phenotypes
				while read -r pheno
				do
					#write bash script
					bash_script=$bash_dir/${pheno}_${csv_name}_fit.sh
					touch $bash_script
					echo "Rscript --save $mod_script $csv_file $pheno $glob_pheno $gamlss_dir" > $bash_script

					#qsub bash script
					qsub -N ${pheno}.${csv_name} -o $bash_dir/${pheno}_${csv_name}_out.txt -e $bash_dir/${pheno}_${csv_name}_err.txt $bash_script

				done < $list
			else
				echo "Help! I don't know what to do with this list."
			fi
		done
	done
fi