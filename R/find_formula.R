#' @title Find model formula
#' @name find_formula
#'
#' @description Returns the formula(s) for the different parts of a model
#'    (like fixed or random effects, zero-inflated component, ...).
#'
#' @param ... Currently not used.
#' @inheritParams find_predictors
#'
#' @return A list of formulas that describe the model. For simple models,
#'    only one list-element, \code{conditional}, is returned. For more complex
#'    models, the returned list may have following elements:
#'    \itemize{
#'      \item \code{conditional}, the "fixed effects" part from the model
#'      \item \code{random}, the "random effects" part from the model (or the \code{id} for gee-models and similar)
#'      \item \code{zero_inflated}, the "fixed effects" part from the zero-inflation component of the model
#'      \item \code{zero_inflated_random}, the "random effects" part from the zero-inflation component of the model
#'      \item \code{dispersion}, the dispersion formula
#'      \item \code{instruments}, for fixed-effects regressions like \code{ivreg}, \code{felm} or \code{plm}, the instrumental variables
#'      \item \code{cluster}, for fixed-effects regressions like \code{felm}, the cluster specification
#'      \item \code{correlation}, for models with correlation-component like \code{gls}, the formula that describes the correlation structure
#'      \item \code{slopes}, for fixed-effects individual-slope models like \code{feis}, the formula for the slope parameters
#'    }
#'
#' @note For models of class \code{lme} or \code{gls} the correlation-component
#'   is only returned, when it is explicitely defined as named argument
#'   (\code{form}), e.g. \code{corAR1(form = ~1 | Mare)}
#'
#' @examples
#' data(mtcars)
#' m <- lm(mpg ~ wt + cyl + vs, data = mtcars)
#' find_formula(m)
#' @importFrom stats formula terms as.formula
#' @export
find_formula <- function(x, ...) {
  UseMethod("find_formula")
}


#' @export
find_formula.default <- function(x, ...) {
  if (inherits(x, "list") && obj_has_name(x, "gam")) {
    x <- x$gam
    class(x) <- c(class(x), c("glm", "lm"))
  }

  tryCatch({
    list(conditional = stats::formula(x))
  },
  error = function(x) {
    NULL
  }
  )
}

#' @export
find_formula.gls <- function(x, ...) {
  ## TODO this is an intermediate fix to return the correlation variables from gls-objects
  f_corr <- parse(text = deparse(x$call$correlation, width.cutoff = 500))[[1]]$form

  l <- tryCatch({
    list(
      conditional = stats::formula(x),
      correlation = stats::as.formula(f_corr)
    )
  },
  error = function(x) {
    NULL
  }
  )

  compact_list(l)
}


#' @export
find_formula.data.frame <- function(x, ...) {
  stop("A data frame is no valid object for this function")
}


#' @export
find_formula.gamlss <- function(x, ...) {
  tryCatch({
    list(
      conditional = x$mu.formula,
      sigma = x$sigma.formula,
      nu = x$nu.formula,
      tau = x$tau.formula
    )
  },
  error = function(x) {
    NULL
  }
  )
}


#' @export
find_formula.gamm <- function(x, ...) {
  x <- x$gam
  class(x) <- c(class(x), c("glm", "lm"))
  NextMethod()
}


#' @export
find_formula.gee <- function(x, ...) {
  tryCatch({
    id <- parse(text = deparse(x$call, width.cutoff = 500))[[1]]$id

    # alternative regex-patterns that also work:
    # sub(".*id ?= ?(.*?),.*", "\\1", deparse(x$call, width.cutoff = 500), perl = TRUE)
    # sub(".*\\bid\\s*=\\s*([^,]+).*", "\\1", deparse(x$call, width.cutoff = 500), perl = TRUE)

    list(
      conditional = stats::formula(x),
      random = stats::as.formula(paste0("~", id))
    )
  },
  error = function(x) {
    NULL
  }
  )
}


#' @export
find_formula.ivreg <- function(x, ...) {
  tryCatch({
    f <- deparse(stats::formula(x), width.cutoff = 500)
    cond <- trim(substr(f, start = 0, stop = regexpr(pattern = "\\|", f) - 1))
    instr <- trim(substr(f, regexpr(pattern = "\\|", f) + 1, stop = 10000L))

    list(
      conditional = stats::as.formula(cond),
      instruments = stats::as.formula(paste0("~", instr))
    )
  },
  error = function(x) {
    NULL
  }
  )
}


