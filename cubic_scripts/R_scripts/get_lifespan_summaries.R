# load models fit on a given csv from .rds and extract centile scores

set.seed(12345)

#LOAD PACKAGES
library(gamlss)
library(dplyr)
library(data.table)
library(tibble)

print(getwd())

source("R_scripts/gamlss_helper_funs.R")

#get args
args <- commandArgs(trailingOnly = TRUE)
read_path <- as.character(args[1]) #path to gamlss models
save_path <- as.character(args[2]) #path to save output csv
fname_str <- as.character(args[3]) #string to look for in data .csv and model .rds files
#make sure - and _ are searched interchangeably
fname_str_search <- gsub("_|-", "[-_]", fname_str)
print(fname_str)
print(fname_str_search)

#find correct models
all.model.files <- list.files(path = read_path, pattern = "mod.rds", full.names = TRUE)
print("all model files:")
print(all.model.files[1:4])
model.files <- all.model.files[grep(fname_str_search, all.model.files)]
print("selected model files:")
print(model.files[1:4])

#extract values from summary table
summary.list <- lapply(model.files, get.gamlss.summary)
names(summary.list) <- lapply(model.files, get.y)
#dataframe
summary.df <- bind_rows(summary.list, .id=pheno)

#write out
fwrite(summary.df, paste0(save_path, "/", fname_str, "_full_sum.csv"))
