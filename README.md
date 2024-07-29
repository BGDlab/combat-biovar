# combat-biovar

Testing the ability of [ComBatLS](https://github.com/andy1764/ComBatFamily) to harmonize multisite imaging features while preserving biological variance in scale. Contains code for all analyses and figures presented in *ComBatLS: A location- and scale-preserving method for multi-site image harmonization*.

##Preprint
Gardner, M., Shinohara, R. T., Bethlehem, R. A. I., Romero-Garcia, R., Warrier, V., Dorfschmidt, L., Shanmugan, S., Seidlitz, J., Alexander-Bloch, A., & Chen, A. (2024). ComBatLS: A location- and scale-preserving method for multi-site image harmonization. bioRxiv, 2024.06.21.599875. https://doi.org/10.1101/2024.06.21.599875

##Contents
### eda/
Directory containing .Rmd scripts to clean data and conduct exploratory analyses.

###cubic_scripts/
Directory containing scripts for conducting analyses on PennMedicine HPC.

###pheno_lists/
Directory containing .txt files listing brain features output by freesurfer, broken down by phenotype class (global volumes & cortical regions' thickness, surface area & volume).

###paper_lbcc_results.Rmd
Analyses of LBCC data

###paper_main_results.Rmd
Compilation of main analyses of simulated sites created from UKB data. Includes Figure 2 and some components of Figure 1 (created in Canva) 

###paper_prop_results.Rmd
Analyses of sites simulated with varying M:F from UKB data.

###paper_replication_results.Rmd
Replicating analyses from `paper_main_results.Rmd` when sites are permuted 100 times.

###pull_stats.sh
Script for getting many of the derivatives output by scripts in `cubic_scripts/`.

##SOFTWARE
All statistical analyses were done locally (R v 4.1.1 or 4.1.2) or on the Penn HPC using a Singularity image of the container [mgardner457/r_gamlss:0.0.1](https://hub.docker.com/layers/mgardner457/r_gamlss/0.0.1/images/sha256-c3f3ea6c8bf8e84a467a4fea839dd23ab19a822ab3b3a814c8052d3fd0ecccf2?context=repo)


