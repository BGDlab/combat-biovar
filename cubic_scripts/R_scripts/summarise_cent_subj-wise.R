#subject-wise centile and Z score error summaries from varying M:F dataframes

#LOAD PACKAGES
library(dplyr)
library(data.table)
library(tibble)

source("R_scripts/gamlss_helper_funs.R")

#pheno lists
vol_list_global <- readRDS(file="R_scripts/vol_list_global.rds")
vol_list_regions <- readRDS(file="R_scripts/Vol_list_regions.rds")
sa_list <- readRDS(file="R_scripts/SA_list.rds")
ct_list <- readRDS(file="R_scripts/CT_list.rds")
pheno.list <- readRDS(file="R_scripts/pheno_list.rds")

#get args
args <- commandArgs(trailingOnly = TRUE)
prop_n <- str_pad(args[1], 2, pad = "0") #each prop. as different qsub
path_to_csvs <- args[2]
save_path <- args[3]
#def how to find correct csvs
prop_str <- paste0("prop-", prop_n)

#READ INTO DATAFRAME
ratio_predictions <- get.predictions.ratio(prop_str, df_path = path_to_csvs)

#GET CENTILE & Z ERRORS
ratio_pred_err <- get.diffs(ratio_predictions, pheno_list=pheno.list)

#CALC SUBJECT-WISE MEANS
subj_mean_preds <- means.by.subj(ratio_pred_err, pheno_list=pheno.list)

#SAVE RESULTS
fwrite(subj_mean_preds, paste0(save_path, "/", prop_str, "_subj_pred.csv"))