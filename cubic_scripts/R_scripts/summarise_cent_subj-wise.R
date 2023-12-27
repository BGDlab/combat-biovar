
#subject-wise centile and Z score error summaries 
#from permuted dfs (output by qsub_perm_centiles.sh) or 
#M:F varying dfs (output by qsub_ratio_centiles.sh

########################################
## Expects args:
# "perm" vs "prop"
# number of perm/prop iteration
# path to csvs (both read and save)
########################################

#LOAD PACKAGES
library(dplyr)
library(data.table)
library(tibble)
library(stringr)

source("R_scripts/gamlss_helper_funs.R")

#pheno lists
vol_list_global <- readRDS(file="R_scripts/vol_list_global.rds")
vol_list_regions <- readRDS(file="R_scripts/Vol_list_regions.rds")
sa_list <- readRDS(file="R_scripts/SA_list.rds")
ct_list <- readRDS(file="R_scripts/CT_list.rds")
pheno.list <- readRDS(file="R_scripts/pheno_list.rds")

#get args
args <- commandArgs(trailingOnly = TRUE)

##### BASIC MODEL RESULTS #####
# parse outputs from 

if (args[1] == "basic"){
  
  path_to_csvs <- as.character(args[3])
  #READ INTO DATAFRAME
  predictions <- get.predictions(df_path = path_to_csvs)
  
  #GET CENTILE & Z ERRORS
  pred_err <- get.diffs(predictions, pheno_list=pheno.list, ref_level = "ukb_CN")
  
  str <- as.character("ukb_basic")

}

##### PERMUTATION PIPELINE RESULTS #####
# parse outputs from 

if (args[1] == "perm"){

  perm_n <- str_pad(args[2], 3, pad = "0") #each perm as different qsub
  path_to_csvs <- as.character(args[3])
  #def how to find correct csvs
  str <- as.character(paste0("perm-", perm_n))
  
  #READ INTO DATAFRAME
  predictions <- get.predictions.perm(str, df_path = path_to_csvs)
  
  #GET CENTILE & Z ERRORS
  pred_err <- get.diffs(predictions, pheno_list=pheno.list)
  
}

##### VARYING M:F PROPORTION PIPELINE RESULTS #####
if (args[1] == "prop"){
  
  prop_n <- str_pad(args[2], 2, pad = "0") #each prop. as different qsub
  path_to_csvs <- args[3]
  #def how to find correct csvs
  str <- as.character(paste0("prop-", prop_n))
  
  #READ INTO DATAFRAME
  predictions <- get.predictions.ratio(str, df_path = path_to_csvs)
  
  #GET CENTILE & Z ERRORS
  pred_err <- get.diffs(predictions, pheno_list=pheno.list)
}

##### CALC AND SAVE #####

#save out
f1 <- paste0(path_to_csvs, "/", str, "_diffs.csv")
print(paste("writing results to", f1))
fwrite(pred_err, file=f1)

#CALC SUBJECT-WISE MEANS
subj_mean_preds <- means.by.subj(pred_err, pheno_list=pheno.list)
  
#SAVE RESULTS
f2 <- paste0(path_to_csvs, "/subject-wise/", str, "_subj_pred.csv")
print(paste("writing results to", f2))
fwrite(subj_mean_preds, file=f2)
print("DONE")
