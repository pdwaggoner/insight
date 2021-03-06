% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/model_info.R
\name{model_info}
\alias{model_info}
\title{Access information from model objects}
\usage{
model_info(x, ...)
}
\arguments{
\item{x}{A fitted model.}

\item{...}{Currently not used.}
}
\value{
A list with information about the model, like family, link-function
  etc. (see 'Details').
}
\description{
Retrieve information from model objects.
}
\details{
\code{model_info()} returns a list with information about the
  model for many different model objects. Following information
   is returned, where all values starting with \code{is_} are logicals.
   \itemize{
     \item \code{is_binomial}: family is binomial (but not negative binomial)
     \item \code{is_poisson}: family is poisson
     \item \code{is_negbin}: family is negative binomial
     \item \code{is_count}: model is a count model (i.e. family is either poisson or negative binomial)
     \item \code{is_beta}: family is beta
     \item \code{is_exponential}: family is exponential (e.g. Gamma or Weibull)
     \item \code{is_logit}: model has logit link
     \item \code{is_progit}: model has probit link
     \item \code{is_linear}: family is gaussian
     \item \code{is_tweedie}: family is tweedie
     \item \code{is_ordinal}: family is ordinal or cumulative link
     \item \code{is_categorical}: family is categorical link
     \item \code{is_censored}: model is a censored model
     \item \code{is_zeroinf}: model has zero-inflation component
     \item \code{is_zero_inflated}: alias for \code{is_zeroinf}
     \item \code{is_mixed}: model is a mixed effects model (with random effects)
     \item \code{is_multivariate}: model is a multivariate response model (currently only works for \emph{brmsfit} objects)
     \item \code{is_trial}: model response contains additional information about the trials
     \item \code{is_bayesian}: model is a Bayesian model
     \item \code{is_anova}: model is an Anova object
     \item \code{link_function}: the link-function
     \item \code{family}: the family-object
     \item \code{n_obs}: number of observations
     \item \code{model_terms}: a list with all model terms, including terms such as random effects or from zero-inflated model parts.
   }
}
\examples{
library(glmmTMB)
data("Salamanders")
m <- glmmTMB(
  count ~ spp + cover + mined + (1 | site),
  ziformula = ~ spp + mined,
  dispformula = ~DOY,
  data = Salamanders,
  family = nbinom2
)

model_info(m)
}
