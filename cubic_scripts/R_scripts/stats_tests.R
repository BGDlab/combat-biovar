# load libraries
library(dplyr)
library(ggplot2)
library(data.table)
library(broom.mixed)
library(broom)
library(purrr)
library(tidyverse)

devtools::source_url("https://raw.githubusercontent.com/BGDlab/combat-biovar/main/cubic_scripts/R_scripts/ranked_welch_tests.R")

##########
## STATS
##########

# centile.t.tests()
# Pairwise T tests: within each feature, run paired t tests (welch's test on ranks) pairwise 
# on each possible pairing of combat configs and return as a single dataframe, 
# with FDR correction for all feature + cf pair combos. 
# Currently runs on magnitude (abs val) of centile diffs, but can be run on other metrics by redefining `feature_list`.
# Recommended for use with mclapply across list of dataframes. 
# Optional argument to correct for more comparisons (e.g. fdr-correct across an 
# entire list of dataframes) using `comp_multiplier` arg.


centile.t.tests <- function(df, feature_list, comp_multiplier = 1) {
  # initialize empty dfs to store outputs
  t.df <- data.frame(
    "pheno" = character(),
    "group1" = character(),
    "group2" = character(),
    "p.value" = double()
  )
  # run tests
  attach(df)
  for (pheno in feature_list) {
    df.pairwise.t <- tidy(pairwise.rank.welch.t.test(x = df[[pheno]], 
                                                     g = df[["dataset"]], 
                                                     paired = TRUE, 
                                                     p.adj = "none"))
    df.pairwise.t$pheno <- pheno
    t.df <- rbind(t.df, df.pairwise.t)
  }
  n_comp <- nrow(t.df)

  # apply fdr correction
  t.df <- t.df %>%
    dplyr::mutate(
      p.val_fdr = p.adjust(p.value, method = "fdr", n = (n_comp * comp_multiplier)),
      sig_fdr = case_when(
        p.val_fdr < 0.05 ~ TRUE,
        p.val_fdr >= 0.05 ~ FALSE
      ),
      pheno = sub("abs.diff_", "", pheno)
    ) %>%
    unite(comp, c("group1", "group2")) %>%
    dplyr::mutate(comp = as.factor(comp))

  t.df.sum <- t.df %>%
    group_by(comp) %>%
    dplyr::summarize(
      n_sig_regions = sum(sig_fdr),
      min_pval = min(p.val_fdr),
      max_pval = max(p.val_fdr)
    ) %>%
    ungroup() %>%
    as.data.frame()
  return(t.df.sum)
  # detach()
}

### EXAMPLE:
# perm_t.tests <- mclapply(perm_diffs, centile.t.tests, mc.preschedule = FALSE)
# names(perm_t.tests) <- n_perm_list
# cent_t.tests.p <- bind_rows(perm_t.tests, .id = "column_label")

# centile.t.tests.full_result()
# same as centile t-test but returns results for each feature instead of summarizing w/in each comparison

centile.t.tests.full_result <- function(df, feature_list, comp_multiplier = 1) {
  # initialize empty dfs to store outputs
  t.df <- data.frame(
    "pheno" = character(),
    "group1" = character(),
    "group2" = character(),
    "p.value" = double()
  )
  # run tests
  attach(df)
  for (pheno in feature_list) {
    df.pairwise.t <- tidy(pairwise.rank.welch.t.test(x = df[[pheno]],
                                                     g = df[["dataset"]],
                                                     paired = TRUE,
                                                     p.adj = "none"))

    #GET ADDITIONAL TEST PARAMETERS 
    # this is admittedly hackey, but basically to use tidy() the object needs
    # to be class pairwise.htest, which only has cols for the 2 groups and p.val
    # so to get additional stats, i'm just rewriting funs that return other stats
    # in p-value col and renaming the col :/
    
    # find bigger group
    df.pairwise.grp <- tidy(pairwise.rank.maxgrp(x = df[[pheno]],
                                                 g = df[["dataset"]],
                                                 paired = TRUE,
                                                 p.adj = "none"))
    df.pairwise.grp <- df.pairwise.grp %>%
      rename(bigger_group = p.value) # fix name
    
    #confirm list
    stopifnot(dim(df.pairwise.grp) == dim(df.pairwise.t))

    # join
    df.pairwise.t2 <- left_join(df.pairwise.t, df.pairwise.grp)

    df.pairwise.t2$pheno <- pheno
    t.df <- rbind(t.df, df.pairwise.t2)
  }
  n_comp <- nrow(t.df)

  dataset_vec <- levels(as.factor(df$dataset))

  # apply fdr correction
  t.df <- t.df %>%
    dplyr::mutate(
      p.val_fdr = p.adjust(p.value, method = "fdr", n = (n_comp * comp_multiplier)),
      sig_fdr = case_when(
        p.val_fdr < 0.05 ~ TRUE,
        p.val_fdr >= 0.05 ~ FALSE
      ),
      pheno = sub("abs.diff_", "", pheno),
      bigger_group = dataset_vec[bigger_group]
    ) %>%
    unite(comp, c("group1", "group2")) %>%
    dplyr::mutate(comp = as.factor(comp))

  return(t.df)
  # detach()
}

# use: tidy(rank.welch.t.test.formula(formula=mean_cent_abs.diff ~ sex, data= ratio_subj_list[[1]], paired = FALSE, p.adj = "none"))
# use: rank.welch.t.test.formula(formula=mean_cent_abs.diff ~ sex, data= ratio_subj_list[[1]], paired = FALSE, p.adj = "none")

