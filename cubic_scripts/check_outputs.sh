#!/bin/bash

# Run stats test on the outputs of 'run_varying_ratios_pipeline.sh'. Trying to make a faster, cubic-based version of 'paper_prop_results.Rmd'

# expected outputs:
# $csv_path/*_diffs.csv x11
# $csv_path/subject-wise/*_subj_pred.csv x11
# $csv_path/*_featurewise_cent_t_tests.csv x2
# $csv_path/*_featurewise_cent_z_tests.csv x2
# $csv_path/subj.abs.mean_sex_bias_cent_t_tests.csv x2
# $csv_path/subj.abs.mean_sex_bias_z_t_tests.csv x2
# $csv_path/*_featurewise_cent_sex_bias_tests.csv x1
# $csv_path/*_featurewise_z_sex_bias_tests.csv x1
# $csv_path/*_no_ext.csv x11

#######################################################################################
# SET PATHS
img=/cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif #singularity image
base=/cbica/home/gardnerm/combat-biovar #base path (cubic)
study_dir=$base/ukb_ratios
csv_path=$study_dir/perm_centile_csvs
r_base=$base/cubic_scripts/R_scripts # paths to R scripts
bash_dir=$study_dir/stats_qsubs
# make dir for subject outputs
if ! [ -d $bash_dir ]
	then
	mkdir $bash_dir
	fi
#######################################################################################
cd $base/cubic_scripts #to source functions correctly
#######################################################################################
# CHECK FOR OUTPUTS

# $csv_path/subject-wise/*_subj_pred.csv x11 - already checked
# $csv_path/*_no_ext.csv x11 - already checked

# $csv_path/*_diffs.csv x11
SECONDS=0

while :    # while TRUE
do
    count_file=$(find $csv_path -type f -name '*_diffs.csv' | wc -l)
    if [ $count_file -eq 11 ] 
	then    # 1st job successfully finished
        echo "all ${count_file} diffs.csv files found! on to the next"
        break
    elif [ $SECONDS -gt 86400 ] #kill if taking more than 1 day
	then
	echo "taking too long, abort!"
	exit 2
    fi
    echo "count ${count_file} *diffs.csv files"
    sleep 60    # wait for 1min before detecting again
done

# $csv_path/*_featurewise_cent_sex_bias_tests.csv x1
# $csv_path/*_featurewise_z_sex_bias_tests.csv x1
SECONDS=0

while :    # while TRUE
do
    count_file=$(find $csv_path -type f -name '*_featurewise_*_sex_bias_tests.csv' | wc -l)
    if [ $count_file -eq 2 ] 
	then    # 1st job successfully finished
        echo "all ${count_file} *featurewise_*_sex_bias_tests.csv files found! on to the next"
        break
    elif [ $SECONDS -gt 86400 ] #kill if taking more than 1 day
	then
	echo "taking too long, abort!"
	exit 2
    fi
    echo "count ${count_file} *featurewise_*_sex_bias_tests.csv files"
    sleep 60    # wait for 1min before detecting again
done

# $csv_path/*_featurewise_cent_t_tests.csv x2
# $csv_path/*_featurewise_cent_z_tests.csv x2
SECONDS=0

while :    # while TRUE
do
    count_file=$(find $csv_path -type f -name '*_featurewise_cent_?_tests.csv' | wc -l)
    if [ $count_file -eq 4 ] 
	then    # 1st job successfully finished
        echo "all ${count_file} featurewise_cent_?_tests.csv files found! on to the next"
        break
    elif [ $SECONDS -gt 86400 ] #kill if taking more than 1 day
	then
	echo "taking too long, abort!"
	exit 2
    fi
    echo "count ${count_file} *featurewise_cent_?_tests.csv files"
    sleep 60    # wait for 1min before detecting again
done

# $csv_path/subj.abs.mean_sex_bias_cent_t_tests.csv x2
# $csv_path/subj.abs.mean_sex_bias_z_t_tests.csv x2
SECONDS=0

while :    # while TRUE
do
    count_file=$(find $csv_path -type f -name 'subj.abs.mean_sex_bias_*_t_tests.csv' | wc -l)
    if [ $count_file -eq 2 ] 
	then    # 1st job successfully finished
        echo "all ${count_file} subj.abs.mean_sex_bias_*_t_tests.csv files found!"
        break
    elif [ $SECONDS -gt 86400 ] #kill if taking more than 1 day
	then
	echo "taking too long, abort!"
	exit 2
    fi
    echo "count ${count_file} subj.abs.mean_sex_bias_*_t_tests.csv files"
    sleep 60    # wait for 1min before detecting again
done

echo "DONE!"