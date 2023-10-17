
set.seed(12345)

#LOAD PACKAGES
library(gamlss)
library(dplyr)
library(data.table)
library(tibble)

source("R_scripts/gamlss_helper_funs.R")

#pheno lists
vol_list_global <- readRDS(file="R_scripts/vol_list_global.rds")
# vol_list_regions <- readRDS(file="R_scripts/Vol_list_regions.rds")
# sa_list <- readRDS(file="R_scripts/SA_list.rds")
ct_list <- readRDS(file="R_scripts/CT_list.rds")
pheno_list <- readRDS(file="R_scripts/pheno_list.rds")

#GET ARGS
args <- commandArgs(trailingOnly = TRUE)
read_path <- args[1] #path to bfp models
save_path <- args[2] #path to save outputs

#iterate across gamlss objects
model.files <- list.files(path = read_path, pattern = "mod.rds", full.names = TRUE)

print("First Few Modfiles")
print(model.files[1:3])

#extract values of sex term from summary table
summary.list <- lapply(model.files, get.summary)

#dataframe
summary.df <- bind_rows(summary.list)

#get phenotype value
summary.df <- summary.df %>%
  mutate(pheno = sapply(mod_name, function(b) {
    pheno <- ""
    for (a in pheno_list) {
      if (grepl(a, b)) {
        pheno <- a
        break
      }
    }
    return(pheno)
  }))

#remaining cols
sigma.sex.df <- summary.df %>%
  dplyr::filter(parameter == "sigma" & term == "sexMale") %>%
  mutate(
    dataset = sub(".*_(.*)", "\\1", mod_name),
    pheno_cat = as.factor(case_when(
    pheno %in% vol_list_global ~ "Global Volume",
    pheno %in% vol_list_regions ~ "Regional Volume",
    pheno %in% sa_list ~ "Regional SA",
    pheno %in% ct_list ~ "Regional CT",
    TRUE ~ NA)),
    sig = case_when(p.value < 0.05 ~ TRUE,
                    p.value >= 0.05 ~ FALSE),
    sig_bf.corr = case_when(pheno %in% vol_list_global & p.value < (0.05/length(vol_list_global)) ~ TRUE,
                            pheno %in% vol_list_global & p.value >= (0.05/length(vol_list_global)) ~ FALSE,
                            !(pheno %in% vol_list_global) & p.value < (0.05/length(ct_list)) ~ TRUE,
                            !(pheno %in% vol_list_global) & p.value >= (0.05/length(ct_list)) ~ FALSE,
                            TRUE ~ NA),
    label = sub("_[^_]*_", "_", pheno)) #for plotting

#test significance of sex term in sigma
drop1.list <- sapply(model.files, USE.NAMES=TRUE, get.and.drop1.p, moment="sigma", term="sexMale")
#convert to df
drop1.df <- data.frame(mod_name = unname(names(drop1.list)), drop1.pval = unlist(unname(drop1.list)))
drop1.df <- drop1.df %>%
  mutate(mod_name = basename(mod_name)) %>%
  mutate(mod_name = sub("_mod.rds$", "", mod_name))

sigma.sex.df2 <- merge(sigma.sex.df, drop1.df, by="mod_name")

write.csv(sigma.sex.df2, file=paste0(save_path, "/sigma.csv"))
