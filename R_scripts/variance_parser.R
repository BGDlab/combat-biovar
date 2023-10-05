
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

sigma.df <- data.frame("file_path" = model.files)
sigma.df <- sigma.df %>%
  mutate(region = sub("_mod\\.rds$", "", basename(file_path)))

#look for sex-terms
sigma.df$contains_sex <- lapply(sigma.df$file_path, find.param, moment="sigma", string="sex")

#list all terms in sigma
sigma.df$terms <- lapply(sigma.df$file_path, list.sigma.terms)
sigma.df$sig_form <- lapply(sigma.df$file_path, get.moment.formula, moment="sigma")

#get sexMale beta weight
sigma.df$sexMale <- lapply(sigma.df$file_path, get.beta, moment="sigma", term="sexMale")

#sigma dfs
sigma.df$degrees <- lapply(sigma.df$file_path, get.sigma.df)
sigma.df$nl_degrees <- lapply(sigma.df$file_path, get.sigma.nl.df)


write.csv(sigma.df, file=paste0(save_path, "/sigma.csv"))