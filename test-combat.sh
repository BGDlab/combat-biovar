#!/bin/bash
cd /Users/megardn/Desktop/BGD_Repos/combat_biovar

Rscript --save /Users/megardn/Desktop/BGD_Repos/combat_biovar/R_scripts/combat_apply.R \
/Users/megardn/Desktop/BGD_Repos/combat_biovar/data/ukb_to_model/ukb_CN_data_simsites.csv \
"sim.site" /Users/megardn/Desktop/BGD_Repos/combat_biovar/data "TEST_combat_script" "age_days,sexMale" 'gam, formula = y ~ s(age_days) + sexMale, ref.batch = "Site_A"'