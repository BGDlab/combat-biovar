
#script to permute sex-imbalanced site assignments

set.seed(1010101)

#LOAD PACKAGES
library(dplyr)
library(data.table)
library(stringr)

#GET ARGUMENTS
args <- commandArgs(trailingOnly = TRUE)
df <- fread(args[1], stringsAsFactors = TRUE, na.strings = "")
save_path <- fread(args[2], stringsAsFactors = TRUE, na.strings = "")
n_permutations <- as.integer(args[3])
pass <- as.logical(args[4]) #whether or not to automatically pass to qsub_combat.sh

#extract csv name
csv_basename <- sub(pattern = "(.*)\\..*$", replacement = "\\1", basename(as.character(args[1])))
csv_basename <- gsub("_", "-", csv_basename)

#SETUP SITES
sim.site.list <- c("Site_A", "Site_B", "Site_C")
n_female <- table(ukb_df_age.filt$sex)["Female"]
n_male <- table(ukb_df_age.filt$sex)["Male"]

# Sample probabilities
male_prob <- c(0.33, 0.0825, 0.5875)
female_prob <- c(0.33, 0.5875, 0.0825)

# Just get cols needed for site assignment
df.filt <- df %>%
  dplyr::select(participant, sex)

#control # permutations to complete
for(i in 1:n_permutations) {
  # Separate samples for males and females
  sampled_males <- sample(sim.site.list, size = n_male, replace = TRUE, prob = male_prob)
  sampled_females <- sample(sim.site.list, size = n_female, replace = TRUE, prob = female_prob)
  
  #assign to df
  new_df <- df.filt %>%
    mutate(sim.site = as.factor(ifelse(sex == "Male", sampled_males, sampled_females)))
  
  #save out csv w permutation number in filename
  n_perm <- str_pad(i, 3, pad = "0")
  fname <- paste0(save_path, "/", csv_basename, "_perm-key_", n_perm, ".csv")
  fwrite(new_df, file=fname)
  
  #automatically send to combat (and on to gamlss fitting)
  if (isTRUE(pass)) {
    print("submitting jobs to run combat")
    cmd <- paste('/cbica/home/gardnerm/combat-biovar/qsub_combat.sh -c', fname, '-p TRUE')
    cat(cmd)
    system(cmd)
  }
  
}
