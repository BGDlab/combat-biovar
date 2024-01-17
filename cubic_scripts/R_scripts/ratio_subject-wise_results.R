# get results for varying-proportion analyses more quickly using cubic

set.seed(12345)

#LOAD PACKAGES
library(dplyr)
library(data.table)
library(tidyverse)
library(purrr)

devtools::source_url("https://raw.githubusercontent.com/BGDlab/combat-biovar/main/cubic_scripts/R_scripts/stats_tests.R")
n_prop_list <- c("0M:10F", "1M:9F", "2M:8F", "3M:7F", "4M:6F", "5M:5F", "6M:4F", "7M:3F", "8M:2F", "9M:1F", "10M:0F")

#get args
args <- commandArgs(trailingOnly = TRUE)
data_path <- args[1] #path to csvs

## LOAD DATA
raw_files <- list.files(path = paste0(data_path,"/subject-wise"), pattern = "_subj_pred.csv", full.names = TRUE)

df_list <- list() #new empty list
for (file in raw_files) {
  # Read each CSV file
  data <- fread(file)
  
  data <- data %>%
    mutate(dataset = gsub("_data|_data_predictions.csv|prop-|[0-9]|-", "", Source_File))
  
  # Bind the data to the combined dataframe
  df_list <- c(df_list, list(data))
  assign("ratio_subj_list", df_list)
}
print(paste("length:", length(ratio_subj_list)))

### W/IN SUBJ MEAN ABS ERROR SEX-BIAS TESTS
# centiles
prop.sex.bias.cent_test <- lapply(ratio_subj_list, sex.bias.t.tests, to_test = "mean_cent_abs.diff", comp_multiplier=length(raw_files))
names(prop.sex.bias.cent_test) <- n_prop_list
sex_bias_ratio_cent_tests_df <- bind_rows(prop.sex.bias.cent_test, .id = "prop")
print(paste("centile df dim:", dim(sex_bias_ratio_cent_tests_df)))

# z-scores
prop.sex.bias.z_test <- lapply(ratio_subj_list, sex.bias.t.tests, to_test = "mean_z_abs.diff", comp_multiplier=length(raw_files))
names(prop.sex.bias.z_test) <- n_prop_list
sex_bias_ratio_z_tests_df <- bind_rows(prop.sex.bias.z_test, .id = "prop")
print(paste("z df dim:", dim(sex_bias_ratio_z_tests_df)))

### SAVE RESULTS
fwrite(sex_bias_ratio_cent_tests_df, file=paste0(data_path, "/subj.abs.mean_sex_bias_cent_t_tests.csv"))
fwrite(sex_bias_ratio_z_tests_df, file=paste0(data_path, "/subj.abs.mean_sex_bias_z_t_tests.csv"))