#' @export
find_formula.iv_robust <- function(x, ...) {
  tryCatch({
    f <- deparse(stats::formula(x), width.cutoff = 500)
    cond <- trim(gsub("(.*)\\+(\\s)*\\((.*)\\)", "\\1", f))
    instr <- trim(gsub("(.*)\\((.*)\\)", "\\2", f))

    list(
      conditional = stats::as.formula(cond),
      instruments = stats::as.formula(paste0("~", instr))
    )
  },
  error = function(x) {
    NULL
  }
  )
}


#' @export
find_formula.plm <- function(x, ...) {
  tryCatch({
    f <- deparse(stats::formula(x), width.cutoff = 500)
    cond <- trim(substr(f, start = 0, stop = regexpr(pattern = "\\|", f) - 1))
    instr <- trim(substr(f, regexpr(pattern = "\\|", f) + 1, stop = 10000L))

    list(
      conditional = stats::as.formula(cond),
      instruments = stats::as.formula(paste0("~", instr))
    )
  },
  error = function(x) {
    NULL
  }
  )
}


#' @export
find_formula.coxme <- function(x, ...) {
  if (!requireNamespace("lme4", quietly = TRUE)) {
    stop("To use this function, please install package 'lme4'.")
  }

  f.cond <- stats::formula(x)

  f.random <- lapply(lme4::findbars(f.cond), function(.x) {
    f <- deparse(.x, width.cutoff = 500)
    stats::as.formula(paste0("~", f))
  })

  if (length(f.random) == 1) {
    f.random <- f.random[[1]]
  }

  f.cond <- stats::as.formula(get_fixed_effects(f.cond))

  compact_list(list(
    conditional = f.cond,
    random = f.random
  ))
}


#' @export
find_formula.felm <- function(x, ...) {
  f <- deparse(stats::formula(x), width.cutoff = 500L)
  f_parts <- unlist(strsplit(f, "(?<!\\()\\|(?![\\w\\s\\+\\(~]*[\\)])", perl = TRUE))

  f.cond <- trim(f_parts[1])

  if (length(f_parts) > 1) {
    f.rand <- paste0("~", trim(f_parts[2]))
  } else {
    f.rand <- NULL
  }

  if (length(f_parts) > 2) {
    f.instr <- trim(f_parts[3])
  } else {
    f.instr <- NULL
  }

  if (length(f_parts) > 3) {
    f.clus <- paste0("~", trim(f_parts[4]))
  } else {
    f.clus <- NULL
  }

  compact_list(list(
    conditional = stats::as.formula(f.cond),
    random = stats::as.formula(f.rand),
    instruments = stats::as.formula(f.instr),
    cluster = stats::as.formula(f.clus)
  ))
}


#' @export
find_formula.feis <- function(x, ...) {
  f <- deparse(stats::formula(x), width.cutoff = 500L)
  f_parts <- unlist(strsplit(f, "(?<!\\()\\|(?![\\w\\s\\+\\(~]*[\\)])", perl = TRUE))

  f.cond <- trim(f_parts[1])
  id <- parse(text = deparse(x$call, width.cutoff = 500))[[1]]$id

  # alternative regex-patterns that also work:
  # sub(".*id ?= ?(.*?),.*", "\\1", deparse(x$call, width.cutoff = 500), perl = TRUE)
  # sub(".*\\bid\\s*=\\s*([^,]+).*", "\\1", deparse(x$call, width.cutoff = 500), perl = TRUE)

  if (length(f_parts) > 1) {
    f.slopes <- paste0("~", trim(f_parts[2]))
  } else {
    f.slopes <- NULL
  }

  compact_list(list(
    conditional = stats::as.formula(f.cond),
    slopes = stats::as.formula(f.slopes),
    random = stats::as.formula(paste0("~", id))
  ))
}


#' @export
find_formula.tobit <- function(x, ...) {
  tryCatch({
    list(conditional = parse(text = deparse(x$call, width.cutoff = 500))[[1]]$formula)
  },
  error = function(x) {
    NULL
  }
  )
}


#' @export
find_formula.hurdle <- function(x, ...) {
  zeroinf_formula(x)
}


#' @export
find_formula.zeroinfl <- function(x, ...) {
  zeroinf_formula(x)
}


#' @export
find_formula.zerotrunc <- function(x, ...) {
  zeroinf_formula(x)
}


#' @export
find_formula.clm2 <- function(x, ...) {
  list(conditional = attr(x$location, "terms", exact = TRUE))
}


#' @export
find_formula.aovlist <- function(x, ...) {
  f <- attr(x, "terms", exact = TRUE)
  attributes(f) <- NULL
  list(conditional = f)
}


