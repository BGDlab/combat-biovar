#!/bin/bash

#PULL OUTPUTS OF 'run_varying_ratios_stats.sh' or 'run_permutation_stats.sh' FROM CUBIC  TO LOCAL
#don't pull *_no_ext.csv, not needed

#need to be on pennmed wifi/vpn
base=/Users/megardn/Desktop/BGD_Repos/combat_biovar/derivatives

#######################################################################################
# GET ARGS
if [ $# -lt 1 ]
then
	echo 1>&2 "$0: 'ratio' or 'perm'"
	exit 2
fi
#######################################################################################

if [ $1 = "ratio" ]
then
	# Varying M:F Ratios (Proportions) #
	if ! [ -d $base/ukb_ratio ]
		then
		mkdir $base/ukb_ratio
		fi
	echo "pulling *_diffs.csv"
	scp -r 'gardnerm@cubic-login.uphs.upenn.edu:/cbica/home/gardnerm/combat-biovar/ukb_ratios/perm_centile_csvs/*_diffs.csv' $base/ukb_ratio

	echo "pulling *_featurewise_*_sex_bias_tests.RDS" 
	scp -r 'gardnerm@cubic-login.uphs.upenn.edu:/cbica/home/gardnerm/combat-biovar/ukb_ratios/perm_centile_csvs/*_featurewise_*_sex_bias_tests.RDS' $base/ukb_ratio

	echo "pulling *_featurewise_*_t_tests.csv"
	scp -r 'gardnerm@cubic-login.uphs.upenn.edu:/cbica/home/gardnerm/combat-biovar/ukb_ratios/perm_centile_csvs/*_featurewise_*_t_tests.csv' $base/ukb_ratio

	echo "pulling subj.abs.mean_sex_bias_*_t_tests.csv"
	scp -r 'gardnerm@cubic-login.uphs.upenn.edu:/cbica/home/gardnerm/combat-biovar/ukb_ratios/perm_centile_csvs/subj.abs.mean_sex_bias_*_t_tests.csv' $base/ukb_ratio

	echo "pulling from ukb_ratios - subject-wise/*_subj_pred.csv"
	scp -r 'gardnerm@cubic-login.uphs.upenn.edu:/cbica/home/gardnerm/combat-biovar/ukb_ratios/perm_centile_csvs/subject-wise/*_subj_pred.csv' $base/ukb_ratio

	#add full centile .RDS outputs
	echo "pulling *_featurewise_*_t_tests_all_out.RDS" 
	scp -r 'gardnerm@cubic-login.uphs.upenn.edu:/cbica/home/gardnerm/combat-biovar/ukb_ratios/perm_centile_csvs/*_featurewise_*_t_tests_all_out.RDS' $base/ukb_ratio

elif [ $1 = "perm" ]
then
# Varying M:F Ratios (Proportions) #
	if ! [ -d $base/ukb_perm ]
		then
		mkdir $base/ukb_perm
		fi

	#not pulling diff csvs - too long and not needed
	#echo "pulling *_diffs.csv"
	#scp -r 'gardnerm@cubic-login.uphs.upenn.edu:/cbica/home/gardnerm/combat-biovar/ukb_permute/perm_centile_csvs/*_diffs.csv' $base/ukb_perm

	echo "pulling *_featurewise_*_sex_bias_tests.RDS" 
	scp -r 'gardnerm@cubic-login.uphs.upenn.edu:/cbica/home/gardnerm/combat-biovar/ukb_permute/perm_centile_csvs/*_featurewise_*_sex_bias_tests.RDS' $base/ukb_perm

	echo "pulling *_featurewise_*_t_tests.csv"
	scp -r 'gardnerm@cubic-login.uphs.upenn.edu:/cbica/home/gardnerm/combat-biovar/ukb_permute/perm_centile_csvs/*_featurewise_*_t_tests.csv' $base/ukb_perm

	echo "pulling subj.abs.mean_sex_bias_*_t_tests.csv"
	scp -r 'gardnerm@cubic-login.uphs.upenn.edu:/cbica/home/gardnerm/combat-biovar/ukb_permute/perm_centile_csvs/subj.abs.mean_sex_bias_*_t_tests.csv' $base/ukb_perm

	echo "pulling from ukb_permute - subject-wise/*_subj_pred.csv"
	scp -r 'gardnerm@cubic-login.uphs.upenn.edu:/cbica/home/gardnerm/combat-biovar/ukb_permute/perm_centile_csvs/subject-wise/*_subj_pred.csv' $base/ukb_perm

	echo "pulling *_featurewise_*_t_tests_all_out.RDS" 
	scp -r 'gardnerm@cubic-login.uphs.upenn.edu:/cbica/home/gardnerm/combat-biovar/ukb_permute/perm_centile_csvs/*_featurewise_*_t_tests_all_out.RDS' $base/ukb_perm

fi