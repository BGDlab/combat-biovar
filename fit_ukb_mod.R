#Basic script to fit a gamlss model

set.seed(12345)

#LOAD PACKAGES
library(gamlss)
library(dplyr)

#GET ARTS
args <- commandArgs(trailingOnly = TRUE)
ukb_df <- fread(args[1], stringsAsFactors = TRUE, na.strings = "")
pheno <- as.character(args[2])
save_path <- args[3]

#FIT BASE MODEL
base_model <- gamlss(formula = as.formula(paste0(pheno,"~ pb(age_days) + sex + fs_version + pb(sex.age) + pb(TBV)")),
             sigma.formula = ~  pb(age_days) + sex,
             nu.formula = ~ 1,
             control = gamlss.control(n.cyc = 200), 
             family = BCCG, data=ukb_df, trace = FALSE)

#USE stepGAICAll.A to fit best model
best_model <- stepGAICAll.A(base_model, scope=list(lower=~1, upper=~pb(age_days) + sex + fs_version + pb(sex.age) + pb(TBV)), k=2) #AIC

#SAVE
saveRDS(best_model,paste0(save_path, "/", pheno, "_mod.rds"))
