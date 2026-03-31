# Shared R functions for regression labs
# Linear and polynomial regression implementations

#' Linear Regression
#'
#' Fit a simple linear model and return key metrics.
#'
#' @param x Predictor variable
#' @param y Response variable
#' @return List with intercept, slope, R-squared, RMSE
linear_regression <- function(x, y) {
  model <- lm(y ~ x)
  list(
    intercept = coef(model)[1],
    slope = coef(model)[2],
    r_squared = summary(model)$r.squared,
    rmse = sqrt(mean(residuals(model)^2))
  )
}

#' Polynomial Regression
#'
#' Fit a polynomial model of specified degree.
#'
#' @param x Predictor variable
#' @param y Response variable
#' @param degree Polynomial degree (1-10)
#' @return List with coefficients, R-squared, RMSE, AIC
polynomial_regression <- function(x, y, degree = 2) {
  model <- lm(y ~ poly(x, degree = degree))
  list(
    coefficients = coef(model),
    r_squared = summary(model)$r.squared,
    rmse = sqrt(mean(residuals(model)^2)),
    aic = AIC(model)
  )
}

#' Calculate Model Metrics
#'
#' Compute R-squared, RMSE, and AIC for predictions.
#'
#' @param y_true True values
#' @param y_pred Predicted values
#' @return List with R-squared, RMSE, AIC
calculate_metrics <- function(y_true, y_pred) {
  ss_res <- sum((y_true - y_pred)^2)
  ss_tot <- sum((y_true - mean(y_true))^2)
  r_squared <- 1 - (ss_res / ss_tot)
  rmse <- sqrt(mean((y_true - y_pred)^2))
  list(
    r_squared = r_squared,
    rmse = rmse
  )
}
