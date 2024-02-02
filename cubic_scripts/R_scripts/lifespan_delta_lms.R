
##LOAD PACKAGES
library(dplyr)
library(data.table)
library(tibble)
library(broom.mixed)
library(stats)

#get args
args <- commandArgs(trailingOnly = TRUE)
delta_path <- as.character(args[1]) #path to delta csv
save_path <- as.character(args[2]) #path to delta csv

pheno_list <- readRDS(file="R_scripts/pheno_list.rds")

##READ IN DELTAS
deltas_df <- fread(delta_path)

#######################################
# CENTILES
#######################################

#initialize empty df to store outputs
tests.df <- data.frame("term" = character(),
                   "estimate" = double(),
                   "std.error" = double(),
                   "statistic" = double(),
                   "p.value" = double(),
                   "iv" = character(),
                   "pheno" = character())

##Loop each Pheno
for (pheno in pheno_list) {
  # Test Sex
  sex.df <- tidy(lm(formula=as.formula(paste0("delta.", pheno, " ~ sexMale")), data=deltas_df)) %>%
    dplyr::filter(term =="sexMale") %>%
    mutate(iv = "sexMale")
  
  # Test Age
  age.df <- tidy(lm(formula=as.formula(paste0("delta.", pheno, " ~ age_days")), data=deltas_df)) %>%
    dplyr::filter(term =="age_days") %>%
    mutate(iv = "age_days")
  
  # Test Sex*Age
  int.df <- tidy(lm(formula=as.formula(paste0("delta.", pheno, " ~ sexMale*age_days")), data=deltas_df)) %>%
    dplyr::filter(term =="sexMale:age_days") %>%
    mutate(iv = "sexMale:age_days")
  
  # Compile w/in phenotype
  stopifnot(dim(sex.df) == dim(age.df) & dim(age.df) == dim(int.df))
  pheno.df <- rbind(sex.df, age.df, int.df)
  pheno.df$pheno <- pheno
  
  # Add to other phenotypes
  tests.df <- rbind(tests.df, pheno.df)
}
#FDR correct across tests/phenotypes
result_df <- tests.df %>%
  dplyr::mutate(p.val_fdr = p.adjust(p.value, method="fdr", n = nrow(tests.df)), 
                sig_fdr = case_when(p.val_fdr < 0.05 ~ TRUE,
                                    p.val_fdr >= 0.05 ~ FALSE))

#Write Out
new_name <- sub("deltas", "cent_delta_lms", basename(delta_path))
fwrite(result_df, paste0(save_path, "/", new_name))

#######################################
# Z-SCORES
#######################################
pheno_list.z <- paste0(pheno_list, ".z")

#initialize empty df to store outputs
tests.df <- data.frame("term" = character(),
                       "estimate" = double(),
                       "std.error" = double(),
                       "statistic" = double(),
                       "p.value" = double(),
                       "iv" = character(),
                       "pheno" = character())

##Loop each Pheno
for (pheno in pheno_list.z) {
  # Test Sex
  sex.df <- tidy(lm(formula=as.formula(paste0("delta.", pheno, " ~ sexMale")), data=deltas_df)) %>%
    dplyr::filter(term =="sexMale") %>%
    mutate(iv = "sexMale")
  
  # Test Age
  age.df <- tidy(lm(formula=as.formula(paste0("delta.", pheno, " ~ age_days")), data=deltas_df)) %>%
    dplyr::filter(term =="age_days") %>%
    mutate(iv = "age_days")
  
  # Test Sex*Age
  int.df <- tidy(lm(formula=as.formula(paste0("delta.", pheno, " ~ sexMale*age_days")), data=deltas_df)) %>%
    dplyr::filter(term =="sexMale:age_days") %>%
    mutate(iv = "sexMale:age_days")
  
  # Compile w/in phenotype
  stopifnot(dim(sex.df) == dim(age.df) & dim(age.df) == dim(int.df))
  pheno.df <- rbind(sex.df, age.df, int.df)
  pheno.df$pheno <- pheno
  
  # Add to other phenotypes
  tests.df <- rbind(tests.df, pheno.df)
}
#FDR correct across tests/phenotypes
result_df <- tests.df %>%
  dplyr::mutate(p.val_fdr = p.adjust(p.value, method="fdr", n = nrow(tests.df)), 
                sig_fdr = case_when(p.val_fdr < 0.05 ~ TRUE,
                                    p.val_fdr >= 0.05 ~ FALSE))

#Write Out
new_name <- sub("deltas", "z_delta_lms", basename(delta_path))
fwrite(result_df, paste0(save_path, "/", new_name))

