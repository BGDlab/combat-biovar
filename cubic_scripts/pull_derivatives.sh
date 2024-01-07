#!/bin/bash

#PULL ALL OUTPUTS FROM CUBIC  TO LOCAL
#need to be on pennmed wifi/vpn
base=/Users/megardn/Desktop/BGD_Repos/combat_biovar/derivatives

# Main Analyses #
if ! [ -d $base/ukb_basic ]
	then
	mkdir $base/ukb_basic
	fi
echo "pulling from ukb_basic"
scp -r 'gardnerm@cubic-login.uphs.upenn.edu:/cbica/home/gardnerm/combat-biovar/ukb_basic/centile_csvs/*.csv' $base/ukb_basic
echo "pulling from ukb_basic - subject-wise"
scp -r 'gardnerm@cubic-login.uphs.upenn.edu:/cbica/home/gardnerm/combat-biovar/ukb_basic/centile_csvs/subject-wise/*.csv' $base/ukb_basic

# Replication (Permutations) #
if ! [ -d $base/ukb_perm ]
	then
	mkdir $base/ukb_perm
	fi
echo "pulling from ukb_permute"
scp -r 'gardnerm@cubic-login.uphs.upenn.edu:/cbica/home/gardnerm/combat-biovar/ukb_permute/perm_centile_csvs/*.csv' $base/ukb_perm
echo "pulling from ukb_permute - subject-wise"
scp -r 'gardnerm@cubic-login.uphs.upenn.edu:/cbica/home/gardnerm/combat-biovar/ukb_permute/perm_centile_csvs/subject-wise/*.csv' $base/ukb_perm

# Varying M:F Ratios (Proportions) #
if ! [ -d $base/ukb_ratio ]
	then
	mkdir $base/ukb_ratio
	fi
echo "pulling from ukb_ratios"
scp -r 'gardnerm@cubic-login.uphs.upenn.edu:/cbica/home/gardnerm/combat-biovar/ukb_ratios/perm_centile_csvs/*.csv' $base/ukb_ratio
echo "pulling from ukb_ratios - subject-wise"
scp -r 'gardnerm@cubic-login.uphs.upenn.edu:/cbica/home/gardnerm/combat-biovar/ukb_ratios/perm_centile_csvs/subject-wise/*.csv' $base/ukb_ratio

# LBCC Lifespan #