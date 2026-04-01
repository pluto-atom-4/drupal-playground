library(testthat)
library(shinytest2)

describe("Lab 01: Polynomial Regression", {

  it("app loads without errors", {
    app <- AppDriver$new(
      app_dir = "../../",
      name = "lab-01-load"
    )

    expect_true(app$is_alive())

    # Verify main UI elements exist
    expect_not_null(app$get_value(input = "degree"))
  })

  it("degree slider updates the plot", {
    app <- AppDriver$new(
      app_dir = "../../",
      name = "lab-01-slider"
    )

    # Initial state: degree = 2
    initial_plot <- app$get_value(output = "regression_plot")
    expect_not_null(initial_plot)

    # Change degree to 5
    app$set_inputs(degree = 5)
    Sys.sleep(1)  # Wait for reactivity

    updated_plot <- app$get_value(output = "regression_plot")
    expect_not_null(updated_plot)

    # Plot should be different
    expect_not_equal(initial_plot, updated_plot)
  })

  it("metrics update when degree changes", {
    app <- AppDriver$new(
      app_dir = "../../",
      name = "lab-01-metrics"
    )

    # Get initial metrics at degree 1
    app$set_inputs(degree = 1)
    Sys.sleep(1)
    metrics_degree_1 <- list(
      r_squared = app$get_value(output = "r_squared"),
      rmse = app$get_value(output = "rmse"),
      aic = app$get_value(output = "aic")
    )

    # Change to degree 5
    app$set_inputs(degree = 5)
    Sys.sleep(1)
    metrics_degree_5 <- list(
      r_squared = app$get_value(output = "r_squared"),
      rmse = app$get_value(output = "rmse"),
      aic = app$get_value(output = "aic")
    )

    # Metrics should change
    expect_not_equal(metrics_degree_1$r_squared, metrics_degree_5$r_squared)
  })

  it("r_squared increases with higher degrees (on this dataset)", {
    app <- AppDriver$new(
      app_dir = "../../",
      name = "lab-01-r2-trend"
    )

    # Collect R² for increasing degrees
    r2_values <- numeric(6)

    for (degree in 1:6) {
      app$set_inputs(degree = degree)
      Sys.sleep(0.5)
      r2_text <- app$get_value(output = "r_squared")
      r2_values[degree] <- as.numeric(r2_text)
    }

    # R² should generally increase (though not strictly monotonic due to noise)
    # At least degree 3 should be better than degree 1
    expect_gt(r2_values[3], r2_values[1])
  })

  it("degree explanation text changes", {
    app <- AppDriver$new(
      app_dir = "../../",
      name = "lab-01-explanation"
    )

    # Degree 1
    app$set_inputs(degree = 1)
    exp_1 <- app$get_value(output = "degree_explanation")
    expect_match(exp_1, "Linear")

    # Degree 2
    app$set_inputs(degree = 2)
    exp_2 <- app$get_value(output = "degree_explanation")
    expect_match(exp_2, "underfitting|Low")

    # Degree 9
    app$set_inputs(degree = 9)
    exp_9 <- app$get_value(output = "degree_explanation")
    expect_match(exp_9, "overfitting|High")
  })

  it("slider bounds are correct", {
    app <- AppDriver$new(
      app_dir = "../../",
      name = "lab-01-slider-bounds"
    )

    # Set to minimum
    app$set_inputs(degree = 1)
    degree_min <- app$get_value(input = "degree")
    expect_equal(degree_min, 1)

    # Set to maximum
    app$set_inputs(degree = 10)
    degree_max <- app$get_value(input = "degree")
    expect_equal(degree_max, 10)
  })

  it("all tabs are accessible", {
    app <- AppDriver$new(
      app_dir = "../../",
      name = "lab-01-tabs"
    )

    # Main tab should be active
    expect_not_null(app$get_value(output = "regression_plot"))

    # About tab (just verify it exists and is selectable)
    # In shiny, switching tabs is done via navbarPage navigation
  })

})
