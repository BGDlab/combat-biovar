#!/bin/bash
# Apply ComFam() with different arguments to specified dataset

#STEP 2 OF VALIDATION PIPELINE#

#######################################################################################
# SET PATHS
img=/cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif #singularity image
base=/cbica/home/gardnerm/combat-biovar #base path (cubic)
cf_script=$base/R_scripts/combat_apply.R #path to .R script
save_path=$base/data/ukb_permutations
#######################################################################################
helpFunction()
{
   echo ""
   echo "Usage: $0 -c data.csv -p pass"
   echo -e "\t-c Path to data as .csv file"
   echo -e "\t-p Automated gamlss fitting (TRUE or FALSE)"
   exit 1 # Exit script after printing help
}
#######################################################################################
# GET ARGS
while getopts "c:p:" opt
do
   case "$opt" in
	c ) csv="$OPTARG" ;;
	p ) pass="$OPTARG" ;;
   esac
done

if [ -z "$csv" ] || [ -z "$oupasstputs" ]
then
   echo "provide path to data & indicate TRUE/FALSE to automated gamlss fitting";
   helpFunction
fi
#######################################################################################
cd $base #to source functions correctly
#######################################################################################
# MAKE DIRECTORIES 
#study dir
study_dir=$base/ukb_permute
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
		echo "singularity run --cleanenv $img Rscript --save $cf_script $csv $batch $save_path $config $pass" > $bash_script

	#COMBAT LM
	elif [ $config = "cf.lm" ]
	then
		echo "singularity run --cleanenv $img Rscript --save $cf_script $csv $batch $save_path $config $covar_list $pass" > $bash_script

	#COMBAT LM W/ REF SITE
	elif [ $config = "cf.lm_refA" ]
	then
		echo "singularity run --cleanenv $img Rscript --save $cf_script $csv $batch $save_path $config $covar_list $pass 'lm, formula = y ~ age_days + sexMale, ref.batch = \"Site_A\"'" > $bash_script

	#COMBAT GAM
	elif [ $config = "cf.gam" ]
	then
		echo "singularity run --cleanenv $img Rscript --save $cf_script $csv $batch $save_path $config $covar_list $pass 'gam, formula = y ~ s(age_days) + sexMale'" > $bash_script

	#COMBAT GAM W/ REF SITE
	elif [ $config = "cf.gam_refA" ]
	then
		echo "singularity run --cleanenv $img Rscript --save $cf_script $csv $batch $save_path $config $covar_list $pass 'gam, formula = y ~ s(age_days) + sexMale, ref.batch = \"Site_A\"'" > $bash_script

	#COMBAT GAMLSS
	elif [ $config = "cf.gamlss" ]
	then
		echo "singularity run --cleanenv $img Rscript --save $cf_script $csv $batch $save_path $config $covar_list $pass 'gamlss, formula = y ~ pb(age_days) + sexMale, sigma.formula = ~ age_days + sexMale'" > $bash_script

	#COMBAT GAMLSS W/ REF SITE
	elif [ $config = "cf.gamlss_refA" ]
	then
		echo "singularity run --cleanenv $img Rscript --save $cf_script $csv $batch $save_path $config $covar_list $pass 'gamlss, formula = y ~ pb(age_days) + sexMale, sigma.formula = ~ age_days + sexMale, ref.batch = \"Site_A\"'" > $bash_script
	fi

#qsub bash script
	qsub -N $config -o $bash_dir/${config}_out.txt -e $bash_dir/${config}_err.txt $bash_script
done
