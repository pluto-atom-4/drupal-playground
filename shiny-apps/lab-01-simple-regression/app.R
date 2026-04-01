# Lab 01: Interactive Polynomial Regression Explorer
# CS109 Introduction to Data Science
#
# Learn about overfitting and model complexity by adjusting polynomial degree
# in real-time and observing how metrics change.

library(shiny)
library(ggplot2)
library(plotly)
library(dplyr)

# Load shared regression functions
source("../shared/regression.R")

# Generate sample data: y = 2x + noise, with some nonlinearity
set.seed(42)
n <- 50
data <- data.frame(
  x = seq(0, 10, length.out = n),
  y = 2 * seq(0, 10, length.out = n) + 0.5 * (seq(0, 10, length.out = n))^2 + rnorm(n, 0, 5)
)

# UI Definition ================================================================
ui <- fluidPage(
  # CSS for Harvard colors and styling
  tags$style(HTML("
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background-color: #f5f5f5;
    }
    .navbar { background-color: #A51C30; }
    .container-fluid {
      background-color: #ffffff;
      border-radius: 4px;
      box-shadow: 0 1px 3px rgba(0,0,0,0.1);
    }
    h1, h2, h3, h4 {
      color: #333333;
      font-weight: 600;
    }
    .metric-box {
      background-color: #f9f9f9;
      border-left: 4px solid #A51C30;
      padding: 12px 16px;
      margin: 8px 0;
      border-radius: 2px;
      font-family: 'Courier New', monospace;
    }
    .metric-label {
      color: #666666;
      font-size: 12px;
      text-transform: uppercase;
      font-weight: 600;
      letter-spacing: 0.5px;
    }
    .metric-value {
      color: #A51C30;
      font-size: 18px;
      font-weight: 700;
      margin-top: 4px;
    }
    .slider-container {
      background-color: #f9f9f9;
      padding: 16px;
      border-radius: 4px;
      margin-bottom: 16px;
    }
    .instruction-text {
      color: #666666;
      font-size: 13px;
      line-height: 1.6;
      margin-bottom: 12px;
    }
  ")),

  # Navigation bar
  navbarPage(
    title = "CS109 Labs",
    theme = bslib::bs_theme(primary = "#A51C30"),

    # Lab 01 tab
    tabPanel(
      "Lab 01: Polynomial Regression",

      sidebarLayout(
        # Sidebar: Controls
        sidebarPanel(
          width = 4,

          h3("Interactive Controls"),

          div(class = "instruction-text",
              "Adjust the polynomial degree to explore how model complexity affects overfitting."),

          div(class = "slider-container",
              sliderInput(
                inputId = "degree",
                label = "Polynomial Degree",
                min = 1,
                max = 10,
                value = 2,
                step = 1,
                width = "100%"
              ),
              p(textOutput("degree_explanation"),
                style = "font-size: 12px; color: #666666; margin-top: 8px;")
          ),

          hr(),

          h4("Model Metrics"),
          p("Updated in real-time as you adjust the degree:", style = "font-size: 12px; color: #666666;"),

          div(class = "metric-box",
              div(class = "metric-label", "R² (Coefficient of Determination)"),
              div(class = "metric-value", textOutput("r_squared")),
              p("Higher = better fit (max 1.0). Watch for overfitting!", style = "font-size: 11px; color: #999999; margin-top: 8px;")
          ),

          div(class = "metric-box",
              div(class = "metric-label", "RMSE (Root Mean Squared Error)"),
              div(class = "metric-value", textOutput("rmse")),
              p("Lower = smaller prediction errors.", style = "font-size: 11px; color: #999999; margin-top: 8px;")
          ),

          div(class = "metric-box",
              div(class = "metric-label", "AIC (Akaike Information Criterion)"),
              div(class = "metric-value", textOutput("aic")),
              p("Lower = better balance of fit and complexity.", style = "font-size: 11px; color: #999999; margin-top: 8px;")
          ),

          hr(),

          h4("Learning Objectives"),
          tags$ul(
            tags$li("Understand how polynomial degree affects model fit"),
            tags$li("Recognize overfitting (high degree = worse generalization)"),
            tags$li("Learn to balance bias-variance tradeoff"),
            tags$li("Use AIC to select optimal model complexity"),
            style = "font-size: 12px; color: #666666;"
          )
        ),

        # Main panel: Visualization
        mainPanel(
          width = 8,

          h2("Interactive Regression Visualization"),

          p("The red curve shows the polynomial fit. Hover over points to see (x, y, residual) values.",
            style = "color: #666666; font-size: 13px; margin-bottom: 16px;"),

          plotlyOutput("regression_plot", height = "600px"),

          hr(),

          h4("How to Use This Lab"),
          tags$ul(
            tags$li(strong("Start with degree 1:"), "Linear regression. Observe the R² and RMSE."),
            tags$li(strong("Increase to degree 2-3:"), "The fit improves. R² increases, RMSE decreases."),
            tags$li(strong("Jump to degree 9-10:"), "Perfect fit! But AIC warns about overfitting."),
            tags$li(strong("Think about:"), "Why does higher degree sometimes perform worse on new data?"),
            style = "font-size: 13px; color: #333333; line-height: 1.8;"
          )
        )
      )
    ),

    # About tab
    tabPanel(
      "About",
      div(
        style = "padding: 20px; max-width: 600px;",
        h3("About This Lab"),
        p("This interactive lab demonstrates polynomial regression and the bias-variance tradeoff,
          two key concepts in machine learning and statistical modeling."),

        h4("What You'll Learn"),
        tags$ul(
          tags$li("How to fit polynomial models to data"),
          tags$li("Why higher-degree polynomials don't always generalize better"),
          tags$li("How to use metrics (R², RMSE, AIC) to evaluate models"),
          tags$li("The importance of model simplicity and interpretability")
        ),

        h4("Technical Details"),
        tags$ul(
          tags$li("Models fitted using R's lm() function with poly(x, degree)"),
          tags$li("R² = 1 - (SS_res / SS_tot) — fraction of variance explained"),
          tags$li("RMSE = √(mean squared residuals) — average prediction error"),
          tags$li("AIC = 2k + n·ln(SS_res/n) — balances fit and complexity")
        ),

        h4("Further Reading"),
        tags$ul(
          tags$li(a("Overfitting and Underfitting", href = "https://en.wikipedia.org/wiki/Overfitting", target = "_blank")),
          tags$li(a("Polynomial Regression", href = "https://en.wikipedia.org/wiki/Polynomial_regression", target = "_blank")),
          tags$li(a("Akaike Information Criterion", href = "https://en.wikipedia.org/wiki/Akaike_information_criterion", target = "_blank"))
        )
      )
    )
  )
)

# Server Logic =================================================================
server <- function(input, output, session) {

  # Reactive: fit polynomial model based on degree
  fitted_model <- reactive({
    degree <- input$degree
    lm(y ~ poly(x, degree = degree), data = data)
  })

  # Reactive: get predictions and residuals
  model_data <- reactive({
    model <- fitted_model()
    data %>%
      mutate(
        fitted = fitted(model),
        residual = residuals(model)
      ) %>%
      arrange(x)  # Ensure sorted by x for smooth line rendering
  })

  # Reactive: calculate metrics
  metrics <- reactive({
    model <- fitted_model()
    df <- model_data()

    r_squared <- summary(model)$r.squared
    rmse <- sqrt(mean(residuals(model)^2))
    aic <- AIC(model)

    list(
      r_squared = r_squared,
      rmse = rmse,
      aic = aic
    )
  })

  # Output: Degree explanation
  output$degree_explanation <- renderText({
    degree <- input$degree
    if (degree == 1) {
      "Degree 1: Linear regression (straight line)"
    } else if (degree <= 3) {
      sprintf("Degree %d: Low complexity, likely underfitting", degree)
    } else if (degree <= 6) {
      sprintf("Degree %d: Moderate complexity, reasonable fit", degree)
    } else {
      sprintf("Degree %d: High complexity, watch for overfitting!", degree)
    }
  })

  # Output: Metrics display
  output$r_squared <- renderText({
    sprintf("%.4f", metrics()$r_squared)
  })

  output$rmse <- renderText({
    sprintf("%.4f", metrics()$rmse)
  })

  output$aic <- renderText({
    sprintf("%.2f", metrics()$aic)
  })

  # Output: Main plot
  output$regression_plot <- renderPlotly({
    df <- model_data()
    degree <- input$degree

    # Create fitted data for line with explicit ordering
    fitted_df <- df %>%
      select(x, fitted) %>%
      arrange(x)

    # Create base ggplot
    p <- ggplot(df, aes(x = x, y = y)) +
      # Scatter points
      geom_point(
        aes(text = sprintf("x: %.2f<br>y: %.2f<br>residual: %.2f", x, y, residual)),
        size = 3,
        alpha = 0.6,
        color = "#666666"
      ) +
      # Fitted line - use explicit data frame
      geom_line(
        data = fitted_df,
        aes(x = x, y = fitted),
        color = "#A51C30",
        size = 1,
        linetype = "solid",
        inherit.aes = FALSE
      ) +
      # Residual ribbons (subtle)
      geom_segment(
        aes(xend = x, yend = fitted),
        color = "#CCCCCC",
        alpha = 0.3,
        linetype = "dashed",
        size = 0.3
      ) +
      # Theme
      theme_minimal() +
      theme(
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(color = "#EEEEEE"),
        axis.title = element_text(size = 12, color = "#333333"),
        axis.text = element_text(size = 11, color = "#666666"),
        plot.title = element_text(size = 14, face = "bold", color = "#333333", margin = margin(b = 10))
      ) +
      labs(
        title = sprintf("Polynomial Regression (Degree %d) | R² = %.4f", degree, metrics()$r_squared),
        x = "x",
        y = "y",
        caption = "Red line: fitted model | Gray dashes: residuals"
      )

    # Convert to plotly with custom tooltip
    ggplotly(p, tooltip = "text") %>%
      config(responsive = TRUE) %>%
      layout(
        hoverlabel = list(bgcolor = "#FFFFFF", namelength = -1),
        font = list(family = "sans-serif", color = "#333333")
      )
  })
}

# Run the Shiny app
shinyApp(ui, server)
