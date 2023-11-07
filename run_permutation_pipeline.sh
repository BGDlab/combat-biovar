#!/bin/bash
# Permute site assignment simulations, then qsub_combat.sh, qsub_basic_gamlss.sh, qsub_centiles.sh, gamlss_parse.sh **need to qsub this**

#######################################################################################
# SET PATHS
img=/cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif #singularity image
base=/cbica/home/gardnerm/combat-biovar #base path (cubic)
og_data=$base/data/ukb_CN_data_agefilt.csv #path to original data for which site assignments should be permuted
save_data_path=$base/data/ukb_permute
# paths to R scripts
permute_script=$base/R_scripts/permute_sites.R #path to .R script
cf_script=$base/R_scripts/combat_apply.R
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
#######################################################################################
# MAKE DIRECTORIES

if ! [ -d $save_data_path ]
	then
	mkdir $save_data_path
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
	
#combat qsub script & outputs
bash_dir=$study_dir/combat_qsub_scripts
if ! [ -d $bash_dir ]
	then
	mkdir $bash_dir
	fi

#combat output obj dir
if ! [ -d ${save_data_path}/combat_objs ]
	then
	mkdir ${save_data_path}/combat_objs
	fi

#######################################################################################
#######################################################################################
# SUBMIT PERMUTAITON JOBS

echo "Prepping $1 permutations"

#write bash script
bash_script=$bash_dir/permute_site_${1}x.sh
touch $bash_script
	
echo "singularity run --cleanenv $img Rscript --save $permute_script $og_data $save_data_path $1" > $bash_script

#qsub bash script
#qsub -N perm-${1}x -o $bash_dir/perm_${1}x_out.txt -e $bash_dir/perm_${1}x_err.txt $bash_script

#######################################################################################
# CHECK FOR OUTPUTS
#expect # csvs in save_data_path = # permutations called for
count_file=$(find $save_data_path/ -type f -name '*.csv' | wc  -l)

SECONDS=0

while :    # while TRUE
do
    # detect the expected output from 1st job
    if [ $count_file -eq $1 ] 
	then    # 1st job successfully finished
        echo "${count_file} permutations completed"
        break
    elif [ $SECONDS -gt 86400 ] #kill if taking more than 1 day
	then
	echo "taking too long, abort!"
	exit 2
    fi
    sleep 60    # wait for 1min before detecting again
done

echo "launching ComBat jobs"
#######################################################################################
#######################################################################################
# SUBMIT COMBAT JOBS

#SET COVAR COLS
covar_list="age_days,sexMale"
#SET BATCH COL
batch="sim.site"

#LIST POSSIBLE CONFIGS
config_list="cf cf.lm cf.gam cf.gamlss" #cf.lm_refA cf.gam_refA cf.gamlss_refA
#######################################################################################
for csv in $($save_data_path/*.csv)
	#GET CSV FILENAME
	echo $csv
	csv_fname=$(basename $csv .csv)
	for config in $config_list
	do
		echo "Prepping $config for $csv_fname"
		#write bash script
		bash_script=$bash_dir/${csv_fname}_${config}_combat.sh
		touch $bash_script

		#SIMPLE COMBAT, NO COVARS
		if [ $config = "cf" ]
		then
			echo "singularity run --cleanenv $img Rscript --save $cf_script $csv $batch $save_path $config" > $bash_script

		#COMBAT LM
		elif [ $config = "cf.lm" ]
		then
			echo "singularity run --cleanenv $img Rscript --save $cf_script $csv $batch $save_path $config $covar_list" > $bash_script

		#COMBAT GAM
		elif [ $config = "cf.gam" ]
		then
			echo "singularity run --cleanenv $img Rscript --save $cf_script $csv $batch $save_path $config $covar_list 'gam, formula = y ~ s(age_days) + sexMale'" > $bash_script

		#COMBAT GAMLSS
		elif [ $config = "cf.gamlss" ]
		then
			echo "singularity run --cleanenv $img Rscript --save $cf_script $csv $batch $save_path $config $covar_list 'gamlss, formula = y ~ pb(age_days) + sexMale, sigma.formula = ~ age_days + sexMale'" > $bash_script

		#qsub bash script
		#qsub -N ${config}.${csv_fname} -o $bash_dir/${config}_out.txt -e $bash_dir/${config}_err.txt $bash_script
	done
done