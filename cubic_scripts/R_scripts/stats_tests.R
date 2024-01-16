#load libraries
library(dplyr)
library(ggplot2)
library(data.table)
library(broom.mixed)
library(broom)
library(purrr)

devtools::source_url("https://raw.githubusercontent.com/BGDlab/combat-biovar/main/cubic_scripts/R_scripts/ranked_welch_tests.R?token=GHSAT0AAAAAACGAYP4GBRV6DV6ZXXAUMDXMZM5SWKQ")

pheno_list <- readRDS(file="R_scripts/pheno_list.rds") #assumes wd is set to cubic_scripts

##########
## STATS
##########
# sex.bias.feat.t.tests()
# Within each combat config, test if there are significant differences in M and F centile errors in each feature 
# FDR corrects for # datasets * # features tested, can multiply additional corrections (i.e. if using lapply to calc from multiple dataframes)

sex.bias.feat.t.tests <- function(df, feature_list, comp_multiplier=1){
  
  pheno_diff_list <- paste0("diff_", feature_list)
  
  #initialize empty df to store outputs
  t.df <- data.frame("dataset" = character(),
                     "pheno" = character(),
                     "p.value" = double(),
                     "sex_diff" = double(),
                     "t.stat" = double(),
                     "df" = double())
  attach(df)
  for (pheno in pheno_diff_list) {
    #print(paste("t-test:", pheno))
    
    #conduct t test
    df.sex.t <- df %>%
      group_by(dataset) %>%
      summarise(p.value = tidy(rank.welch.t.test.formula(formula=as.formula(paste(pheno, "~ sex")), paired = FALSE, p.adj = "none"))$p.value,
                sex_diff = tidy(rank.welch.t.test.formula(formula=as.formula(paste(pheno, "~ sex")), paired = FALSE, p.adj = "none"))$estimate,
                t.stat = tidy(rank.welch.t.test.formula(formula=as.formula(paste(pheno, "~ sex")), paired = FALSE, p.adj = "none"))$statistic,
                df = tidy(rank.welch.t.test.formula(formula=as.formula(paste(pheno, "~ sex")), paired = FALSE, p.adj = "none"))$parameter) %>%
      ungroup()
    
    df.sex.t$pheno <- sub("diff_", "", pheno)
    
    #append to full df
    t.df <- rbind(t.df, df.sex.t)
  }
  detach(df)
  
  #also get medians for m and f
  med_df <- df %>%
    dplyr::group_by(dataset, sex) %>%
    summarise_at(pheno_diff_list, median, na.rm=FALSE) %>%
    ungroup() %>%
    pivot_longer(cols = starts_with("diff_"), names_to="pheno", names_prefix="diff_") %>%
    pivot_wider(names_from = sex, values_from=value, names_glue = "med_{sex}") %>%
    mutate(median_sex_diff = (med_Male - med_Female)) %>%
    ungroup()
  
  #combine feature dfs
  result_df <- left_join(t.df, med_df)  
  
  #apply fdr correction
  n_comp=length(unique(df$dataset))*length(feature_list)
  result_df <- result_df %>%
    dplyr::mutate(p.val_fdr = p.adjust(p.value, method="fdr", n = (n_comp*comp_multiplier)), #use comp_multiplier if using fun with lapply
                  sig_fdr = case_when(p.val_fdr < 0.05 ~ TRUE,
                                      p.val_fdr >= 0.05 ~ FALSE),
                  dataset=as.factor(dataset))
  
  # #summarize
  # df.sex.t.sum <- df.sex.t %>%
  #   group_by(dataset) %>%
  #   dplyr::summarize(n_sig_regions = sum(sig_fdr),
  #             min_pval = min(p.val_fdr),
  #             max_pval = max(p.val_fdr)) %>%
  #   ungroup() %>%
  #   as.data.frame()
  
  return(result_df)
  
}

#centile.t.tests()
#Pairwise T tests: within each feature, run paired t tests (welch's test on ranks) pairwise on each possible pairing of combat configs and return as a single dataframe, with FDR correction for all feature + cf pair combos. Currently runs on magnitude (abs val) of centile diffs, but can be run on other metrics by redefining `feature_list` Recommended for use with mclapply across list of dataframes. Optional argument to correct for more comparisons (e.g. fdr-correct across an entire list of dataframes) using `comp_multiplier` arg.

