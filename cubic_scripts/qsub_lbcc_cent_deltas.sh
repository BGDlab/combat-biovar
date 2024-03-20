#!/bin/bash

#see how different predicted centiles are for each subject when ComBat-GAM or ComBatLS are used to harmonize LBCC

#######################################################################################
# SET PATHS
img=/cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif #singularity image
base=/cbica/home/gardnerm/combat-biovar #base path (cubic) - also path that output csvs will be saved to
r_script=$base/cubic_scripts/R_scripts/get_lifespan_deltas.R #path to .R script
cent_path=$base/lifespan/centile_csvs #path to centile csvs
bash_dir=$base/lifespan/centile_qsubs

#search string:
config_list="batch.study" # batch.site"
#######################################################################################
cd $base/cubic_scripts #to source functions correctly
#######################################################################################
for config in $config_list
do
bash_script=$bash_dir/${config}_deltas.sh
touch $bash_script

#arg1=gam csv path, arg2=gamlss csv path, arg3=save path, arg4=search string
echo "singularity run --cleanenv $img Rscript --save $r_script $cent_path $config $config" > $bash_script

#qsub bash script
qsub -N $config -o $bash_dir/${config}_deltas_out.txt -e $bash_dir/${config}_deltas_err.txt $bash_script
done
