#single script to parse outputs & get results for OHBM 2024 abstract (condensed from proof-of-concept_mods.Rmd)

#define path
data_path <- "/cbica/home/gardnerm/combat-biovar/ukb_basic"

### LOAD ###
pheno_list <- readRDS(file="R_scripts/pheno_list.rds")
vol_list_global <- readRDS(file="R_scripts/vol_list_global.rds")
vol_list_regions <- readRDS(file="R_scripts/Vol_list_regions.rds")
sa_list <- readRDS(file="R_scripts/SA_list.rds")
ct_list <- readRDS(file="R_scripts/CT_list.rds")

library(data.table) 
library(readr)
library(ggplot2) 
library(tidyverse) 
library(mgcv) 
library(gamlss)
library(ggseg)
library(paletteer)

### CENTILES ###
#Do centile scores change based on combat version?

pred.csvs <- list.files(path = data_path, pattern = "_predictions.csv", full.names = TRUE)
combined_preds <- data.frame()

for (file in pred.csvs) {
  # Read each CSV file
  data <- fread(file)
  
  # Add a "Source_File" column with the file name
  data <- data %>%
    mutate(Source_File = as.factor(basename(file))) %>%
    mutate(dataset = sub("_data_predictions.csv", "", Source_File))
  
  # Bind the data to the combined dataframe
  combined_preds <- bind_rows(combined_preds, data, .id = "File_ID")
}

#calculate abs error
cent_abs.diffs <- combined_preds %>%
  dplyr::filter(!str_detect(dataset, "_refA")) %>% #drop ref site results
  mutate(dataset = factor(dataset, levels = unique(dataset), ordered = FALSE)) %>%
  mutate(dataset = relevel(dataset, ref= "ukb_CN")) %>%
  arrange(dataset) %>%
  group_by(participant) %>%
  mutate(across(all_of(pheno_list), ~ abs(. - first(.)), .names = "abs.diff_{.col}")) %>%
  ungroup() %>%
  dplyr::filter(dataset != "ukb_CN") #drop raw

#within each phenotype, iterate paired t test between each combo of combat dfs 

#initalize empty dfs to store outputs
sum.df <- data.frame(pheno = character(),
                     term = character(),
                     df = double(),
                     sumsq = double(),
                     meansq = double(),
                     statistic = double(),
                     p.value = double())
t.df <- data.frame("pheno" = character(),
                   "group1" = character(),
                   "group2" = character(),
                   "p.value" = double())
pheno_diff.list <- paste0("abs.diff_", pheno_list)

#run tests
attach(cent_abs.diffs)
for (pheno in pheno_diff.list) {
  df.aov <- tidy(aov(cent_abs.diffs[[pheno]] ~ cent_abs.diffs[["dataset"]]))
  df.aov$pheno <- pheno
  sum.df <- rbind(sum.df, df.aov)
  
  df.pairwise.t <- tidy(pairwise.t.test(x=cent_abs.diffs[[pheno]], g=cent_abs.diffs[["dataset"]], paired = TRUE, p.adj = "none"))
  df.pairwise.t$pheno <- pheno
  t.df <- rbind(t.df, df.pairwise.t)
}
detach()

#apply fdr correction
sum.df <- sum.df %>%
  dplyr::filter(term != "Residuals") %>%
  mutate(p.val_fdr = p.adjust(p.value, method="fdr", n = length(pheno_list)))

t.df <- t.df %>%
  mutate(p.val_fdr = p.adjust(p.value, method="fdr", n = length(pheno)),
         sig_fdr = case_when(p.val_fdr < 0.05 ~ TRUE,
                             p.val_fdr >= 0.05 ~ FALSE),
         pheno = sub("abs.diff_", "", pheno)) %>%
  unite(comp, c("group1", "group2")) %>%
  mutate(comp = as.factor(comp))

t.df.sum <- t.df %>%
  group_by(comp) %>%
  summarize(n_sig_regions = sum(sig_fdr),
            n_compare = n(),
            min_pval = min(p.val_fdr),
            max_pval = max(p.val_fdr))

#test big plot
plot.cents <- cent_abs.diffs %>%
  #dplyr::filter(dataset == "cf.gamlss") %>%
  pivot_longer(starts_with("abs.diff_"), names_to="pheno", values_to="abs.diff", names_prefix = "abs.diff_") %>%
  mutate(pheno_cat = as.factor(case_when(
    pheno %in% vol_list_global ~ "Global Volume",
    pheno %in% vol_list_regions ~ "Regional Volume",
    pheno %in% sa_list ~ "Regional SA",
    pheno %in% ct_list ~ "Regional CT",
    TRUE ~ NA_character_))) %>%
  ggplot() +
  geom_density(aes(x=diff, fill=dataset), alpha=0.4) +
  facet_wrap(~pheno_cat) +
  theme(legend.position="none")
ggsave("figs/cent_plot_test.jpeg", var.plot, width=10, height=10)


