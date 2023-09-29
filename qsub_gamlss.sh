#!/bin/bash

#Fit GAMLSS growth chart models for each phenotype

#######################################################################################
# SET PATHS
base=/cbica/home/gardnerm/combat-biovar #base path
data_csv=$base/data/ukb_CN_data.csv #path to csv with CLEANED DATA (no duplicates, etc)
pheno_list=$base/phenotype_list.txt #path to .txt file listing phenotypes (global & regional)
mod_script=$base/fit_ukb_mod.R #path to .R script

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

#iterate through list of phenotypes
while read -r pheno
do
    #write bash script
	bash_script=$bash_dir/${pheno}_fit.sh
	touch $bash_script
	echo "Rscript --save $mod_script $data_csv $pheno $gamlss_dir" > $bash_script

	#qsub bash script
	#qsub -N ${pheno} -o $bash_dir/${pheno}_out.txt -e $bash_dir/${pheno}_err.txt $bash_script

done < $pheno_list