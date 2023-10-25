set.seed(1010101)

#######################################################
#SIMULATE SITE ASSIGNMENTS
#######################################################
sim.site.list <- c("Site_A", "Site_B", "Site_C")
n_female <- table(ukb_df_age.filt$sex)["Female"]
n_male <- table(ukb_df_age.filt$sex)["Male"]

# Sample probabilities
male_prob <- c(0.33, 0.0825, 0.5875)
female_prob <- c(0.33, 0.5875, 0.0825)

# Create a list to store data frames
df_list <- list()

for(i in 1:5) {
  # Separate samples for males and females
  sampled_males <- sample(sim.site.list, size = n_male, replace = TRUE, prob = male_prob)
  sampled_females <- sample(sim.site.list, size = n_female, replace = TRUE, prob = female_prob)
  
  new_df <- ukb_df_age.filt %>%
    mutate(sim.site = as.factor(ifelse(sex == "Male", sampled_males, sampled_females)))
  
  # Store the data frame in the list
  df_list[[i]] <- new_df
}
#######################################################
#RUN COMBAT
#######################################################

cf_method_names <- c("cf", "cf.lm", "cf.lm_refA", "cf.gam", "cf.gam_refA", "cf.gamlss", "cf.gamlss_refA")

for(cf.name in cf_method_names) {
  #apply combat to list of dataframes
  cf_data_list <- lapply() #APPLY FUNCTION THAT RUNS COMBAT WITH DIFFERENT METHODS
  
  #make new list to store data from each method
  assign(cf.name, df_list, envir = .GlobalEnv)
}

#######################################################
#FIT GAMLSS
#######################################################

all_data_dfs <- c(df_list, cf, cf.lm, cf.lm_refA, cf.gam, cf.gam_refA, cf.gamlss, cf.gamlss_refA)
names(all_data_dfs) <- c("raw_data", cf_method_names)

for (data_list in all_data_dfs){
  print(name(data_list))
  drop1_df <- data.frame() #empty dataframe to store drop1 outputs for each phenotype/permutation
  sum_df <- data.frame() #empty dataframe to store summary outputs for each phenotype/permutation
  
  for(i in length(data_list)){
    #lapply function to fit gamlss on each phenotype
    
    # return drop1 and summary outputs for mu & sigma
  }
  
}

