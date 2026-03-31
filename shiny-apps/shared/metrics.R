# Shared metrics calculation functions

#' Format metrics for display
#'
#' @param metrics List with r_squared, rmse, aic
#' @return Formatted string for UI display
format_metrics <- function(metrics) {
  sprintf(
    "R²: %.4f\nRMSE: %.4f\nAIC: %.4f",
    metrics$r_squared,
    metrics$rmse,
    metrics$aic %||% NA
  )
}
