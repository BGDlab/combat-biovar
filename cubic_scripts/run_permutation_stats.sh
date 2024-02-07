#!/bin/bash

# Run stats test on the outputs of 'run_permutation_pipeline.sh'.

# expected outputs:
# $csv_path/*_diffs.csv x # perms
# $csv_path/subject-wise/*_subj_pred.csv x # perms
# $csv_path/*_featurewise_cent_t_tests.csv x2
# $csv_path/*_featurewise_cent_z_tests.csv x2
# $csv_path/subj.abs.mean_sex_bias_cent_t_tests.csv x1
# $csv_path/subj.abs.mean_sex_bias_z_t_tests.csv x1
# $csv_path/*_featurewise_cent_sex_bias_tests.RDS x2
# $csv_path/*_featurewise_z_sex_bias_tests.RDS x2
# $csv_path/*_no_ext.csv x # perms

#######################################################################################
# SET PATHS
img=/cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif #singularity image
base=/cbica/home/gardnerm/combat-biovar #base path (cubic)
study_dir=$base/ukb_permute
csv_path=$study_dir/perm_centile_csvs
r_base=$base/cubic_scripts/R_scripts # paths to R scripts
bash_dir=$study_dir/stats_qsubs
# make dir for subject outputs
if ! [ -d $bash_dir ]
	then
	mkdir $bash_dir
	fi
#######################################################################################
# GET ARGS
if [ $# -lt 1 ]
then
	echo 1>&2 "$0: provide # of permutations run"
	exit 2
fi
#######################################################################################
cd $base/cubic_scripts #to source functions correctly
#######################################################################################
# Remove outputs from prior runs
rm -rf $csv_path/*_diffs.csv
rm -rf $csv_path/subject-wise/*_subj_pred.csv
rm -rf $csv_path/*_featurewise_cent_t_tests.csv
rm -rf $csv_path/*_featurewise_cent_z_tests.csv
rm -rf $csv_path/subj.abs.mean_sex_bias_cent_t_tests.csv
rm -rf $csv_path/subj.abs.mean_sex_bias_z_t_tests.csv
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
for n_perm in $(seq -f "%03g" 1 $1) 
do
	echo "Prepping perm-$n_perm"
	#write bash script
	bash_script=$bash_dir/perm-${n_perm}_cent_sum.sh
	touch $bash_script
	
	echo "singularity run --cleanenv $img Rscript --save $r_script "perm" $n_perm $csv_path" > $bash_script

	#qsub bash script
	qsub -N perm-${n_perm}_sum -o $bash_dir/perm-${n_perm}_sum_out.txt -e $bash_dir/perm-${n_perm}_sum_err.txt -l h_vmem=64G,s_vmem=64G $bash_script
done
#######################################################
## CHECK FOR OUTPUTS
### summarise_cent_subj-wise.R saves 2 csv files per n_perm loop, second in 'subject-wise/*_subj_pred.csv' 
SECONDS=0

while :    # while TRUE
do
    count_file=$(find $csv_path/subject-wise -type f -name '*.csv' | wc -l)
    # detect the expected output from 1st job
    if [ $count_file -eq $1 ] 
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

echo "singularity run --cleanenv $img Rscript --save $r_script $csv_path 'full' 'perm' " > $bash_script
## qsub bash script
qsub -N perm_cent_tests -o $bash_dir/cent_test_out.txt -e $bash_dir/cent_test_err.txt -l h_vmem=60.5G,s_vmem=60.0G $bash_script

# sex-bias test of subj-means
r_script=$r_base/ratio_subject-wise_results.R
bash_script=$bash_dir/perm_subj-wise_sex_bias_test.sh 
touch $bash_script

echo "singularity run --cleanenv $img Rscript --save $r_script $csv_path 'perm'" > $bash_script
## qsub bash script
qsub -N perm_sub-wide_sex_tests -o $bash_dir/sub-wide_sex_test_out.txt -e $bash_dir/sub-wide_sex_test_err.txt -l h_vmem=60.5G,s_vmem=60.0G $bash_script

# featurewise sex bias tests
## based on `qsub_sex_bias_test.sh`
r_script=$r_base/featurewise_sex_bias_test.R
bash_script=$bash_dir/sex_bias_test.sh
touch $bash_script
	
echo "singularity run --cleanenv $img Rscript --save $r_script $csv_path 'full' 'perm'" > $bash_script
## qsub bash script
qsub -N perm_sex-bias -o $bash_dir/sex_bias_test_out.txt -e $bash_dir/sex_bias_test_err.txt -l h_vmem=60.5G,s_vmem=60.0G $bash_script

#######################################################
# RM EXTREMES
## based on `qsub_rm_extremes.sh`
r_script=$r_base/remove_extremes_single.R
# sub jobs
for n_perm in $(seq -f "%03g" 1 $1) #10 sims
do
	echo "Prepping perm-$n_perm"
	#write bash script
	bash_script=$bash_dir/perm-${n_perm}_rm_ext.sh
	touch $bash_script
	
	echo "singularity run --cleanenv $img Rscript --save $r_script $csv_path "perm" $n_perm" > $bash_script

	#qsub bash script
	qsub -N perm-${n_perm}_rm_ext -o $bash_dir/perm-${n_perm}_rm_ext_out.txt -e $bash_dir/perm-${n_perm}_rm_ext_err.txt -l h_vmem=64G,s_vmem=64G $bash_script
done
#######################################################
## CHECK FOR OUTPUTS
### expect 'remove_extremes_single.R' to write out 1 csv per n_perm loop
SECONDS=0

while :    # while TRUE
do
    count_file=$(find $csv_path -type f -name '*_no_ext.csv' | wc -l)
    # detect the expected output from 1st job
    if [ $count_file -eq $1 ] 
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
bash_script=$bash_dir/centile_tests_noext.sh
touch $bash_script

echo "singularity run --cleanenv $img Rscript --save $r_script $csv_path 'no.ext' 'perm'" > $bash_script
## qsub bash script
qsub -N perm_cent_tests_noext -o $bash_dir/cent_test_noext_out.txt -e $bash_dir/cent_test_noext_err.txt -l h_vmem=60.5G,s_vmem=60.0G $bash_script

# featurewise sex bias tests
## based on `qsub_sex_bias_test.sh`
r_script=$r_base/featurewise_sex_bias_test.R
bash_script=$bash_dir/sex_bias_test_noext.sh
touch $bash_script

echo "singularity run --cleanenv $img Rscript --save $r_script $csv_path 'no.ext' 'perm'" > $bash_script
## qsub bash script
qsub -N perm_sex-bias_noext -o $bash_dir/sex_bias_test_noext_out.txt -e $bash_dir/sex_bias_test_noext_err.txt -l h_vmem=60.5G,s_vmem=60.0G $bash_script

#######################################################
# CHECK FOR OUTPUTS

# $csv_path/subject-wise/*_subj_pred.csv x n permutations - already checked
# $csv_path/*_no_ext.csv x n permutations - already checked

# $csv_path/*_diffs.csv x n permutations
SECONDS=0

while :    # while TRUE
do
    count_file=$(find $csv_path -type f -name '*_diffs.csv' | wc -l)
    if [ $count_file -eq $1 ] 
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

# $csv_path/subj.abs.mean_sex_bias_cent_t_tests.csv x1
# $csv_path/subj.abs.mean_sex_bias_z_t_tests.csv x1
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
