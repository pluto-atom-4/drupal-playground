# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Vision

This is a **Decoupled Visualization Platform** bridging Drupal (content management and authentication) with R Shiny (interactive data science applications) for Harvard CS109 (Introduction to Data Science). The platform transforms static course content into interactive labs where students explore machine learning concepts through responsive interfaces directly connected to computational models.

**Core Thesis**: Reactive computation where slider movements, degree selections, and file uploads instantly trigger model re-evaluation with live visualization updates—creating a playground for understanding overfitting, regularization, and prediction error through direct experimentation.

## System Architecture

### Drupal (The Host Layer)
- **Content Management**: Lab Exercise custom content type with Paragraphs module for flexible layouts
- **Authentication**: SimpleSAMLphp or OpenID Connect for enrollment verification
- **Layout & Theming**: Bootstrap 5 framework; Asset Injector module for dynamic CSS/JS injection per lab node
- **Deployment Pattern**: "Progressively Decoupled"—Drupal renders navigation/breadcrumbs/sidebar; R Shiny app embedded via iframe or custom React/Vue component calling an R API backend

### R Shiny (The Analytical Engine)
- **Reactive Framework**: Inputs (sliders, degree selectors, file uploads) → reactive() expressions → renderPlotly() outputs
- **Libraries**:
  - `shiny`: Reactive UI and server-side logic
  - `ggplot2`: Static-quality plots
  - `plotly`: Interactive features (hover tooltips, zooming, linked visualizations)
  - `dplyr`, `tidyr`: Data wrangling (filtering, reshaping, grouping)
  - `readr`: Safe CSV import with validation
  - `purrr`: Functional programming for batch processing (map, map_df)
- **Compute Pattern**: lm() and poly() for regression models; cache expensive computations with bindCache()
- **Deployment**: Shiny Server (self-hosted) or shinyapps.io; stateful R processes per student session

### Bridge: Progressive Decoupling
- **Primary**: Iframe embedding with iframe-resizer for responsive sizing
- **Alternative**: React/Vue component making REST API calls to a Plumber R API (if tighter Drupal integration needed)
- **Session Isolation**: Drupal verifies enrollment before rendering iframe; R Shiny maintains its own session state

## Core Algorithms & Reactive Patterns

### Phase 2: Regression Models
The heart of the interactive labs. Each maps a student input action to a model update.

#### Linear Regression
```r
linear_regression <- function(x, y) {
  model <- lm(y ~ x)
  list(
    intercept = coef(model)[1],
    slope = coef(model)[2],
    r_squared = summary(model)$r.squared,
    rmse = sqrt(mean(residuals(model)^2))
  )
}
```
**Reactive Pattern**:
- Input: Slider to exclude outliers or filter data
- Trigger: reactive({filtered_data()}) updates when user adjusts filter
- Output: renderPlotly(~) redraws scatter + regression line + slope/intercept in sidebar "scorecard"

#### Polynomial Regression (1–10 degrees)
```r
polynomial_regression <- function(x, y, degree = 2) {
  model <- lm(y ~ poly(x, degree = degree))
  list(
    coefficients = coef(model),
    r_squared = summary(model)$r.squared,
    rmse = sqrt(mean(residuals(model)^2)),
    aic = AIC(model)
  )
}
```
**Reactive Pattern**:
- Input: Slider for polynomial degree (1–10)
- Trigger: reactive({poly_regression(data$x, data$y, input$degree)})
- Output: Smooth curve fit overlaid on scatter plot; scorecard shows R², RMSE, AIC—**teaching moment**: students observe AIC increase as degree → 10, revealing overfitting trade-off

#### Metrics Calculation
```r
calculate_metrics <- function(y_true, y_pred) {
  ss_res <- sum((y_true - y_pred)^2)
  ss_tot <- sum((y_true - mean(y_true))^2)
  r_squared <- 1 - (ss_res / ss_tot)
  rmse <- sqrt(mean((y_true - y_pred)^2))
  list(
    r_squared = r_squared,
    rmse = rmse,
    aic = AIC(lm(y_true ~ y_pred))
  )
}
```
**UI Rendering**: Real-time "Scorecard" block in sidebar (tidyverse-styled boxes with live values)

### Phase 3: Batch Processing & Linked Visualizations

#### Batch Regression Over Multiple Columns
```r
batch_process_regressions <- function(data, target_col) {
  purrr::map_df(
    names(data)[-which(names(data) == target_col)],
    ~ {
      model <- lm(reformulate(., response = target_col), data = data)
      tibble(
        predictor = .,
        r_squared = summary(model)$r.squared,
        rmse = sqrt(mean(residuals(model)^2))
      )
    }
  )
}
```
**UX Integration**:
- File upload (CSV) → withProgress() bar shows "Processing columns 1/15…"
- Results displayed as interactive Plotly bar chart: predictor on x-axis, R² on y-axis
- **Linked visualization**: Click a bar → main scatter plot updates to show that predictor vs target

