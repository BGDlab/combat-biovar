#!/bin/bash
# run ComBat, ComBat-GAM, and ComBatLS on curated LBCC data, then fit brain charts.
# follow with run_LBCC_stats.sh
#######################################################################################
# SET PATHS
img=/cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif #singularity image
base=/cbica/home/gardnerm/combat-biovar #base path (cubic)
og_data=$base/data/lifespan_CN_site-level_euler.csv #path to original data
save_data_path=$base/data/lifespan

# paths to R scripts
r_base=$base/cubic_scripts/R_scripts

cf_script=$r_base/combat_apply_w_transform.R
mod_script=$r_base/fit_lifespan_mod_notbv.R
mod_script_batch=$r_base/fit_lifespan_mod_site_est.R

pheno_path=$base/pheno_lists #path to .txt files listing phenotypes (global & regional)
#######################################################################################
cd $base/cubic_scripts #to source functions correctly
#######################################################################################

#######################################################################################
#######################################################################################
# MAKE DIRECTORIES

if ! [ -d $save_data_path ]
	then
	mkdir $save_data_path
	fi

#study dir
study_dir=$base/lifespan
if ! [ -d $study_dir ]
	then
	mkdir $study_dir
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
# SUBMIT COMBAT JOBS
#######################################################################################
#SET COVAR COLS
covar_list="age_days,sexMale,sex.age" #age_days
batch="study"

#LIST POSSIBLE CONFIGS
config_list="cf.lm cf.gam cf.gamlss"
#######################################################################################
for config in $config_list
do
	echo "Prepping $config"
	#write bash script
	bash_script=$bash_dir/${csv_fname}_${config}_combat.sh
	touch $bash_script

	#COMBAT LM
	elif [ $config = "cf.lm" ]
	then
		echo "singularity run --cleanenv $img Rscript --save $cf_script $csv $batch $save_data_path $config $covar_list" > $bash_script

	#COMBAT GAM
	elif [ $config = "cf.gam" ]
	then
		echo "singularity run --cleanenv $img Rscript --save $cf_script $csv $batch $save_data_path $config $covar_list 'gam, formula = y ~ s(age_days) + sexMale + sex.age'" > $bash_script

	#COMBAT GAMLSS
	elif [ $config = "cf.gamlss" ]
	then
		echo "singularity run --cleanenv $img Rscript --save $cf_script $csv $batch $save_data_path $config $covar_list 'gamlss, formula = y ~ pb(age_days) + sexMale + sex.age, sigma.formula = ~ pb(age_days, inter=5)  + sexMale'" > $bash_script

#qsub bash script
	qsub -l h_vmem=64G,s_vmem=64G -N ${config}.${batch}.${csv_fname} -o $bash_dir/${config}.${csv_fname}_${batch}_out.txt -e $bash_dir/${config}.${csv_fname}_${batch}_err.txt $bash_script
done
#######################################################################################
# CHECK FOR OUTPUTS
#expect # csvs in save_data_path = # permutations called for * (# combat permutations + 1)
combat_counts=`echo ${config_list[@]} | wc -w`

echo "submitted ${combat_counts} combat configurations, looking for ${combat_counts} output csvs"

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

#COPY RAW DATAFRAME
cp $og_data $save_data_path/lifespan_CN_imp-sites_euler_raw.csv
sleep 30

echo "launching gamlss jobs"
#######################################################################################
######################################################################################
# SUBMIT GAMLSS JOBS
#give permissions
#chmod -R 755 $save_data_path

#run iterations
for csv_file in "$save_data_path"/*.csv
do
  	csv_name=$(basename $csv_file .csv)
	csv_name=${csv_name//_/\-}
	echo "Pulling data from $csv_name"
	#iterate through measure types 
	for list in "$pheno_path"/*
	do
		#iterate through list of phenotypes
		while read -r pheno
		do
			#write bash script
			bash_script=$bash_dir/${pheno}_${csv_name}_fit.sh
			touch $bash_script
			echo "singularity run --cleanenv $img Rscript --save $mod_script $csv_file $pheno $gamlss_dir" > $bash_script

			#qsub bash script
			qsub -N ${pheno}.${csv_name} -o $bash_dir/${pheno}_${csv_name}_no.tbv_out.txt -e $bash_dir/${pheno}_${csv_name}_no.tbv_err.txt $bash_script

		done < $list
	done
done

echo "launching gamlss jobs with study term"
#######################################################################################
# SUBMIT GAMLSS JOBS WITH STUDY TERM
#give permissions

#run iterations
for csv_file in "$save_data_path"/*.csv
do
  	csv_name=$(basename $csv_file .csv)
	csv_name=${csv_name//_/\-}
	echo "Pulling data from $csv_name"
	#iterate through measure types 
	for list in "$pheno_path"/*
	do
		#iterate through list of phenotypes
		while read -r pheno
		do
			#write bash script
			bash_script=$bash_dir/${pheno}_${csv_name}_fit.sh
			touch $bash_script
			echo "singularity run --cleanenv $img Rscript --save $mod_script_batch $csv_file $pheno $gamlss_dir" > $bash_script

			#qsub bash script
			qsub -N ${pheno}.${csv_name}.batch.est -o $bash_dir/${pheno}_${csv_name}_batch.est_out.txt -e $bash_dir/${pheno}_${csv_name}_batch.est_err.txt $bash_script

		done < $list
	done
done

#######################################################################################
# CHECK FOR OUTPUTS
#expect # models in gamlss_dir = #csvs * 208
csv_counts=$((${combat_counts}+1))
mod_counts=$((${csv_counts}*208*2))

echo "${csv_counts} csvs, looking for ${mod_counts} output csvs"

SECONDS=0

while :    # while TRUE
do
	count_mods=$(find $gamlss_dir -type f -name '*mod.rds' | wc -l)
    # detect the expected output from 1st job
    if [ $count_mods -eq $mod_counts ] 
	then    # 1st job successfully finished
        echo "${count_mods} gamlss models written"
        break
    elif [ $SECONDS -gt 172800 ] #kill if taking more than 2 days
	then
	echo "taking too long, abort!"
	exit 2
    fi
	echo "${count_mods} gamlss models found"
    sleep 60    # wait for 1min before detecting again
done

echo "SUCCESS! All done :)"


