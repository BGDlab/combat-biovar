# change in centile scores for subjects when calculated on data harmonized with ComBat GAM vs ComBatLS
# also run basic stats tests

#LOAD PACKAGES
library(data.table)
library(tidyverse)
library(dplyr)

#get args
args <- commandArgs(trailingOnly = TRUE)
csv_path <- as.character(args[1]) #path to read & save csvs
config <- as.character(args[2]) #search str to match gam and gamlss fit centile csvs
fname_str <- as.character(args[3]) #string for saving nameå

#LOAD DFS
#read in data
gam.df.path <- list.files(path = csv_path, pattern = paste0("cf.gam-", config), full.names = TRUE) %>% unlist()
gam.df <- fread(gam.df.path)
gamlss.df.path <- list.files(path = csv_path, pattern = paste0("cf.gamlss-", config), full.names = TRUE) %>% unlist()
gamlss.df <- fread(gamlss.df.path)

#get identifiers
id_cols <- c("participant", "sex", "age_days", "site", "log_age", "sexMale", "sex.age", "fs_version")

id.gam.df <- gam.df %>%
  dplyr::select(all_of(id_cols)) %>%
  mutate(id = row_number())

id.gamlss.df <- gamlss.df %>%
  dplyr::select(all_of(id_cols)) %>%
  mutate(id = row_number())

stopifnot(id.gam.df == id.gamlss.df) #make sure same subj. in each
print("ID cols match")

#drop cols missing from one or other df (i.e. if brain chart model failed to converge in either dataset)
rm_cols <- c(setdiff(names(gam.df), names(gamlss.df)), setdiff(names(gamlss.df), names(gam.df)))
print(paste(length(rm_cols), "col name diffs to remove:"))
print(rm_cols)

#drop ID cols & missing cols
gam.df <- gam.df %>%
  dplyr::select(!any_of(c(id_cols, rm_cols)))

gamlss.df <- gamlss.df %>%
  dplyr::select(!any_of(c(id_cols, rm_cols)))

#checks
stopifnot(names(gam.df) == names(gamlss.df))
stopifnot(nrow(gam.df) == nrow(gamlss.df))

#subtract
diff.df <- gam.df - gamlss.df
diff.df <- diff.df %>%
  rename_with(~ paste("delta", ., sep = ".")) %>%
  mutate(id = row_number())

#merge back
stopifnot(nrow(diff.df) == nrow(id.gam.df))
cf_deltas <- base::merge(id.gam.df, diff.df, by = "id") %>%
  dplyr::select(!id)

#SAVE
print("saving deltas")
fwrite(cf_deltas, paste0(csv_path, "/", fname_str, "_pred_deltas.csv"))


print("DONE")

