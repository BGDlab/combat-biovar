#plot centile differences

#define path
cent_abs.diffs <- readRDS(file="/cbica/home/gardnerm/combat-biovar/data/centile_abs_diffs.rds")

### LOAD ###
vol_list_global <- readRDS(file="R_scripts/vol_list_global.rds")
vol_list_regions <- readRDS(file="R_scripts/Vol_list_regions.rds")
sa_list <- readRDS(file="R_scripts/SA_list.rds")
ct_list <- readRDS(file="R_scripts/CT_list.rds")

# library(data.table) 
library(ggplot2) 
library(tidyverse) 
# library(ggseg)
# library(paletteer)

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
  geom_density(aes(x=abs.diff, fill=dataset), alpha=0.4) +
  facet_wrap(~pheno_cat) +
  theme(legend.position="none")
ggsave("figs/cent_plot_test.jpeg", plot.cents, width=10, height=10)
