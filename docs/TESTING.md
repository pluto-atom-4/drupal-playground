# Testing Strategy & Best Practices

Comprehensive testing approach for Drupal and R Shiny components, covering unit tests, integration tests, and end-to-end testing.

---

## Testing Philosophy

**Goal**: Ship features with confidence. Tests act as living documentation and prevent regressions.

**Principles**:
1. **Test behavior, not implementation** — Test what the user sees, not internal details
2. **Fast feedback loop** — Unit tests run in < 1s; dev shouldn't wait for tests
3. **Pyramid structure**:
   - 🔺 Many unit tests (fast, isolated)
   - △ Some integration tests (moderate speed, realistic)
   - ▽ Few end-to-end tests (slow, fragile)
4. **Test at the boundary** — Validate inputs/outputs where systems interact

---

## R Shiny Testing

### Unit Tests: Pure Functions

**Goal**: Test regression models and metrics in isolation.

**Tools**: Base R + `testthat` package

**Setup**:
```r
# In RStudio console
install.packages("testthat")

# Create test structure
usethis::use_test("regression")  # Creates tests/testthat/test_regression.R
```

**Example test file**: `shiny-apps/tests/testthat/test_regression.R`
```r
library(testthat)

# Load functions
source("../../shared/regression.R")

describe("linear_regression", {
  it("returns correct intercept and slope for known data", {
    x <- c(1, 2, 3, 4, 5)
    y <- c(2, 4, 6, 8, 10)  # y = 2*x (perfect relationship)

    result <- linear_regression(x, y)

    expect_equal(result$intercept, 0, tolerance = 0.001)
    expect_equal(result$slope, 2, tolerance = 0.001)
    expect_equal(result$r_squared, 1, tolerance = 0.001)
  })

  it("handles noisy data correctly", {
    set.seed(42)
    x <- 1:20
    y <- 2*x + rnorm(20, 0, 3)

    result <- linear_regression(x, y)

    expect(result$r_squared > 0.9)
    expect(result$r_squared < 1.0)  # Not perfect due to noise
  })

  it("raises error on mismatched vector lengths", {
    expect_error(linear_regression(c(1, 2), c(1, 2, 3)))
  })
})

describe("polynomial_regression", {
  it("linear degree (1) equals linear_regression", {
    x <- 1:10
    y <- 2*x + rnorm(10, 0, 1)

    poly_result <- polynomial_regression(x, y, degree = 1)
    lin_result <- linear_regression(x, y)

    expect_equal(poly_result$r_squared, lin_result$r_squared, tolerance = 0.001)
  })

  it("higher degrees improve fit on polynomial data", {
    set.seed(42)
    x <- seq(0, 10, 0.5)
    y <- x^2 + rnorm(length(x), 0, 2)  # Quadratic relationship

    r2_degree1 <- polynomial_regression(x, y, degree = 1)$r_squared
    r2_degree2 <- polynomial_regression(x, y, degree = 2)$r_squared
    r2_degree3 <- polynomial_regression(x, y, degree = 3)$r_squared

    expect(r2_degree2 > r2_degree1)      # Degree 2 better than 1
    expect(r2_degree3 > r2_degree2)      # Degree 3 better than 2
  })
})

describe("calculate_metrics", {
  it("computes R² correctly", {
    y_true <- c(1, 2, 3, 4, 5)
    y_pred <- c(1.1, 2.1, 2.9, 4.2, 4.9)

    result <- calculate_metrics(y_true, y_pred)

    expect(result$r_squared > 0.99)  # Very close fit
  })
})
```

**Run tests**:
```r
# In RStudio console
testthat::test_dir("tests/testthat")

# Or from command line
R -e "testthat::test_dir('tests/testthat')"
```

**Expected output**:
```
✓ test_regression.R
  ✓ linear_regression
    ✓ returns correct intercept and slope for known data
    ✓ handles noisy data correctly
    ✓ raises error on mismatched vector lengths
  ✓ polynomial_regression
    ✓ linear degree (1) equals linear_regression
    ✓ higher degrees improve fit on polynomial data
  ✓ calculate_metrics
    ✓ computes R² correctly

Test results:
  8 passed ✓
  0 failed ✗
  0 skipped
```

---

### UI Interaction Tests: shinytest2

**Goal**: Verify that user actions (slider moves, uploads) trigger correct plots/metrics updates.

