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
save_path <- args[3]

csv_name <- sub(pattern = "(.*)\\..*$", replacement = "\\1", basename(as.character(args[1])))

#FIT
if(grepl("raw", csv_name, fixed=TRUE)){
  #fit with log link in mu for unharmonized data
  base_model <- gamlss(formula = as.formula(paste0(pheno,"~ pb(age_days) + sexMale + fs_version + pb(sex.age)")),
                       sigma.formula = as.formula(paste0("~ pb(age_days) + sexMale + pb(sex.age) + fs_version")),
                       nu.formula = as.formula(paste0("~ pb(age_days) + sexMale + pb(sex.age) + fs_version")),
                       control = gamlss.control(n.cyc = 200), 
                       family = BCCGo, data=df, trace = FALSE)
} else{
  base_model <- gamlss(formula = as.formula(paste0(pheno,"~ pb(age_days) + sexMale + fs_version + pb(sex.age)")),
                       sigma.formula = as.formula(paste0("~ pb(age_days) + sexMale + pb(sex.age) + fs_version")),
                       nu.formula = as.formula(paste0("~ pb(age_days) + sexMale + pb(sex.age) + fs_version")),
                       control = gamlss.control(n.cyc = 200), 
                       family = BCCG, data=df, trace = FALSE)
}

#SAVE
csv_rename <- gsub("_", "-", csv_name)

saveRDS(base_model,paste0(save_path, "/", pheno, "_", csv_rename, "_no.tbv_mod.rds"))
