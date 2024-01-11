# LOAD PACKAGES
library(data.table) 
library(tidyverse) 


# GET ARGS
args <- commandArgs(trailingOnly = TRUE)
data_path <- args[1] #path to centile error & prediction csvs, also save path
d.type <- args[2] #prop vs perm

###############################################################
# DEF FUNCTION
###############################################################

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
        dplyr::select(participant, sex, age_days, sim.site, Source_File, dataset, prop, all_of(list)) %>% #get correct cols
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

###############################################################
# LOAD DATA
###############################################################
pheno_list <- readRDS(file="cubic_scripts/R_scripts/pheno_list.rds")
z.pheno_list <- paste0(pheno_list, ".z")

# centile errors

raw_files <- list.files(path = data_path, pattern = "_diffs.csv", full.names = TRUE)

df_list <- list() #new empty list
for (file in raw_files) {
  print(paste("reading file", file))
  # Read each CSV file
  data <- fread(file)
  
  data <- data %>%
    mutate(dataset = gsub("_data|_data_predictions.csv|prop-|[0-9]|-", "", Source_File))
  
  # Bind the data to the combined dataframe
  df_list[[file]] <- as.data.frame(data)
  assign("ratio_list", df_list)
}
print(paste("centile error list length:", length(ratio_list)))
ratio.df <- bind_rows(ratio_list)

# raw centiles
pred.csvs <- list.files(path = data_path, pattern = "raw_predictions.csv", full.names = TRUE)

df_list <- list() #new empty list
for (file in pred.csvs) {
  # Read each CSV file
  data <- fread(file)
  
  # Add a "Source_File" column with the file name
  data <- data %>%
    mutate(Source_File = as.factor(basename(file))) %>%
    mutate(dataset = gsub("_data|_predictions.csv|prop-|[0-9]|-", "", Source_File),
           prop=gsub("-raw_predictions.csv", "", Source_File))
  
  # Bind the data to the combined dataframe
  df_list <- c(df_list, list(data))
  assign("ratio_raw_pred_list", df_list)
}
length(ratio_raw_pred_list)

#merge into single df
ratio_raw_pred.df <- bind_rows(ratio_raw_pred_list)
print(paste("raw centile df dim:", dim(ratio_raw_pred.df)))

###############################################################
# MERGE DFS
###############################################################

ratio.merge.df <- full_join(ratio_raw_pred.df, ratio.df)
print(unique(ratio.merge.df$dataset))
print(dim(ratio_raw_pred.df))
print(dim(ratio.merge.df))

ratio.merge.df <- ratio.merge.df %>%
  dplyr::select(!File_ID)
###############################################################
# REMOVE EXTREMES
###############################################################

# remove extreme centiles
no_ext.cent <- rm_ext_cents(ratio.merge.df, feat_list = pheno_list, col_select=d.type)

# remove extreme z-scores
no_ext.z <- rm_ext_cents(ratio.merge.df, feat_list = z.pheno_list, col_select=d.type)

###############################################################
# SAVE
###############################################################

#append config name
fwrite(no_ext.cent, file=paste0(data_path, "/no_ext_cent.csv"))
print("saved centiles")

#append config name
fwrite(no_ext.z, file=paste0(data_path, "/no_ext_z.csv"))
print("saved z-scores")

print("DONE")