pheno_abs.diff.list <- paste0("abs.diff_", pheno_list)

centile.t.tests <- function(df, feature_list=pheno_abs.diff.list, comp_multiplier=1){
  #initialize empty dfs to store outputs
  t.df <- data.frame("pheno" = character(),
                     "group1" = character(),
                     "group2" = character(),
                     "p.value" = double())
  #run tests
  attach(df)
  for (pheno in feature_list) {
    df.pairwise.t <- tidy(pairwise.rank.welch.t.test(x=df[[pheno]], g=df[["dataset"]], paired = TRUE, p.adj = "none"))
    df.pairwise.t$pheno <- pheno
    t.df <- rbind(t.df, df.pairwise.t)
  }
  n_comp <- nrow(t.df)

  #apply fdr correction
  t.df <- t.df %>%
    dplyr::mutate(p.val_fdr = p.adjust(p.value, method="fdr", n = (n_comp*comp_multiplier)),
           sig_fdr = case_when(p.val_fdr < 0.05 ~ TRUE,
                               p.val_fdr >= 0.05 ~ FALSE),
           pheno = sub("abs.diff_", "", pheno)) %>%
    unite(comp, c("group1", "group2")) %>%
   dplyr::mutate(comp = as.factor(comp))

  t.df.sum <- t.df %>%
    group_by(comp) %>%
    dplyr::summarize(n_sig_regions = sum(sig_fdr),
              min_pval = min(p.val_fdr),
              max_pval = max(p.val_fdr)) %>%
    ungroup() %>%
    as.data.frame()
  return(t.df.sum)
  #detach()
}

### EXAMPLE:
# perm_t.tests <- mclapply(perm_diffs, centile.t.tests, mc.preschedule = FALSE)
# names(perm_t.tests) <- n_perm_list
# cent_t.tests.p <- bind_rows(perm_t.tests, .id = "column_label")

#sex.bias.t.tests()
# Within each combat config, test if there are significant differences in M and F subject's mean abs. centile error. Can test mean (not abs) centile errors, Z errors, etc, using `to_test` arg. FDR corrects for number of datasets tested

sex.bias.t.tests <- function(df, to_test = "mean_cent_abs.diff", comp_multiplier=1){
  
  #conduct t test
  df.sex.t <- df %>%
    group_by(dataset) %>%
    summarise(p.value = tidy(rank.welch.t.test.formula(formula=as.formula(paste(to_test, "~ sex")), paired = FALSE, p.adj = "none"))$p.value,
              sex_diff = tidy(rank.welch.t.test.formula(formula=as.formula(paste(to_test, "~ sex")), paired = FALSE, p.adj = "none"))$estimate,
              t.stat = tidy(rank.welch.t.test.formula(formula=as.formula(paste(to_test, "~ sex")), paired = FALSE, p.adj = "none"))$statistic,
              df = tidy(rank.welch.t.test.formula(formula=as.formula(paste(to_test, "~ sex")), paired = FALSE, p.adj = "none"))$parameter) %>%
    ungroup()
  
  #apply fdr correction
  n_comp=length(unique(df$dataset))
  df.sex.t <- df.sex.t %>%
    dplyr::mutate(p.val_fdr = p.adjust(p.value, method="fdr", n = (n_comp*comp_multiplier)), #use comp_multiplier if using fun with lapply
                  sig_fdr = case_when(p.val_fdr < 0.05 ~ TRUE,
                                      p.val_fdr >= 0.05 ~ FALSE))
  return(df.sex.t)
  #detach()
}

# tidy(rank.welch.t.test.formula(formula=mean_cent_abs.diff ~ sex, data= ratio_subj_list[[1]], paired = FALSE, p.adj = "none"))
# rank.welch.t.test.formula(formula=mean_cent_abs.diff ~ sex, data= ratio_subj_list[[1]], paired = FALSE, p.adj = "none")

