#' @title Get summary of priors used for a model
#' @name get_priors
#'
#' @description Provides a summary of the prior distributions used
#'   for the parameters in a given model.
#'
#' @param x A Bayesian model.
#' @param ... Currently not used.
#'
#' @return A data frame with a summary of the prior distributions used
#'   for the parameters in a given model.
#'
#' @examples
#' \dontrun{
#' library(rstanarm)
#' model <- stan_glm(Sepal.Width ~ Species * Petal.Length, data=iris)
#' get_priors(model)}
#'
#' @export
get_priors <- function(x, ...) {
  UseMethod("get_priors")
}


#' @export
get_priors.stanreg <- function(x, ...) {
  if (!requireNamespace("rstanarm", quietly = TRUE)) {
    stop("To use this function, please install package 'rstanarm'.")
  }

  ps <- rstanarm::prior_summary(x)

  l <- lapply(ps[c("prior_intercept", "prior")], function(x) {
    do.call(cbind, x)
  })

  prior_info <- Reduce(function(x, y) merge(x, y, all = TRUE), l)
  prior_info$parameter <- find_parameters(x)$conditional

  prior_info <- prior_info[, intersect(c("parameter", "dist", "location", "scale", "adjusted_scale"), colnames(prior_info))]

  colnames(prior_info) <- gsub("dist", "distribution", colnames(prior_info))
  colnames(prior_info) <- gsub("df", "DoF", colnames(prior_info))

  as.data.frame(lapply(prior_info, function(x) {
    if (.is_numeric_character(x))
      as.numeric(as.character(x))
    else
      as.character(x)
  }), stringsAsFactors = FALSE)
}


#' @export
get_priors.brmsfit <- function(x, ...) {
  ## TODO needs testing for edge cases - check if "coef"-column is
  # always empty for intercept-class
  x$prior$coef[x$prior$class == "Intercept"] <- "(Intercept)"

  prior_info <- x$prior[x$prior$coef != "" & x$prior$class %in% c("b", "(Intercept)"), ]

  prior_info$distribution <- gsub("(.*)\\(.*", "\\1", prior_info$prior)
  prior_info$scale <- gsub("(.*)\\((.*)\\,(.*)", "\\2", prior_info$prior)
  prior_info$location <- gsub("(.*)\\,(.*)\\)(.*)", "\\2", prior_info$prior)
  prior_info$parameter <- prior_info$coef

  prior_info <- prior_info[, c("parameter", "distribution", "location", "scale")]

  as.data.frame(lapply(prior_info, function(x) {
    if (.is_numeric_character(x))
      as.numeric(as.character(x))
    else
      as.character(x)
  }), stringsAsFactors = FALSE)
}


#' @importFrom stats na.omit
.is_numeric_character <- function(x) {
  (is.character(x) && !anyNA(suppressWarnings(as.numeric(stats::na.omit(x))))) ||
    (is.factor(x) && !anyNA(suppressWarnings(as.numeric(levels(x)))))
}
