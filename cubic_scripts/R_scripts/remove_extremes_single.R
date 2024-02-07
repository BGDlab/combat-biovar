# LOAD PACKAGES
library(data.table) 
library(tidyverse) 
library(dplyr)
library(tibble)
library(stringr)

# GET ARGS
args <- commandArgs(trailingOnly = TRUE)
path_to_csvs <- args[1] #path to centile error & prediction csvs, also save path
d.type <- args[2] #prop vs perm
n_perm <- args[3]

pheno_list <- readRDS(file="R_scripts/pheno_list.rds")
z.pheno_list <- paste0(pheno_list, ".z")

###############################################################
# DEF FUNCTION
###############################################################
#remove subjs. with raw centiles <0.05 or >0.95
rm_ext_cents <- function(og.data, feat_list, col_select){
  df_ext_list <- c()
  count <- 1
  for(pheno in feat_list) {
    list <- c(pheno, paste0("diff_", pheno), paste0("abs.diff_", pheno))
    
    if (col_select == "prop"){
      df <- og.data %>%
        dplyr::select(participant, sex, age_days, sim.site, Source_File, dataset, prop, all_of(list)) %>% #get correct cols
        group_by(participant) %>% 
        dplyr::filter(!any((get(pheno) < 0.05 | get(pheno) > 0.95) & dataset == "raw")) %>% #drop ppts if raw centile is <0.05 or >0.95
        ungroup() %>%
        dplyr::filter(dataset != "raw") #now drop raw vals
    } else if (col_select == "perm"){
      df <- og.data %>%
        dplyr::select(participant, sex, age_days, sim.site, Source_File, dataset, perm, all_of(list)) %>% #get correct cols
        group_by(participant) %>% 
        dplyr::filter(!any((get(pheno) < 0.05 | get(pheno) > 0.95) & dataset == "raw")) %>% #drop ppts if raw centile is <0.05 or >0.95
        ungroup() %>%
        dplyr::filter(dataset != "raw") #now drop raw vals
    } else {
      stop("need 'prop' or 'perm' for propper col selection. execution halted.")
    }
    
    df_ext_list[count] <- list(df)
    count <- count + 1
  }
  stopifnot(length(df_ext_list) == length(feat_list))
  df.no_ext <- Reduce(full_join, df_ext_list)
  return(df.no_ext)
}

rm_ext_z <- function(og.data, feat_list, col_select){
  df_ext_list <- c()
  count <- 1
  for(pheno in feat_list) {
    list <- c(pheno, paste0("diff_", pheno), paste0("abs.diff_", pheno))
    
    if (col_select == "prop"){
      df <- og.data %>%
        dplyr::select(participant, sex, age_days, sim.site, Source_File, dataset, prop, all_of(list)) %>% #get correct cols
        group_by(participant) %>% 
        dplyr::filter(!any((get(pheno) < -2 | get(pheno) > 2) & dataset == "raw")) %>%
        ungroup() %>%
        dplyr::filter(dataset != "raw") #now drop raw vals
    } else if (col_select == "perm"){
      df <- og.data %>%
        dplyr::select(participant, sex, age_days, sim.site, Source_File, dataset, perm, all_of(list)) %>% #get correct cols
        group_by(participant) %>% 
        dplyr::filter(!any((get(pheno) < -2 | get(pheno) > 2) & dataset == "raw")) %>%
        dplyr::filter(dataset != "raw") #now drop raw vals
    } else {
      stop("need 'prop' or 'perm' for propper col selection. execution halted.")
    }
    
    df_ext_list[count] <- list(df)
    count <- count + 1
  }
  stopifnot(length(df_ext_list) == length(feat_list))
  df.no_ext <- Reduce(full_join, df_ext_list)
  return(df.no_ext)
}

###############################################################
# LOAD DATA
###############################################################
##### PERMUTATION PIPELINE RESULTS #####

