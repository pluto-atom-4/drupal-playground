# Lab 02: Batch Analysis
# CSV upload and batch regression processing

library(shiny)
library(ggplot2)
library(plotly)
library(dplyr)
library(readr)
library(purrr)

source("../shared/regression.R")

ui <- fluidPage(
  titlePanel("Lab 02: Batch Regression Analysis"),
  sidebarLayout(
    sidebarPanel(
      h4("Data Upload"),
      fileInput("file", "Upload CSV", accept = ".csv"),
      selectInput("target", "Target Variable", choices = NULL),
      br(),
      h4("Processing"),
      actionButton("process", "Run Analysis", class = "btn-primary"),
      uiOutput("progress_ui")
    ),
    mainPanel(
      uiOutput("results_ui")
    )
  )
)

server <- function(input, output, session) {

  data <- reactive({
    req(input$file)
    read_csv(input$file$datapath)
  })

  # Update target variable choices
  observe({
    df <- data()
    updateSelectInput(session, "target",
                      choices = names(df),
                      selected = names(df)[1])
  })

  # Placeholder for batch processing results
  output$results_ui <- renderUI({
    p("Upload a CSV file to begin analysis.")
  })
}

shinyApp(ui, server)
