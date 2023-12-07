
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

#control # proportions to complete
for(prop in prop.male) {
  
  # Separate samples for each site
  balanced_weights <- ifelse(df$sex == "Male", 0.5, 0.5)
  balanced <- df %>%
    slice_sample(n=14000, weight_by=balanced_weights, replace=TRUE) %>%
    mutate(sim.site = "Balanced")
  
  imbalanced_weights <- ifelse(df$sex == "Male", prop, (1-prop))
  imbalanced <- df %>%
    slice_sample(n=14000, weight_by=imbalanced_weights, replace=TRUE)%>%
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
