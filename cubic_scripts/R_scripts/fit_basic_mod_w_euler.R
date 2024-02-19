#Basic script to fit very simple gamlss model & test significance of sex term in sigma
#adding euler to see if/how centiles change

set.seed(12345)

#LOAD PACKAGES
library(gamlss)
library(dplyr)
library(data.table)

source("R_scripts/gamlss_helper_funs.R")

#GET ARTS
args <- commandArgs(trailingOnly = TRUE)
df <- fread(args[1], stringsAsFactors = TRUE, na.strings = "")
pheno <- as.character(args[2])
save_path <- args[3]

#READ IN EULER #s
df.euler <- fread("/cbica/home/gardnerm/combat-biovar/data/ukb_euler_nums.csv")
df <- left_join(df, df.euler)

#FIT BASIC MODEL
model <- gamlss(formula = as.formula(paste0(pheno,"~ poly(age_days, 3) + sexMale + surfholes")),
                     sigma.formula = ~ poly(age_days, 3) + sexMale + surfholes,
                     nu.formula = ~ 1,
                     control = gamlss.control(n.cyc = 200), 
                     family = BCCG, data=df, trace = FALSE)

#SAVE
csv_name <- sub(pattern = "(.*)\\..*$", replacement = "\\1", basename(as.character(args[1])))
csv_rename <- gsub("_", "-", csv_name)

saveRDS(model,paste0(save_path, "/", pheno, "_", csv_rename, "_euler_mod.rds"))