# Lab 01: Interactive Polynomial Regression Explorer

An interactive Shiny application for exploring polynomial regression and the bias-variance tradeoff.

## Learning Objectives

After completing this lab, you should understand:

- ✅ How to fit polynomial models to data using `lm()` and `poly()`
- ✅ How polynomial degree affects model complexity and fit quality
- ✅ The bias-variance tradeoff and overfitting
- ✅ How to interpret R², RMSE, and AIC metrics
- ✅ Why simpler models often generalize better to new data

## How to Use

### Run Locally

```bash
unset DOCKER_HOST
cd shiny-apps/lab-01-simple-regression
Rscript -e "shiny::runApp()"
```

Then open: http://localhost:3838

### Interactive Controls

- **Polynomial Degree Slider** (1-10): Adjust the complexity of the polynomial fit
- **Real-time Metrics**: Watch R², RMSE, and AIC update as you change the degree
- **Interactive Plot**: Hover over points to see (x, y, residual) values; zoom and pan with mouse

### What to Observe

1. **Degree 1 (Linear)**
   - Simplest model
   - Likely underfitting (low R²)
   - Straight line fit

2. **Degrees 2-4**
   - Better fit as degree increases
   - R² improves, RMSE decreases
   - Still interpretable

3. **Degrees 7-10**
   - Near-perfect fit on training data
   - BUT: AIC warns about complexity
   - Likely to overfit on new data
   - Watch for "wiggly" curves that don't make sense

## Metrics Explained

### R² (Coefficient of Determination)
- **Range**: 0 to 1 (higher is better)
- **Meaning**: Fraction of variance in y explained by x
- **Interpretation**: R² = 0.9 means 90% of variance explained
- **Caveat**: Can increase artificially with higher degree

### RMSE (Root Mean Squared Error)
- **Unit**: Same as y variable
- **Meaning**: Average prediction error on training data
- **Interpretation**: RMSE = 2.5 means typical prediction off by 2.5 units
- **Caveat**: Decreases with overfitting; use on validation data to detect it

### AIC (Akaike Information Criterion)
- **Range**: Lower is better (no upper limit)
- **Meaning**: Balances model fit with complexity penalty
- **Interpretation**: Penalizes unnecessary parameters
- **Benefit**: Helps select optimal degree without manual tuning

## Data

The lab uses a semi-synthetic dataset:
- **X**: 50 evenly spaced points from 0 to 10
- **Y**: Generated as: `y = 2x + 0.5x² + noise`
- **Noise**: Normal distribution (μ=0, σ=5)

File: `data/sample.csv`

## Files

```
lab-01-simple-regression/
├── app.R                    # Main Shiny application
├── README.md               # This file
├── data/
│   └── sample.csv          # Sample dataset
└── tests/
    └── testthat/
        └── test-lab-01.R   # Automated tests
```

## Testing

Run automated tests:

```bash
cd shiny-apps/lab-01-simple-regression
R -e "shinytest2::test_app()"
```

Tests verify:
- ✅ App loads without errors
- ✅ Slider updates plots
- ✅ Metrics update correctly
- ✅ R² increases with model complexity
- ✅ UI elements are responsive

## Key Takeaways

1. **More parameters ≠ better model**: Higher degree doesn't always mean better generalization
2. **Use validation data**: Test on separate data to detect overfitting
3. **Balance complexity**: AIC helps balance fit quality with model simplicity
4. **Understand tradeoffs**: Every model represents a bias-variance tradeoff

## Further Reading

- [Polynomial Regression (Wikipedia)](https://en.wikipedia.org/wiki/Polynomial_regression)
- [Overfitting and Underfitting (Wikipedia)](https://en.wikipedia.org/wiki/Overfitting)
- [Akaike Information Criterion (Wikipedia)](https://en.wikipedia.org/wiki/Akaike_information_criterion)
- [An Introduction to Statistical Learning (ISLR)](https://www.statlearning.com/)

## Technical Details

### Stack
- **Shiny**: Interactive web framework for R
- **ggplot2**: Static plots
- **plotly**: Interactive visualization with hover/zoom
- **dplyr**: Data manipulation

### Browser Compatibility
- Chrome, Firefox, Safari, Edge (latest versions)
- Mobile browsers supported but optimized for desktop

### Performance
- Data size: 50 points → near-instant computation
- Plot rendering: < 500ms (Plotly)
- Reactive updates: < 1 second

## Authors

Created for CS109: Introduction to Data Science

## License

MIT
