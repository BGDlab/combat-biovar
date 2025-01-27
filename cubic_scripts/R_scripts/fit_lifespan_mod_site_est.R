#Basic script to fit a gamlss model

set.seed(12345)

#LOAD PACKAGES
library(gamlss)
library(dplyr)
library(data.table)

#GET ARTS
args <- commandArgs(trailingOnly = TRUE)
df <- fread(args[1], stringsAsFactors = TRUE, na.strings = "")
pheno <- as.character(args[2])
save_path <- args[3]

csv_name <- sub(pattern = "(.*)\\..*$", replacement = "\\1", basename(as.character(args[1])))

#def fitting function
gamlss_est_fit <- function(pheno, fam= "BCCG"){
  result <- tryCatch({
    gamlss_RSformula <-paste("gamlss(formula =", pheno, "~ pb(age_days) + sexMale + fs_version + pb(sex.age) + study,",
                             "sigma.formula = ~ pb(age_days) + sexMale + fs_version + pb(sex.age) + study,",
                             "nu.formula = ~ pb(age_days) + sexMale + fs_version + pb(sex.age) + study,", 
                             "control = gamlss.control(n.cyc = 200), family =", fam, ", data= df, trace = FALSE)")
    
    eval(parse(text = gamlss_RSformula))
    
  } , warning = function(w) {
    message("warning")
    eval(parse(text = gamlss_RSformula))
    
  } , error = function(e) {
    message(e$message, ", trying method=CG()")
    tryCatch({
      gamlss_CGformula <- paste("gamlss(formula =", pheno, "~ pb(age_days) + sexMale + fs_version + pb(sex.age) + study,",
                              "sigma.formula = ~ pb(age_days) + sexMale + fs_version + pb(sex.age) + study,",
                              "nu.formula = ~ pb(age_days) + sexMale + fs_version + pb(sex.age) + study,", 
                              "method=CG(), control = gamlss.control(n.cyc = 200), family =", fam, ", data= df, trace = FALSE)")
      eval(parse(text = gamlss_CGformula))
      
      #if CG also fails, return NULL
    }, error = function(e2) {
      message("second error, returning NULL")
      return(NULL)
    })
  } , finally = {
    message("done")
  } )
  return(result)
}

#FIT
if(grepl("raw", csv_name, fixed=TRUE)){
  #fit with log link in mu for unharmonized data
  base_model <- gamlss_est_fit(pheno, "BCCGo")
} else {
  base_model <- gamlss_est_fit(pheno, "BCCG")
}

#SAVE
csv_rename <- gsub("_", "-", csv_name)

saveRDS(base_model,paste0(save_path, "/", pheno, "_", csv_rename, "_site.est_mod.rds"))
