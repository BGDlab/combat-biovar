#Replicating results using models from CentileBrain resource, per reviewer request
#take harmonized LBCC data and prep for fitting centilebrain models

library(tidyverse)

#GET ARGS
args <- commandArgs(trailingOnly = TRUE)
df <- fread(args[1], stringsAsFactors = TRUE, na.strings = "")
save_path <- as.character(args[2]) #path to save outputs

csv_basename <- sub(pattern = "(.*)\\..*$", replacement = "\\1", basename(as.character(args[1])))
csv_basename <- gsub("_", "-", csv_basename)

pheno_list <- readRDS(file="R_scripts/pheno_list.rds")

#Drop subjects >90 yrs
df_drop_old <- df %>%
  dplyr::filter(age_days <= ((365.25*90)+280))

#SPLIT BY SEX & CENTER DATA
df_m <- df_drop_old %>%
  dplyr::filter(sexMale == 1) %>%
  mutate(across(all_of(pheno_list), scale, scale=FALSE, center=TRUE))

df_f <- df_drop_old %>%
  dplyr::filter(sexMale == 0) %>%
  mutate(across(all_of(pheno_list), scale, scale=FALSE, center=TRUE))

#WRITE OUT

#append config name
m_datafile <- paste0(save_path, "/", csv_basename, "_cb_male_data.csv")
fwrite(df_m, file=m_datafile)

f_datafile <- paste0(save_path, "/", csv_basename, "_cb_female_data.csv")
fwrite(df_f, file=f_datafile)

print("DONE")