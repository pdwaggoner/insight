% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/get_priors.R
\name{get_priors}
\alias{get_priors}
\title{Get summary of priors used for a model}
\usage{
get_priors(x, ...)
}
\arguments{
\item{x}{A Bayesian model.}

\item{...}{Currently not used.}
}
\value{
A data frame with a summary of the prior distributions used
  for the parameters in a given model.
}
\description{
Provides a summary of the prior distributions used
  for the parameters in a given model.
}
\examples{
\dontrun{
library(rstanarm)
model <- stan_glm(Sepal.Width ~ Species * Petal.Length, data=iris)
get_priors(model)}

}
