#Basic script to fit very simple gamlss model & test significance of sex term in sigma

set.seed(12345)

#LOAD PACKAGES
library(gamlss)
library(dplyr)
library(data.table)

#GET ARTS
args <- commandArgs(trailingOnly = TRUE)
df <- fread(args[1], stringsAsFactors = TRUE, na.strings = "")
pheno <- as.character(args[2])
save_path <- args[3]

#FIT BASIC MODEL
model <- gamlss(formula = as.formula(paste0(pheno,"~ poly(age_days, 3) + sex")),
                     sigma.formula = ~ poly(age_days, 3) + sex,
                     nu.formula = ~ 1,
                     control = gamlss.control(n.cyc = 200), 
                     family = BCCG, data=df, trace = FALSE)

#SAVE
csv_name <- sub(pattern = "(.*)\\..*$", replacement = "\\1", basename(as.character(args[1])))

saveRDS(model,paste0(save_path, "/", pheno, "_", csv_name, "_mod.rds"))
