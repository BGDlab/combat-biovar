
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
sigma.sex <- sapply(model.files, find.param, moment="sigma", string="sex", USE.NAMES=TRUE)
#make dataframe
sigma.sex.df <- sigma.sex %>%
  as.data.frame() %>%
  rename(contains_sex = ".") %>%
  rownames_to_column(var = "file") %>%
  mutate(mod_name = basename(file))

write.csv(sigma.sex.df, file=paste0(save_path, "/sigma_sex_term.csv"))