#sex.bias.feat.t.tests() KEEP THIS ONE
#modifying to test for sex-biases w/in feature rather than mean centiles

pheno_diff_list <- paste0("diff_", pheno_list)
sex.bias.feat.t.tests <- function(df, feature_list=pheno_diff_list, comp_multiplier=1){
  
  #initialize empty df to store outputs
  t.df <- data.frame("dataset" = character(),
                     "pheno" = character(),
                     "p.value" = double(),
                     "sex_diff" = double(),
                     "t.stat" = double(),
                     "df" = double())
  attach(df)
  for (pheno in feature_list) {
    #print(paste("t-test:", pheno))
    
    #conduct t test
    df.sex.t <- df %>%
      group_by(dataset) %>%
      summarise(p.value = tidy(rank.welch.t.test.formula(formula=as.formula(paste(pheno, "~ sex")), paired = FALSE, p.adj = "none"))$p.value,
                sex_diff = tidy(rank.welch.t.test.formula(formula=as.formula(paste(pheno, "~ sex")), paired = FALSE, p.adj = "none"))$estimate,
                t.stat = tidy(rank.welch.t.test.formula(formula=as.formula(paste(pheno, "~ sex")), paired = FALSE, p.adj = "none"))$statistic,
                df = tidy(rank.welch.t.test.formula(formula=as.formula(paste(pheno, "~ sex")), paired = FALSE, p.adj = "none"))$parameter) %>%
      ungroup()
    
    df.sex.t$pheno <- sub("diff_", "", pheno)
    
    #append to full df
    t.df <- rbind(t.df, df.sex.t)
  }
  detach(df)
  
  #also get medians for m and f
  med_df <- df %>%
    dplyr::group_by(dataset, sex) %>%
    summarise_at(feature_list, median, na.rm=TRUE) %>%
    ungroup() %>%
    pivot_longer(cols = starts_with("diff_"), names_to="pheno", names_prefix="diff_") %>%
    pivot_wider(names_from = sex, values_from=value, names_glue = "med_{sex}") %>%
    mutate(median_sex_diff = (med_Male - med_Female)) %>%
    ungroup()
  
  #also get max for m and f
  max_df <- df %>%
    dplyr::group_by(dataset, sex) %>%
    summarise_at(feature_list, max, na.rm=TRUE) %>%
    ungroup() %>%
    pivot_longer(cols = starts_with("diff_"), names_to="pheno", names_prefix="diff_") %>%
    pivot_wider(names_from = sex, values_from=value, names_glue = "max_{sex}") %>%
    mutate(max_sex_diff = (max_Male - max_Female)) %>%
    ungroup()
  
  #combine feature dfs
  result_df <- Reduce(left_join, c(list(t.df), list(med_df), list(max_df)))  
  
  #apply fdr correction
  n_comp=length(unique(df$dataset))*length(feature_list)
  result_df <- result_df %>%
    dplyr::mutate(p.val_fdr = p.adjust(p.value, method="fdr", n = (n_comp*comp_multiplier)), #use comp_multiplier if using fun with lapply
                  sig_fdr = case_when(p.val_fdr < 0.05 ~ TRUE,
                                      p.val_fdr >= 0.05 ~ FALSE),
                  dataset=as.factor(dataset))
  
  # #summarize
  # df.sex.t.sum <- df.sex.t %>%
  #   group_by(dataset) %>%
  #   dplyr::summarize(n_sig_regions = sum(sig_fdr),
  #             min_pval = min(p.val_fdr),
  #             max_pval = max(p.val_fdr)) %>%
  #   ungroup() %>%
  #   as.data.frame()
  
  return(result_df)
  
}
# sex.bias.feat.t.tests(diffs.df, feature_list = global.diff)

#extremeness.lm()
#Test for linear relationships between subject's actual centile score (calculated from raw data) and how much that score is affected by different combat methods.