### Z-SCORES ###
z_abs.diffs <- combined_preds %>%
  dplyr::filter(!str_detect(dataset, "_refA")) %>% #drop ref site results
  mutate(dataset = factor(dataset, levels = unique(dataset), ordered = FALSE)) %>%
  mutate(dataset = relevel(dataset, ref = "ukb_CN")) %>%
  arrange(dataset) %>%
  group_by(participant) %>%
  mutate(across(ends_with(".z"), ~ abs(. - first(.)), .names = "abs.diff_{.col}")) %>%
  ungroup() %>%
  dplyr::filter(dataset != "ukb_CN") #drop raw

#initalize empty dfs to store outputs
z.sum.df <- data.frame(pheno = character(),
                       term = character(),
                       df = double(),
                       sumsq = double(),
                       meansq = double(),
                       statistic = double(),
                       p.value = double())
z.t.df <- data.frame("pheno" = character(),
                     "group1" = character(),
                     "group2" = character(),
                     "p.value" = double())

z.pheno_abs.diff.list <- paste0("abs.diff_", pheno_list, ".z")

#run tests
attach(z_abs.diffs)
for (pheno in z.pheno_abs.diff.list) {
  df.aov <- tidy(aov(z_abs.diffs[[pheno]] ~ z_abs.diffs[["dataset"]]))
  df.aov$pheno <- pheno
  z.sum.df <- rbind(z.sum.df, df.aov)
  
  df.pairwise.t <- tidy(pairwise.t.test(x=z_abs.diffs[[pheno]], g=z_abs.diffs[["dataset"]], paired = TRUE, p.adj = "none"))
  df.pairwise.t$pheno <- pheno
  z.t.df <- rbind(z.t.df, df.pairwise.t)
}
detach()

#apply fdr correction
z.sum.df <- z.sum.df %>%
  dplyr::filter(term != "Residuals") %>%
  mutate(p.val_fdr = p.adjust(p.value, method="fdr", n = length(pheno_list)))

z.t.df <- z.t.df %>%
  mutate(p.val_fdr = p.adjust(p.value, method="fdr", n = length(pheno)),
         sig_fdr = case_when(p.val_fdr < 0.05 ~ TRUE,
                             p.val_fdr >= 0.05 ~ FALSE),
         pheno = sub("abs.diff_", "", pheno),
         pheno = sub(".z", "", pheno)) %>%
  unite(comp, c("group1", "group2")) %>%
  mutate(comp = as.factor(comp))

sum_z.t.df <- z.t.df %>%
  group_by(comp) %>%
  summarize(n_sig_regions = sum(sig_fdr),
            n_compare = n(),
            min.pval = min(p.val_fdr),
            max.pval = max(p.val_fdr))

### SCALE EFFECTS OF SEX ###
#fix age, get diff between male and female pred. variance

pred.csvs <- list.files(path = data_path, pattern = "_variance.csv", full.names = TRUE)
combined_var <- data.frame()

for (file in pred.csvs) {
  # Read each CSV file
  data <- fread(file)
  
  # Add a "Source_File" column with the file name
  data <- data %>%
    mutate(Source_File = as.factor(basename(file))) %>%
    mutate(dataset = sub("_data_variance.csv", "", Source_File))
  
  # Bind the data to the combined dataframe
  combined_var <- bind_rows(combined_var, data, .id = "File_ID")
}

#get sex effect
combined_var <- combined_var %>%
  mutate(sex_std = sex_effect/f.var)

#get summary df for p vals, plotting
sigma.sex.df <- fread("ukb_basic/gamlss_summary.csv", stringsAsFactors = TRUE) %>%
  dplyr::select(-V1) %>%
  mutate(dataset = gsub("-data", "", dataset),
         dataset = gsub("-", "_", dataset),
         dataset = gsub("_simsites", "", dataset)) %>% #clean up dataset naming
  mutate(dataset = factor(dataset, levels = unique(dataset), ordered = FALSE)) %>%
  mutate(dataset = relevel(dataset, ref= "ukb_CN")) %>%
  dplyr::filter(parameter == "sigma" & term == "sexMale") %>%
  dplyr::select(mod_name, pheno, dataset, pheno_cat, label, sig.sum_bf.corr)

#add more info from parcellations
dk.parc <- dk$data %>%
  as.data.frame() %>%
  na.omit() %>%
  dplyr::select(c(hemi, region, label)) %>%
  distinct()

sigma.sex.df <- left_join(sigma.sex.df, dk.parc, by="label")

combined_var <- inner_join(combined_var, plot.info)

#var plot
var.plot <- combined_var %>%
  dplyr::filter(sig.sum_bf.corr == TRUE & pheno_cat != "Global Volume") %>%
  group_by(dataset, pheno_cat) %>%
  ggplot() +
  geom_brain(atlas = dk, 
             position = position_brain(hemi ~ side),
             aes(fill = sex_std)) +
  #scale_fill_gradient2() +
  facet_grid(dataset~pheno_cat) + 
  theme_bw(base_size=12) +
  theme(axis.title = element_blank(), axis.text = element_blank(), axis.ticks = element_blank(), panel.grid.major = element_blank(), panel.grid.minor = element_blank(), panel.border = element_rect(color= "gray", fill = NA)) +
  paletteer::scale_fill_paletteer_c("grDevices::Oslo") +
  scale_fill_continuous(labels = c("Sex Effect"))
  ggtitle("Standardized effect of male sex on variance")

ggsave("figs/male_variance_ohbm.jpeg", var.plot, width=10, height=10)