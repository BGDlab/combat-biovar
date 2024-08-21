# load libraries
library(stats)

# contains 3 functions for running welch's t-test on data rankings
# (accounting for both skew and unequal variances - Zimmerman & Zumbo, 1993)

# rank.welch.t.test() - analogous to t.test()
# pairwise.rank.welch.t.test() - analogous to pairwise.t.test()
# pairwise.rank.maxgrp() - also returns group with larger ranks

rank.welch.t.test <- function(x, ...) {
  UseMethod("rank.welch.t.test", x)
}

## Default S3 method:
rank.welch.t.test.default <- function(x_list, y_list,
                                      alternative = c("two.sided", "less", "greater"),
                                      mu = 0, paired = FALSE, conf.level = 0.95, ...) {
  # rank pooled vals
  pooled <- c(x_list, y_list)
  pooled_r <- rank(pooled, na.last = NA) # remove NAs

  # Split the rankings back into the original lists
  x_ranks <- pooled_r[seq_along(x_list)]
  y_ranks <- pooled_r[seq_along(y_list) + length(x_list)]

  # kill if ranks are wrong length
  stopifnot(length(x_ranks) == length(x_list))
  stopifnot(length(y_ranks) == length(y_list))

  # conduct t.test
  welch.test <- t.test(
    x = x_ranks, y = y_ranks, var.equal = FALSE,
    alternative = alternative, mu = mu, paired = paired, conf.level = conf.level
  )

  return(welch.test)
}


## S3 method for class 'formula' (based on t.test.formula())
rank.welch.t.test.formula <- function(formula, data, subset, na.action, ...) {
  if (missing(formula) ||
    (length(formula) != 3L) ||
    (length(attr(terms(formula[-2L]), "term.labels")) != 1L))
    stop("'formula' missing or incorrect")
  m <- match.call(expand.dots = FALSE)
  if (is.matrix(eval(m$data, parent.frame())))
    m$data <- as.data.frame(data)
  ## need stats:: for non-standard evaluation
  m[[1L]] <- quote(stats::model.frame)
  m$... <- NULL
  mf <- eval(m, parent.frame())
  DNAME <- paste(names(mf), collapse = " by ")
  names(mf) <- NULL
  response <- attr(attr(mf, "terms"), "response")
  # rank values
  mf[[response]] <- rank(mf[[response]], na.last = NA)
  # group
  g <- factor(mf[[-response]])
  if (nlevels(g) != 2L)
    stop("grouping factor must have exactly 2 levels")
  DATA <- setNames(split(mf[[response]], g), c("x", "y"))
  y <- do.call("t.test", c(DATA, var.equal = FALSE, list(...)))
  y$data.name <- DNAME
  if (length(y$estimate) == 2L)
    names(y$estimate) <- paste("mean in group", levels(g))
  y
}

pairwise.rank.welch.t.test <- function(x, g, p.adjust.method = p.adjust.methods,
                                       paired = FALSE,
                                       alternative = c("two.sided", "less", "greater"),
                                       ...) {
  # code based heavily on pairwise.t.test() and pairwise.wilcox.test()

  ## parse args
  p.adjust.method <- match.arg(p.adjust.method)
  DNAME <- paste(deparse(substitute(x)), "and", deparse(substitute(g)))
  g <- factor(g)
  METHOD <- if (paired) "Wilcoxon signed rank test"
  else "Wilcoxon rank sum test"

  ## comp matrix
  compare.levels <- function(i, j) {
    ## get vals
    xi <- x[as.integer(g) == i]
    xj <- x[as.integer(g) == j]

    # rank pooled vals
    pooled <- c(xi, xj)
    pooled_r <- rank(pooled, na.last = NA)

    ## split rankings back into the original lists
    x_ranks <- pooled_r[seq_along(xi)]
    y_ranks <- pooled_r[seq_along(xj) + length(xi)]

    ## test
    t.test(x_ranks, y_ranks, paired = paired, var.equal = FALSE, alternative = alternative, ...)$p.value
  }

  ## compile results
  PVAL <- pairwise.table(compare.levels, levels(g), p.adjust.method)

  # find which site has larger estimate
  ## comp matrix
  compare.levels.est <- function(i, j) {
    ## get vals
    xi <- x[as.integer(g) == i]
    xj <- x[as.integer(g) == j]

    # rank pooled vals
    pooled <- c(xi, xj)
    pooled_r <- rank(pooled, na.last = NA)

    ## split rankings back into the original lists
    x_ranks <- pooled_r[seq_along(xi)]
    y_ranks <- pooled_r[seq_along(xj) + length(xi)]

    ## get est
    est <- broom::tidy(t.test(x_ranks, y_ranks,
      paired = paired,
      var.equal = FALSE,
      alternative = alternative, ...
    ))$estimate

    bigger_group <- as.character(ifelse(est > 0, i, j))
    return(bigger_group)
  }
  # (estimate = estimate1-estimate2) ~ positive -> levels(g)[1], negative -> levels(g)[2]
  big_group <- pairwise.table(compare.levels.est, levels(g), p.adjust.method)
  est_matrix <- matrix(as.list(levels(g))[big_group], ncol = ncol(big_group), dimnames = dimnames(big_group))

  ans <- list(
    method = METHOD, data.name = DNAME,
    p.value = PVAL, p.adjust.method = p.adjust.method,
    larger_group = big_group
  )
  class(ans) <- "pairwise.htest" # prevents larger_group from displaying but enables tidy()
  ans
}

# making new fun that will return the level with the greater estimated ranks in each pairwise comparison
pairwise.rank.maxgrp <- function(x, g, p.adjust.method = p.adjust.method,
                                 paired = FALSE, alternative = c("two.sided", "less", "greater"),
                                 ...) {
  ## parse args
  p.adjust.method <- match.arg(p.adjust.method)
  DNAME <- paste(deparse(substitute(x)), "and", deparse(substitute(g)))
  g <- factor(g)
  METHOD <- if (paired) "return group with larger ranks estimated by Wilcoxon signed rank test"
  else "return group with larger ranks estimated by Wilcoxon rank sum test"


  # find which site has larger estimate
  ## comp matrix
  compare.levels.est <- function(i, j) {
    ## get vals
    xi <- x[as.integer(g) == i]
    xj <- x[as.integer(g) == j]

    # rank pooled vals
    pooled <- c(xi, xj)
    pooled_r <- rank(pooled, na.last = NA)

    ## split rankings back into the original lists
    x_ranks <- pooled_r[seq_along(xi)]
    y_ranks <- pooled_r[seq_along(xj) + length(xi)]

    ## get est
    est <- broom::tidy(t.test(x_ranks, y_ranks,
      paired = paired,
      var.equal = FALSE,
      alternative = alternative, ...
    ))$estimate

    bigger_group <- ifelse(est > 0, i, j) # i, j
    return(bigger_group)
  }
  # (estimate = estimate1-estimate2) ~ positive -> levels(g)[1], negative -> levels(g)[2]
  big_group <- pairwise.table(compare.levels.est, levels(g), p.adjust.method)

  ans <- list(
    method = METHOD, data.name = DNAME,
    p.value = big_group, p.adjust.method = p.adjust.method
  ) # estimate column needs to be mislabeld so that tidy() work
  class(ans) <- "pairwise.htest"
  ans
}
