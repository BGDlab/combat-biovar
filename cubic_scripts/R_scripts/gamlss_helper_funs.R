#load libraries
library(gamlss)
library(dplyr)
library(ggplot2)
library(data.table)
library(broom.mixed)
library(broom)

#note - some of these functions do not seem to work on CUBIC, as they rely on saving environment variables

### CONTENTS ###
# find.param()
# get.beta()
# list.sigma.terms()
# get.sigma.df()
# get.sigma.nl.df()
# get.moment.formula()
# un_log()
################

drop1_all <- function(mod_obj, list = c("mu", "sigma"), name = NA, dataset = NA){
  if (is.na(name)){
    n <- deparse(substitute(mod_obj))
  } else {
    n <- name
  }
  if (is.na(dataset)){
    d <- NA_character_
  } else {
    d <- dataset
  }
  
  df <- data.frame("Model"=character(),
                   "Term"=character(),
                   "Df"=double(),
                   "AIC"=double(),
                   "LRT"=double(),
                   "Pr(Chi)"=double(),
                   "Moment"=character(),
                   "Dataset"=character())
  
  for (m in list){
    print(paste("drop1 from", m))
    drop.obj<-drop1(mod_obj, what = m)
    df2 <- drop.obj %>%
      as.data.frame() %>%
      mutate(Moment=attributes(drop.obj)$heading[2],
             Model=n,
             Dataset=d) %>%
      tibble::rownames_to_column("Term")
    df <- rbind(df, df2)
  }
  return(df)
}

################
# LOADING GAMLSS MODELS FROM .RDS
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

