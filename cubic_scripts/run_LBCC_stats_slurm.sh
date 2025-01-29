#!/bin/bash
# run ComBat, ComBat-GAM, and ComBatLS on curated LBCC data, then fit brain charts and get stats
#######################################################################################
# SET PATHS
img=/cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif #singularity image
base=/cbica/home/gardnerm/combat-biovar #base path (cubic)
og_data=$base/data/lifespan_CN_site-level_euler.csv #path to original data
save_data_path=$base/data/lifespan
study_dir=$base/lifespan
gamlss_dir=$study_dir/gamlss_objs
# paths to R scripts
r_base=$base/cubic_scripts/R_scripts

centile_script=$r_base/fit_lifespan_centiles.R
mod_summary_script=$r_base/get_lifespan_site_eff.R
deltas_script=$r_base/get_lifespan_deltas.R
#######################################################################################
cd $base/cubic_scripts #to source functions correctly
#######################################################################################
# MAKE DIRECTORIES
#study dir

#centile qsubs
cent_bash_dir=$study_dir/centile_qsubs
if ! [ -d $cent_bash_dir ]
	then
	mkdir $cent_bash_dir
	else
    rm -f $cent_bash_dir/*.*
	fi

#centile output csvs
cent_save_dir=$study_dir/centile_csvs
if ! [ -d $cent_save_dir ]
	then
	mkdir $cent_save_dir
	else
    rm -f $cent_save_dir/*.*
	fi

######################################################################################
# SUBMIT CENTILE MODELING JOBS
config_list_nosite="lifespan-CN-imp-sites-euler-log-cf-cf.gam-batch.study-data_no.tbv lifespan-CN-imp-sites-euler-log-cf-cf.gamlss-batch.study-data_no.tbv lifespan-CN-imp-sites-euler-raw_no.tbv"
#iterate through combat configs
for config in $config_list_nosite
do
	echo "Prepping $config"
	#write bash script
	bash_script=$cent_bash_dir/${config}_cent.sh
	touch $bash_script
	
	echo "#!/bin/bash" > $bash_script
		
	echo "singularity run --cleanenv $img Rscript --save $centile_script $save_data_path $gamlss_dir $cent_save_dir $config" >> $bash_script

	#qsub bash script
	sbatch --time=04-00:00:00 --mem=64G -J $config \
        -o $cent_bash_dir/${config}_out.txt \
        -e $cent_bash_dir/${config}_err.txt \
        --partition=long $bash_script
done
#######################################################################################
# CHECK FOR OUTPUTS
cent_csv_count=$(echo $config_list_nosite | wc -w)
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

echo "getting deltas"
######################################################################################
# GET Diffs between ComBatGAM and ComBatLS centiles
config_str="batch.study-data_no.tbv_predictions"
bash_script=$cent_bash_dir/${config_str}_deltas.sh
touch $bash_script

echo "#!/bin/bash" > $bash_script

#arg1=gam csv path, arg2=gamlss csv path, arg3=save path, arg4=search string
echo "singularity run --cleanenv $img Rscript --save $deltas_script $cent_save_dir $config_str $config_str" >> $bash_script

#qsub bash script
sbatch --time=04-00:00:00 --mem=64G -J ${config_str}_deltas \
        -o $cent_bash_dir/${config_str}_deltas_out.txt \
        -e $cent_bash_dir/${config_str}_deltas_err.txt \
        --partition=long $bash_script

echo "getting site effect estimates and summaries"
######################################################################################
# GET MODEL SUMMARIES AND SITE EFFECTS

config_list_plusraw="lifespan-CN-imp-sites-euler-log-cf-cf.gam-batch.study-data lifespan-CN-imp-sites-euler-log-cf-cf.gamlss-batch.study-data lifespan-CN-imp-sites-euler-raw" 
for config in $config_list_plusraw
do
	echo "Prepping $config"
	#write bash script
	bash_script=$cent_bash_dir/${config}_site_est.sh
	touch $bash_script
	
	echo "#!/bin/bash" > $bash_script
	
	echo "singularity run --cleanenv $img Rscript --save $mod_summary_script $gamlss_dir $cent_save_dir $config" >> $bash_script

	#qsub bash script
	sbatch --time=04-00:00:00 --mem=64G -J $config \
        -o $cent_bash_dir/${config}_site_est_out.txt \
        -e $cent_bash_dir/${config}_site_est_err.txt \
        --partition=long $bash_script
done

echo "DONE. Count files once all jobs finish"