extremeness.lm <- function(df, f, comp_multiplier=1){

  #conduct t test
  df.lm <- df %>%
    group_by(dataset) %>%
    #returns values for last (highest order) predictor
    summarise(p.value = tail(tidy(lm(as.formula(f)))$p.value, n=1),
              estimate = tail(tidy(lm(as.formula(f)))$estimate, n=1),
              t.stat = tail(tidy(lm(as.formula(f)))$statistic[2], n=1),
              std.error = tail(tidy(lm(as.formula(f)))$std.error[2]), n=1) %>%
    ungroup()
  n_comp=length(unique(df$dataset))

  #apply fdr correction
  df.lm <- df.lm %>%
    dplyr::mutate(p.val_fdr = p.adjust(p.value, method="fdr", n = (n_comp*comp_multiplier)),
           sig_fdr = case_when(p.val_fdr < 0.05 ~ TRUE,
                               p.val_fdr >= 0.05 ~ FALSE))
  return(df.lm)
  #detach()
}

# tidy(lm(mean_centile ~ mean_cent_diff, data= ratio_subj_list[[1]]))
# summary(lm(mean_centile ~ mean_cent_diff, data= ratio_subj_list[[1]]))

##########
## Plot
##########

#plot.cent.diffs()
#plot w/in feature average centile errors
plot.cent.diffs <- function(df){
mean.diffs.long <- df %>%
  mutate(dataset = factor(dataset, levels = c("raw", "cf", "cf.lm", "cf.gam", "cf.gamlss"), ordered = TRUE)) %>%
  group_by(dataset) %>%
  dplyr::summarize(across(starts_with("abs.diff_"), mean)) %>%
  ungroup() %>%
  dplyr::select(-ends_with(".z")) %>% #drop z-score cols
  pivot_longer(cols=starts_with("abs.diff_"), values_to="centile_abs.diff", names_to = "pheno", names_prefix = "abs.diff_") %>%
  mutate(pheno_cat = as.factor(case_when(
      pheno %in% vol_list_global ~ "Global Volume",
      pheno %in% vol_list_regions ~ "Regional Volume",
      pheno %in% sa_list ~ "Regional SA",
      pheno %in% ct_list ~ "Regional CT",
      TRUE ~ NA_character_)),
      label = sub("_[^_]*_", "_", pheno))

cent.diffs.plot <- mean.diffs.long %>%
  dplyr::filter(dataset != "raw") %>%
  mutate(centile_abs.diff = centile_abs.diff*100) %>% #for visuals
  ggplot() +
  geom_histogram(aes(x=centile_abs.diff, fill=dataset, y = stat(width*density)), color="black", alpha=0.6, position="identity") +
  theme_linedraw(base_size = 11) +
  facet_wrap(~pheno_cat) +
  scale_y_continuous(labels = scales::percent) + 
  scale_fill_manual(values=dataset_colors, name = "ComBat \nConfiguration", labels=dataset_names) +
  labs(y= "Percent Features", x = "Mean Absolute Centile Error") +
  ggtitle("Absolute errors in centile scores across ComBat processing pipelines")

print(cent.diffs.plot)
}

#sex.bias.t.tests()
# Within each combat config, test if there are significant differences in M and F subject's mean abs. centile error. Can test mean (not abs) centile errors, Z errors, etc, using `to_test` arg. FDR corrects for number of datasets tested

sex.bias.t.tests <- function(df, to_test = "mean_cent_abs.diff", comp_multiplier=1){
  
  #conduct t test
  df.sex.t <- df %>%
    group_by(dataset) %>%
    summarise(p.value = tidy(rank.welch.t.test.formula(formula=as.formula(paste(to_test, "~ sex")), paired = FALSE, p.adj = "none"))$p.value,
              sex_diff = tidy(rank.welch.t.test.formula(formula=as.formula(paste(to_test, "~ sex")), paired = FALSE, p.adj = "none"))$estimate,
              t.stat = tidy(rank.welch.t.test.formula(formula=as.formula(paste(to_test, "~ sex")), paired = FALSE, p.adj = "none"))$statistic,
              df = tidy(rank.welch.t.test.formula(formula=as.formula(paste(to_test, "~ sex")), paired = FALSE, p.adj = "none"))$parameter) %>%
    ungroup()
  
  #apply fdr correction
  n_comp=length(unique(df$dataset))
  df.sex.t <- df.sex.t %>%
    dplyr::mutate(p.val_fdr = p.adjust(p.value, method="fdr", n = (n_comp*comp_multiplier)), #use comp_multiplier if using fun with lapply
                  sig_fdr = case_when(p.val_fdr < 0.05 ~ TRUE,
                                      p.val_fdr >= 0.05 ~ FALSE))
  return(df.sex.t)
  #detach()
}

