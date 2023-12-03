singularity run --cleanenv \
-B /cbica/home/gardnerm/combat-biovar/ukb_basic,/cbica/home/gardnerm/combat-biovar/R_scripts \
/cbica/home/gardnerm/software/containers/r_gamlss_0.0.1.sif \
Rscript --save /cbica/home/gardnerm/combat-biovar/R_scripts/gamlss_parser.R /cbica/home/gardnerm/combat-biovar/ukb_permute/gamlss_objs /cbica/home/gardnerm/combat-biovar/ukb_permute
