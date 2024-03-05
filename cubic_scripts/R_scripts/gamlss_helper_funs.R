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
  print(gamlss.rds.file)
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
get.var.across.ages.lbcc <- function(gamlss.rds.file, og_df) {
  #sim data for centiles
  minAge <- min(df$log_age)
  maxAge <- max(df$log_age)
  ageRange <- seq(minAge, maxAge, 0.5)
  
  #sim data
  dataToPredictM <- data.frame(log_age=ageRange,
                               sexMale=c(rep(1, length(ageRange))),
                               fs_version=c(rep(Mode(df$fs_version), length(ageRange))),
                               sex.age=ageRange)
  dataToPredictM$TBV <- mean.tb.sim(df, "Male", ageRange, "TBV")
  dataToPredictM$Vol_total <- mean.tb.sim(df, "Male", ageRange, "Vol_total")
  dataToPredictM$SA_total <- mean.tb.sim(df, "Male", ageRange, "SA_total")
  dataToPredictM$CT_total <- mean.tb.sim(df, "Male", ageRange, "CT_total")
  
  dataToPredictF <- data.frame(log_age=ageRange,
                               sexMale=c(rep(0, length(ageRange))),
                               fs_version=c(rep(Mode(df$fs_version), length(ageRange))),
                               sex.age=c(rep(0, length(ageRange))))
  dataToPredictF$TBV <- mean.tb.sim(df, "Female", ageRange, "TBV")
  dataToPredictF$Vol_total <- mean.tb.sim(df, "Female", ageRange, "Vol_total")
  dataToPredictF$SA_total <- mean.tb.sim(df, "Female", ageRange, "SA_total")
  dataToPredictF$CT_total <- mean.tb.sim(df, "Female", ageRange, "CT_total")
  
  # List of centiles for the fan plot
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
      # arrange(age_days) %>%
      # dplyr::filter(age_days >= (i-183) & age_days <= (i+183)) %>%
      arrange(log_age) %>%
      dplyr::filter(log_age >= (i-log(183, base=10)) & age_days <= (i+log(183, base=10))) %>%
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
  desiredCentiles <- c(0.01, 0.05, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95, 0.99)
  
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
  qfun <- paste0("q", fname)

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
  
  print(paste("length:", length(fanCentiles)))
  print(fanCentiles)
  #print(paste("male max:", max(fanCentiles_M)))
  #print(paste("female max:", max(fanCentiles_F)))
  
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
  print(paste("age length:", length(age)))
  cent <- sim[["desiredCentiles"]]
  print(paste("centile length:", length(cent)))
  
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
  pfun <- paste0("p", fname)
  
  centiles <- c()
  #iterate through participants
  for (i in 1:nrow(og.data)){
      centiles[i] <- eval(call(pfun, og.data[[pheno]][[i]], mu=predModel$mu[[i]], sigma=predModel$sigma[[i]], nu=predModel$nu[[i]]))
      
      #don't let centile = 1!
      if (centiles[i] == 1) {
        centiles[i] <- 0.99999999999999994 #largest number i could get w/o rounding to 1 (trial & error)
      }
      #don't let centile = 0!
      if (centiles[i] == 0) {
        centiles[i] <- 0.0000000000000000000000001 #25 dec places, should be plenty based on min centile
      }
  }
  #double check there are no impossible centiles
  if(c(1,0) %in% centiles) 
    stop("Error: predicted centiles include 0 or 1!")
  
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

get.og.data.centiles.lbcc <- function(gamlss.rds.file, og.data, get.zscores = FALSE){
  gamlss.rds.file <- as.character(gamlss.rds.file)
  gamlss.obj <- readRDS(gamlss.rds.file)
  pheno <- gamlss.obj$mu.terms[[2]]
  
  newData <- data.frame(log_age=og.data$log_age,
                        sexMale=og.data$sexMale,
                        sex.age=og.data$sex.age,
                        fs_version=og.data$fs_version,
                        TBV=og.data$TBV,
                        Vol_total=og.data$Vol_total,
                        SA_total=og.data$SA_total,
                        CT_total=og.data$CT_total
                        )
  
  predModel <- predictAll(gamlss.obj, newdata=newData, data=og.data, type= "response")
  
  #get dist type (e.g. GG, BCCG) and write out function
  fname <- gamlss.obj$family[1]
  pfun <- paste0("p", fname)
  
  centiles <- c()
  #iterate through participants
  for (i in 1:nrow(og.data)){
    centiles[i] <- eval(call(pfun, og.data[[pheno]][[i]], mu=predModel$mu[[i]], sigma=predModel$sigma[[i]], nu=predModel$nu[[i]]))
    
    #don't let centile = 1!
    if (centiles[i] == 1) {
      centiles[i] <- 0.99999999999999994 #largest number i could get w/o rounding to 1 (trial & error)
    }
    #don't let centile = 0!
    if (centiles[i] == 0) {
      centiles[i] <- 0.0000000000000000000000001 #25 dec places, should be plenty based on min centile
    }
    
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

### PARSE ACROSS VARYING M:F PERMUTAITON CENTILE CSVS
#loads prediction csvs and returns as list of dataframes
get.predictions.ratio <- function(x, df_path){
  df <- data.frame() #new empty dataframe
  pred.csvs.p <- list.files(path = df_path, pattern = paste0(x, ".+_predictions.csv"), full.names = TRUE)
  for (file in pred.csvs.p) {
    # Read each CSV file
    data <- fread(file)
    
    # Add a "Source_File" column with the file name
    data <- data %>%
      mutate(Source_File = as.factor(basename(file)),
             prop = as.factor(x)) %>%
      mutate(dataset = gsub("_data|_predictions.csv|prop-|[0-9]|-", "", Source_File))
    
    # Bind the data to the combined dataframe
    df <- bind_rows(df, data, .id = "File_ID")
  }
  return(df)
}

### PARSE CENTILE CSV
#loads prediction csvs and returns as list of dataframes
get.predictions <- function(df_path){
  df <- data.frame() #new empty dataframe
  pred.csvs.p <- list.files(path = df_path, pattern = ".+_predictions.csv", full.names = TRUE)
  for (file in pred.csvs.p) {
    # Read each CSV file
    data <- fread(file)
    
    # Add a "Source_File" column with the file name
    data <- data %>%
      mutate(Source_File = as.factor(basename(file))) %>%
      mutate(dataset = gsub("_data|_predictions.csv|-", "", Source_File))
    
    # Bind the data to the combined dataframe
    df <- bind_rows(df, data, .id = "File_ID")
  }
  return(df)
}


### PARSE ACROSS PERMUTAITON CENTILE CSVS
#loads prediction csvs and returns as list of dataframes
get.predictions.perm <- function(x, df_path){
  df <- data.frame() #new empty dataframe
  pred.csvs.p <- list.files(path = df_path, pattern = paste0(x, ".+_predictions.csv"), full.names = TRUE)
  for (file in pred.csvs.p) {
    # Read each CSV file
    data <- fread(file)
    
    # Add a "Source_File" column with the file name
    data <- data %>%
      mutate(Source_File = as.factor(basename(file)), #get cf configuration!
             perm = as.factor(x)) %>%
      mutate(dataset = gsub("_data|_predictions.csv|perm-|[0-9]|-", "", Source_File))
    
    # Bind the data to the combined dataframe
    df <- bind_rows(df, data, .id = "File_ID")
  }
  return(df)
}

### CALC CENTILE ERROR
#requires that pheno_list obj be defined, assumes ref. level (non-combatted data) named "raw"
get.diffs <- function(x, pheno_list, ref_level = "raw"){
  df <- x %>%
    mutate(dataset = factor(dataset, levels = unique(dataset), ordered = FALSE)) %>%
    mutate(dataset = relevel(dataset, ref= ref_level)) %>%
    arrange(dataset) %>%
    group_by(participant) %>%
    dplyr::mutate(across(all_of(pheno_list), ~ (. - first(.)), .names = "diff_{.col}")) %>% #centile err
    dplyr::mutate(across(ends_with(".z"), ~ (. - first(.)), .names = "diff_{.col}")) %>% #z-score err
    ungroup() %>%
    dplyr::filter(dataset != ref_level) %>% #drop raw
    dplyr::mutate(across(starts_with("diff_"), 
                         .fns = list( ~ abs(.)),
                         .names = "abs.{col}")) #new set of cols w abs. err vals
  return(df)
}

### GET W/IN SUBJ MEAN SCORES AND ERRS
#requires that pheno_list obj be defined
means.by.subj <- function(df, pheno_list){
  #def. columns to average across
  pheno_list.z <- paste0(pheno_list, ".z")
  pheno_list.diff <- paste0("diff_", pheno_list)
  pheno_list.diff.z <- paste0("diff_", pheno_list, ".z")
  pheno_list.abs.diff <- paste0("abs.diff_", pheno_list)
  pheno_list.abs.diff.z <- paste0("abs.diff_", pheno_list, ".z")
  
  mean.diffs.subj <- df %>%
    mutate(dataset = factor(dataset, levels = c("cf", "cf.lm", "cf.gam", "cf.gamlss"), ordered = TRUE)) %>%
    group_by(dataset) %>%
    rowwise() %>%
    #centile
    dplyr::mutate(mean_centile = mean(c_across(pheno_list))) %>%
    dplyr::select(!pheno_list) %>% #drop cols that have already been averaged
    #z-score
    dplyr::mutate(mean_z = mean(c_across(pheno_list.z))) %>%
    dplyr::select(!pheno_list.z) %>%
    #diff.centile
    dplyr::mutate(mean_cent_diff = mean(c_across(pheno_list.diff))) %>%
    dplyr::select(!pheno_list.diff) %>%
    #diff.z
    dplyr::mutate(mean_z_diff = mean(c_across(pheno_list.diff.z))) %>%
    dplyr::select(!pheno_list.diff.z) %>%
    #abs.diff.centile
    dplyr::mutate(mean_cent_abs.diff = mean(c_across(pheno_list.abs.diff))) %>%
    dplyr::select(!pheno_list.abs.diff) %>%
    #abs.diff.z
    #diff.z
    dplyr::mutate(mean_z_abs.diff = mean(c_across(pheno_list.abs.diff.z))) %>%
    dplyr::select(!pheno_list.abs.diff.z)
    
  return(mean.diffs.subj)
}

### GET W/IN SUBJ MEAN SCORES AND ERRS FOR EACH PHENO CAT
#requires named list of pheno lists
means.by.subj.by.cat <- function(df, list_of_pheno_lists){
  #def. columns to average across
  pheno_list <- do.call(c, list_of_pheno_lists)
  ct <- 1
  
  #df to merge back into
  df.results <- df %>%
    dplyr::select(-matches(paste(pheno_list, collapse = "|")))
  
  for (cat_list in list_of_pheno_lists) {
    #name of pheno cat
    name_str <- list_of_pheno_lists[ct]
    print(paste("summarizing across", name_str))
    
    #vals to average over
    cat_list.z <- paste0(cat_list, ".z")
    cat_list.diff <- paste0("diff_", cat_list)
    cat_list.diff.z <- paste0("diff_", cat_list, ".z")
    cat_list.abs.diff <- paste0("abs.diff_", cat_list)
    cat_list.abs.diff.z <- paste0("abs.diff_", cat_list, ".z")
  
  mean.diffs.subj <- df %>%
    mutate(dataset = factor(dataset, levels = c("cf", "cf.lm", "cf.gam", "cf.gamlss"), ordered = TRUE)) %>%
    group_by(dataset) %>%
    rowwise() %>%
    #averages
    dplyr::mutate(mean_z_abs.diff = mean(c_across(cat_list.abs.diff.z)),
                  mean_centile = mean(c_across(cat_list)),
                  mean_z = mean(c_across(cat_list.z)),
                  mean_cent_diff = mean(c_across(cat_list.diff)),
                  mean_z_diff = mean(c_across(cat_list.diff.z)),
                  mean_cent_abs.diff = mean(c_across(cat_list.abs.diff))) %>%
    #drop unnecessary cols
    dplyr::select(-matches(paste(pheno_list, collapse = "|"))) %>%
    rename_with(~ gsub("mean", paste(name_str, "mean", sep = "_"), .), starts_with("mean")) #rename
  
  df.results <- full_join(df.results, mean.diffs.subj) #save results to df
  
  ct <- ct + 1 #next loop
  }
  return(df.results)
  
}