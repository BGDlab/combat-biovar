#script for applying different versions of combat to different feature types

#expects 4 - 6 arguments:
## 1. dataframe of data to be combatted
## 2. name of column containing batch identifier
## 3. path to save output csv
## 4. filename for output csv
## 5. list of columns to be included as covariates (OPTIONAL)
## 6. Additional combat arguments, including model, formula, ref.batch, ... (OPTIONAL)

set.seed(12345)

#LOAD PACKAGES
#library(devtools) #may need to install ComBatFamily
library(data.table) 
library(readr)
library(ggplot2) 
library(tidyverse) 
library(mgcv) 
library(gamlss)
library(ComBatFamily)

##########################################################################

#GET ARGS
args <- commandArgs(trailingOnly = TRUE)
raw.df <- fread(args[1], stringsAsFactors = TRUE, na.strings = "")
batch.col <- as.character(args[2])
save_path <- as.character(args[3]) #path to save outputs
save_name <- as.character(args[4])

# see if optional args provided for combatting
if (length(args) < 4){
  stop("Too few arguments!", call.=FALSE)
} else if(length(args)==4) {
  print("Warning: No additional combat args provided, proceeding without covariate correction")
  covar.list <- NULL
} else if(length(args)==5) {
  print("Applying basic lm covariate correction")
  covar.list <- as.list(args[5])
} else if (length(args)==6) {
  print("Applying additional combat args")
  covar.list <- as.list(args[5])
  cf.args <- args[6]
}

#GET FEATURE LISTS
vol_list_global <- readRDS(file="R_scripts/vol_list_global.rds")
vol_list_regions <- readRDS(file="R_scripts/Vol_list_regions.rds")
sa_list <- readRDS(file="R_scripts/SA_list.rds")
ct_list <- readRDS(file="R_scripts/CT_list.rds")
#combine
list_of_feature_lists <- list(vol_list_global, vol_list_regions, sa_list, ct_list)

#DEF BATCHES & COVARS
batch <- as.factor(raw.df[[batch.col]])

if (!is.null(covar.list)){
#covar df only works with numeric variables (otherwise need to use matrix to dummy-code). sticking with just df for now, can update later
stopifnot(all(sapply(covar.list, is.numeric)))

covar.df <- raw.df %>%
  dplyr::select(all_of(covar.list))
stopifnot(length(batch) == nrow(covar.df))
}

##########################################################################

#COMBAT

#initialize df for combat method
cf <- data.frame()

#ITERATE ACROSS FEATURE LISTS
for (l in list_of_feature_lists){
  pheno.df <- raw.df %>%
    dplyr::select(all_of(l))
  
  #make sure batch, covars, and pheno dfs are all the same length
  stopifnot(nrow(pheno.df) == length(batch))
  
  #run combat w/ or w/o additional args
  if (length(args) < 6){
    cf.obj <- comfam(pheno.df, batch, covar.df)
  } else if(length(args)==6) {
    cf.obj <- comfam(pheno.df, batch, covar.df, cf.args)
  }
  
  #add in combatted values
  cf <- merge(cf, cf.obj$dat.combat, by = 'row.names')
}

#merge back in batch and covars
cf[, "batch"] <- batch

if (!is.null(covar.list)){
  cf <- merge(cf, covar.df, by = 'row.names')
}

##########################################################################

#WRITE OUT
fwrite(cf, file=paste0(save_path, "/", save_name, "_data.csv"))
