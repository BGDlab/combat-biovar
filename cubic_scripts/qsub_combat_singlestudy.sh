#!/bin/bash
# Apply ComFam() with different arguments to specified dataset. 
#smaller K for fitting, also removing pb(sex.age) from sigma based on troubleshooting & and making linear in mu (NA's in the working vector or weights for parameter sigma)

#STEP 2 OF ANALYSIS PIPELINE#

#######################################################################################
# SET PATHS
img=/cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif #singularity image
base=/cbica/home/gardnerm/combat-biovar #base path (cubic)
save_path=$base/data/lifespan
#######################################################################################
helpFunction()
{
   echo ""
   echo "Usage: $0 -c data.csv -t true"
   echo -e "\t-c Path to data as .csv file"
   echo -e "\t-t true/false to log-transform"
   exit 1 # Exit script after printing help
}
#######################################################################################
# GET ARGS
while getopts ":c:t:" opt
do
   case "$opt" in
	c ) csv="$OPTARG" ;;
	t ) transform="$OPTARG" ;;
   esac
done

if [ -z "$csv" ] || [ -z "$transform" ]
then
   echo "provide: path to data and whether to log-transform global vols before running ComBat";
   helpFunction
fi
#######################################################################################
# DEFINE COMBAT .R SCRIPT (DEPENDING ON TRANSFORMATION OPTION)
if [ "$transform" = true ]
then
cf_script=$base/cubic_scripts/R_scripts/combat_apply_w_transform.R #path to .R script - set to apply log-transform to global vols before combatting
elif [ "$transform" = false ]
then
cf_script=$base/cubic_scripts/R_scripts/combat_apply.R #path to .R script
else
echo "Help! Invalid selection for transform true/false"
fi
#######################################################################################
cd $base/cubic_scripts #to source functions correctly
#######################################################################################
# MAKE DIRECTORIES 
#study dir
study_dir=$base/lifespan
if ! [ -d $study_dir ]
	then
	mkdir $study_dir
	fi

#qsub script & outputs
bash_dir=$study_dir/combat_qsub_scripts
if ! [ -d $bash_dir ]
	then
	mkdir $bash_dir
	#else
	#remove old error messages if necessary
	#rm -rf $bash_dir/*.txt
	fi

#combat output obj dir
if ! [ -d ${save_path}/combat_objs ]
	then
	mkdir ${save_path}/combat_objs
	fi

#GET CSV FILENAME
csv_fname=$(basename $csv .csv)

#######################################################################################
#SET COVAR COLS
covar_list="age_days,sexMale,sex.age"
#SET BATCH COL
batch="site"

#LIST POSSIBLE CONFIGS
config_list="cf.gam cf.gamlss"
#######################################################################################
for config in $config_list
do
	echo "Prepping $config"
	#write bash script
	bash_script=$bash_dir/${csv_fname}_${config}_combat.sh
	touch $bash_script

	#COMBAT GAM
	if [ $config = "cf.gam" ]
	then
		echo "singularity run --cleanenv $img Rscript --save $cf_script $csv $batch $save_path $config $covar_list 'gam, formula = y ~ s(age_days, k=5) + sexMale + sex.age'" > $bash_script

	#COMBAT GAMLSS
	elif [ $config = "cf.gamlss" ]
	then
		echo "singularity run --cleanenv $img Rscript --save $cf_script $csv $batch $save_path $config $covar_list 'gamlss, formula = y ~ pb(age_days) + sexMale + sex.age, sigma.formula = ~ pb(age_days) + sexMale'" > $bash_script
	fi
#qsub bash script
	qsub -l h_vmem=64G,s_vmem=64G -N ${config}.${csv_fname} -o $bash_dir/${config}.${csv_fname}_out.txt -e $bash_dir/${config}.${csv_fname}_err.txt $bash_script
done