**Tools**: `shinytest2` package (snapshot-based testing)

**Setup**:
```r
# In RStudio console
install.packages("shinytest2")

# Initialize test for an app
setwd("shiny-apps/lab-01-simple-regression")
shinytest2::record_test()
```

**What happens**: RStudio opens browser, records your interactions (clicks, slider movements), saves snapshot.

**Example test file**: `shiny-apps/lab-01-simple-regression/tests/testthat/test-app.R`
```r
library(shinytest2)

test_that("degree slider updates plot and metrics", {
  app <- shinytest2::AppDriver$new(
    app_dir = getwd(),
    name = "lab-01"
  )

  # Initial state: degree = 1
  expect_snapshot(app$get_values())

  # User moves slider to degree = 3
  app$set_inputs(degree = 3)

  # Verify plot updated
  plot_output <- app$get_values()$output$plot
  expect_not_null(plot_output)

  # Verify metrics updated
  metrics <- app$get_values()$output$metrics
  expect_match(metrics, "R²:")
  expect_match(metrics, "RMSE:")
  expect_match(metrics, "AIC:")

  # Verify R² changed (degree 3 should fit better than degree 1)
  app$set_inputs(degree = 1)
  metrics_degree1 <- app$get_values()$output$metrics
  expect_not_equal(metrics, metrics_degree1)
})

test_that("file upload triggers batch processing", {
  app <- shinytest2::AppDriver$new(
    app_dir = "../../lab-02-batch-analysis",
    name = "lab-02"
  )

  # Upload CSV file
  app$upload_file(file = "data/sample.csv")

  # Wait for processing
  Sys.sleep(2)

  # Verify results displayed
  results <- app$get_values()$output$results_ui
  expect_match(results, "Regression Results")
})

test_that("hover tooltip shows predictions", {
  app <- shinytest2::AppDriver$new(
    app_dir = getwd(),
    name = "lab-01"
  )

  # Get snapshot of initial plot
  expect_snapshot(app$get_values()$output$plot)
})
```

**Run tests**:
```bash
cd shiny-apps/lab-01-simple-regression
R -e "shinytest2::test_app()"
```

**Update snapshots** (when intentional UI changes occur):
```bash
R -e "shinytest2::test_app(update = TRUE)"
```

---

### Integration Tests: Multiple Components

**Goal**: Verify that data flows correctly from reactive inputs → model computation → plot rendering.

**Example**: `shiny-apps/lab-01-simple-regression/tests/testthat/test-integration.R`
```r
library(shinytest2)

test_that("full workflow: slider → model → plot → metrics", {
  app <- shinytest2::AppDriver$new(
    app_dir = getwd(),
    name = "lab-01-integration"
  )

  # Initial state
  initial_metrics <- app$get_values()$output$metrics
  expect_match(initial_metrics, "R²: 0")

  # User increases degree
  app$set_inputs(degree = 2)
  Sys.sleep(0.5)  # Let reactivity settle

  # Metrics should improve
  updated_metrics <- app$get_values()$output$metrics
  expect_not_equal(initial_metrics, updated_metrics)

  # Verify plot renders without errors
  plot_val <- app$get_values()$output$plot
  expect_not_null(plot_val)
  expect_no_error(plot_val)
})
```

---

## Drupal Testing

### Unit Tests: Module Logic

**Tools**: PHPUnit

**Setup**:
```bash
cd drupal-site
composer require phpunit/phpunit --dev

# Create test directory
mkdir -p web/modules/custom/cs109_labs/tests/Unit
```

**Example test**: `drupal-site/web/modules/custom/cs109_labs/tests/Unit/LabHelperTest.php`
```php
<?php

namespace Drupal\Tests\cs109_labs\Unit;

use Drupal\Tests\UnitTestCase;
use Drupal\cs109_labs\LabHelper;

class LabHelperTest extends UnitTestCase {

  /**
   * Test that lab URL is properly sanitized
   */
  public function testSanitizeLabUrl() {
    $helper = new LabHelper();

    // Valid URL should pass
    $clean_url = $helper->sanitizeLabUrl('http://localhost:3838/lab-01');
    $this->assertEquals('http://localhost:3838/lab-01', $clean_url);

    // XSS attempt should be blocked
    $xss_url = 'javascript:alert("XSS")';
    $this->expectException(\InvalidArgumentException::class);
    $helper->sanitizeLabUrl($xss_url);
  }

  /**
   * Test enrollment verification
   */
  public function testCheckEnrollment() {
    $helper = new LabHelper();

    // Mock user object
    $account = $this->createMock('Drupal\user\Entity\User');
    $account->method('hasRole')
      ->with('cs109_student')
      ->willReturn(true);

    $is_enrolled = $helper->checkEnrollment($account, 'lab-01');
    $this->assertTrue($is_enrolled);
  }
}
```