# tidy(rank.welch.t.test.formula(formula=mean_cent_abs.diff ~ sex, data= ratio_subj_list[[1]], paired = FALSE, p.adj = "none"))
# rank.welch.t.test.formula(formula=mean_cent_abs.diff ~ sex, data= ratio_subj_list[[1]], paired = FALSE, p.adj = "none")

#sex.bias.wilcox.tests()
# Within each combat config, test if there are significant differences in M and F subject's mean abs. centile error. Can test mean (not abs) centile errors, Z errors, etc, using `to_test` arg. FDR corrects for number of datasets tested

sex.bias.wilcox.tests <- function(df, to_test = "mean_cent_abs.diff", comp_multiplier=1){
  
  #conduct t test
  df.sex.t <- df %>%
    group_by(dataset) %>%
    summarise(p.value = tidy(wilcox.test(formula=as.formula(paste(to_test, "~ sex")), paired = FALSE, p.adj = "none"))$p.value,
              w.stat = tidy(wilcox.test(formula=as.formula(paste(to_test, "~ sex")), paired = FALSE, p.adj = "none"))$statistic) %>%
    ungroup()
  
  #apply fdr correction
  n_comp=length(unique(df$dataset))
  df.sex.t <- df.sex.t %>%
    dplyr::mutate(p.val_fdr = p.adjust(p.value, method="fdr", n = (n_comp*comp_multiplier)), #use comp_multiplier if using fun with lapply
                  sig_fdr = case_when(p.val_fdr < 0.05 ~ TRUE,
                                      p.val_fdr >= 0.05 ~ FALSE))
  return(df.sex.t)
  #detach()
}

# tidy(wilcox.test(formula=mean_cent_abs.diff ~ sex, data= ratio_subj_list[[1]], paired = FALSE, p.adj = "none"))
# wilcox.test(formula=mean_cent_abs.diff ~ sex, data= ratio_subj_list[[1]], paired = FALSE, p.adj = "none")

#sex.bias.feat.t.tests()
#modifying to test for sex-biases w/in feature rather than mean centiles

pheno_diff_list <- paste0("diff_", pheno_list)
sex.bias.feat.wilcox.tests <- function(df, feature_list=pheno_diff_list, comp_multiplier=1){
  
  #initialize empty df to store outputs
  t.df <- data.frame("dataset" = character(),
                     "pheno" = character(),
                     "p.value" = double(),
                     "w.stat" = double())
  attach(df)
  for (pheno in feature_list) {
    #print(paste("t-test:", pheno))
    
    #conduct t test
    df.sex.t <- df %>%
      group_by(dataset) %>%
      summarise(p.value = tidy(wilcox.test(formula=as.formula(paste(pheno, "~ sex")), paired = FALSE, p.adj = "none"))$p.value,
                w.stat = tidy(wilcox.test(formula=as.formula(paste(pheno, "~ sex")), paired = FALSE, p.adj = "none"))$statistic) %>%
      ungroup()
    
    df.sex.t$pheno <- sub("diff_", "", pheno)
    
    #append to full df
    t.df <- rbind(t.df, df.sex.t)
  }
  detach(df)
  
  #also get medians for m and f
  med_df <- df %>%
    dplyr::group_by(dataset, sex) %>%
    summarise_at(feature_list, median) %>%
    ungroup() %>%
    pivot_longer(cols = starts_with("diff_"), names_to="pheno", names_prefix="diff_") %>%
    pivot_wider(names_from = sex, values_from=value, names_glue = "med_{sex}") %>%
    mutate(median_sex_diff = (med_Male - med_Female)) %>%
    ungroup()
  
  #combine feature dfs
  result_df <- left_join(t.df, med_df)  
  
  #apply fdr correction
  n_comp=length(unique(df$dataset))*length(feature_list)
  result_df <- result_df %>%
    dplyr::mutate(p.val_fdr = p.adjust(p.value, method="fdr", n = (n_comp*comp_multiplier)), #use comp_multiplier if using fun with lapply
                  sig_fdr = case_when(p.val_fdr < 0.05 ~ TRUE,
                                      p.val_fdr >= 0.05 ~ FALSE),
                  dataset=as.factor(dataset))
  
  # #summarize
  # df.sex.t.sum <- df.sex.t %>%
  #   group_by(dataset) %>%
  #   dplyr::summarize(n_sig_regions = sum(sig_fdr),
  #             min_pval = min(p.val_fdr),
  #             max_pval = max(p.val_fdr)) %>%
  #   ungroup() %>%
  #   as.data.frame()
  
  return(result_df)
  
}
# sex.bias.feat.t.tests(diffs.df, feature_list = global.diff)

