# load models fit on a given csv from .rds and extract centile scores

set.seed(12345)

#LOAD PACKAGES
library(gamlss)
library(dplyr)
library(data.table)
library(tibble)

print(getwd())

source("R_scripts/gamlss_helper_funs.R")
pheno_list <- readRDS(file="R_scripts/pheno_list.rds")

#get args
args <- commandArgs(trailingOnly = TRUE)
read_path <- as.character(args[1]) #path to gamlss models
save_path <- as.character(args[2]) #path to save output csv
fname_str <- as.character(args[3]) #string to look for in data .csv and model .rds files
#make sure - and _ are searched interchangeably
fname_str_search <- gsub("_|-", "[-_]", fname_str)
print(fname_str)
print(fname_str_search)

### find correct models ###
all.model.files <- list.files(path = read_path, pattern = "mod.rds", full.names = TRUE)
print("all model files:")
print(all.model.files[1:4])

#brain chart models - '_mod.rds'
notbv_search <- paste0(fname_str_search, "_mod")
notbv_model.files <- all.model.files[grep(notbv_search, all.model.files)]
print("selected brain chart model files:")
print(notbv_model.files[1:4])

#site effect models - 'site.est'
site.est_search <- paste0(fname_str_search, "_site.est_mod")
site.est_model.files <- all.model.files[grep(site.est_search, all.model.files)]
print("selected site.est model files:")
print(site.est_model.files[1:4])

#Get Cohen's F2 for study effect
cohensf2.df <- data.frame("pheno" = character(),
                          "fsq" = double())

for (pheno in pheno_list){

  pheno_search <- paste0(read_path,"/", pheno)

  #get full model
  full_mod_name <- site.est_model.files[grep(pheno_search, site.est_model.files)]
  print(full_mod_name)
  
  #get null model
  null_mod_name <- notbv_model.files[grep(pheno_search, notbv_model.files)]
  print(null_mod_name)
  
  tryCatch({
  full_mod <- readRDS(full_mod_name)
  null_mod <- readRDS(null_mod_name)
  
  #get cohens f
  f2 <- cohens_f2_local(full_mod, null_mod)
  f2.df <- data.frame("pheno" = as.character(pheno),
                      "fsq" = f2)
  
  cohensf2.df <- rbind(cohensf2.df, f2.df)},
  
  error=function(e) {
    message(paste("Can't load", pheno))
    print(e)
  })
}
fwrite(cohensf2.df, paste0(save_path, "/", fname_str, "_cohenfsq.csv"))
