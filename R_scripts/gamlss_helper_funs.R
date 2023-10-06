#load libraries
library(gamlss)
library(dplyr)

### CONTENTS ###
# find.param()
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
