# load models fit on a given csv from .rds and extract centile scores

set.seed(12345)

#LOAD PACKAGES
library(gamlss)
library(dplyr)
library(data.table)
library(tibble)

source("R_scripts/gamlss_helper_funs.R")

#pheno lists
vol_list_global <- readRDS(file="R_scripts/vol_list_global.rds")
vol_list_regions <- readRDS(file="R_scripts/Vol_list_regions.rds")
sa_list <- readRDS(file="R_scripts/SA_list.rds")
ct_list <- readRDS(file="R_scripts/CT_list.rds")
pheno_list <- readRDS(file="R_scripts/pheno_list.rds")

#get args
args <- commandArgs(trailingOnly = TRUE)
df_path <- args[1] #path to original data csv
read_path <- args[2] #path to gamlss models
save_path <- args[3] #path to save output csv
fname_str <- args[4] #string to look for in data .csv and model .rds files
fname_str_search <- sub("_", "[-_]", fname_str)

#find correct df
all.csvs <- list.files(path = df_path, pattern = ".csv", full.names = TRUE)
matched_csv <- all.csvs[grep(fname_str_search, all.csvs)]
df <- fread(matched_csv, stringsAsFactors = TRUE)

#find correct models
all.model.files <- list.files(path = read_path, pattern = "mod.rds", full.names = TRUE)
model.files <- all.model.files[grep(fname_str_search, all.model.files)]

#sim data
sim.df <- sim.data.ukb(df)

#predict centiles from each gamlss model
pred.list <- lapply(model.files, get.centile.pred, og.data = df, sim=sim.df)
names(pred.list) <- lapply(model.files, function(x) {sub("_mod\\.rds$", "", basename(x))})

#compile into dataframe

# Calculate the number of iterations
num_iterations <- length(sim.df$desiredCentiles)
# Preallocate the dataframe with the desired number of columns
cent.df <- data.frame(
  age_days = as.numeric(),
  mod_name = as.character()
)

# Iterate through the desiredCentiles
for (i in 1:num_iterations) {
  cent_col_name_M <- paste0("M_centile_", i)
  cent_col_name_F <- paste0("F_centile_", i)
  
  # Add the new columns for each iteration
  cent.df[[cent_col_name_M]] <- as.numeric()
  cent.df[[cent_col_name_F]] <- as.numeric()
}

#append centiles predicted from each model
for (n in names(pred.list)){
  #setup
  new.df <- data.frame(age_days = sim.df[["ageRange"]],
                       mod_name = rep(n, length(sim.df[["ageRange"]])))
  
  #get predicted data from correct gamlss model
  pred.df <- pred.list[[n]]
  
  #iterate across each centile
  for (i in 1:num_iterations){
    cent_col_name_M <- paste0("M_centile_", i)
    new.df[[cent_col_name_M]] <- pred.df[["fanCentiles_M"]][[i]]
    
    cent_col_name_F <- paste0("F_centile_", i)
    new.df[[cent_col_name_F]] <- pred.df[["fanCentiles_F"]][[i]]
  }
  cent.df <- rbind(cent.df, new.df)
}

#parse and add more info about model (phenotype, dataset used) w code borrowed from gamlss_parser.R
final.df <- cent.df %>%
  mutate(pheno = sapply(mod_name, function(b) {
    pheno <- ""
    for (a in pheno_list) {
      if (grepl(a, b)) {
        pheno <- a
        break
      }
    }
    return(pheno)
  })) %>%
  mutate(
    dataset = sub(".*_(.*)", "\\1", mod_name),
    pheno_cat = as.factor(case_when(
      pheno %in% vol_list_global ~ "Global Volume",
      pheno %in% vol_list_regions ~ "Regional Volume",
      pheno %in% sa_list ~ "Regional SA",
      pheno %in% ct_list ~ "Regional CT",
      TRUE ~ NA_character_)))

#write out
fwrite(final.df, paste0(save_path, "/", fname_str, "_centiles.csv"))