#' @export
find_formula.glmmTMB <- function(x, ...) {
  if (!requireNamespace("lme4", quietly = TRUE)) {
    stop("To use this function, please install package 'lme4'.")
  }

  f.cond <- stats::formula(x)
  f.zi <- stats::formula(x, component = "zi")
  f.disp <- stats::formula(x, component = "disp")

  if (identical(deparse(f.zi, width.cutoff = 500), "~0") ||
    identical(deparse(f.zi, width.cutoff = 500), "~1")) {
    f.zi <- NULL
  }

  if (identical(deparse(f.disp, width.cutoff = 500), "~0") ||
    identical(deparse(f.disp, width.cutoff = 500), "~1")) {
    f.disp <- NULL
  }


  f.random <- lapply(lme4::findbars(f.cond), function(.x) {
    f <- deparse(.x, width.cutoff = 500)
    stats::as.formula(paste0("~", f))
  })

  if (length(f.random) == 1) {
    f.random <- f.random[[1]]
  }

  f.zirandom <- lapply(lme4::findbars(f.zi), function(.x) {
    f <- deparse(.x, width.cutoff = 500)
    if (f == "NULL") {
      return(NULL)
    }
    stats::as.formula(paste0("~", f))
  })

  if (length(f.zirandom) == 1) {
    f.zirandom <- f.zirandom[[1]]
  }


  f.cond <- stats::as.formula(get_fixed_effects(f.cond))
  if (!is.null(f.zi)) f.zi <- stats::as.formula(get_fixed_effects(f.zi))

  compact_list(list(
    conditional = f.cond,
    random = f.random,
    zero_inflated = f.zi,
    zero_inflated_random = f.zirandom,
    dispersion = f.disp
  ))
}


#' @export
find_formula.merMod <- function(x, ...) {
  if (!requireNamespace("lme4", quietly = TRUE)) {
    stop("To use this function, please install package 'lme4'.")
  }

  f.cond <- stats::formula(x)
  f.random <- lapply(lme4::findbars(f.cond), function(.x) {
    f <- deparse(.x, width.cutoff = 500)
    stats::as.formula(paste0("~", f))
  })

  if (length(f.random) == 1) {
    f.random <- f.random[[1]]
  }

  f.cond <- stats::as.formula(get_fixed_effects(f.cond))

  compact_list(list(conditional = f.cond, random = f.random))
}


#' @export
find_formula.rlmerMod <- function(x, ...) {
  if (!requireNamespace("lme4", quietly = TRUE)) {
    stop("To use this function, please install package 'lme4'.")
  }

  f.cond <- stats::formula(x)
  f.random <- lapply(lme4::findbars(f.cond), function(.x) {
    f <- deparse(.x, width.cutoff = 500)
    stats::as.formula(paste0("~", f))
  })

  if (length(f.random) == 1) {
    f.random <- f.random[[1]]
  }

  f.cond <- stats::as.formula(get_fixed_effects(f.cond))

  compact_list(list(conditional = f.cond, random = f.random))
}


#' @export
find_formula.mixed <- function(x, ...) {
  if (!requireNamespace("lme4", quietly = TRUE)) {
    stop("To use this function, please install package 'lme4'.")
  }

  f.cond <- stats::formula(x)
  f.random <- lapply(lme4::findbars(f.cond), function(.x) {
    f <- deparse(.x, width.cutoff = 500)
    stats::as.formula(paste0("~", f))
  })

  if (length(f.random) == 1) {
    f.random <- f.random[[1]]
  }

  f.cond <- stats::as.formula(get_fixed_effects(f.cond))

  compact_list(list(conditional = f.cond, random = f.random))
}


#' @export
find_formula.clmm <- function(x, ...) {
  if (!requireNamespace("lme4", quietly = TRUE)) {
    stop("To use this function, please install package 'lme4'.")
  }

  f.cond <- stats::formula(x)
  f.random <- lapply(lme4::findbars(f.cond), function(.x) {
    f <- deparse(.x, width.cutoff = 500)
    stats::as.formula(paste0("~", f))
  })

  if (length(f.random) == 1) {
    f.random <- f.random[[1]]
  }

  f.cond <- stats::as.formula(get_fixed_effects(f.cond))

  compact_list(list(conditional = f.cond, random = f.random))
}


#' @export
find_formula.stanreg <- function(x, ...) {
  if (!requireNamespace("lme4", quietly = TRUE)) {
    stop("To use this function, please install package 'lme4'.")
  }

  f.cond <- stats::formula(x)
  f.random <- lapply(lme4::findbars(f.cond), function(.x) {
    f <- deparse(.x, width.cutoff = 500)
    stats::as.formula(paste0("~", f))
  })

  if (length(f.random) == 1) {
    f.random <- f.random[[1]]
  }

  f.cond <- stats::as.formula(get_fixed_effects(f.cond))

  compact_list(list(conditional = f.cond, random = f.random))
}


