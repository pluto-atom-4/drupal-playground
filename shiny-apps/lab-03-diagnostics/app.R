# Lab 03: Diagnostic Plots
# Three-panel dashboard with linked residual diagnostics

library(shiny)
library(ggplot2)
library(plotly)
library(dplyr)

source("../shared/regression.R")

# Sample data
data <- data.frame(
  x = 1:30,
  y = 2 * (1:30) + rnorm(30, 0, 5)
)

ui <- fluidPage(
  titlePanel("Lab 03: Regression Diagnostics Dashboard"),
  sidebarLayout(
    sidebarPanel(
      h4("Model Controls"),
      sliderInput("degree", "Polynomial Degree",
                  min = 1, max = 10, value = 2, step = 1)
    ),
    mainPanel(
      fluidRow(
        column(6, plotlyOutput("plot_regression")),
        column(6, plotlyOutput("plot_residuals"))
      ),
      fluidRow(
        column(12, plotlyOutput("plot_qq"))
      )
    )
  )
)

server <- function(input, output, session) {

  model_data <- reactive({
    model <- lm(y ~ poly(x, degree = input$degree), data = data)
    data.frame(
      x = data$x,
      y = data$y,
      fitted = fitted(model),
      residual = residuals(model)
    )
  })

  output$plot_regression <- renderPlotly({
    df <- model_data()
    p <- ggplot(df, aes(x = x, y = y)) +
      geom_point(size = 2, alpha = 0.6) +
      geom_line(aes(y = fitted), color = "red") +
      theme_minimal() +
      labs(title = "Fitted Regression", x = "X", y = "Y")
    ggplotly(p)
  })

  output$plot_residuals <- renderPlotly({
    df <- model_data()
    p <- ggplot(df, aes(x = fitted, y = residual)) +
      geom_point(size = 2, alpha = 0.6) +
      geom_hline(yintercept = 0, color = "red", linetype = "dashed") +
      theme_minimal() +
      labs(title = "Residuals vs Fitted", x = "Fitted Values", y = "Residuals")
    ggplotly(p)
  })

  output$plot_qq <- renderPlotly({
    df <- model_data()
    p <- ggplot(df, aes(sample = residual)) +
      geom_qq() +
      geom_qq_line() +
      theme_minimal() +
      labs(title = "Q-Q Plot", x = "Theoretical", y = "Sample")
    ggplotly(p)
  })
}

shinyApp(ui, server)
