#!/bin/bash
# Apply ComFam() with different arguments to specified dataset

#######################################################################################
# SET PATHS
img=/cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif #singularity image

base=/cbica/home/gardnerm/combat-biovar #base path (cubic)
#base=/Users/megardn/Desktop/BGD_Repos/combat_biovar #base path (local)
data_csv=$base/data/ukb_to_model/ukb_CN_data_simsites.csv #path to csv with CLEANED DATA (no duplicates, etc)
#pheno_path=$base/pheno_lists #path to .txt files listing phenotypes (global & regional) - may need to pass as arg. on cubic/w singularity
cf_script=$base/R_scripts/combat_apply.R #path to .R script
save_path=$base/data/ukb_to_model

cd $base #to source functions correctly
#######################################################################################
# MAKE DIRECTORIES 
#study dir
study_dir=$base/ukb_basic
if ! [ -d $study_dir ]
	then
	mkdir $study_dir
	fi

#qsub script & outputs
bash_dir=$study_dir/combat_qsub_scripts
if ! [ -d $bash_dir ]
	then
	mkdir $bash_dir
	fi

#combat output obj dir
if ! [ -d ${save_path}/combat_objs ]
	then
	mkdir ${save_path}/combat_objs
	fi
#######################################################################################
#SET COVAR COLS
covar_list="age_days,sexMale"
#SET BATCH COL
batch="sim.site"

#LIST POSSIBLE CONFIGS
config_list="cf cf.lm cf.lm_refA cf.gam cf.gam_refA cf.gamlss cf.gamlss_refA"
#######################################################################################
for config in $config_list
do
	echo "Prepping $config"
	#write bash script
	bash_script=$bash_dir/${config}_combat.sh
	touch $bash_script

	#SIMPLE COMBAT, NO COVARS
	if [ $config = "cf" ]
	then
		echo "singularity run --cleanenv $img Rscript --save $cf_script $data_csv $batch $save_path $config" > $bash_script

	#COMBAT LM
	elif [ $config = "cf.lm" ]
	then
		echo "singularity run --cleanenv $img Rscript --save $cf_script $data_csv $batch $save_path $config $covar_list" > $bash_script

	#COMBAT LM W/ REF SITE
	elif [ $config = "cf.lm_refA" ]
	then
		echo "singularity run --cleanenv $img Rscript --save $cf_script $data_csv $batch $save_path $config $covar_list 'lm, formula = y ~ age_days + sexMale, ref.batch = "Site_A"'" > $bash_script

	#COMBAT GAM
	elif [ $config = "cf.gam" ]
	then
		echo "singularity run --cleanenv $img Rscript --save $cf_script $data_csv $batch $save_path $config $covar_list 'gam, formula = y ~ s(age_days) + sexMale'" > $bash_script

	#COMBAT GAM W/ REF SITE
	elif [ $config = "cf.gam_refA" ]
	then
		echo "singularity run --cleanenv $img Rscript --save $cf_script $data_csv $batch $save_path $config $covar_list 'gam, formula = y ~ s(age_days) + sexMale, ref.batch = "Site_A"'" > $bash_script

	#COMBAT GAMLSS
	elif [ $config = "cf.gamlss" ]
	then
		echo "singularity run --cleanenv $img Rscript --save $cf_script $data_csv $batch $save_path $config $covar_list 'gamlss, formula = y ~ s(age_days) + sexMale'" > $bash_script

	#COMBAT GAMLSS W/ REF SITE
	elif [ $config = "cf.gamlss_refA" ]
	then
		echo "singularity run --cleanenv $img Rscript --save $cf_script $data_csv $batch $save_path $config $covar_list 'gamlss, formula = y ~ s(age_days) + sexMale, ref.batch = "Site_A"'" > $bash_script
	fi

#qsub bash script
	qsub -N $config -o $bash_dir/${config}_out.txt -e $bash_dir/${config}_err.txt $bash_script
done
