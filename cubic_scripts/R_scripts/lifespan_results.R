# change in centile scores for subjects when calculated on data harmonized with ComBat GAM vs ComBatLS
# also run basic stats tests

#LOAD PACKAGES
library(data.table)
library(tidyverse)
library(dplyr)

#get args
args <- commandArgs(trailingOnly = TRUE)
delta_path <- as.character(args[1]) #path to delta csv
save_path <- as.character(args[2]) #path to save output csvs
fname_str <- as.character(args[3]) #string for saving name

devtools::source_url("https://raw.githubusercontent.com/BGDlab/combat-biovar/main/cubic_scripts/R_scripts/stats_tests.R")

#pheno lists
pheno_list <- readRDS(file="R_scripts/pheno_list.rds")
pheno_list.z <- paste0(pheno_list, ".z")

#LOAD DFS
#read in data
delta.df <- fread(gam_csv_path)


print("DONE")

