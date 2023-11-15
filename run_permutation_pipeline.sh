#!/bin/bash
# Permute site assignment simulations, then qsub_combat.sh, qsub_basic_gamlss.sh, qsub_centiles.sh, gamlss_parse.sh **need to qsub this**

#######################################################################################
# SET PATHS
img=/cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif #singularity image
base=/cbica/home/gardnerm/combat-biovar #base path (cubic)
og_data=$base/data/ukb_CN_data_agefilt.csv #path to original data for which site assignments should be permuted
save_data_path=$base/data/ukb_permute
pheno_path=$base/pheno_lists #path to .txt files listing phenotypes (global & regional)
# paths to R scripts
permute_script=$base/R_scripts/permute_sites.R
cf_script=$base/R_scripts/combat_apply.R
mod_script=$base/R_scripts/fit_basic_mod.R
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
perm_bash_dir=$study_dir/perm_qsub_scripts
if ! [ -d $perm_bash_dir ]
	then
	mkdir $perm_bash_dir
	fi
	
#combat qsub script & outputs
cf_bash_dir=$study_dir/combat_qsub_scripts
if ! [ -d $cf_bash_dir ]
	then
	mkdir $cf_bash_dir
	fi

#combat output obj dir
if ! [ -d ${save_data_path}/combat_objs ]
	then
	mkdir ${save_data_path}/combat_objs
	fi

#qsub script & outputs
gamlss_bash_dir=$study_dir/qsub_scripts
if ! [ -d $gamlss_bash_dir ]
	then
	mkdir $gamlss_bash_dir
	fi

#model outputs
gamlss_dir=$study_dir/gamlss_objs
if ! [ -d $gamlss_dir ]
	then
	mkdir $gamlss_dir
	fi

#######################################################################################
#######################################################################################
# SUBMIT PERMUTAITON JOBS

echo "Prepping $1 permutations"

#write bash script
bash_script=$perm_bash_dir/permute_site_${1}x.sh
touch $bash_script
	
echo "singularity run --cleanenv $img Rscript --save $permute_script $og_data $save_data_path $1" > $bash_script

#qsub bash script
#qsub -N perm-${1}x -o $perm_bash_dir/perm_${1}x_out.txt -e $perm_bash_dir/perm_${1}x_err.txt $bash_script

#######################################################################################
# CHECK FOR OUTPUTS
SECONDS=0

while :    # while TRUE
do
    #expect # csvs in save_data_path = # permutations called for
    count_file=$(find $save_data_path -type f -name '*.csv' | wc -l)
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
    echo "count ${count_file} files"
    #echo $(find $save_data_path -type f -name '*.csv')
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
#give permissions
#chmod -R 755 $save_data_path

#iterate through csvs
for csv in "$save_data_path"/*.csv
do
	#GET CSV FILENAME
	echo $csv
	csv_fname=$(basename $csv .csv)
	for config in $config_list
	do
		echo "Prepping $config for $csv_fname"
		#write bash script
		bash_script=$cf_bash_dir/${csv_fname}_${config}_combat.sh
		touch $bash_script

		#SIMPLE COMBAT, NO COVARS
		if [ $config = "cf" ]
		then
			echo "singularity run --cleanenv $img Rscript --save $cf_script $csv $batch $save_data_path $config" > $bash_script

		#COMBAT LM
		elif [ $config = "cf.lm" ]
		then
			echo "singularity run --cleanenv $img Rscript --save $cf_script $csv $batch $save_data_path $config $covar_list" > $bash_script

		#COMBAT GAM
		elif [ $config = "cf.gam" ]
		then
			echo "singularity run --cleanenv $img Rscript --save $cf_script $csv $batch $save_data_path $config $covar_list 'gam, formula = y ~ s(age_days) + sexMale'" > $bash_script

		#COMBAT GAMLSS
		elif [ $config = "cf.gamlss" ]
		then
			echo "singularity run --cleanenv $img Rscript --save $cf_script $csv $batch $save_data_path $config $covar_list 'gamlss, formula = y ~ pb(age_days) + sexMale, sigma.formula = ~ age_days + sexMale'" > $bash_script

		fi
		#qsub bash script
		#qsub -N ${config}.${csv_fname} -o $cf_bash_dir/${csv_fname}_${config}_out.txt -e $cf_bash_dir/${csv_fname}_${config}_err.txt $bash_script
	done
done
#######################################################################################
# CHECK FOR OUTPUTS
#expect # csvs in save_data_path = # permutations called for * (# combat permutations + 1)
cf_len=`echo ${config_list[@]} | wc -w`
combat_counts=$((len*(cf_len+1)))
echo "submitted ${cf_len} combat configurations, looking for ${combat_counts} output csvs"

SECONDS=0

while :    # while TRUE
do
	count_file=$(find $save_data_path -type f -name '*.csv' | wc -l)
    # detect the expected output from 1st job
    if [ $count_file -eq $combat_counts ] 
	then    # 1st job successfully finished
        echo "${count_file} csvs written"
        break
    elif [ $SECONDS -gt 172800 ] #kill if taking more than 2 days
	then
	echo "taking too long, abort!"
	exit 2
    fi
	echo "${count_file} csvs found"
    sleep 60    # wait for 1min before detecting again
done

echo "launching gamlss jobs"
#######################################################################################
#######################################################################################
# SUBMIT GAMLSS JOBS
#give permissions
#chmod -R 755 $save_data_path

#run iterations
for csv in "$save_data_path"/*.csv
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
			bash_script=$gamlss_bash_dir/${pheno}_${csv_name}_basic_fit.sh
			touch $bash_script
			echo "singularity run --cleanenv /cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif Rscript --save $mod_script $csv_file $pheno $gamlss_dir" > $bash_script
			#qsub bash script
			qsub -N ${pheno}.${csv_name} -o $gamlss_bash_dir/${pheno}_${csv_name}_out.txt -e $gamlss_bash_dir/${pheno}_${csv_name}_err.txt $bash_script
		done < $list
	done
done