#' @export
find_formula.brmsfit <- function(x, ...) {
  f <- stats::formula(x)

  if (obj_has_name(f, "forms")) {
    mv_formula <- lapply(f$forms, get_brms_formula)
    attr(mv_formula, "is_mv") <- "1"
    mv_formula
  } else {
    get_brms_formula(f)
  }
}


#' @export
find_formula.stanmvreg <- function(x, ...) {
  f <- stats::formula(x)
  mv_formula <- lapply(f, get_stanmv_formula)
  attr(mv_formula, "is_mv") <- "1"
  mv_formula
}


#' @export
find_formula.MCMCglmm <- function(x, ...) {
  fm <- x$Fixed$formula
  fmr <- x$Random$formula

  compact_list(list(conditional = fm, random = fmr))
}


#' @export
find_formula.lme <- function(x, ...) {
  fm <- eval(x$call$fixed)
  fmr <- eval(x$call$random)
  ## TODO this is an intermediate fix to return the correlation variables from lme-objects
  fc <- parse(text = deparse(x$call$correlation, width.cutoff = 500))[[1]]$form

  compact_list(list(
    conditional = fm,
    random = fmr,
    correlation = stats::as.formula(fc)
  ))
}


#' @export
find_formula.MixMod <- function(x, ...) {
  f.cond <- stats::formula(x)
  f.zi <- stats::formula(x, type = "zi_fixed")
  f.random <- stats::formula(x, type = "random")
  f.zirandom <- stats::formula(x, type = "zi_random")

  compact_list(list(
    conditional = f.cond,
    random = f.random,
    zero_inflated = f.zi,
    zero_inflated_random = f.zirandom
  ))
}


zeroinf_formula <- function(x) {
  f <- tryCatch({
    stats::formula(x)
  },
  error = function(x) {
    NULL
  }
  )

  if (is.null(f)) {
    return(NULL)
  }

  f <- trim(unlist(strsplit(deparse(f, width.cutoff = 500L), "\\|")))

  c.form <- stats::as.formula(f[1])
  if (length(f) == 2) {
    zi.form <- stats::as.formula(paste0("~", f[2]))
  } else {
    zi.form <- NULL
  }

  compact_list(list(conditional = c.form, zero_inflated = zi.form))
}


get_brms_formula <- function(f) {
  if (!requireNamespace("lme4", quietly = TRUE)) {
    stop("To use this function, please install package 'lme4'.")
  }

  f.cond <- f$formula
  f.random <- lapply(lme4::findbars(f.cond), function(.x) {
    fm <- deparse(.x, width.cutoff = 500)
    stats::as.formula(paste0("~", fm))
  })

  if (length(f.random) == 1) {
    f.random <- f.random[[1]]
  }

  f.cond <- stats::as.formula(get_fixed_effects(f.cond))

  f.zi <- f$pforms$zi
  f.zirandom <- NULL

  if (!is_empty_object(f.zi)) {
    f.zirandom <- lapply(lme4::findbars(f.zi), function(.x) {
      f <- deparse(.x, width.cutoff = 500)
      stats::as.formula(paste0("~", f))
    })

    if (length(f.zirandom) == 1) {
      f.zirandom <- f.zirandom[[1]]
    }

    f.zi <- stats::as.formula(paste0("~", deparse(f.zi[[3L]], width.cutoff = 500)))
    f.zi <- stats::as.formula(get_fixed_effects(f.zi))
  }

  compact_list(list(
    conditional = f.cond,
    random = f.random,
    zero_inflated = f.zi,
    zero_inflated_random = f.zirandom
  ))
}


get_stanmv_formula <- function(f) {
  if (!requireNamespace("lme4", quietly = TRUE)) {
    stop("To use this function, please install package 'lme4'.")
  }

  f.cond <- f
  f.random <- lapply(lme4::findbars(f.cond), function(.x) {
    fm <- deparse(.x, width.cutoff = 500)
    stats::as.formula(paste0("~", fm))
  })

  if (length(f.random) == 1) {
    f.random <- f.random[[1]]
  }

  f.cond <- stats::as.formula(get_fixed_effects(f.cond))

  compact_list(list(
    conditional = f.cond,
    random = f.random
  ))
}


#' @importFrom utils tail
#' @export
find_formula.BFBayesFactor <- function(x, ...) {
  if (.classify_BFBayesFactor(x) == "linear") {
    utils::tail(x@numerator, 1)[[1]]@identifier$formula
  } else{
    NULL
  }
}
