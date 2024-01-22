#Basic script to fit a gamlss model

set.seed(12345)

#LOAD PACKAGES
library(gamlss)
library(dplyr)
library(data.table)

#GET ARTS
args <- commandArgs(trailingOnly = TRUE)
df <- fread(args[1], stringsAsFactors = TRUE, na.strings = "")
pheno <- as.character(args[2])
glob_pheno <- as.character(args[3])
save_path <- args[4]

#FIT BASE MODEL
base_model <- gamlss(formula = as.formula(paste0(pheno,"~ pb(log_age) + sexMale + fs_version + pb(sex.age) + pb(", glob_pheno,")")),
             sigma.formula = as.formula(paste0("~ pb(log_age) + sexMale + pb(sex.age) + fs_version + pb(", glob_pheno,")")),
             nu.formula = as.formula(paste0("~ pb(log_age) + sexMale + pb(sex.age) + fs_version + pb(", glob_pheno,")")),
             control = gamlss.control(n.cyc = 200), 
             family = BCCG, data=df, trace = FALSE)

#SAVE
csv_name <- sub(pattern = "(.*)\\..*$", replacement = "\\1", basename(as.character(args[1])))
csv_rename <- gsub("_", "-", csv_name)

saveRDS(base_model,paste0(save_path, "/", pheno, "_", csv_rename, "_mod.rds"))
