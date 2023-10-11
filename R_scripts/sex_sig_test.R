set.seed(12345)

#LOAD PACKAGES
library(gamlss)
library(dplyr)
library(data.table)
library(tibble)

source("R_scripts/gamlss_helper_funs.R")

#note - some of these functions do not seem to work on CUBIC, as they rely on saving environment variables

#GET ARGS
args <- commandArgs(trailingOnly = TRUE)
read_path <- args[1] #path to bfp models
save_path <- args[2] #path to save outputs

#iterate across gamlss objects
model.files <- list.files(path = read_path, pattern = "mod.rds", full.names = TRUE)

sigma.df <- data.frame("file_path" = model.files)
sigma.df <- sigma.df %>%
  mutate(region = sub("_mod\\.rds$", "", basename(as.character(file_path))))

#test significance of sex term in sigma
sigma.df$sig.sex_drop1.p <- lapply(sigma.df$file_path, get.and.drop1.p, moment="sigma", term="sex")

#get sexMale beta weight
sigma.df$sig.sex_beta <- lapply(sigma.df$file_path, get.beta, moment="sigma", term="sexMale")

#extract values of sex term from summary table
sigma.df$sig.sex_std.err <- lapply(sigma.df$file_path, get.summary.table.outputs, moment = 'sigma', select1 = 'sexMale', select2 = 'Std. Error')
sigma.df$sig.sex_tval <- lapply(sigma.df$file_path, get.summary.table.outputs, moment = 'sigma', select1 = 'sexMale', select2 = 't value')
sigma.df$sig.sex_p <- lapply(sigma.df$file_path, get.summary.table.outputs, moment = 'sigma', select1 = 'sexMale', select2 = 'Pr(>|t|)')

#make sure all values are correct class
sigma.df <- sigma.df %>%
  mutate(file_path = as.character(file_path),
         region = as.character(region)) %>%
  mutate(across(!file_path & !region, as.numeric()))

write.csv(sigma.df, file=paste0(save_path, "/sig_test.csv"))