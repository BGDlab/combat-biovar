#Basic script to fit very simple gamlss model & test significance of sex term in sigma

set.seed(12345)

#LOAD PACKAGES
library(gamlss)
library(dplyr)
library(data.table)

source("R_scripts/gamlss_helper_funs.R")

#GET ARTS
args <- commandArgs(trailingOnly = TRUE)
df <- fread(args[1], stringsAsFactors = TRUE, na.strings = "")
save_path <- args[2]

#LIST PHENOTYPES
pheno_list <- readRDS(file="/cbica/home/gardnerm/combat-biovar/cubic_scripts/R_scripts/pheno_list.rds")

#FIT BASIC MODEL

for (pheno in pheno_list){
  print(paste('modeling', pheno))
  model <- gamlss(formula = as.formula(paste(pheno,"~ poly(age_days, 3) + sexMale")),
                       sigma.formula = ~ poly(age_days, 3) + sexMale,
                       nu.formula = ~ 1,
                       control = gamlss.control(n.cyc = 200), 
                       family = BCCG, data=df, trace = FALSE)
  
  #SAVE
  csv_name <- sub(pattern = "(.*)\\..*$", replacement = "\\1", basename(as.character(args[1])))
  csv_rename <- gsub("_", "-", csv_name)
  
  saveRDS(model,paste0(save_path, "/", pheno, "_", csv_rename, "_mod.rds"))
  
  #DROP1 SIGNIFICANCE TESTING
  drop1_df <- drop1_all(model, name=pheno, dataset=csv_rename)
  fwrite(drop1_df, file=paste0(save_path, "/", pheno, "_", csv_rename, "_drop.csv"))
}