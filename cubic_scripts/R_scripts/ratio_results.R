# get results for varying-proportion analyses more quickly using cubic

set.seed(12345)

#LOAD PACKAGES
library(dplyr)
library(data.table)
library(tidyverse)
library(purrr)

devtools::source_url("https://raw.githubusercontent.com/BGDlab/combat-biovar/main/cubic_scripts/R_scripts/stats_tests.R")

#pheno lists
pheno_list <- readRDS(file="R_scripts/pheno_list.rds")

pheno_diff_list <- paste0("diff_", pheno_list)
pheno_abs.diff.list <- paste0("abs.diff_", pheno_list)

pheno_list.z <- paste0(pheno_list, ".z")
z.pheno_diff_list <- paste0(pheno_diff_list, ".z")
z.pheno_abs.diff.list <- paste0(pheno_abs.diff.list, ".z")

#get args
args <- commandArgs(trailingOnly = TRUE)
data_path <- args[1] #path to csvs
d.type <- args[2] #full or no_ext
name_str <- args[3] #optional 3rd argument to work for permutations instead of prop


## READ IN CENTILE/Z-SCORE ERRORS
if (d.type == "full"){
  raw_files <- list.files(path = data_path, pattern = "_diffs.csv", full.names = TRUE) %>% unlist()
} else if (d.type == "no.ext"){
  raw_files <- list.files(path = data_path, pattern = "_no_ext.csv", full.names = TRUE) %>% unlist()
} else {
  stop("Error: not sure what files to load")
}

df_list <- list() #new empty list
for (file in raw_files) {
  print(paste("reading file", file))
  # Read each CSV file
  data <- fread(file)
  
  data <- data %>%
    mutate(dataset = gsub("_data|_data_predictions.csv|prop-|[0-9]|-|perm-", "", Source_File))
  
  # Bind the data to the combined dataframe
  df_list[[file]] <- as.data.frame(data)
  assign("ratio_list", df_list)
}
print(paste("length", length(ratio_list)))
ratio.df <- bind_rows(ratio_list)

if (is.na(name_str)) {
  names_list <- c("0M:10F", "1M:9F", "2M:8F", "3M:7F", "4M:6F", "5M:5F", "6M:4F", "7M:3F", "8M:2F", "9M:1F", "10M:0F")
} else {
  names_list <- c(paste(name_str, seq(1:length(ratio_list)), sep="-"))
}

############################################
## CENTILE ERROR TESTS ###
############################################

##### Within each M:F proportion simulated, is the magnitude of subjects' mean centile errors within each feature differ significantly by combat configuration?
prop_abs.cent_t.tests <- lapply(ratio_list, centile.t.tests, feature_list=pheno_abs.diff.list, comp_multiplier=length(ratio_list)) #FDR correction across 11 M:F permutations
names(prop_abs.cent_t.tests) <- names_list
prop_abs.cent_t.tests_df <- bind_rows(prop_abs.cent_t.tests, .id = "column_label")
### save results
fwrite(prop_abs.cent_t.tests_df, file=paste0(data_path, "/", d.type, "_featurewise_cent_t_tests.csv"))

#write out full results as list for plotting
prop_abs.cent_t.tests_all <- lapply(ratio_list, centile.t.tests.full_result, feature_list=pheno_abs.diff.list, comp_multiplier=length(ratio_list)) #FDR correction across 11 M:F permutations
names(prop_abs.cent_t.tests_all) <- names_list

### save results
saveRDS(prop_abs.cent_t.tests_all, file=paste0(data_path, "/", d.type, "_featurewise_cent_t_tests_all_out.RDS"))

############################################
## Z-SCORE ERROR TESTS ###
############################################
##### Within each M:F proportion simulated, is the magnitude of subjects' mean centile errors within each feature differ significantly by combat configuration?
prop_abs.z_t.tests <- lapply(ratio_list, centile.t.tests, feature_list=z.pheno_abs.diff.list, comp_multiplier=length(ratio_list)) #FDR correction across 11 M:F permutations
names(prop_abs.z_t.tests) <- names_list
prop_abs.z_t.tests <- bind_rows(prop_abs.z_t.tests, .id = "column_label")
### save results
fwrite(prop_abs.z_t.tests, file=paste0(data_path, "/", d.type, "_featurewise_z_t_tests.csv"))


#write out full results as list for plotting
prop_abs.z_t.tests_all <- lapply(ratio_list, centile.t.tests.full_result, feature_list=z.pheno_abs.diff.list, comp_multiplier=length(ratio_list)) #FDR correction across 11 M:F permutations
names(prop_abs.z_t.tests_all) <- names_list

### save results
saveRDS(prop_abs.z_t.tests_all, file=paste0(data_path, "/", d.type, "_featurewise_z_t_tests_all_out.RDS"))

