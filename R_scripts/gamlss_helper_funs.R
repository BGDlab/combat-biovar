#load libraries
library(gamlss)
library(dplyr)
library(ggplot2)

### CONTENTS ###
# find.param()
# get.beta()
# list.sigma.terms()
# get.sigma.df()
# get.sigma.nl.df()
# get.moment.formula()
################

################
# find.param(gamlss.rds.file, moment, string)
### Use: read gamlss objects from RDS file and see whether the formula for a specific moment includes vars containing specified string
### Arguments: gamlss.rds.file = .rds containing gamlss obj;  moment = c("mu", "sigma", "nu", "tau"); string = search string

find.param <- function(gamlss.rds.file, moment, string) {
  #USE WITH sapply(USE.NAMES=TRUE) to keep file names with values!
  gamlss.rds.file <- as.character(gamlss.rds.file)
  gamlss.obj <- readRDS(gamlss.rds.file)
  sigma.coeff.list <- coef(gamlss.obj, what = moment) %>%
    names()
  any(sapply(sigma.coeff.list, function(x) grepl(string, x, ignore.case = TRUE)))
}

get.beta <- function(gamlss.rds.file, moment, term) {
  #USE WITH sapply(USE.NAMES=TRUE) to keep file names with values!
  gamlss.rds.file <- as.character(gamlss.rds.file)
  gamlss.obj <- readRDS(gamlss.rds.file)
  beta <- coef(gamlss.obj, what = moment)[term] %>%
    unname()
  return(beta)
}

list.sigma.terms <- function(gamlss.rds.file) {
  #USE WITH sapply(USE.NAMES=TRUE) to keep file names with values!
  gamlss.rds.file <- as.character(gamlss.rds.file)
  gamlss.obj <- readRDS(gamlss.rds.file)
  terms <- attr(gamlss.obj$sigma.terms, "term.labels")
  return(terms)
}

get.sigma.df <- function(gamlss.rds.file) {
  #USE WITH sapply(USE.NAMES=TRUE) to keep file names with values!
  gamlss.rds.file <- as.character(gamlss.rds.file)
  gamlss.obj <- readRDS(gamlss.rds.file)
  gamlss.obj$sigma.df
}

get.sigma.nl.df <- function(gamlss.rds.file) {
  #USE WITH sapply(USE.NAMES=TRUE) to keep file names with values!
  gamlss.rds.file <- as.character(gamlss.rds.file)
  gamlss.obj <- readRDS(gamlss.rds.file)
  gamlss.obj$sigma.nl.df
}

get.moment.formula <- function(gamlss.rds.file, moment) {
  #USE WITH sapply(USE.NAMES=TRUE) to keep file names with values!
  gamlss.rds.file <- as.character(gamlss.rds.file)
  gamlss.obj <- readRDS(gamlss.rds.file)
  moment.form <- formula(gamlss.obj, what = moment)
}

################
# PLOTTING
################

mean.tb.sim <- function(df, sex_level, ageRange, measure){
  tbv_list <- list()
  for (i in ageRange){
    tb.df <- df %>%
      dplyr::filter(sex == sex_level) %>%
      arrange(age_yrs) %>%
      dplyr::filter(age_yrs >= (i-0.005) & age_yrs <= (i+0.005)) %>%
      summarize(m = mean(deparse(substitute(measure)), na.rm = TRUE))
    tb.val <-tb.df$m
    tb_list <- append(tb_list, tb.val)
  }
  return(unlist(tb_list))
}

sim.data.ukb <- function(df){
  minAge <- min(df$age_days)
  maxAge <- max(df$age_days)
  ageRange <- seq(minAge, maxAge, 25)  # generate an age range with increments of 25 (since scaling in days)
  
  #sim data
  dataToPredictM <- data.frame(age_yrs=ageRange,
                               sex=c(rep(as.factor("Male"), length(ageRange))),
                               fs_version=c(rep(Mode(df$fs_version), length(ageRange))),
                               study=c(as.factor(rep(Mode(df$study), length(ageRange)))),
                               sex.age_yrs=c(rep(0, length(ageRange))))
  dataToPredictM$TBV <- mean.tbv.sim(df, "Male", ageRange)
  
  dataToPredictF <- data.frame(age_yrs=ageRange,
                               sex=c(rep(as.factor("Female"), length(ageRange))),
                               fs_version=c(rep(Mode(df$fs_version), length(ageRange))),
                               study=c(as.factor(rep(Mode(df$study), length(ageRange)))),
                               sex.age_yrs=ageRange)
  dataToPredictF$TBV <- mean.tbv.sim(df, "Female", ageRange)
  
  # List of centiles for the fan plot
  desiredCentiles <- c(0.1, 0.25, 0.5, 0.75, 0.9)
  
  # return
  sim <- list(ageRange, dataToPredictM, dataToPredictF, desiredCentiles)
  names(sim) <- c("ageRange", "dataToPredictM", "dataToPredictF", "desiredCentiles")
  return(sim)
}


plot_singlestudy_centiles <- function(gamlssModel, phenotype, df, color_var)
{
  #use functions in GAMLSS repo plotting_functions.R to sim and predict
  sim <- sim.data.ukb(df) #simulate data
  pred <- centile_predict(gamlssModel, sim$dataToPredictM, sim$dataToPredictF, sim$ageRange, sim$desiredCentiles) #predict centiles
  
  #extract vals
  ages <- sim$ageRange
  age_col <- df$age_yrs
  male_peak_age <- pred$peak_age_M
  female_peak_age <- pred$peak_age_F
  unit_text <- "(years)"
  
  #plot!
  #sometimes df[,get()] works, sometimes not found...????
  yvar <- df[[phenotype]]
  color_col <- df[[color_var]]
  
  sampleCentileFan <- ggplot() +
    geom_point(aes(x=age_col, y=yvar, color=color_col), alpha=0.3) +
    scale_colour_manual(values=c("#5AAE61FF", "#9970ABFF")) + 
    geom_line(aes(x=ages, y=pred$fanCentiles_M[[1]]), alpha=0.1) +
    geom_line(aes(x=ages, y=pred$fanCentiles_M[[2]]), alpha=0.3) +
    geom_line(aes(x=ages, y=pred$fanCentiles_M[[3]]), color="#40004BFF") +
    geom_line(aes(x=ages, y=pred$fanCentiles_M[[4]]), alpha=0.3) +
    geom_line(aes(x=ages, y=pred$fanCentiles_M[[5]]), alpha=0.1) +
    geom_line(aes(x=ages, y=pred$fanCentiles_F[[1]]), alpha=0.1) +
    geom_line(aes(x=ages, y=pred$fanCentiles_F[[2]]), alpha=0.3) +
    geom_line(aes(x=ages, y=pred$fanCentiles_F[[3]]), color="#00441BFF") +
    geom_line(aes(x=ages, y=pred$fanCentiles_F[[4]]), alpha=0.3) +
    geom_line(aes(x=ages, y=pred$fanCentiles_F[[5]]), alpha=0.1) +
    geom_point(aes(x=male_peak_age, y=pred$peak_M), color="#40004BFF", size=3) +
    geom_point(aes(x=female_peak_age, y=pred$peak_F), color="#00441BFF", size=3) +
    labs(title=deparse(substitute(gamlssModel))) +
    theme(legend.title = element_blank())+
    xlab(paste("Age at Scan", unit_text)) +
    ylab(deparse(substitute(phenotype)))
  
  print(sampleCentileFan)
}

