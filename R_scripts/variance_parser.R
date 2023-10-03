
set.seed(12345)

#LOAD PACKAGES
library(gamlss)
library(dplyr)
library(data.table)

source("gamlss_helper_funs.R")

#GET ARGS
args <- commandArgs(trailingOnly = TRUE)
read_path <- args[1] #path to bfp models
save_path <- args[2] #path to save diagnostic plots

#iterate across gamlss objects
model.files <- list.files(path = read_path, pattern = "mod.rds", full.names = TRUE)
sigma.sex <- sapply(model.files, find.param, moment="sigma", string="sex", USE.NAMES=TRUE)