**Run tests**:
```bash
./vendor/bin/phpunit --bootstrap=web/autoload.php \
  web/modules/custom/cs109_labs/tests/Unit
```

---

### Functional Tests: Content Types & Workflows

**Tools**: Drupal Functional tests (BrowserTestBase)

**Example test**: `drupal-site/web/modules/custom/cs109_labs/tests/Functional/LabExerciseTest.php`
```php
<?php

namespace Drupal\Tests\cs109_labs\Functional;

use Drupal\Tests\BrowserTestBase;

class LabExerciseTest extends BrowserTestBase {

  protected $defaultTheme = 'stark';

  protected static $modules = ['cs109_labs', 'node', 'user'];

  /**
   * Test Lab Exercise content type exists
   */
  public function testLabExerciseContentTypeExists() {
    $admin = $this->drupalCreateUser(['administer content types']);
    $this->drupalLogin($admin);

    $this->drupalGet('admin/structure/types');
    $this->assertSession()->pageTextContains('Lab Exercise');
  }

  /**
   * Test creating and viewing a Lab Exercise node
   */
  public function testCreateLabExerciseNode() {
    $admin = $this->drupalCreateUser([
      'create lab_exercise content',
      'edit own lab_exercise content',
      'view lab_exercise revisions',
    ]);
    $this->drupalLogin($admin);

    // Create node
    $node_data = [
      'title[0][value]' => 'Test Lab: Regression',
      'lab_url[0][value]' => 'http://localhost:3838/lab-01',
    ];
    $this->drupalPostForm('node/add/lab_exercise', $node_data, 'Save');

    // Verify node was created
    $this->assertSession()->pageTextContains('Lab Exercise Test Lab: Regression has been created');

    // View the node
    $this->drupalGet('node/1');
    $this->assertSession()->pageTextContains('Test Lab: Regression');
  }

  /**
   * Test enrollment-based access control
   */
  public function testEnrollmentAccessControl() {
    // Create non-enrolled user
    $user = $this->drupalCreateUser([]);
    $this->drupalLogin($user);

    // Try to access lab
    $this->drupalGet('node/1');
    $this->assertSession()->statusCodeEquals(403);

    // Add to student role
    $user->addRole('cs109_student');
    $user->save();

    // Now should be accessible
    $this->drupalGet('node/1');
    $this->assertSession()->statusCodeEquals(200);
  }
}
```

**Run tests**:
```bash
cd drupal-site
./vendor/bin/phpunit --bootstrap=web/autoload.php \
  web/modules/custom/cs109_labs/tests/Functional
```

---

## End-to-End Testing: Drupal + Shiny Integration

**Goal**: Verify that Drupal embeds Shiny app correctly and students can interact.

**Tools**: Playwright (JavaScript-based browser automation)

**Setup**:
```bash
npm install -g playwright
# Or use the example-skills:webapp-testing skill if available
```

**Example test**: `docs/e2e-tests/lab-integration.spec.js`
```javascript
const { test, expect } = require('@playwright/test');

test('Student accesses lab exercise and uses regression slider', async ({ page }) => {
  // 1. Login to Drupal
  await page.goto('http://drupal-playground.ddev.site/user/login');
  await page.fill('input[name="name"]', 'student@example.com');
  await page.fill('input[name="pass"]', 'password');
  await page.click('button[type="submit"]');

  // 2. Navigate to Lab Exercise node
  await page.goto('http://drupal-playground.ddev.site/node/1');
  await expect(page).toHaveTitle(/Lab Exercise/);

  // 3. Wait for iframe to load
  const iframe = page.frameLocator('iframe[src*="localhost:3838"]').first();
  await expect(iframe.locator('h2')).toContainText('Lab 01');

  // 4. Interact with Shiny app inside iframe
  const degreeSlider = iframe.locator('input[id="degree"]');
  await degreeSlider.fill('5');

  // 5. Verify plot updated
  const plotOutput = iframe.locator('#plot');
  await expect(plotOutput).toBeVisible();

  // 6. Verify metrics updated
  const metrics = iframe.locator('#metrics');
  await expect(metrics).toContainText('R²:');

  // 7. Verify they changed from initial values
  const metricsText = await metrics.innerText();
  expect(metricsText).toContain('0.');  // R² should be between 0 and 1
});

test('CSV upload and batch processing', async ({ page }) => {
  // Navigate to Lab 02
  await page.goto('http://drupal-playground.ddev.site/node/2');

  const iframe = page.frameLocator('iframe[src*="lab-02"]').first();

  // Upload file
  await iframe.locator('input[type="file"]').setInputFiles('docs/test-data/sample.csv');

  // Click process button
  await iframe.locator('button:has-text("Run Analysis")').click();

  // Wait for results
  await expect(iframe.locator('#results_ui')).toContainText('Regression Results', { timeout: 5000 });

  // Verify bar chart rendered
  const chart = iframe.locator('svg');
  await expect(chart).toBeVisible();
});
```

