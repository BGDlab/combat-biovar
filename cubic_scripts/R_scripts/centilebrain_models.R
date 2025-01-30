#Replicating results using models from CentileBrain resource, per reviewer request
#lms models from tutorials at https://centilebrain.org/#/tutorial

set.seed(12345)

#LOAD PACKAGES
library(gamlss)
library(dplyr)
library(data.table)

#GET ARGS
args <- commandArgs(trailingOnly = TRUE)
df <- fread(args[1], stringsAsFactors = TRUE, na.strings = "")
pheno <- as.character(args[2])
save_path <- args[3]

#FIT LMS
model_formula <- paste0("lms(", pheno, ", age_days, method.pb='GAIC', data=df, k=5, calibration=FALSE)")

mod <- eval(parse(text=model_formula))

#FIT GAMLSS
fam <- mod$family[1]
print(paste("fitting", pheno, "with", fam))

if ("tau" %in% mod[[2]]){
  gamlss_formula <-paste("gamlss(formula =", pheno, "~ pb(age_days, method='GAIC', k=5),",
                         "sigma.formula = ~ pb(age_days, method='GAIC', k=5),",
                         "nu.formula = ~ pb(age_days, method='GAIC', k=5),",
                         "tau.formula = ~ pb(age_days, method='GAIC', k=5),",
                         "family =", fam, ", data=df, trace = FALSE)")
} else {
  gamlss_formula <-paste("gamlss(formula =", pheno, "~ pb(age_days, method='GAIC', k=5),",
                         "sigma.formula = ~ pb(age_days, method='GAIC', k=5),",
                         "nu.formula = ~ pb(age_days, method='GAIC', k=5),", 
                         "family =", fam, ", data=df, trace = FALSE)")
}

base_mod <- eval(parse(text = gamlss_formula))

#SAVE
csv_name <- sub(pattern = "(.*)\\..*$", replacement = "\\1", basename(as.character(args[1])))
csv_rename <- gsub("_", "-", csv_name)

saveRDS(base_mod,paste0(save_path, "/", pheno, "_", csv_rename, "_cb_mod.rds"))

#ALSO FIT MOD WITH SITE EFFECTS
#easier to match mod with df

print(paste("fitting", pheno, "with", fam, "family to get study terms"))

#Write out formula
if ("tau" %in% mod[[2]]){
  gamlss_formula <-paste("gamlss(formula =", pheno, "~ pb(age_days, method='GAIC', k=5) + study,",
                         "sigma.formula = ~ pb(age_days, method='GAIC', k=5) + study,",
                         "nu.formula = ~ pb(age_days, method='GAIC', k=5),",
                         "tau.formula = ~ pb(age_days, method='GAIC', k=5),",
                         "family =", fam, ", data=df, trace = FALSE)")
} else {
  gamlss_formula <-paste("gamlss(formula =", pheno, "~ pb(age_days, method='GAIC', k=5) + study,",
                         "sigma.formula = ~ pb(age_days, method='GAIC', k=5) + study,",
                         "nu.formula = ~ pb(age_days, method='GAIC', k=5),", 
                         "family =", fam, ", data=df, trace = FALSE)")
}

site_mod <- eval(parse(text = gamlss_formula))

#SAVE
saveRDS(site_mod, paste0(save_path, "/", pheno, "_", csv_rename, "_cb_site.est_mod.rds"))
