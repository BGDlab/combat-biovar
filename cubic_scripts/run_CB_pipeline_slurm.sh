#!/bin/bash
# Prep harmonized data for and run CentileBrain style gamlss models for review
#######################################################################################
# SET PATHS
img=/cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif # Singularity image
base=/cbica/home/gardnerm/combat-biovar # Base path (cubic)
in_data_path=$base/data/lifespan
save_data_path=$base/data/cb #saving csvs separatley

# Paths to R scripts
r_base=$base/cubic_scripts/R_scripts

data_prep_cb=$r_base/centilebrain_data_prep.R
mod_script=$r_base/centilebrain_models.R

pheno_path=$base/pheno_lists # Path to .txt files listing phenotypes (global & regional)
#######################################################################################
cd $base/cubic_scripts # To source functions correctly
#######################################################################################

# MAKE DIRECTORIES

if ! [ -d $save_data_path ]; then
    mkdir $save_data_path
fi

# Study directory
study_dir=$base/lifespan
if ! [ -d $study_dir ]; then
    mkdir $study_dir
fi

# ComBat qsub script & outputs
cf_bash_dir=$study_dir/combat_qsub_scripts
if ! [ -d $cf_bash_dir ]; then
    mkdir $cf_bash_dir
fi

# ComBat output obj directory
if ! [ -d ${save_data_path}/combat_objs ]; then
    mkdir ${save_data_path}/combat_objs
fi

# Qsub script & outputs
gamlss_bash_dir=$study_dir/qsub_scripts
if ! [ -d $gamlss_bash_dir ]; then
    mkdir $gamlss_bash_dir
fi

# Model outputs
gamlss_dir=$study_dir/cb_gamlss_objs
if ! [ -d $gamlss_dir ]; then
    mkdir $gamlss_dir
fi

#######################################################################################
#CHECK FOR HARMONIZED & RAW DATAFRAMES TO FIT MODELS ON
count_file=$(find $in_data_path -type f -name '*.csv' | wc -l)
if [ ! $count_file -eq 3 ]; then
  echo "incorrect number of dataframes. should be 3 (raw, combat-gam, and combatLS)"
  exit 1
fi

echo "found $count_file csvs, proceeding"
#######################################################################################
#PREP DATAFRAMES
for csv_file in "$in_data_path"/*.csv
do
  csv_name=$(basename $csv_file .csv)
	csv_name=${csv_name//_/\-}
	echo "prepping data from $csv_name for centilebrain models"
	
	#write bash script
	bash_script=$gamlss_bash_dir/${csv_name}_cb_prep.sh
	touch $bash_script
	
	echo "#!/bin/bash" > $bash_script
			
	echo "singularity run --cleanenv $img Rscript --save $data_prep_cb $csv_file $save_data_path" >> $bash_script
	
	#qsub bash script
	sbatch -J ${csv_name}.cbprep\
			-o $gamlss_bash_dir/${csv_name}_cbprep_out.txt \
			-e $gamlss_bash_dir/${csv_name}_cbprep_err.txt \
			$bash_script
			
done

#######################################################################################
# CHECK FOR OUTPUTS
#expect 2 saved csvs per input

echo "looking for 6 output CSVs"

SECONDS=0

while :; do
    count_file=$(find $save_data_path -type f -name '*.csv' | wc -l)
    if [ $count_file -eq 6 ]; then
        echo "${count_file} CSVs written"
        break
    elif [ $SECONDS -gt 172800 ]; then # Kill if taking more than 2 days
        echo "Taking too long, abort!"
        exit 2
    fi
    echo "${count_file} CSVs found"
    sleep 60 # Wait for 1 min before detecting again
done

echo "Launching GAMLSS jobs"
#######################################################################################
# SUBMIT GAMLSS JOBS
for csv_file in "$save_data_path"/*.csv; do
    csv_name=$(basename $csv_file .csv)
    csv_name=${csv_name//_/\-}
    echo "Pulling data from $csv_name"
    for list in "$pheno_path"/*; do
        while read -r pheno; do
            bash_script=$gamlss_bash_dir/${pheno}_${csv_name}_fit.sh
            touch $bash_script

            echo "#!/bin/bash" > $bash_script

            echo "singularity run --cleanenv $img Rscript --save $mod_script $csv_file $pheno $gamlss_dir" >> $bash_script

            sbatch -J ${pheno}.${csv_name} \
                -o $gamlss_bash_dir/${pheno}_${csv_name}_cb_out.txt \
                -e $gamlss_bash_dir/${pheno}_${csv_name}_cb_err.txt \
                --partition=long --time=04-00:00:00 $bash_script
        done < $list
    done
done

#######################################################################################
# CHECK FOR OUTPUTS
#check for cb models first, since those should fit faster
mod_counts=$((${count_file}*208*2))

echo "${count_file} csvs, looking for ${mod_counts} output csvs"

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