#extremeness.lm()
#Test for linear relationships between subject's actual centile score (calculated from raw data) and how much that score is affected by different combat methods.

extremeness.lm <- function(df, f, comp_multiplier=1){

  #conduct t test
  df.lm <- df %>%
    group_by(dataset) %>%
    #returns values for last (highest order) predictor
    summarise(p.value = tail(tidy(lm(as.formula(f)))$p.value, n=1),
              estimate = tail(tidy(lm(as.formula(f)))$estimate, n=1),
              t.stat = tail(tidy(lm(as.formula(f)))$statistic[2], n=1),
              std.error = tail(tidy(lm(as.formula(f)))$std.error[2]), n=1) %>%
    ungroup()
  n_comp=length(unique(df$dataset))

  #apply fdr correction
  df.lm <- df.lm %>%
    dplyr::mutate(p.val_fdr = p.adjust(p.value, method="fdr", n = (n_comp*comp_multiplier)),
           sig_fdr = case_when(p.val_fdr < 0.05 ~ TRUE,
                               p.val_fdr >= 0.05 ~ FALSE))
  return(df.lm)
  #detach()
}

# tidy(lm(mean_centile ~ mean_cent_diff, data= ratio_subj_list[[1]]))
# summary(lm(mean_centile ~ mean_cent_diff, data= ratio_subj_list[[1]]))

##########
## Plot
##########

#plot.cent.diffs()
#plot w/in feature average centile errors
plot.cent.diffs <- function(df){
mean.diffs.long <- df %>%
  mutate(dataset = factor(dataset, levels = c("raw", "cf", "cf.lm", "cf.gam", "cf.gamlss"), ordered = TRUE)) %>%
  group_by(dataset) %>%
  dplyr::summarize(across(starts_with("abs.diff_"), mean)) %>%
  ungroup() %>%
  dplyr::select(-ends_with(".z")) %>% #drop z-score cols
  pivot_longer(cols=starts_with("abs.diff_"), values_to="centile_abs.diff", names_to = "pheno", names_prefix = "abs.diff_") %>%
  mutate(pheno_cat = as.factor(case_when(
      pheno %in% vol_list_global ~ "Global Volume",
      pheno %in% vol_list_regions ~ "Regional Volume",
      pheno %in% sa_list ~ "Regional SA",
      pheno %in% ct_list ~ "Regional CT",
      TRUE ~ NA_character_)),
      label = sub("_[^_]*_", "_", pheno))

cent.diffs.plot <- mean.diffs.long %>%
  dplyr::filter(dataset != "raw") %>%
  mutate(centile_abs.diff = centile_abs.diff*100) %>% #for visuals
  ggplot() +
  geom_histogram(aes(x=centile_abs.diff, fill=dataset, y = stat(width*density)), color="black", alpha=0.6, position="identity") +
  theme_linedraw(base_size = 11) +
  facet_wrap(~pheno_cat) +
  scale_y_continuous(labels = scales::percent) + 
  scale_fill_manual(values=dataset_colors, name = "ComBat \nConfiguration", labels=dataset_names) +
  labs(y= "Percent Features", x = "Mean Absolute Centile Error") +
  ggtitle("Absolute errors in centile scores across ComBat processing pipelines")

print(cent.diffs.plot)
}
