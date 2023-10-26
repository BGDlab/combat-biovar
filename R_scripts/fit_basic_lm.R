#Basic script to fit very simple gamlss model & test significance of sex term in sigma

set.seed(12345)

#LOAD PACKAGES
library(dplyr)
library(data.table)

source("R_scripts/gamlss_helper_funs.R")

#GET ARTS
args <- commandArgs(trailingOnly = TRUE)
df <- fread(args[1], stringsAsFactors = TRUE, na.strings = "")
pheno <- as.character(args[2])
save_path <- args[3]

#FIT BASIC MODEL
model <- lm(as.formula(paste0(pheno,"age_days + sexMale")), data=df)

#SAVE
csv_name <- sub(pattern = "(.*)\\..*$", replacement = "\\1", basename(as.character(args[1])))
csv_rename <- gsub("_", "-", csv_name)

saveRDS(model,paste0(save_path, "/", pheno, "_", csv_rename, "_lm.rds"))

#SIGNIFICANCE TESTING
df <- summary(model)$pTerms.table
fwrite(df, file=paste0(save_path, "/", pheno, "_", csv_rename, "_lm_sig.csv"))
