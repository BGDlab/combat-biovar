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
#######################################################################################
# featurewise sex bias tests
## based on `qsub_sex_bias_test.sh`
r_script=$r_base/featurewise_sex_bias_test.R
bash_script=$bash_dir/sex_bias_test.sh
touch $bash_script
	
echo "singularity run --cleanenv $img Rscript --save $r_script $csv_path 'full'" > $bash_script
## qsub bash script
qsub -N prop_sex-bias -o $bash_dir/sex_bias_test_out.txt -e $bash_dir/sex_bias_test_err.txt -l h_vmem=60.5G,s_vmem=60.0G $bash_script

#######################################################
# STATS TESTS OF ERRORS W/O EXTREMES
# featurewise sex bias tests
## based on `qsub_sex_bias_test.sh`
r_script=$r_base/featurewise_sex_bias_test.R
bash_script=$bash_dir/sex_bias_test.sh
touch $bash_script

echo "singularity run --cleanenv $img Rscript --save $r_script $csv_path 'no.ext'" > $bash_script
## qsub bash script
qsub -N prop_sex-bias -o $bash_dir/sex_bias_test_out.txt -e $bash_dir/sex_bias_test_err.txt -l h_vmem=60.5G,s_vmem=60.0G $bash_script
