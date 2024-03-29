
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
n_permutations <- as.integer(args[3])

#extract csv name
csv_basename <- sub(pattern = "(.*)\\..*$", replacement = "\\1", basename(as.character(args[1])))
csv_basename <- gsub("_", "-", csv_basename)

#SETUP SITES
sim.site.list <- c("Site_A", "Site_B", "Site_C")
n_female <- table(df$sex)["Female"]
n_male <- table(df$sex)["Male"]

# Sample probabilities
male_prob <- c(0.33, 0.0825, 0.5875)
female_prob <- c(0.33, 0.5875, 0.0825)

#control # permutations to complete
for(i in 1:n_permutations) {
  # Separate samples for males and females
  sampled_males <- sample(sim.site.list, size = n_male, replace = TRUE, prob = male_prob)
  sampled_females <- sample(sim.site.list, size = n_female, replace = TRUE, prob = female_prob)
  
  #assign to df
  new_df <- df %>%
    mutate(sim.site = as.factor(ifelse(sex == "Male", sampled_males, sampled_females)))
  
  #save out csv w permutation number in filename
  n_perm <- str_pad(i, 3, pad = "0")
  fname <- paste0(save_path, "/", csv_basename, "_perm-", n_perm, ".csv")
  fwrite(new_df, file=fname)
  
}
