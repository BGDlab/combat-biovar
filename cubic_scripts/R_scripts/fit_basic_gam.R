#Basic script to fit very simple gamlss model & test significance of sex term in sigma

set.seed(12345)

#LOAD PACKAGES
library(mgcv)
library(dplyr)
library(data.table)

source("R_scripts/gamlss_helper_funs.R")

#GET ARTS
args <- commandArgs(trailingOnly = TRUE)
df <- fread(args[1], stringsAsFactors = TRUE, na.strings = "")
pheno <- as.character(args[2])
save_path <- args[3]

#FIT BASIC MODEL
model <- gam(as.formula(paste0(pheno,"~ poly(age_days, 3) + sexMale")), data=df)

#SAVE
csv_name <- sub(pattern = "(.*)\\..*$", replacement = "\\1", basename(as.character(args[1])))
csv_rename <- gsub("_", "-", csv_name)

saveRDS(model,paste0(save_path, "/", pheno, "_", csv_rename, "_gam.rds"))

#SIGNIFICANCE TESTING
df <- anova.gam(model)$pTerms.table
df <- data.frame(term = row.names(df), df) %>%
  mutate(dataset = csv_rename,
         phenotype = pheno)

fwrite(df, file=paste0(save_path, "/", pheno, "_", csv_rename, "_gam_sig.csv"))
