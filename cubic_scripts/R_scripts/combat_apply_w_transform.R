#script for applying different versions of combat to different feature types
#added optional pipe to qsub gamlss object fitting

#expects 4 - 6 arguments:
## 1. dataframe of data to be combatted
## 2. name of column containing batch identifier, or path to a csv containing batch identifier
## 3. path to save output csv
## 4. combat config name to append to output csv's filename
## 5. list of columns to be included as covariates (OPTIONAL)
## 6. Additional comfam() arguments, including model, formula, ref.batch, ... (OPTIONAL)

set.seed(12345)

#LOAD PACKAGES
library(data.table) 
library(readr)
library(ggplot2) 
library(tidyverse) 
library(mgcv) 
library(gamlss)
library(ComBatFamily)

source("/cubic_scripts/R_scripts/gamlss_helper_funs.R")

##########################################################################

#GET ARGS
args <- commandArgs(trailingOnly = TRUE)
raw.df <- fread(args[1], stringsAsFactors = TRUE, na.strings = "")

print(paste("col names:", names(raw.df)))

batch.arg <- args[2]
#if batch arg is csv, merge csv into raw.df and designate last col as batch ID
if (endsWith(batch.arg, '.csv')){
  batch.df <- fread(batch.arg, stringsAsFactors = TRUE, na.strings = "")
  batch <- as.factor(batch.df[,ncol(batch.df)])
  raw.df <- base::merge(raw.df, batch.df)
} else {
  #if batch arg is a column name, select that column name from raw.df
  batch.col <- as.character(batch.arg)
  batch <- as.factor(raw.df[[batch.col]])
}

save_path <- as.character(args[3]) #path to save outputs
config_name <- as.character(args[4])

# see if optional args provided for combatting
if (length(args) < 4){
  stop("Too few arguments!", call.=FALSE)
} else if(length(args)==4) {
  print("Warning: No additional combat args provided, proceeding without covariate correction")
  covar.list <- NULL
} else if(length(args)==5) {
  print("Applying basic lm covariate correction")
  covar.list <- as.character(unlist(strsplit(args[5], ",")))
} else if (length(args)==6) {
  print("Applying additional combat args")
  covar.list <- as.character(unlist(strsplit(args[5], ",")))
  cf.args <- args[6]
}

#GET FEATURE LISTS
vol_list_global <- readRDS(file="R_scripts/vol_list_global.rds")
vol_list_regions <- readRDS(file="R_scripts/Vol_list_regions.rds")
sa_list <- readRDS(file="R_scripts/SA_list.rds")
ct_list <- readRDS(file="R_scripts/CT_list.rds")
#combine
list_of_feature_lists <- list(vol_list_global, vol_list_regions, sa_list, ct_list)
names(list_of_feature_lists) <- c("VolGlob", "VolReg", "SA", "CT")

#DEF COVARS

if (!is.null(covar.list)){
covar.df <- raw.df %>%
  dplyr::select(all_of(covar.list))

stopifnot(length(batch) == nrow(covar.df))
#covar df only works with numeric variables (otherwise need to use matrix to dummy-code). sticking with just df for now, can update later
stopifnot(all(sapply(covar.df, is.numeric)))
}

#extract csv name from input data
csv_basename <- sub(pattern = "(.*)\\..*$", replacement = "\\1", basename(as.character(args[1])))
csv_basename <- gsub("_", "-", csv_basename)

##########################################################################

#COMBAT

#initialize df for combat method
cf <- data.frame(matrix(NA, ncol=1, nrow=(nrow(raw.df))))[-1] %>%
  mutate(id = row_number())

i=0

#ITERATE ACROSS FEATURE LISTS
for (l in list_of_feature_lists){
  i=i+1
  print(names(list_of_feature_lists[i]))
  pheno.df <- raw.df %>%
    dplyr::select(all_of(l))
  
  #log-transform global vals - added for lifespan data analyses, not sure if i should rerun for ukb analyses
  if (names(list_of_feature_lists[i]) = "VolGlob"){
    pheno.df <- pheno.df %>%
      mutate(across(c(l), \(x) log(x, base=10)))
  }
  
  #make sure batch, covars, and pheno dfs are all the same length
  stopifnot(nrow(pheno.df) == length(batch))
  
  #run combat w/ or w/o additional args
  if (length(args) < 5){
    cf.obj <- comfam(pheno.df, batch)
  } else if (length(args) == 5){
    cf.obj <- comfam(pheno.df, batch, covar.df)
  } else if(length(args) == 6) {
    #check for ref.batch
    if (grepl("ref\\.batch\\s*=\\s*", cf.args)) {
      # Split the string into two parts
      cf.args_split <- unlist(strsplit(cf.args, "ref.batch", fixed = TRUE))
      
      # The split_string will contain two elements - ONLY WORKS if ref.batch is LAST argument passed
      cf.arg1 <- cf.args_split[1]
      ref_batch <- gsub("=", "", cf.args_split[2])
      ref_batch <- trimws(ref_batch)
      
      #Combat
      cf.obj <- eval(parse(text = paste0("comfam(pheno.df, batch, covar.df, ", cf.arg1, " ref.batch = '", as.factor(ref_batch),"')")))
    } else {
      cf.obj <- eval(parse(text = paste("comfam(pheno.df, batch, covar.df,", cf.args, ")")))
    }
  }
  
  #un-log-transform global vals
  if (names(list_of_feature_lists[i]) = "VolGlob"){
    cf.obj$dat.combat <- cf.obj$dat.combat %>%
      mutate(across(c(l), \(x) un_log(x)))
  }
  
  #save cf.obj
  saveRDS(cf.obj, file=paste0(save_path, "/combat_objs/",csv_basename,"_", config_name,"_", names(list_of_feature_lists[i]), "_cf_obj.rds"))
  
  #row number
  cf.obj.df <- cf.obj$dat.combat %>%
    mutate(id = row_number())
  
  #add in combatted values
  cf <- base::merge(cf, cf.obj.df, 
              by = "id")
  
}

#merge back into the rest of the raw dataset (demographics, etc.)
pheno_list <- unname(unlist(list_of_feature_lists)) #features that were combatted

nonpheno.df <- raw.df %>%
  dplyr::select(!any_of(pheno_list)) %>%
  mutate(id = row_number())

cf.merged <- base::merge(cf, nonpheno.df, by = "id")

#recalculate TBV, Vol_total, SA_total, & CT_total on combatted data
final.df <- cf.merged %>%
  mutate(TBV=rowSums(dplyr::select(., .dots=all_of(c(vol_list_global)))),
         Vol_total=rowSums(dplyr::select(., .dots=all_of(c(vol_list_regions)))),
         SA_total=rowSums(dplyr::select(., .dots=all_of(c(sa_list)))),
         CT_total=rowSums(dplyr::select(., .dots=all_of(c(ct_list)))))

##########################################################################
#WRITE OUT

#append config name
datafile <- paste0(save_path, "/", csv_basename, "_", config_name, "_data.csv")
fwrite(final.df, file=datafile)

print("DONE")