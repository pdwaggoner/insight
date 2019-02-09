if (require("testthat") && require("insight") && require("nlme") && require("lme4")) {
  context("insight, model_info")

  data("sleepstudy")
  m1 <- lme(
    Reaction ~ Days,
    random = ~1 + Days | Subject,
    data = sleepstudy
  )

  test_that("model_info", {
    expect_true(model_info(m1)$is_linear)
  })

  test_that("find_predictors", {
    expect_identical(find_predictors(m1), list(conditional = c("Days")))
    expect_identical(find_predictors(m1, effects = "all"), list(conditional = "Days", random = "Subject"))
    expect_identical(find_predictors(m1, flatten = TRUE), "Days")
    expect_identical(find_predictors(m1, effects = "random"), list(random = "Subject"))
  })

  test_that("find_response", {
    expect_identical(find_response(m1), "Reaction")
  })

  test_that("link_inverse", {
    expect_equal(link_inverse(m1)(.2), .2, tolerance = 1e-5)
  })

  test_that("get_data", {
    expect_equal(nrow(get_data(m1)), 180)
    expect_equal(colnames(get_data(m1)), c("Reaction", "Days", "Subject"))
  })

  test_that("find_formula", {
    expect_length(find_formula(m1), 2)
    expect_equal(
      find_formula(m1),
      list(
        conditional = as.formula("Reaction ~ Days"),
        random = as.formula("~1 + Days | Subject")
      )
    )
  })

  test_that("find_terms", {
    expect_equal(find_terms(m1), list(response = "Reaction", conditional = "Days", random = "Subject"))
    expect_equal(find_terms(m1, flatten = TRUE), c("Reaction", "Days", "Subject"))
  })

  test_that("n_obs", {
    expect_equal(n_obs(m1), 180)
  })

  test_that("linkfun", {
    expect_false(is.null(link_function(m1)))
  })

  test_that("find_parameters", {
    expect_equal(
      find_parameters(m1),
      list(
        conditional = c("(Intercept)", "Days"),
        random = c("(Intercept)", "Days")
    ))
    expect_equal(nrow(get_parameters(m1)), 2)
    expect_equal(get_parameters(m1)$parameter, c("(Intercept)", "Days"))
  })

}