**Run e2e tests**:
```bash
playwright test docs/e2e-tests/lab-integration.spec.js

# With report
playwright test --reporter=html
```

---

## Test Organization & CI/CD

### Local Test Workflow

```bash
# Before committing, run all tests locally:
cd drupal-site
./vendor/bin/phpunit --bootstrap=web/autoload.php web/modules/custom

cd ../shiny-apps/lab-01-simple-regression
R -e "shinytest2::test_app()"

cd ../../
# E2E tests
playwright test
```

### GitHub Actions CI/CD Pipeline

**File**: `.github/workflows/test.yml`
```yaml
name: Tests

on: [push, pull_request]

jobs:
  drupal-tests:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15-alpine
        env:
          POSTGRES_DB: drupal
          POSTGRES_PASSWORD: drupal
    steps:
      - uses: actions/checkout@v3
      - name: Set up PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
      - name: Install Drupal
        run: |
          cd drupal-site
          composer install
          ddev drush install --yes
      - name: Run Drupal tests
        run: |
          cd drupal-site
          ./vendor/bin/phpunit --bootstrap=web/autoload.php web/modules/custom

  r-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up R
        uses: r-lib/actions/setup-r@v2
      - name: Install R dependencies
        run: |
          install.packages(c('testthat', 'shinytest2', 'ggplot2', 'dplyr', 'plotly'))
        shell: Rscript {0}
      - name: Run R unit tests
        run: |
          R -e "testthat::test_dir('shiny-apps/tests/testthat')"
      - name: Run Shiny app tests
        run: |
          cd shiny-apps/lab-01-simple-regression
          R -e "shinytest2::test_app()"

  e2e-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Playwright
        uses: microsoft/playwright-github-action@v1
      - name: Start Docker Compose
        run: docker-compose up -d
      - name: Wait for services
        run: sleep 10
      - name: Run E2E tests
        run: npx playwright test
```

---

## Testing Checklist

Before merging any PR:

- [ ] Unit tests pass (R functions, Drupal logic)
- [ ] Shiny UI tests pass (sliders, uploads, plots)
- [ ] Drupal functional tests pass (content types, access control)
- [ ] E2E test passes (full Drupal → Shiny workflow)
- [ ] No console errors in browser DevTools
- [ ] No R warnings from `lintr::lint_dir('shiny-apps')`
- [ ] No PHP warnings from `phpcs`
- [ ] Test coverage > 70% (check with `coverage` reports)
- [ ] Documentation updated (CLAUDE.md, TESTING.md, code comments)

---

## Test Coverage Goals

| Component | Target | Method |
|-----------|--------|--------|
| R functions (regression, metrics) | 100% | Unit tests |
| R Shiny app (slider → plot flow) | 80% | shinytest2 snapshots |
| Drupal module (Lab type, access) | 75% | PHPUnit functional |
| API endpoints | 100% | Feature tests |
| Error handling | 90% | Edge case unit tests |

---

## Resources

- **Shiny testing**: https://rstudio.github.io/shinytest2/
- **testthat**: https://testthat.r-lib.org/
- **Drupal testing**: https://www.drupal.org/docs/drupal-apis/testing-api
- **Playwright**: https://playwright.dev/
- **GitHub Actions**: https://docs.github.com/en/actions

See [DEVELOPMENT.md](./DEVELOPMENT.md) for local development guidance.
