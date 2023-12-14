
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
  
  #sample males
  df_male <- df %>%
    dplyr::filter(sex == "Male")
    #sample for balanced site
    balanced_m <- df_male %>%
      slice_sample(n=round(n_sample*0.5), replace=FALSE) %>%
      mutate(sim.site = "Balanced")
    
      #remove ppts that are already sampled
      df_male_remaining <- anti_join(df_male, balanced_m)
  
      #sample for imbalanced site
      if (prop > 0) {
      imbalanced_m <- df_male_remaining %>%
        slice_sample(n=round(n_sample*prop), replace=FALSE) %>%
        mutate(sim.site = "Imbalanced")
      }
      
  #sample females
  df_female <- df %>%
    dplyr::filter(sex == "Female")
      #sample for balanced site
      balanced_f <- df_female %>%
        slice_sample(n=round(n_sample*0.5), replace=FALSE) %>%
        mutate(sim.site = "Balanced")
      
      #remove ppts that are already sampled
      df_female_remaining <- anti_join(df_female, balanced_f)
      
      #sample for imbalanced site
      if ((1-prop) > 0) {
      imbalanced_f <- df_female_remaining %>%
        slice_sample(n=round(n_sample*(1-prop)), replace=FALSE) %>%
        mutate(sim.site = "Imbalanced")
      }

  #assign to df
      if (prop == 0) {
        new_df <- rbind(balanced_m, balanced_f, imbalanced_f)
      } else if (prop == 1) {
        new_df <- rbind(balanced_m, balanced_f, imbalanced_m)
      } else {
        new_df <- rbind(balanced_m, balanced_f, imbalanced_m, imbalanced_f)
      }
    new_df <- new_df %>%
      mutate(sim.site = as.factor(sim.site))
  
  #save out csv w count number in filename
  n_count <- str_pad(i, 2, pad = "0")
  fname <- paste0(save_path, "/", csv_basename, "_prop-", n_count, ".csv")
  fwrite(new_df, file=fname)
  
  #update count
  i <- i + 1
}