#### Residual Diagnostics Dashboard
Three panels with linked hover:
1. **Regression Plot**: Scatter points (color-coded by row) + fitted line
2. **Residual Plot**: Residuals vs predicted values (highlight outliers)
3. **Q-Q Plot**: Normality check (identify non-normal error distributions)

**Linking Logic**: Clicking/hovering on a point in any panel highlights the same observation in all three plots (using Plotly's key/color mappings).

### Phase 4: Caching Strategy

**Common Computations** (cache these—students often select degrees 1–3):
```r
reactive({
  bindCache(
    expr = polynomial_regression(data$x, data$y, input$degree),
    input$degree,  # Cache key: invalidate when degree changes
    cache = cachedDataStore
  )
})
```

**Never Cache**: User-uploaded CSV data (always recompute once file is set; use req(input$file) to guard)

## Development Phases & Milestones

### Phase 1: Architecture & UI Foundations
**Objective**: Seamless Drupal-to-Shiny bridge with unified styling.

**Deliverables**:
- Drupal: Lab Exercise content type + Asset Injector module setup
- R Shiny: fluidPage() skeleton with sidebarLayout (sidebar = controls, main = plots)
- Bootstrap 5 CSS aligned in both systems (Harvard brand: crimson + white + gray)
- Iframe embedding working with responsive sizing
- DDEV environment for Drupal + RStudio Desktop for Shiny (teaching staff standardization)

**Commands**:
```bash
# Drupal setup (assuming DDEV)
ddev composer install
ddev drush install

# Shiny local dev
Rscript -e "shiny::runApp('shiny-apps/lab-01')"
```

### Phase 2: Translating Analytical Requirements
**Objective**: Interactive regression labs working (linear + polynomial).

**Deliverables**:
- `shiny-apps/lab-01-regression/app.R`: Linear + polynomial regression with sliders
  - Degree slider (1–10) with reactive curve updates
  - Sidebar scorecard: R², RMSE, AIC updated in real-time
  - Hover tooltips on points showing (x, y, residual)
  - Sample dataset (e.g., Anscombe's quartet or Boston housing subset)
- shinytest2 tests for slider interactions
- Drupal node embedding the iframe

**User Story Example**:
> "As a CS109 student, I want to increase the polynomial degree and see how the fitted curve changes and the metrics (R², AIC) shift, helping me understand the overfitting-bias trade-off."

### Phase 3: Data-Intensive Integration
**Objective**: Batch processing and linked visualizations.

**Deliverables**:
- File upload widget (CSV parsing with readr, validation with req/validate)
- Batch regression: iterate over all columns against a selected target
- withProgress() bar showing real-time progress
- Dashboard: 3 panels (Regression, Residuals, Q-Q) with linked Plotly interactivity
- Error "Validation Log" panel showing helpful error messages (e.g., "Column 'age' contains non-numeric values")

**Metrics Displayed**:
- Per-predictor: R², RMSE
- Overall: Residual summary (mean, std dev, outlier flags)
- Model diagnostics: Normality (Shapiro-Wilk), heteroscedasticity warning

### Phase 4: Reliability & Security
**Objective**: Production-ready deployment for 1000+ concurrent students.

**Deliverables**:
- **Caching**: bindCache() applied to degrees 1–10 polynomial regressions; test cache hit rate with ShinyManager
- **Input Validation**: readr::spec_csv() with strict type checking; validate() guards in UI
- **Authentication**: Drupal SimpleSAMLphp integration; enrollment check before iframe renders
- **Logging**: ShinyManager dashboard for usage metrics; Drupal audit log for enrollment access
- **Session Management**: R process limits per container; graceful session timeout after 2 hours of inactivity
- **Performance Monitoring**: Server-side timing logs for model computations; alert if mean regression time > 500ms

## Directory Structure (Planned)

```
drupal-playground/
├── CLAUDE.md                      # This file
├── docker-compose.yml             # Local dev: Drupal (port 8080) + R Shiny (port 3838) + PostgreSQL
├── ddev-config.yaml               # DDEV Drupal configuration
├── docs/
│   └── start-from-here.md         # Architectural plan (source of truth)
├── drupal-site/
│   ├── composer.json              # Drupal dependencies (Paragraphs, Asset Injector, SimpleSAMLphp)
│   ├── web/
│   │   ├── modules/custom/
│   │   │   └── cs109_labs/        # Custom module: Lab Exercise content type + iframe embedding
│   │   │       ├── cs109_labs.module
│   │   │       ├── src/
│   │   │       │   └── Plugin/Block/LabEmbedBlock.php
│   │   │       └── config/install/
│   │   │           └── node.type.lab_exercise.yml
│   │   ├── themes/custom/
│   │   │   └── harvard_crimson/   # Theme: Bootstrap 5 + Harvard brand colors
│   │   │       ├── css/
│   │   │       ├── templates/
│   │   │       └── theme.info.yml
│   │   └── profiles/
│   └── docroot/                   # Drupal root
└── shiny-apps/
    ├── shared/                    # Shared R utilities
    │   ├── regression.R           # linear_regression(), polynomial_regression()
    │   ├── metrics.R              # calculate_metrics()
    │   └── plotting.R             # ggplot + plotly helpers
    ├── lab-01-simple-regression/
    │   ├── app.R                  # UI + server (linear + polynomial regression)
    │   ├── data/
    │   │   └── sample.csv         # Anscombe's quartet or Boston housing subset
    │   └── tests/
    │       └── test-sliders.R     # shinytest2: degree slider interaction
    ├── lab-02-batch-analysis/
    │   ├── app.R                  # File upload + batch processing
    │   ├── functions/
    │   │   ├── batch_process.R    # purrr::map_df() implementation
    │   │   └── validation.R       # readr + validate() guards
    │   └── tests/
    │       └── test-upload.R      # shinytest2: CSV upload workflow
    └── lab-03-diagnostics/
        ├── app.R                  # 3-panel dashboard with linked Plotly
        └── www/
            └── css/
                └── custom.css     # Harvard styling overrides
```

## Tech Stack & Commands

### Development Environment Setup
```bash
# Drupal setup (DDEV)
ddev auth ssh
ddev start
ddev composer install
ddev drush install
ddev exec drush pm-install paragraphs asset_injector

# R Shiny setup (RStudio Desktop)
# Open RStudio, create project in shiny-apps/lab-01
# Install dependencies via console: install.packages(c('shiny', 'ggplot2', 'plotly', 'dplyr', 'tidyr', 'readr', 'purrr'))
```

### Running Locally
```bash
# Terminal 1: Drupal on http://localhost:8080
ddev start

# Terminal 2: Shiny dev server on http://localhost:3838
cd shiny-apps/lab-01-simple-regression
Rscript -e "shiny::runApp()"
```

### Docker (Parity with Production)
```bash
docker-compose up -d
# Drupal: http://localhost:8080
# Shiny 1: http://localhost:3838/lab-01-simple-regression
# Shiny 2: http://localhost:3838/lab-02-batch-analysis
```

### Linting & Code Quality
```bash
# Drupal: PHP CodeSniffer
phpcs --standard=Drupal web/modules/custom/cs109_labs

# R: styler + lintr
R -e "styler::style_dir('shiny-apps')"
R -e "lintr::lint_dir('shiny-apps')"
```

### Testing
```bash
# Drupal: PHPUnit
./vendor/bin/phpunit --bootstrap=web/autoload.php web/modules/custom/cs109_labs

# R Shiny: shinytest2
cd shiny-apps/lab-01-simple-regression
R -e "shinytest2::test_app()"
```

### Deployment
```bash
# Build Docker images
docker build -t drupal-cs109:latest ./drupal-site
docker build -t shiny-cs109:latest ./shiny-apps

# Push to registry and deploy to production
# (Assumes docker-compose or Kubernetes orchestration)
```

## Key Architectural Decisions

### Why Progressively Decoupled (Drupal + Iframe)?
- **Separation of concerns**: Drupal owns content + auth; Shiny owns computation + UI responsiveness
- **Development velocity**: Drupal and Shiny teams can work independently; minimal API contract
- **Maintenance**: Updating a lab doesn't risk breaking Drupal navigation or authentication
- **Trade-off**: Cross-window communication requires postMessage() if real-time sync needed; iframe-resizer handles sizing elegantly

### Why Reactive Programming (Shiny)?
- **Direct mapping**: A slider change → reactive() invalidates → renderPlotly() reruns—matches the "instant feedback" expectation of a lab environment
- **Simplicity**: No REST endpoints, polling, or client-side state management
- **Teaching clarity**: Students see input → computation → output in real-time, understanding causality
- **Trade-off**: Shiny requires understanding R reactivity; stateful processes consume memory if many students run simultaneously (mitigate with caching + container limits)

### Why R (Not Python/JavaScript)?
- **Continuity**: Students already learned R in CS109
- **Statistical libraries**: lm(), poly(), AIC() are battle-tested for teaching
- **Data wrangling**: dplyr is simpler than pandas for course-level analysis
- **Trade-off**: R memory footprint; mitigate with bindCache() and horizontal scaling

### Why Polynomial Regression (Not More Complex Models)?
- **Conceptual focus**: Polynomial degree elegantly teaches overfitting (degree 1 = underfitting, degree 10 = overfitting)
- **Computational simplicity**: lm() with poly() is fast; no hyperparameter tuning needed
- **Visualization clarity**: Smooth curves are intuitive to interpret
- **Future**: Batch processing (Phase 3) sets foundation for logistic regression, cross-validation labs in subsequent courses

## Implementation Mapping: Algorithm → UI

| Algorithm | Return Values | UI Component | Interactive Feature |
|-----------|---------------|--------------|---------------------|
| `linear_regression(x, y)` | {intercept, slope, R², RMSE} | Scatter + line overlay | Slope tooltip on hover |
| `polynomial_regression(x, y, degree)` | {coeffs, R², RMSE, AIC} | Smooth curve fit | Degree slider (1–10) with live redraw |
| `calculate_metrics(y_true, y_pred)` | {R², RMSE, AIC} | Sidebar scorecard boxes | Auto-update when model changes |
| `batch_process_regressions(data, target)` | tibble(predictor, R², RMSE) | Bar chart (predictor × R²) | Click bar → main plot updates |
| Residual diagnostics | {residuals, fitted, q-q stats} | 3-panel dashboard (Regression, Residuals, Q-Q) | Linked hover/click highlighting |

## Common Development Workflows

### Adding a New Lab Module
1. Create directory: `shiny-apps/lab-NN-NAME/`
2. Write `app.R` using Phase 2 or 3 patterns (e.g., reactive regression + plotly)
3. Copy sample data to `data/` directory
4. Add shinytest2 tests in `tests/`
5. Create Drupal Lab Exercise node with iframe: `http://shiny.internal:3838/lab-NN-NAME`
6. Test in DDEV: verify enrollment check passes, iframe renders

### Updating an Algorithm
1. Edit `shiny-apps/shared/regression.R` (or relevant module)
2. Update the reactive expression in `app.R` if signature changed
3. Run `R -e "shinytest2::test_app()"` to validate tests still pass
4. Update the Implementation Mapping table in CLAUDE.md
5. Commit with message: "Update polynomial regression to use orthogonal poly()"

### Performance Debugging
1. Check ShinyManager dashboard for slow sessions
2. Profile R code: wrap computations with `system.time()`
3. Review Plotly render time in browser DevTools
4. Enable bindCache() if computation is reused across students
5. Monitor DataFrame size: if > 100k rows, implement pagination in Plotly

### Enrollment Verification Issues
1. Check Drupal SimpleSAMLphp configuration: `drush config-get samlauth.authentication`
2. Review browser console for iframe loading errors
3. Verify enrollment API endpoint returns expected claims
4. Test with a known student account; check Drupal audit log

## Deployment & Scaling

**Development**: DDEV + RStudio (single developer machine)

**Staging**: Docker Compose with persistent PostgreSQL; mount volumes for live code reload

**Production**:
- Drupal: Kubernetes StatefulSet (PostgreSQL) + Deployment (PHP-FPM)
- R Shiny: Kubernetes Deployment with session affinity (sticky pods); each lab is a separate service
- Load Balancer: Nginx ingress; URL routing `/lab-01/*` → shiny-lab-01 service
- Monitoring: Prometheus + Grafana (Drupal endpoint latency, Shiny session count); ShinyManager for app-level metrics
- Caching layer: Redis for bindCache() backend (optional, in-memory is fine for < 500 students)

## Security Checklist

- [ ] Drupal SimpleSAMLphp or OIDC configured; enrollment verified before iframe renders
- [ ] R Shiny input validation: req(), validate(), readr type-checking on CSV uploads
- [ ] Rate limiting on file upload: max 50MB per student, max 1 upload/minute
- [ ] Session timeout: 2 hours of inactivity
- [ ] Logging: All model computations timestamped and attributed to authenticated student
- [ ] No hardcoded secrets in code; use environment variables (Docker secret mounts)
- [ ] HTTPS enforced; CSP headers set; iframe sandboxing (allow-scripts, allow-same-origin only)

## References & Resources

- **Shiny**: https://shiny.rstudio.com/articles/
- **ggplot2 + Plotly**: https://plotly.com/ggplot2/
- **dplyr**: https://dplyr.tidyverse.org/
- **purrr**: https://purrr.tidyverse.org/
- **readr**: https://readr.tidyverse.org/
- **shinytest2**: https://rstudio.github.io/shinytest2/
- **Drupal Paragraphs**: https://www.drupal.org/project/paragraphs
- **Drupal Asset Injector**: https://www.drupal.org/project/asset_injector
- **DDEV**: https://ddev.readthedocs.io/
- **Source Plan**: `docs/start-from-here.md`
