
#compile outputs from fit_basic_gam.R

set.seed(12345)

#LOAD PACKAGES
library(mgcv)
library(dplyr)
library(data.table)
library(broom)

source("R_scripts/gamlss_helper_funs.R")

#pheno lists
vol_list_global <- readRDS(file="R_scripts/vol_list_global.rds")
vol_list_regions <- readRDS(file="R_scripts/Vol_list_regions.rds")
sa_list <- readRDS(file="R_scripts/SA_list.rds")
ct_list <- readRDS(file="R_scripts/CT_list.rds")
pheno_list <- readRDS(file="R_scripts/pheno_list.rds")

#GET ARGS
args <- commandArgs(trailingOnly = TRUE)
read_path <- args[1] #path to bfp models
save_path <- args[2] #path to save outputs

#iterate across gam objects
model.files <- list.files(path = read_path, pattern = "gam.rds", full.names = TRUE)

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
      if (grepl(paste0("^", a), b)) {
        pheno <- a
        break
      }
    }
    return(pheno)
  }))

#remaining cols
summary.df2 <- summary.df %>%
  mutate(
    dataset = sub("_gam$", "", mod_name), #drop _gam
    dataset = sub(".*_(.*)", "\\1", dataset),
    pheno_cat = as.factor(case_when(
    pheno %in% vol_list_global ~ "Global Volume",
    pheno %in% vol_list_regions ~ "Regional Volume",
    pheno %in% sa_list ~ "Regional SA",
    pheno %in% ct_list ~ "Regional CT",
    TRUE ~ NA_character_)),
    sig.sum = case_when(p.value < 0.05 ~ TRUE,
                    p.value >= 0.05 ~ FALSE),
    sig.sum_bf.corr = case_when(pheno %in% vol_list_global & p.value < (0.05/length(vol_list_global)) ~ TRUE,
                            pheno %in% vol_list_global & p.value >= (0.05/length(vol_list_global)) ~ FALSE,
                            !(pheno %in% vol_list_global) & p.value < (0.05/length(ct_list)) ~ TRUE,
                            !(pheno %in% vol_list_global) & p.value >= (0.05/length(ct_list)) ~ FALSE,
                            TRUE ~ NA),
    label = sub("_[^_]*_", "_", pheno)) #for plotting

write.csv(summary.df2, file=paste0(save_path, "/gam_summary.csv"))

#iterate across anova csvs
csv.files <- list.files(path = read_path, pattern = ".csv", full.names = TRUE)
anova.df <- do.call(rbind, lapply(csv.files, fread))

anova.df <- anova.df %>%
  mutate(sig.drop_bf.corr = case_when(phenotype %in% vol_list_global & p.value < (0.05/length(vol_list_global)) ~ TRUE,
                                      phenotype %in% vol_list_global & p.value >= (0.05/length(vol_list_global)) ~ FALSE,
                                      !(phenotype %in% vol_list_global) & p.value < (0.05/length(ct_list)) ~ TRUE,
                                      !(phenotype %in% vol_list_global) & p.value >= (0.05/length(ct_list)) ~ FALSE,
                                      TRUE ~ NA))

write.csv(anova.df, file=paste0(save_path, "/anova_gam_tests.csv"))

#merge sex results - can't merge age b/c polynomials are handled differently by anova and summary
anova.df <- anova.df %>%
  rename(pheno = phenotype) #for easier merging

final.df <- base::merge(summary.df2, anova.df, by=c("pheno", "term", "dataset"))

write.csv(final.df, file=paste0(save_path, "/sex_summary_gam.csv"))
