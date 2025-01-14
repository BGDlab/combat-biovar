#!/bin/bash
# Run ComBat, ComBat-GAM, and ComBatLS on curated LBCC data, then fit brain charts.
# updated to run on SLURM using ChatGPT
# Follow with run_LBCC_stats.sh
#######################################################################################
# SET PATHS
img=/cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif # Singularity image
base=/cbica/home/gardnerm/combat-biovar # Base path (cubic)
og_data=$base/data/lifespan_CN_imp-sites_euler.csv # Path to original data
save_data_path=$base/data/lifespan

# Paths to R scripts
r_base=$base/cubic_scripts/R_scripts

cf_script=$r_base/combat_apply_w_transform.R
mod_script=$r_base/fit_lifespan_mod_notbv.R
mod_script_batch=$r_base/fit_lifespan_mod_site_est.R

pheno_path=$base/pheno_lists # Path to .txt files listing phenotypes (global & regional)
#######################################################################################
cd $base/cubic_scripts # To source functions correctly
#######################################################################################

#######################################################################################
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
gamlss_dir=$study_dir/gamlss_objs
if ! [ -d $gamlss_dir ]; then
    mkdir $gamlss_dir
fi

#######################################################################################
# SUBMIT COMBAT JOBS
#######################################################################################
# Set covariate columns
covar_list="age_days,sexMale,sex.age" # age_days
batch="study"

# List possible configurations
config_list="cf.lm cf.gam cf.gamlss"

# Get data
csv_fname=$(basename $og_data .csv)
#######################################################################################
for config in $config_list; do
    echo "Prepping $config"
    # Write bash script
    bash_script=$cf_bash_dir/${csv_fname}_${config}_combat.sh
    touch $bash_script

    echo "#!/bin/bash" > $bash_script

    # ComBat LM
    if [ $config = "cf.lm" ]; then
        echo "singularity run --cleanenv $img Rscript --save $cf_script $og_data $batch $save_data_path $config $covar_list 'lm, formula = y ~ age_days + sexMale + sex.age'" >> $bash_script

    # ComBat GAM
    elif [ $config = "cf.gam" ]; then
        echo "singularity run --cleanenv $img Rscript --save $cf_script $og_data $batch $save_data_path $config $covar_list 'gam, formula = y ~ s(age_days) + sexMale + sex.age'" >> $bash_script

    # ComBat GAMLSS
    elif [ $config = "cf.gamlss" ]; then
        echo "singularity run --cleanenv $img Rscript --save $cf_script $og_data $batch $save_data_path $config $covar_list 'gamlss, formula = y ~ pb(age_days) + sexMale + sex.age, sigma.formula = ~ pb(age_days, inter=5)  + sexMale'" >> $bash_script
    fi

    # Submit bash script
    qsub -l h_vmem=64G,s_vmem=64G -N ${config}.${batch}.${csv_fname} \
        -o $cf_bash_dir/${config}.${csv_fname}_${batch}_out.txt \
        -e $cf_bash_dir/${config}.${csv_fname}_${batch}_err.txt \
	-l time=2-00:00:00 $bash_script
done
#######################################################################################
# CHECK FOR OUTPUTS
combat_counts=$(echo ${config_list[@]} | wc -w)

echo "Submitted ${combat_counts} ComBat configurations, looking for ${combat_counts} output CSVs"

SECONDS=0

while :; do
    count_file=$(find $save_data_path -type f -name '*.csv' | wc -l)
    if [ $count_file -eq $combat_counts ]; then
        echo "${count_file} CSVs written"
        break
    elif [ $SECONDS -gt 172800 ]; then # Kill if taking more than 2 days
        echo "Taking too long, abort!"
        exit 2
    fi
    echo "${count_file} CSVs found"
    sleep 60 # Wait for 1 min before detecting again
done

# Copy raw data frame
cp $og_data $save_data_path/lifespan_CN_imp-sites_euler_raw.csv
sleep 30

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

            qsub -N ${pheno}.${csv_name} \
                -o $gamlss_bash_dir/${pheno}_${csv_name}_no.tbv_out.txt \
                -e $gamlss_bash_dir/${pheno}_${csv_name}_no.tbv_err.txt \
		-l time=2-00:00:00 $bash_script
        done < $list
    done
done

echo "SUCCESS! All done :)"
