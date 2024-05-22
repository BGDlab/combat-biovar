# load models fit on a given csv from .rds and extract centile scores

set.seed(12345)

#LOAD PACKAGES
library(gamlss)
library(dplyr)
library(data.table)
library(tibble)

print(getwd())

source("R_scripts/gamlss_helper_funs.R")

#pheno lists
vol_list_global <- readRDS(file="R_scripts/vol_list_global.rds")
vol_list_regions <- readRDS(file="R_scripts/Vol_list_regions.rds")
sa_list <- readRDS(file="R_scripts/SA_list.rds")
ct_list <- readRDS(file="R_scripts/CT_list.rds")
pheno_list <- readRDS(file="R_scripts/pheno_list.rds")

#get args
args <- commandArgs(trailingOnly = TRUE)
df_path <- as.character(args[1]) #path to original data csv
read_path <- as.character(args[2]) #path to gamlss models
save_path <- as.character(args[3]) #path to save output csv
fname_str <- as.character(args[4]) #string to look for in data .csv and model .rds files
#make sure - and _ are searched interchangeably
fname_str_search <- gsub("_|-", "[-_]", fname_str)
print(fname_str)
print(fname_str_search)

#find correct df
all.csvs <- list.files(path = df_path, pattern = ".csv", full.names = TRUE)
#csv name = fname_str w/o _no.tbv
fname_str_search.csv <- gsub("_no.tbv", "", fname_str_search)
matched_csv <- all.csvs[grep(fname_str_search.csv, all.csvs)]
print(paste("csv:", matched_csv))
df <- fread(matched_csv, stringsAsFactors = TRUE)
print("data dim:")
print(dim(df))

#find correct models
all.model.files <- list.files(path = read_path, pattern = "mod.rds", full.names = TRUE)
print("all model files:")
print(all.model.files[1:4])
model.files <- all.model.files[grep(fname_str_search, all.model.files)]
print("selected model files:")
print(model.files[1:4])

#predict centile scores for original data points
cent.list <- lapply(model.files, get.og.data.centiles.lbcc, og.data = df, get.zscores = TRUE)
names(cent.list) <- lapply(model.files, get.y)
print("predicted centiles for each subject:")
#print(cent.list[1:4])
print(names(cent.list[1:4]))

#compile into dataframe
cent.df <- df %>%
  dplyr::select(participant, sex, age_days, site, log_age, sexMale, sex.age, fs_version)

#loop through centiles for each phenotype
for (name in names(cent.list)){
  cent.df[[name]] <- unlist(cent.list[[name]][, "centile"])
  cent.df[[paste0(name, ".z")]] <- unlist(cent.list[[name]] [,"z_score"])
}

#write out
fwrite(cent.df, paste0(save_path, "/", fname_str, "_predictions.csv"))
