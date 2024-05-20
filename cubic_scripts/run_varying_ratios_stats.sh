#!/bin/bash

# Run stats test on the outputs of 'run_varying_ratios_pipeline.sh'. Trying to make a faster, cubic-based version of 'paper_prop_results.Rmd'

# expected outputs:
# $csv_path/*_diffs.csv x11
# $csv_path/subject-wise/*_subj_pred.csv x11
# $csv_path/*_featurewise_cent_t_tests.csv x2
# $csv_path/*_featurewise_cent_z_tests.csv x2
# $csv_path/*_featurewise_cent_sex_bias_tests.RDS x2
# $csv_path/*_featurewise_z_sex_bias_tests.RDS x2
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
# Remove outputs from prior runs
rm -rf $csv_path/*_diffs.csv
rm -rf $csv_path/subject-wise/*_subj_pred.csv
rm -rf $csv_path/*_featurewise_cent_t_tests.csv
rm -rf $csv_path/*_featurewise_cent_z_tests.csv
rm -rf $csv_path/*_featurewise_cent_sex_bias_tests.RDS
rm -rf $csv_path/*_featurewise_z_sex_bias_tests.RDS
rm -rf $csv_path/*_no_ext.csv

echo "Old outputs deleted"
sleep 120 #wait to make sure files are deleted
#######################################################################################
# CALCULATE CENTILE & Z-SCORE ERRORS
## also calculates subject-level summary stats
## based on `qsub_summarize_subj_centiles.sh`
r_script=$r_base/summarise_cent_subj-wise.R
# make dir for subject outputs
if ! [ -d $csv_path/subject-wise ]
	then
	mkdir $csv_path/subject-wise
	fi
# sub jobs
for n_prop in $(seq -f "%02g" 1 11) #11 sims
do
	echo "Prepping prop-$n_prop"
	#write bash script
	bash_script=$bash_dir/prop-${n_prop}_cent_sum.sh
	touch $bash_script
	
	echo "singularity run --cleanenv $img Rscript --save $r_script "prop" $n_prop $csv_path" > $bash_script

	#qsub bash script
	qsub -N prop-${n_prop}_sum -o $bash_dir/prop-${n_prop}_sum_out.txt -e $bash_dir/prop-${n_prop}_sum_err.txt -l h_vmem=64G,s_vmem=64G $bash_script
done
#######################################################
## CHECK FOR OUTPUTS
### summarise_cent_subj-wise.R saves 2 csv files per n_prop loop, second in 'subject-wise/*_subj_pred.csv' 
SECONDS=0

while :    # while TRUE
do
    count_file=$(find $csv_path/subject-wise -type f -name '*.csv' | wc -l)
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

echo "launching stats tests"
#######################################################
# STATS TESTS OF ERRORS
# featurewise error tests
r_script=$r_base/ratio_results.R
bash_script=$bash_dir/centile_tests.sh
touch $bash_script

echo "singularity run --cleanenv $img Rscript --save $r_script $csv_path 'full'" > $bash_script
## qsub bash script
qsub -N prop_cent_tests -o $bash_dir/cent_test_out.txt -e $bash_dir/cent_test_err.txt -l h_vmem=60.5G,s_vmem=60.0G $bash_script

# featurewise sex bias tests
## based on `qsub_sex_bias_test.sh`
r_script=$r_base/featurewise_sex_bias_test.R
bash_script=$bash_dir/sex_bias_test.sh
touch $bash_script
	
echo "singularity run --cleanenv $img Rscript --save $r_script $csv_path 'full' 'prop'" > $bash_script
## qsub bash script
qsub -N prop_sex-bias -o $bash_dir/sex_bias_test_out.txt -e $bash_dir/sex_bias_test_err.txt -l h_vmem=60.5G,s_vmem=60.0G $bash_script

#######################################################
# RM EXTREMES
## based on `qsub_rm_extremes.sh`
r_script=$r_base/remove_extremes_single.R
# sub jobs
for n_prop in $(seq -f "%02g" 1 11) #11 sims
do
	echo "Prepping prop-$n_prop"
	#write bash script
	bash_script=$bash_dir/prop-${n_prop}_rm_ext.sh
	touch $bash_script
	
	echo "singularity run --cleanenv $img Rscript --save $r_script $csv_path "prop" $n_prop " > $bash_script

	#qsub bash script
	qsub -N prop-${n_prop}_rm_ext -o $bash_dir/prop-${n_prop}_rm_ext_out.txt -e $bash_dir/prop-${n_prop}_rm_ext_err.txt -l h_vmem=64G,s_vmem=64G $bash_script
done
#######################################################
## CHECK FOR OUTPUTS
### expect 'remove_extremes_single.R' to write out 1 csv per n_prop loop
SECONDS=0

while :    # while TRUE
do
    count_file=$(find $csv_path -type f -name '*_no_ext.csv' | wc -l)
    # detect the expected output from 1st job
    if [ $count_file -eq 11 ] 
	then    # 1st job successfully finished
        echo "${count_file} no-ext files found"
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

echo "launching stats tests on data w extremes removed"
#######################################################
# STATS TESTS OF ERRORS W/O EXTREMES

# featurewise error tests
r_script=$r_base/ratio_results.R
bash_script=$bash_dir/noext_centile_tests.sh
touch $bash_script

echo "singularity run --cleanenv $img Rscript --save $r_script $csv_path 'no.ext'" > $bash_script
## qsub bash script
qsub -N prop_cent_tests -o $bash_dir/noext_cent_test_out.txt -e $bash_dir/noext_cent_test_err.txt -l h_vmem=60.5G,s_vmem=60.0G $bash_script

# featurewise sex bias tests
## based on `qsub_sex_bias_test.sh`
r_script=$r_base/featurewise_sex_bias_test.R
bash_script=$bash_dir/noext_sex_bias_test.sh
touch $bash_script

echo "singularity run --cleanenv $img Rscript --save $r_script $csv_path 'no.ext' 'prop'" > $bash_script
## qsub bash script
qsub -N prop_sex-bias -o $bash_dir/noext_sex_bias_test_out.txt -e $bash_dir/noext_sex_bias_test_err.txt -l h_vmem=60.5G,s_vmem=60.0G $bash_script

#######################################################
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

# $csv_path/*_featurewise_cent_sex_bias_tests.RDS x2
# $csv_path/*_featurewise_z_sex_bias_tests.RDS x2
SECONDS=0

while :    # while TRUE
do
    count_file=$(find $csv_path -type f -name '*_featurewise_*_sex_bias_tests.RDS' | wc -l)
    if [ $count_file -eq 4 ] 
	then    # 1st job successfully finished
        echo "all ${count_file} *featurewise_*_sex_bias_tests.RDS files found! on to the next"
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
# $csv_path/*_featurewise_z_t_tests.csv x2
SECONDS=0

while :    # while TRUE
do
    count_file=$(find $csv_path -type f -name '*_featurewise_*_t_tests.csv' | wc -l)
    if [ $count_file -eq 4 ] 
	then    # 1st job successfully finished
        echo "all ${count_file} featurewise_cent_t_tests.csv files found! on to the next"
        break
    elif [ $SECONDS -gt 86400 ] #kill if taking more than 1 day
	then
	echo "taking too long, abort!"
	exit 2
    fi
    echo "count ${count_file} *featurewise_cent_?_tests.csv files"
    sleep 60    # wait for 1min before detecting again
done

echo "DONE!"
