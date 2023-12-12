
#script to permute sex-imbalanced site assignments

set.seed(1010101)

#LOAD PACKAGES
library(dplyr)
library(data.table)
library(stringr)

#GET ARGUMENTS
args <- commandArgs(trailingOnly = TRUE)
df <- fread(args[1], stringsAsFactors = TRUE, na.strings = "")
save_path <- as.character(args[2])

#extract csv name
csv_basename <- sub(pattern = "(.*)\\..*$", replacement = "\\1", basename(as.character(args[1])))
csv_basename <- gsub("_", "-", csv_basename)

#list proportions
prop.male <- seq(0, 1, by=0.1)
# setup to count iterations
i <- 1

#get size of each sample so that sampling can be done w/o replacement

#find lower of n male or n female
n_female <- table(df$sex)["Female"]
n_male <- table(df$sex)["Male"]
n_min <- min(c(n_female, n_male))

#define sample size as 2/3 of n_min, rounded down to nearest 100
n_sample <- plyr::round_any((2/3)*n_min, 100, f=floor)

#control # proportions to complete
for(prop in prop.male) {
  
  #define M:F in each site
  balanced_weights <- ifelse(df$sex == "Male", 0.5, 0.5)
  imbalanced_weights <- ifelse(df$sex == "Male", prop, (1-prop))
  
  #sample for balanced site
  balanced <- df %>%
    slice_sample(n=n_sample, weight_by=balanced_weights, replace=FALSE) %>%
    mutate(sim.site = "Balanced")
  
  #remove ppts that are already sampled
  df_remaining <- anti_join(df, balanced)
  
  #sample for imbalanced site
  imbalanced <- df_remaining %>%
    slice_sample(n=n_sample, weight_by=imbalanced_weights, replace=FALSE)%>%
    mutate(sim.site = "Imbalanced")
  
  #assign to df
  new_df <- rbind(balanced, imbalanced)
  new_df <- new_df %>%
    mutate(sim.site = as.factor(sim.site))
  
  #save out csv w count number in filename
  n_count <- str_pad(i, 2, pad = "0")
  fname <- paste0(save_path, "/", csv_basename, "_prop-", n_count, ".csv")
  fwrite(new_df, file=fname)
  
  #update count
  i <- i + 1
}