get.moment.betas <- function(gamlss.rds.file, moment) {
  #USE WITH sapply(USE.NAMES=TRUE) to keep file names with values!
  gamlss.rds.file <- as.character(gamlss.rds.file)
  gamlss.obj <- readRDS(gamlss.rds.file)
  beta.list <- coef(gamlss.obj, what = moment) %>%
    as.list()
  return(beta.list)
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

get.gamlss.summary<- function(gamlss.rds.file) {
  #USE WITH sapply(USE.NAMES=TRUE) to keep file names with values!
  gamlss.rds.file <- as.character(gamlss.rds.file)
  gamlss.obj <- readRDS(gamlss.rds.file)
  sum.table <- broom.mixed::tidy(gamlss.obj) %>%
    as.data.frame() %>%
    rename(t_stat = statistic)
  sum.table$mod_name <- sub("_mod\\.rds$", "", basename(gamlss.rds.file)) #append model name
  return(sum.table)
}

#more generic version of get.gamlss.summary()
get.summary<- function(rds.file) {
  #USE WITH sapply(USE.NAMES=TRUE) to keep file names with values!
  rds.file <- as.character(rds.file)
  obj <- readRDS(rds.file)
  sum.table <- broom::tidy(obj, parametric = TRUE) %>%
    as.data.frame() %>%
    rename(t_stat = statistic)
  sum.table$mod_name <- sub("\\.rds$", "", basename(rds.file)) #append model name (agnostic of ending str)
  return(sum.table)
}

#find dependent variable
get.y <- function(gamlss.rds.file) {
  #USE WITH sapply(USE.NAMES=TRUE) to keep file names with values!
  gamlss.rds.file <- as.character(gamlss.rds.file)
  gamlss.obj <- readRDS(gamlss.rds.file)
  pheno <- as.character(gamlss.obj$mu.terms[[2]])
  return(pheno)
}

#get mean and sd of each moments' estimates (to standardize beta weights)
get.moment.dist <- function(gamlss.rds.file) {
  #USE WITH sapply(USE.NAMES=TRUE) to keep file names with values!
  gamlss.rds.file <- as.character(gamlss.rds.file)
  gamlss.obj <- readRDS(gamlss.rds.file)
  
  #init df
  df <- data.frame("parameter" = character(),
                   "moment.mean" = double(),
                   "moment.sd" = double())
  
  #get list of fitted values for each moment for each subj.
  for (moment in gamlss.obj$parameters) {
    fv <- paste(moment, "fv", sep=".")
    df2 <- data.frame(parameter = moment,
                      moment.mean = mean(gamlss.obj[[fv]]),
                      moment.sd = sd(gamlss.obj[[fv]]))
    df <- rbind(df, df2)
  }
  df$mod_name = as.character(sub("_mod\\.rds$", "", basename(gamlss.rds.file)))
  return(df)
}

get.var.at.mean.age <- function(gamlss.rds.file, og_df) {
  #USE WITH sapply(USE.NAMES=TRUE) to keep file names with values!
  gamlss.rds.file <- as.character(gamlss.rds.file)
  gamlss.obj <- readRDS(gamlss.rds.file)
  
  #get mean age
  age <- mean(og_df[["age_days"]])
  
  #sim male and female subj.
  dataToPredictM <- data.frame(age_days=age,
                               sexMale=1)
  dataToPredictF <- data.frame(age_days=age,
                               sexMale=0)
  
  var.df <- data.frame("m.var" = exp(predict(gamlss.obj, what="sigma", data = og_df, newdata=dataToPredictM)),
             "f.var" = exp(predict(gamlss.obj, what="sigma", data = og_df, newdata=dataToPredictF)),
             "pheno" = as.character(gamlss.obj$mu.terms[[2]]))
  return(var.df)
}
################
# COMBAT
################

post_combat_concat <- function(comfam_obj, og_df){
  #check for correct lengths
  stopifnot(nrow(comfam_obj$dat.combat) == length(comfam_obj$batch$batch))
  stopifnot(nrow(comfam_obj$dat.combat) == nrow(og_df))
  
  comfam_obj$dat.combat[, "sim.site"] <- comfam_obj$batch$batch
  comfam_obj$dat.combat[, "age_days"] <- og_df[["age_days"]] #update in the future for more flexible naming & covar addition
  comfam_obj$dat.combat[, "sexMale"] <- og_df[["sexMale"]]
  return(as.data.frame(comfam_obj$dat.combat))
}

################
# PLOTTING & CENTILE CALC
################

mean.tb.sim <- function(df, sex_level, ageRange, measure){
  measure <- as.character(measure)
  tb_list <- list()
  for (i in ageRange){
    tb.df <- df %>% 
      dplyr::filter(sex == sex_level) %>%
      arrange(age_days) %>%
      dplyr::filter(age_days >= (i-183) & age_days <= (i+183)) %>%
      as.data.frame() # +- 1.5 yrs
    tb.val <- mean(tb.df[[measure]], na.rm = TRUE)
    tb_list <- append(tb_list, tb.val)
  }
  return(unlist(tb_list))
}

sim.data.ukb <- function(df){
  minAge <- min(df$age_days)
  maxAge <- max(df$age_days)
  ageRange <- seq(minAge, maxAge, 25)  # generate an age range with increments of 25 (since scaling in days)
  
  #sim data
  dataToPredictM <- data.frame(age_days=ageRange,
                               sexMale=c(rep(1, length(ageRange))))
                               #fs_version=c(rep(Mode(df$fs_version), length(ageRange))),
                               #sex.age=ageRange)
  #dataToPredictM$TBV <- mean.tb.sim(df, "Male", ageRange, "TBV")
  #dataToPredictM$Vol_total <- mean.tb.sim(df, "Male", ageRange, "Vol_total")
  #dataToPredictM$SA_total <- mean.tb.sim(df, "Male", ageRange, "SA_total")
  #dataToPredictM$CT_total <- mean.tb.sim(df, "Male", ageRange, "CT_total")
  
  dataToPredictF <- data.frame(age_days=ageRange,
                               sexMale=c(rep(0, length(ageRange))))
                               #fs_version=c(rep(Mode(df$fs_version), length(ageRange))),
                               #sex.age=c(rep(0, length(ageRange))))
  #dataToPredictF$TBV <- mean.tb.sim(df, "Female", ageRange, "TBV")
  #dataToPredictF$Vol_total <- mean.tb.sim(df, "Female", ageRange, "Vol_total")
  #dataToPredictF$SA_total <- mean.tb.sim(df, "Female", ageRange, "SA_total")
  #dataToPredictF$CT_total <- mean.tb.sim(df, "Female", ageRange, "CT_total")
  
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
  age_col <- df$age_days
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

plot.hist.by.sex <- function(data, pheno_list, facet_fac = NA) {
  
  # Create an empty list to store the ggplot objects
  plots <- list()
  
  # Loop through the list of variables
  for (pheno in pheno_list) {
    # Check if the variable exists in the data frame
    if (!pheno %in% names(data)) {
      warning(paste("Variable '", pheno, "' not found in the data frame. Skipping..."))
      next
    }
    
    # Create a ggplot histogram for the variable
    plot <- ggplot(data, aes(x = .data[[pheno]], fill= sex, color=sex)) +
      geom_histogram(alpha=0.5, position="identity") +
      labs(title = paste("Histogram of", pheno), x = pheno, y = "Frequency")
    
    # add facet wrapping if needed
    if (!is.na(facet_fac)) {
      plot <- plot + facet_wrap(~ .data[[facet_fac]])
    }
    
    # Add the plot to the list
    plots[[pheno]] <- plot
  }
  
  # Return the list of ggplot objects
  return(plots)
}

#modified centile_predict() from GAMLSS repo that automatically adjusts to distribution family (e.g. GG, BCCG) 
centile_predict <- function(gamlssModel, dataToPredictM, dataToPredictF, ageRange, desiredCentiles, og.data = NA){

  # Predict phenotype values in a set age range
  predictedModelM <- predictAll(gamlssModel, data = og.data, newdata=dataToPredictM) #
  predictedModelF <- predictAll(gamlssModel, data = og.data, newdata=dataToPredictF) #
  
  #get dist type (e.g. GG, BCCG) and write out function
  fname <- gamlss.obj$family[1]
  qfun <- paste0("p", fname)

  # For each desired centile
  fanCentiles <- c()
  fanCentiles_M <- c()
  fanCentiles_F <- c()
  for (i in c(1:length(desiredCentiles))){
    fanCentiles_M[[i]] <- eval(call(qfun, 
                              desiredCentiles[[i]],
                              mu=predictedModelM$mu,
                              sigma=predictedModelM$sigma,
                              nu=predictedModelM$nu))
    
    fanCentiles_F[[i]] <- eval(call(qfun,
                              desiredCentiles[[i]],
                              mu=predictedModelF$mu,
                              sigma=predictedModelF$sigma,
                              nu=predictedModelF$nu))
    
    fanCentiles[[i]] <- (fanCentiles_M[[i]] + fanCentiles_F[[i]])/2
  }
  # to get peaks, match median point with age ranges
  med.idx <- ceiling(length(desiredCentiles) / 2) #find median centile
  
  medians_M <- data.frame("ages"=ageRange,
                          "median"=fanCentiles_M[[med.idx]])
  peak_M <- medians_M[which.max(medians_M$median),]$median
  peak_age_M <- medians_M[which.max(medians_M$median),]$ages 
  
  medians_F <- data.frame("ages"=ageRange,
                          "median"=fanCentiles_F[[med.idx]])
  peak_F <- medians_F[which.max(medians_F$median),]$median
  peak_age_F <- medians_F[which.max(medians_F$median),]$ages
  
  medians <- data.frame("ages"=ageRange,
                        "median"=fanCentiles[[med.idx]])
  peak <- medians[which.max(medians$median),]$median
  peak_age <- medians[which.max(medians$median),]$ages
  
  pred <- list(fanCentiles, fanCentiles_M, fanCentiles_F, peak, peak_age, peak_M, peak_age_M, peak_F, peak_age_F, predictedModelM$mu, predictedModelM$sigma, predictedModelM$nu, predictedModelF$mu, predictedModelF$sigma, predictedModelF$nu)
  names(pred) <- c("fanCentiles", "fanCentiles_M", "fanCentiles_F", "peak", "peak_age", "peak_M", "peak_age_M", "peak_F", "peak_age_F", "M_mu", "M_sigma", "M_nu", "F_mu", "F_sigma", "F_nu")
  return(pred)
}

#wrapped version of centile_predict including readRDS
get.centile.pred <- function(gamlss.rds.file, og.data, sim) {
  #USE WITH sapply(USE.NAMES=TRUE) to keep file names with values!
  gamlss.rds.file <- as.character(gamlss.rds.file)
  gamlss.obj <- readRDS(gamlss.rds.file)
  #pass gamlss model to global
  assign("gamlss.obj", gamlss.obj, envir=globalenv())
  
  #get args to pass
  df.M <- sim[["dataToPredictM"]]
  df.F <- sim[["dataToPredictF"]]
  age <- sim[["ageRange"]]
  cent <- sim[["desiredCentiles"]]
  
  centiles <- centile_predict(gamlss.obj, df.M, df.F, age, cent, og.data)
  assign(sub("_mod\\.rds$", "", basename(gamlss.rds.file)), centiles)
  return(centiles)
}

# predict centile score of original data - dont think this will separate out m and f distributions though
#based on Jenna's function calculatePhenotypeCentile() from mpr_analysis repo & z.scores() from gamlss package

get.og.data.centiles <- function(gamlss.rds.file, og.data, get.zscores = FALSE){
  gamlss.rds.file <- as.character(gamlss.rds.file)
  gamlss.obj <- readRDS(gamlss.rds.file)
  pheno <- gamlss.obj$mu.terms[[2]]

  newData <- data.frame(age_days=og.data$age_days,
                        sexMale=og.data$sexMale)
    
  predModel <- predictAll(gamlss.obj, newdata=newData, data=og.data, type= "response")
  
  #get dist type (e.g. GG, BCCG) and write out function
  fname <- gamlss.obj$family[1]
  qfun <- paste0("p", fname)
  
  centiles <- c()
  #iterate through participants
  for (i in 1:nrow(og.data)){
      centiles[i] <- eval(call(qfun, og.data[[pheno]][[i]], mu=predModel$mu[[i]], sigma=predModel$sigma[[i]], nu=predModel$nu[[i]]))
  }
  if (get.zscores == FALSE){
  return(centiles)
  } else {
    #check to make sure distribution family is LMS
    if (fname != "BCCG") 
      stop(paste("This gamlss model does not use the BCCG family distribution, can't get z scores.", "\n If you think this message was returned in error, update code to include appropriate dist. families.", ""))
    
    #get z scores from normed centiles - how z.score() does it, but double check
    rqres <- qnorm(centiles)
    
    #return dataframe
    df <- data.frame("centile" = centiles,
                     "z_score" = rqres)
    return(df)
  }
}

### UN-LOG-SCALE - used to un-transform log_age values
un_log <- function(x){return(10^(x))}