# Shared plotting utilities for ggplot2 + plotly

#' Harvard theme for ggplot2
#'
#' Apply Harvard brand colors and styling
harvard_theme <- function() {
  list(
    theme_minimal(),
    scale_color_manual(values = c("#A51C30", "#4A4A4A")),
    scale_fill_manual(values = c("#A51C30", "#4A4A4A"))
  )
}

#' Convert ggplot to interactive plotly
#'
#' @param p ggplot object
#' @return plotly object with Harvard styling
as_interactive_plot <- function(p) {
  ggplotly(p, tooltip = c("x", "y")) %>%
    config(responsive = TRUE)
}
