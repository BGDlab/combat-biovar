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

# Remove outputs from prior runs
rm -rf $csv_path/*_diffs.csv
rm -rf $csv_path/subject-wise/*_subj_pred.csv
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
	qsub -N perm-${n_perm}_sum -o $bash_dir/perm-${n_perm}_sum_out.txt -e $bash_dir/perm-${n_perm}_sum_err.txt -l h_vmem=120G,s_vmem=120G $bash_script
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

echo "DONE"
