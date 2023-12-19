# load models fit on a given csv from .rds and extract centile scores

set.seed(12345)

#LOAD PACKAGES
library(gamlss)
library(dplyr)
library(data.table)
library(tibble)

print(getwd())

source("R_scripts/gamlss_helper_funs.R")

#pheno lists
vol_list_global <- readRDS(file="R_scripts/vol_list_global.rds")
vol_list_regions <- readRDS(file="R_scripts/Vol_list_regions.rds")
sa_list <- readRDS(file="R_scripts/SA_list.rds")
ct_list <- readRDS(file="R_scripts/CT_list.rds")
pheno_list <- readRDS(file="R_scripts/pheno_list.rds")

#get args
args <- commandArgs(trailingOnly = TRUE)
df_path <- as.character(args[1]) #path to original data csv
read_path <- as.character(args[2]) #path to gamlss models
save_path <- as.character(args[3]) #path to save output csv
fname_str <- as.character(args[4]) #string to look for in data .csv and model .rds files
#make sure - and _ are searched interchangeably
fname_str_search <- gsub("_|-", "[-_]", fname_str)
print(fname_str)
print(fname_str_search)

#find correct df
all.csvs <- list.files(path = df_path, pattern = ".csv", full.names = TRUE)
matched_csv <- all.csvs[grep(fname_str_search, all.csvs)]
print(paste("csv:", matched_csv))
df <- fread(matched_csv, stringsAsFactors = TRUE)
print("data dim:")
print(dim(df))

#find correct models
all.model.files <- list.files(path = read_path, pattern = "mod.rds", full.names = TRUE)
print("all model files:")
print(all.model.files[1:4])
model.files <- all.model.files[grep(fname_str_search, all.model.files)]
print("selected model files:")
print(model.files[1:4])

#sim data
sim.df <- sim.data.ukb(df)
print("simulated data:")
print(sim.df$dataToPredictM[1:4,])

#predict centiles from each gamlss model
pred.list <- lapply(model.files, get.centile.pred, og.data = df, sim=sim.df)
names(pred.list) <- lapply(model.files, function(x) {sub("_mod\\.rds$", "", basename(x))})
print("dim predicted centiles:")
print(dim(pred.list))

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
  cent_col_name <- paste0("centile_", i)

  # Add the new columns for each iteration
  cent.df[[cent_col_name_M]] <- as.numeric()
  cent.df[[cent_col_name_F]] <- as.numeric()
  cent.df[[cent_col_name]] <- as.numeric()
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

    cent_col_name <- paste0("centile_", i)
    new.df[[cent_col_name]] <- pred.df[["fanCentiles"]][[i]]
    print("dim predicted centiles:")
    print(dim(pred.df[["fanCentiles"]][[i]]))
  }
  cent.df <- rbind(cent.df, new.df)
}
print("dim centile dataframe:")
print(dim(cent.df))

#parse and add more info about model (phenotype, dataset used) w code borrowed from gamlss_parser.R
final.df <- cent.df %>%
  mutate(pheno = sapply(mod_name, function(b) {
    pheno <- ""
    for (a in pheno_list) {
      if (grepl(paste0("^", a), b)) {
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

#also predict centile scores for original data points
cent.list <- lapply(model.files, get.og.data.centiles, og.data = df, get.zscores = TRUE)
names(cent.list) <- lapply(model.files, get.y)
print("predicted centiles for each subject:")
#print(cent.list[1:4])
print(names(cent.list[1:4]))

#compile into dataframe
cent.df <- df %>%
  dplyr::select(participant, sex, age_days, sim.site)

#loop through centiles for each phenotype
for (name in names(cent.list)){
  cent.df[[name]] <- unlist(cent.list[[name]][, "centile"])
  cent.df[[paste0(name, ".z")]] <- unlist(cent.list[[name]] [,"z_score"])
}

#write out
fwrite(cent.df, paste0(save_path, "/", fname_str, "_predictions.csv"))

#get variance for males and females at mean age
var.list <- lapply(model.files, get.var.at.mean.age, og_df = df)
var_df <- do.call(rbind, var.list)
var_df <- var_df %>%
  mutate(sex_effect = (m.var - f.var))

#write out
fwrite(var_df, paste0(save_path, "/", fname_str, "_variance.csv"))

