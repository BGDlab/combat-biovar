#!/bin/bash
# Permute site assignment simulations, then qsub_combat.sh, qsub_basic_gamlss.sh, qsub_centiles.sh, gamlss_parse.sh **need to qsub this**

#######################################################################################
# SET PATHS
img=/cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif #singularity image
base=/cbica/home/gardnerm/combat-biovar #base path (cubic)
og_data=$base/data/ukb_CN_data_agefilt.csv #path to original data for which site assignments should be permuted
save_data_path=$base/data/ukb_ratios

# paths to R scripts
r_base=$base/cubic_scripts/R_scripts
permute_script=$r_base/permute_sites_varying_ratio.R
cf_script=$r_base/combat_apply.R
mod_script=$r_base/fit_perm_basic_mod.R
centile_script=$r_base/fit_centiles.R
cent_subj_parse=$r_base/summarise_cent_subj-wise.R 
#######################################################################################
cd $base/cubic_scripts #to source functions correctly
#######################################################################################
#######################################################################################
# MAKE DIRECTORIES
if ! [ -d $save_data_path ]
	then
	mkdir $save_data_path
	else
	rm -f $save_data_path/*.*
	fi

#study dir
study_dir=$base/ukb_ratios
if ! [ -d $study_dir ]
	then
	mkdir $study_dir
	fi

#qsub script & outputs
perm_bash_dir=$study_dir/perm_qsub_scripts
if ! [ -d $perm_bash_dir ]
	then
	mkdir $perm_bash_dir
	else
    rm -f $perm_bash_dir/*.*
	fi
	
#combat qsub script & outputs
cf_bash_dir=$study_dir/combat_qsub_scripts
if ! [ -d $cf_bash_dir ]
	then
	mkdir $cf_bash_dir
	else
    rm -f $cf_bash_dir/*.*
	fi

#combat output obj dir
if ! [ -d ${save_data_path}/combat_objs ]
	then
	mkdir ${save_data_path}/combat_objs
	else
    rm -f $save_data_path/combat_objs/*.*
	fi

#qsub script & outputs
gamlss_bash_dir=$study_dir/qsub_scripts
if ! [ -d $gamlss_bash_dir ]
	then
	mkdir $gamlss_bash_dir
	else
    rm -f $gamlss_bash_dir/*.*
	fi

#model outputs
gamlss_dir=$study_dir/gamlss_objs
if ! [ -d $gamlss_dir ]
	then
	mkdir $gamlss_dir
	else
    rm -f $gamlss_dir/*.*
	fi

#centile qsubs
cent_bash_dir=$study_dir/centile_qsubs
if ! [ -d $cent_bash_dir ]
	then
	mkdir $cent_bash_dir
	else
    rm -f $cent_bash_dir/*.*
	fi

#centile output csvs
cent_save_dir=$study_dir/perm_centile_csvs
if ! [ -d $cent_save_dir ]
	then
	mkdir $cent_save_dir
	else
    rm -f $cent_save_dir/*.*
	fi

# ... with subdir for subject-level outputs
cent_subj_dir=$cent_save_dir/subject-wise
if ! [ -d $cent_subj_dir ]
	then
	mkdir $cent_subj_dir
	else
    rm -f $cent_subj_dir/*.*
	fi

#######################################################################################
#######################################################################################
# SUBMIT PERMUTAITON JOBS

echo "prepping site simulations"

#write bash script
bash_script=$perm_bash_dir/permute_site_ratios.sh
touch $bash_script
	
echo "singularity run --cleanenv $img Rscript --save $permute_script $og_data $save_data_path" > $bash_script

#qsub bash script
qsub -N perm-ratios -o $perm_bash_dir/perm_ratios_out.txt -e $perm_bash_dir/perm_ratios_err.txt $bash_script

#######################################################################################
# CHECK FOR OUTPUTS
SECONDS=0

while :    # while TRUE
do
    #expect # csvs in save_data_path = # permutations called for
    count_file=$(find $save_data_path -type f -name '*.csv' | wc -l)
    # detect the expected output from 1st job
    if [ $count_file -eq 11 ] 
	then    # 1st job successfully finished
        echo "${count_file} sims completed"
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
config_list="cf cf.lm cf.gam cf.gamlss"
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
			echo "singularity run --cleanenv $img Rscript --save $cf_script $csv $batch $save_data_path $config $covar_list 'lm, formula = y ~ age_days + sexMale'" > $bash_script

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
		qsub -N ${config}.${csv_fname} -o $cf_bash_dir/${csv_fname}_${config}_out.txt -e $cf_bash_dir/${csv_fname}_${config}_err.txt $bash_script
	done
done
#######################################################################################
# CHECK FOR OUTPUTS
#expect # csvs in save_data_path = # permutations called for * (# combat permutations + 1)
cf_len=`echo ${config_list[@]} | wc -w`
combat_counts=$((11*(${cf_len}+1)))
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
######################################################################################
# SUBMIT GAMLSS JOBS
#give permissions
#chmod -R 755 $save_data_path

#run iterations
for csv_file in "$save_data_path"/*.csv
do
  	#append "raw" suffix to og, non-combatted dfs so that the csvs and models are easily searchable
        # Check if the filename ends with a number
    if [[ $csv_file =~ [0-9]+\.csv ]]
    then
		# Append "_raw" after the number
        new_name="${csv_file/.csv/_raw.csv}"

        # Rename the file
        mv "$csv_file" "$new_name"
        echo "Renamed: $csv_file -> $new_name"
        csv_name=$(basename $new_name .csv)
		csv_to_load=$new_name
    else
        csv_name=$(basename $csv_file .csv)
		csv_to_load=$csv_file
    fi
	csv_name=${csv_name//_/\-}
    echo "Pulling data from $csv_name"

	#write bash script
	bash_script=$gamlss_bash_dir/${csv_name}_basic_fit.sh
	touch $bash_script
	echo "singularity run --cleanenv /cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif Rscript --save $mod_script $csv_to_load $gamlss_dir" > $bash_script
	#qsub bash script
	qsub -N ${csv_name}.gamlss -o $gamlss_bash_dir/${csv_name}_gamlss_out.txt -e $gamlss_bash_dir/${csv_name}_gamlss_err.txt $bash_script
done
#######################################################################################
# CHECK FOR OUTPUTS
#expect # models in gamlss_dir = #csvs * 208
mod_counts=$((${combat_counts}*208))

echo "${combat_counts} csvs, looking for ${mod_counts} output csvs"

SECONDS=0

while :    # while TRUE
do
	count_mods=$(find $gamlss_dir -type f -name '*.rds' | wc -l)
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
echo "getting centiles"
######################################################################################
# SUBMIT CENTILE MODELING JOBS

config_list_plusraw="cf_data cf.lm_data cf.gam_data cf.gamlss_data raw"

#LIST permutations
for p in $(seq -f "%02g" 1 11) #11 sims
do
	#iterate through combat configs
	for config in $config_list_plusraw
	do
		f_string=prop-${p}-${config}
		echo "Prepping $f_string"
		#write bash script
		bash_script=$cent_bash_dir/${f_string}_cent.sh
		touch $bash_script
		
		echo "singularity run --cleanenv $img Rscript --save $centile_script $save_data_path $gamlss_dir $cent_save_dir $f_string" > $bash_script

		#qsub bash script
		qsub -N $f_string -o $cent_bash_dir/${f_string}_out.txt -e $cent_bash_dir/${f_string}_err.txt $bash_script
	done
done
#######################################################################################
# CHECK FOR OUTPUTS
#expect 3 csvs per centile script iteration
num_configs=$(echo $config_list_plusraw | wc -w)
cent_csv_count=$((${num_configs}*11*3))
echo "looking for ${cent_csv_count} output csvs"

SECONDS=0

while :    # while TRUE
do
	count_cent=$(find $cent_save_dir -type f -name '*.csv' | wc -l)
    # detect the expected output from 1st job
    if [ $count_cent -eq $cent_csv_count ] 
	then    # 1st job successfully finished
        echo "all ${count_cent} csvs written"
        break
    elif [ $SECONDS -gt 172800 ] #kill if taking more than 2 days
	then
	echo "taking too long, abort!"
	exit 2
    fi
	echo "${count_cent} csvs found"
    sleep 60    # wait for 1min before detecting again
done

echo "getting subject-level summary stats"

######################################################################################
# SUBMIT SUBJ-LEVEL SUMMARY JOBS

#LIST permutations
for n_prop in $(seq -f "%02g" 1 11) #11 sims
do
	echo "Prepping prop-$n_prop"
	#write bash script
	bash_script=$bash_dir/prop-${n_prop}_cent_sum.sh
	touch $bash_script
		
	echo "singularity run --cleanenv $img Rscript --save $cent_subj_parse $n_prop $cent_save_dir" > $bash_script

	#qsub bash script
	qsub -N prop-${n_prop}_sum -o $cent_bash_dir/prop-${n_prop}_sum_out.txt -e $cent_bash_dir/prop-${n_prop}_sum_err.txt -l h_vmem=64G,s_vmem=64G $bash_script

done
#######################################################################################
# CHECK FOR OUTPUTS
#expect 11 csvs
echo "looking for 11 output csvs"

SECONDS=0

while :    # while TRUE
do
	count_cent_subj=$(find $cent_subj_dir -type f -name '*.csv' | wc -l)
    # detect the expected output from 1st job
    if [ $count_cent_subj -eq 11 ] 
	then    # 1st job successfully finished
        echo "all ${count_cent_subj} csvs written"
        break
    elif [ $SECONDS -gt 172800 ] #kill if taking more than 2 days
	then
	echo "taking too long, abort!"
	exit 2
    fi
	echo "${count_cent_subj} csvs found"
    sleep 60    # wait for 1min before detecting again
done
echo "SUCCESS! All done :)"
