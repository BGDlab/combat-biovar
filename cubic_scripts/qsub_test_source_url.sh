#!/bin/bash
#######################################################################################
# SET PATHS
img=/cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif #singularity image
base=/cbica/home/gardnerm/combat-biovar #base path (cubic) - also path that output csvs will be saved to
r_script=$base/cubic_scripts/R_scripts/test_source_url.R #path to .R script
#######################################################################################
#write bash script
bash_script=$base/test_source_url.sh
touch $bash_script
	
echo "singularity run --cleanenv $img Rscript --save $r_script" > $bash_script

#qsub bash script
qsub -N test_source_url -o $base/test-source-url_out.txt -e $base/test-source-url_err.txt $bash_script