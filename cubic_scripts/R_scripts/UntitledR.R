essai <- function(x){
  result <- tryCatch({
    lm(x ~ sex + age_days, data=raw.dfs)
  } , warning = function(w) {
    message("warning")
    lm(x ~ sex + age_days, data=raw.df)
  } , error = function(e) {
    message("error")
    lm(x ~ sex + age_days, data=raw.df)
  } , finally = {
    message("done")
  } )
}
