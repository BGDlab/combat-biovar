
set.seed(12345)

#LOAD PACKAGES
library(gamlss)
library(dplyr)
library(data.table)
library(tibble)

source("R_scripts/gamlss_helper_funs.R")

#GET ARGS
args <- commandArgs(trailingOnly = TRUE)
read_path <- args[1] #path to bfp models
save_path <- args[2] #path to save outputs

#iterate across gamlss objects
model.files <- list.files(path = read_path, pattern = "mod.rds", full.names = TRUE)

print("First Few Modfiles")
print(model.files[1:3])

sigma.df <- data.frame("file_path" = model.files)
sigma.df <- sigma.df %>%
  mutate(file_pat = as.character(file_path),
	region = sub("_mod\\.rds$", "", basename(as.character(file_path))))

#look for sex-terms
sigma.df$contains_sex <- lapply(sigma.df$file_path, find.param, moment="sigma", string="sex")

#get formula
sigma.df$sig_form <- lapply(sigma.df$file_path, get.moment.formula, moment="sigma")

#get sexMale beta weight
sigma.df$sexMale <- lapply(sigma.df$file_path, get.beta, moment="sigma", term="sexMale")

#sigma dfs
sigma.df$degrees <- lapply(sigma.df$file_path, get.sigma.df)
sigma.df$nl_degrees <- lapply(sigma.df$file_path, get.sigma.nl.df)

#make sure all values are correct class
sigma.df <- sigma.df %>%
  mutate(file_path = as.character(file_path),
 	contains_sex = as.logical(contains_sex),
	sexMale = as.integer(sexMale),
	degrees = as.integer(degrees),
	nl_degrees = as.integer(nl_degrees),
	sig_form = as.character(sig_form),
	region = as.character(region))

write.csv(sigma.df, file=paste0(save_path, "/sigma.csv"))
