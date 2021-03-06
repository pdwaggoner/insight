% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/find_variables.R
\name{find_variables}
\alias{find_variables}
\title{Find names of all variables}
\usage{
find_variables(x, ...)
}
\arguments{
\item{x}{A fitted model.}

\item{...}{Currently not used.}
}
\value{
A list with (depending on the model) following elements (character
   vectors):
   \itemize{
     \item \code{response}, the name of the response variable
     \item \code{conditional}, the names of the predictor variables from the \emph{conditional} model (as opposed to the zero-inflated part of a model)
     \item \code{random}, the names of the random effects (grouping factors)
     \item \code{zero_inflated}, the names of the predictor variables from the \emph{zero-inflated} part of the model
     \item \code{zero_inflated_random}, the names of the random effects (grouping factors)
     \item \code{dispersion}, the name of the dispersion terms
     \item \code{instruments}, the names of instrumental variables
   }
}
\description{
Returns a list with the names of all variables, including
  response value and random effects, "as is". This means, on-the-fly
  tranformations like \code{log()}, \code{I()}, \code{as.factor()} etc.
  are preserved.
}
\note{
The difference to \code{\link{find_terms}} is that \code{find_variables()}
  may return a variable multiple times in case of multiple transformations
  (see examples below), while \code{find_terms()} returns each term only
  once.
}
\examples{
library(lme4)
data(sleepstudy)
m <- lmer(
  log(Reaction) ~ Days + I(Days^2) + (1 + Days + exp(Days) | Subject),
  data = sleepstudy
)

find_variables(m)

}
