#!/bin/bash

#see how different predicted centiles are for each subject when ComBat-GAM or ComBatLS are used to harmonize LBCC

#######################################################################################
# SET PATHS
img=/cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif #singularity image
base=/cbica/home/gardnerm/combat-biovar #base path (cubic) - also path that output csvs will be saved to
r_script=$base/cubic_scripts/R_scripts/lifespan_delta_lms.R #path to .R script
cent_path=$base/lifespan/centile_csvs #path to centile csvs
bash_dir=$base/lifespan/centile_qsubs

#search string:
config="batch.study"
#######################################################################################
cd $base/cubic_scripts #to source functions correctly
#######################################################################################
bash_script=$bash_dir/${config}_delta_lms.sh
touch $bash_script

echo "singularity run --cleanenv $img Rscript --save $r_script $cent_path/${config}_pred_deltas.csv $cent_path" > $bash_script

#qsub bash script
qsub -N $config -o $bash_dir/${config}_delta_lms_out.txt -e $bash_dir/${config}_delta_lms_err.txt $bash_script
