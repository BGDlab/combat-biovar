#Within each combat config, test if there are significant differences in M and F centile errors in each feature 

set.seed(12345)

#LOAD PACKAGES
library(dplyr)
library(data.table)
#library(parallel)
library(tidyverse)

devtools::source_url("https://raw.githubusercontent.com/BGDlab/combat-biovar/main/cubic_scripts/R_scripts/stats_tests.R")

#pheno lists
pheno_list <- readRDS(file="R_scripts/pheno_list.rds")
diff_list <- paste0("diff_", pheno_list)

#get args
args <- commandArgs(trailingOnly = TRUE)
data_path <- args[1] #path to csvs
d.type <- args[2] #full or no_ext

#Read in centile/z-score errors
if (d.type == "full"){
  raw_files <- list.files(path = data_path, pattern = "_diffs.csv", full.names = TRUE) %>% unlist()
} else if (d.type == "no.ext"){
  raw_files <- list.files(path = data_path, pattern = "_no_ext.csv", full.names = TRUE) %>% unlist()
} else {
  stop("Error: not sure what files to load")
}

df_list <- list() #new empty list
for (file in raw_files) {
  # Read each CSV file
  data <- fread(file)
  
  data <- data %>%
    mutate(dataset = gsub("_data|_data_predictions.csv|prop-|[0-9]|perm|-", "", Source_File))
  
  # Bind the data to the combined dataframe
  df_list <- c(df_list, list(data))
  assign("diffs_perm.list", df_list)
}

#centile t-tests
cent.sex_t_tests_in_feat.df <- lapply(diffs_perm.list, sex.bias.feat.t.tests, comp_multiplier=length(diffs_perm.list), feature_list=diff_list)

#save
fwrite(cent.sex_t_tests_in_feat.df, file=paste0(data_path, "/", d.type, "_featurewise_cent_sex_bias_tests.csv"))

#z-score t-tests
z.sex_t_tests_in_feat.df <- lapply(diffs_perm.list, sex.bias.feat.t.tests, comp_multiplier=length(diffs_perm.list), feature_list=paste0(diff_list,".z"))

#save
fwrite(z.sex_t_tests_in_feat.df, file=paste0(data_path, "/", d.type, "_featurewise_z_sex_bias_tests.csv"))

print("DONE!")
