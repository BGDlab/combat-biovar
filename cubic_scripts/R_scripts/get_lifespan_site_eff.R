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

#brain chart models - 'no.tbv'
notbv_search <- paste0(fname_str_search, "_no.tbv")
notbv_model.files <- all.model.files[grep(notbv_search, all.model.files)]
print("selected brain chart model files:")
print(notbv_model.files[1:4])

# #extract values from summary table
# notbv_summary.list <- lapply(notbv_model.files, get.gamlss.summary)
# names(notbv_summary.list) <- lapply(notbv_model.files, get.y)
# #dataframe
# notbv_summary.df <- bind_rows(notbv_summary.list, .id="pheno")
# #write out
# fwrite(notbv_summary.df, paste0(save_path, "/", fname_str, "_notbv_full_sum.csv"))

#site effect models - 'site.est'
site.est_search <- paste0(fname_str_search, "_site.est")
site.est_model.files <- all.model.files[grep(site.est_search, all.model.files)]
print("selected site.est model files:")
print(site.est_model.files[1:4])

# #extract values from summary table
# site.est_summary.list <- lapply(site.est_model.files, get.gamlss.summary)
# names(site.est_summary.list) <- lapply(site.est_model.files, get.y)
# #dataframe
# site.est_summary.df <- bind_rows(site.est_summary.list, .id="pheno")
# #write out
# fwrite(site.est_summary.df, paste0(save_path, "/", fname_str, "_site.est_full_sum.csv"))


#Get Cohen's F2 for study effect
cohensf2.df <- data.frame("pheno" = character(),
                          "fsq" = double())

for (pheno in pheno_list){
  #get full model
  full_mod_name <- site.est_model.files[grep(pheno, site.est_model.files)]
  print(full_mod_name)
  
  #get null model
  null_mod_name <- notbv_model.files[grep(pheno, notbv_model.files)]
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
    message("Can't load this pheno")
    print(e)
  })
}
fwrite(cohensf2.df, paste0(save_path, "/", fname_str, "_cohenfsq.csv"))