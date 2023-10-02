#!/bin/bash

#Fit GAMLSS growth chart models for each phenotype

#######################################################################################
# SET PATHS
base=/cbica/home/gardnerm/combat-biovar #base path (cubic)
#base=/Users/megardn/Desktop/BGD_Repos/combat_biovar #base path (local)
data_csv=$base/data/ukb_CN_data.csv #path to csv with CLEANED DATA (no duplicates, etc)
pheno_path=$base/pheno_lists #path to .txt files listing phenotypes (global & regional)
mod_script=$base/R_scripts/fit_ukb_mod.R #path to .R script

#cd to where .Rprofile is stored (for propper package loading)
cd $base
#######################################################################################

# MAKE DIRECTORIES 

#study dir
study_dir=$base/ukb
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
			bash_script=$bash_dir/${pheno}_fit.sh
			touch $bash_script
			echo "Rscript --save $mod_script $data_csv $pheno $glob_pheno $gamlss_dir" > $bash_script

			#qsub bash script
			qsub -N ${pheno} -o $bash_dir/${pheno}_out.txt -e $bash_dir/${pheno}_err.txt $bash_script

		done < $list

	elif [ $list = $pheno_path/"Vol_list_regions.txt" ]
	then
		glob_pheno="Vol_total"
		echo "Submitting models for regional volumes corrected by $glob_pheno"

		#iterate through list of phenotypes
		while read -r pheno
		do
			#write bash script
			bash_script=$bash_dir/${pheno}_fit.sh
			touch $bash_script
			echo "Rscript --save $mod_script $data_csv $pheno $glob_pheno $gamlss_dir" > $bash_script

			#qsub bash script
			qsub -N ${pheno} -o $bash_dir/${pheno}_out.txt -e $bash_dir/${pheno}_err.txt $bash_script

		done < $list

	elif [ $list = $pheno_path/"SA_list.txt" ]
	then
		glob_pheno="SA_total"
		echo "Submitting models for regional SA corrected by $glob_pheno"

		#iterate through list of phenotypes
		while read -r pheno
		do
			#write bash script
			bash_script=$bash_dir/${pheno}_fit.sh
			touch $bash_script
			echo "Rscript --save $mod_script $data_csv $pheno $glob_pheno $gamlss_dir" > $bash_script

			#qsub bash script
			qsub -N ${pheno} -o $bash_dir/${pheno}_out.txt -e $bash_dir/${pheno}_err.txt $bash_script

		done < $list

	elif [ $list = $pheno_path/"CT_list.txt" ]
	then
		glob_pheno="CT_total"
		echo "Submitting models for regional CT corrected by $glob_pheno"

		#iterate through list of phenotypes
		while read -r pheno
		do
			#write bash script
			bash_script=$bash_dir/${pheno}_fit.sh
			touch $bash_script
			echo "Rscript --save $mod_script $data_csv $pheno $glob_pheno $gamlss_dir" > $bash_script

			#qsub bash script
			qsub -N ${pheno} -o $bash_dir/${pheno}_out.txt -e $bash_dir/${pheno}_err.txt $bash_script

		done < $list
	else
		echo "Help! I don't know what to do with this list."
	fi
done