# sex.bias.feat.t.tests()
# modifying to test for sex-biases w/in feature rather than mean centiles.
# optional ID_col so fun will retain prop or perm as necessary when lapplying across a list of dfs

sex.bias.feat.t.tests <- function(df, feature_list, comp_multiplier = 1, ID_col = NA) {
  # initialize empty df to store outputs
  t.df <- data.frame(
    "dataset" = character(),
    "pheno" = character(),
    "p.value" = double(),
    "sex_diff" = double(),
    "t.stat" = double(),
    "df" = double()
  )
  attach(df)
  for (pheno in feature_list) {

    # conduct t test
    df.sex.t <- df %>%
      group_by(dataset) %>%
      summarise(
        p.value = tidy(rank.welch.t.test.formula(formula = as.formula(paste(pheno, "~ sex")),
                                                 paired = FALSE, p.adj = "none"))$p.value,
        sex_diff = tidy(rank.welch.t.test.formula(formula = as.formula(paste(pheno, "~ sex")),
                                                  paired = FALSE, p.adj = "none"))$estimate,
        t.stat = tidy(rank.welch.t.test.formula(formula = as.formula(paste(pheno, "~ sex")),
                                                paired = FALSE, p.adj = "none"))$statistic,
        df = tidy(rank.welch.t.test.formula(formula = as.formula(paste(pheno, "~ sex")),
                                            paired = FALSE, p.adj = "none"))$parameter
      ) %>%
      ungroup()

    df.sex.t$pheno <- sub("diff_", "", pheno)

    # append to full df
    t.df <- rbind(t.df, df.sex.t)
  }
  detach(df)

  # also get medians for m and f
  med_df <- df %>%
    dplyr::group_by(dataset, sex) %>%
    summarise_at(feature_list, median, na.rm = TRUE) %>%
    ungroup() %>%
    pivot_longer(cols = starts_with("diff_"), names_to = "pheno", names_prefix = "diff_") %>%
    pivot_wider(names_from = sex, values_from = value, names_glue = "med_{sex}") %>%
    mutate(median_sex_diff = (med_Male - med_Female)) %>%
    ungroup()

  # also get max for m and f
  max_df <- df %>%
    dplyr::group_by(dataset, sex) %>%
    summarise_at(feature_list, max, na.rm = TRUE) %>%
    ungroup() %>%
    pivot_longer(cols = starts_with("diff_"), names_to = "pheno", names_prefix = "diff_") %>%
    pivot_wider(names_from = sex, values_from = value, names_glue = "max_{sex}") %>%
    mutate(max_sex_diff = (max_Male - max_Female)) %>%
    ungroup()

  # combine feature dfs
  result_df <- Reduce(left_join, c(list(t.df), list(med_df), list(max_df)))

  # apply fdr correction
  n_comp <- length(unique(df$dataset)) * length(feature_list)
  result_df <- result_df %>%
    dplyr::mutate(
      p.val_fdr = p.adjust(p.value, method = "fdr",
                           n = (n_comp * comp_multiplier)),
                          # use comp_multiplier if using fun with lapply
      sig_fdr = case_when(
        p.val_fdr < 0.05 ~ TRUE,
        p.val_fdr >= 0.05 ~ FALSE
      ),
      dataset = as.factor(dataset)
    )

  # add back source file info in ID_col if needed
  if (!is.na(ID_col)) {
    print(paste("ID col vals:", unique(df[[ID_col]])))
    stopifnot(length(unique(df[[ID_col]])) == 1)
    result_df[[ID_col]] <- unique(df[[ID_col]])
  }

  return(result_df)
}
# use: sex.bias.feat.t.tests(diffs.df, feature_list = global.diff)

sex.bias.feat.wilcox.tests <- function(df, feature_list, comp_multiplier = 1) {
  # initialize empty df to store outputs
  t.df <- data.frame(
    "dataset" = character(),
    "pheno" = character(),
    "p.value" = double(),
    "w.stat" = double()
  )
  attach(df)
  for (pheno in feature_list) {

    # conduct t test
    df.sex.t <- df %>%
      group_by(dataset) %>%
      summarise(
        p.value = tidy(wilcox.test(formula = as.formula(paste(pheno, "~ sex")),
                                   paired = FALSE, p.adj = "none"))$p.value,
        w.stat = tidy(wilcox.test(formula = as.formula(paste(pheno, "~ sex")),
                                  paired = FALSE, p.adj = "none"))$statistic
      ) %>%
      ungroup()

    df.sex.t$pheno <- sub("diff_", "", pheno)

    # append to full df
    t.df <- rbind(t.df, df.sex.t)
  }
  detach(df)

  # also get medians for m and f
  med_df <- df %>%
    dplyr::group_by(dataset, sex) %>%
    summarise_at(feature_list, median) %>%
    ungroup() %>%
    pivot_longer(cols = starts_with("diff_"), names_to = "pheno", names_prefix = "diff_") %>%
    pivot_wider(names_from = sex, values_from = value, names_glue = "med_{sex}") %>%
    mutate(median_sex_diff = (med_Male - med_Female)) %>%
    ungroup()

  # combine feature dfs
  result_df <- left_join(t.df, med_df)

  # apply fdr correction
  n_comp <- length(unique(df$dataset)) * length(feature_list)
  result_df <- result_df %>%
    dplyr::mutate(
      p.val_fdr = p.adjust(p.value, method = "fdr", n = (n_comp * comp_multiplier)),
      # use comp_multiplier if using fun with lapply
      sig_fdr = case_when(
        p.val_fdr < 0.05 ~ TRUE,
        p.val_fdr >= 0.05 ~ FALSE
      ),
      dataset = as.factor(dataset)
    )

  return(result_df)
}
