# Lab 01: Simple Regression
# Interactive linear and polynomial regression explorer

library(shiny)
library(ggplot2)
library(plotly)
library(dplyr)

source("../shared/regression.R")

# Load sample data
data <- data.frame(
  x = 1:20,
  y = 2 * (1:20) + rnorm(20, 0, 3)
)

ui <- fluidPage(
  titlePanel("Lab 01: Interactive Regression Explorer"),
  sidebarLayout(
    sidebarPanel(
      h4("Model Controls"),
      sliderInput("degree", "Polynomial Degree",
                  min = 1, max = 10, value = 1, step = 1),
      br(),
      h4("Model Metrics"),
      verbatimTextOutput("metrics")
    ),
    mainPanel(
      plotlyOutput("plot")
    )
  )
)

server <- function(input, output, session) {

  # Reactive model computation
  model_data <- reactive({
    model <- lm(y ~ poly(x, degree = input$degree), data = data)
    data.frame(
      x = data$x,
      y = data$y,
      fitted = fitted(model),
      residual = residuals(model)
    )
  })

  # Metrics display
  output$metrics <- renderPrint({
    model <- lm(y ~ poly(x, degree = input$degree), data = data)
    cat("R²:", round(summary(model)$r.squared, 4), "\n")
    cat("RMSE:", round(sqrt(mean(residuals(model)^2)), 4), "\n")
    cat("AIC:", round(AIC(model), 4), "\n")
  })

  # Plot output
  output$plot <- renderPlotly({
    df <- model_data()
    p <- ggplot(df, aes(x = x, y = y)) +
      geom_point(size = 3, alpha = 0.6) +
      geom_line(aes(y = fitted), color = "red", size = 1) +
      theme_minimal() +
      labs(title = paste("Polynomial Regression (Degree", input$degree, ")"),
           x = "X", y = "Y")
    ggplotly(p)
  })
}

shinyApp(ui, server)
