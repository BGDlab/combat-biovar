#Within each combat config, test if there are significant differences in M and F centile errors in each feature 

set.seed(12345)

#LOAD PACKAGES
library(dplyr)
library(data.table)
library(parallel)

source("R_scripts/gamlss_helper_funs.R")

#pheno lists
pheno_list <- readRDS(file="R_scripts/pheno_list.rds")

#get args
args <- commandArgs(trailingOnly = TRUE)
data_path <- args[1] #path to csvs


#Read in centile/z-score errors

raw_files <- list.files(path = data_path, pattern = "_diffs.csv", full.names = TRUE) %>% unlist()

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
print(paste("length=", length(diffs_perm.list)))

#centile t-tests
cent.sex_t_tests_in_feat.df <- mclapply(diffs_perm.list, sex.bias.feat.t.tests, mc.preschedule = FALSE, comp_multiplier=length(diffs_perm.list), feature_list=pheno_list)

#save rds
saveRDS(cent.sex_t_tests_in_feat.df, file=paste0(data_path, "/featurewise_cent_sex_bias_tests.RDS"))

#z-score t-tests
z.sex_t_tests_in_feat.df <- mclapply(diffs_perm.list, sex.bias.feat.t.tests, mc.preschedule = FALSE, comp_multiplier=length(diffs_perm.list), feature_list=paste0(pheno_list,".z"))

#save rds
saveRDS(z.sex_t_tests_in_feat.df, file=paste0(data_path, "/featurewise_z_sex_bias_tests.RDS"))