if (d.type == "perm"){
  
  perm_n <- str_pad(n_perm, 3, pad = "0") #each perm as different qsub
  #def how to find correct csvs
  str <- as.character(paste0("perm-", perm_n))
  print(str)
  
  #READ ERRORS INTO DATAFRAME
  perm.diff.csv <- list.files(path = path_to_csvs, pattern = glob2rx(paste0(str, "*_diffs.csv")), full.names = TRUE)
  perm.diff.df <- fread(perm.diff.csv[[1]])
  perm.diff.df <- perm.diff.df %>%
    mutate(dataset = gsub("_data|_data_predictions.csv|perm-|[0-9]|-", "", Source_File))
  print(paste("diff dataframe dim:", dim(perm.diff.df)))
  
  #READ RAW CENTS INTO DATAFRAME
  perm.raw.csv <- list.files(path = path_to_csvs, pattern = glob2rx(paste0(str, "*raw_predictions.csv")), full.names = TRUE)
  perm.raw.df <- fread(perm.raw.csv[[1]])
  perm.raw.df <- perm.raw.df %>%
    mutate(Source_File = as.factor(basename(perm.raw.csv[[1]]))) %>%
    mutate(dataset = gsub("_data|_predictions.csv|perm-|[0-9]|-", "", Source_File),
           perm=gsub("-raw_predictions.csv", "", Source_File))
  print(paste("raw cent dataframe dim:", dim(perm.raw.df)))
  
  #MERGE DFS
  merge.df <- full_join(perm.raw.df, perm.diff.df)
}

##### VARYING M:F PROPORTION PIPELINE RESULTS #####
if (d.type == "prop"){
  
  prop_n <- str_pad(n_perm, 2, pad = "0") #each prop. as different qsub
  #def how to find correct csvs
  str <- as.character(paste0("prop-", prop_n))
  
  print(str)
  
  #READ ERRORS INTO DATAFRAME
  perm.diff.csv <- list.files(path = path_to_csvs, pattern = glob2rx(paste0(str, "*_diffs.csv")), full.names = TRUE)
  perm.diff.df <- fread(perm.diff.csv[[1]])
  perm.diff.df <- perm.diff.df %>%
    mutate(dataset = gsub("_data|_data_predictions.csv|prop-|[0-9]|-", "", Source_File))
  print(paste("diff dataframe dim:", dim(perm.diff.df)))
  
  #READ RAW CENTS INTO DATAFRAME
  perm.raw.csv <- list.files(path = path_to_csvs, pattern = glob2rx(paste0(str, "*raw_predictions.csv")), full.names = TRUE)
  perm.raw.df <- fread(perm.raw.csv[[1]])
  perm.raw.df <- perm.raw.df %>%
    mutate(Source_File = as.factor(basename(perm.raw.csv[[1]]))) %>%
    mutate(dataset = gsub("_data|_predictions.csv|prop-|[0-9]|-", "", Source_File),
           prop=gsub("-raw_predictions.csv", "", Source_File))
  print(paste("raw cent dataframe dim:", dim(perm.raw.df)))
  
  #MERGE DFS
  merge.df <- full_join(perm.raw.df, perm.diff.df)
}

print(unique(merge.df$dataset))
print(dim(merge.df))

merge.df <- merge.df %>%
  dplyr::select(!File_ID)

###############################################################
# REMOVE EXTREMES
###############################################################
# remove extreme centiles
no_ext.cent <- rm_ext_cents(merge.df, feat_list = pheno_list, col_select=d.type)

# remove extreme z-scores
no_ext.z <- rm_ext_z(merge.df, feat_list = z.pheno_list, col_select=d.type)

# merge
no_ext_all <- full_join(no_ext.cent, no_ext.z)
print(paste("dim full dataframe:", dim(no_ext_all)))

###############################################################
# SAVE
###############################################################
#append config name
fwrite(no_ext_all, file=paste0(path_to_csvs, "/", str, "_no_ext.csv"))

print("DONE")
