# Local Development Guide

This guide covers the recommended workflow for developing the Drupal + R Shiny CS109 labs locally using DDEV (with SQLite), PhpStorm, and R CLI tools.

## Development Environment Setup

### Why DDEV + PhpStorm + SQLite + R CLI?
- **DDEV with SQLite**: Zero database server setup; file-based, instant, perfect for local iteration
- **PhpStorm**: Powerful Drupal IDE with Drupal plugins, integrated terminal, Git, Docker support
- **R via CLI/Terminal**: Command-line R development; edit scripts in PhpStorm; lighter than RStudio
- **Separation of Concerns**: Drupal and R developed independently with clear tooling boundaries
- **Performance**: Faster startup, lower memory overhead than PostgreSQL setup

### Prerequisites
```bash
# macOS (Homebrew)
brew install ddev sqlite3
# Download PhpStorm from https://www.jetbrains.com/phpstorm/

# Linux (Ubuntu/Debian)
curl https://get.ddev.com | bash
sudo apt-get install sqlite3
# Download PhpStorm from https://www.jetbrains.com/phpstorm/

# Windows (Chocolatey)
choco install ddev sqlite
# Download PhpStorm from https://www.jetbrains.com/phpstorm/
```

### PhpStorm Plugins Setup

Open PhpStorm → Settings → Plugins → Marketplace. Install:

1. **Drupal Symfony Bridge** (official) — Drupal code completion, hooks, services
2. **Markdown** (built-in) — Documentation editing
3. **R Language Support** (JetBrains) — R syntax, debugging, package management
4. **Docker** (built-in) — DDEV integration
5. **Database Tools** (built-in) — SQLite query editor
6. **Git Integration** (built-in) — GitHub operations

**Optional**:
- **Drupal Inspections** — Static analysis for Drupal code
- **PHP Inspections (EA Extended)** — PHP best practices

---

## Initial Setup (First Time Only)

### 1. Open Project in PhpStorm

```
File > Open > /path/to/drupal-playground
```

PhpStorm detects DDEV automatically. You'll see a prompt: **"Configure PHP for Drupal"** → Click **Yes**.

### 2. Configure DDEV with PostgreSQL

```bash
cd drupal-site

# Initialize DDEV environment with PostgreSQL 15
# (DDEV requires a database service; SQLite is file-based and not supported via ddev config)
ddev config --project-type=drupal10 --docroot=web --database=postgres:15
```

PhpStorm will prompt to configure PHP interpreter. Select DDEV's PHP.

**Note on SQLite**: While DDEV requires a database service container (PostgreSQL, MySQL, etc.),
Drupal can still use SQLite directly if needed. However, PostgreSQL is lightweight and provides
production parity. For local development, PostgreSQL is recommended.

### 3. Verify DDEV Configuration

Check the generated `.ddev/config.yaml`:
```yaml
name: drupal-site
type: drupal10
docroot: web
database: postgres:15
php_version: "8.2"
timezone: UTC
```

DDEV automatically creates and manages the PostgreSQL container.

### 4. Start DDEV & Install Drupal

```bash
ddev start
# This starts PostgreSQL container and PHP environment

# Install Drupal
ddev drush install \
  --site-name="CS109 Labs" \
  --account-name=admin \
  --account-pass=admin123

# Install required modules
ddev drush pm-install paragraphs asset_injector samlauth
ddev drush en cs109_labs
```

**Drupal URL**: http://drupal-site.ddev.site

**Database**: PostgreSQL 15 (managed by DDEV, running in container)
- Host: `postgres` (container name, accessible from within DDEV)
- Database: `db` (created by DDEV automatically)
- User: `db` (default DDEV user)
- Password: `db` (default DDEV password)

### 5. Configure PostgreSQL in PhpStorm

```
Settings > Languages & Frameworks > Database > Data Sources
  → [+] > PostgreSQL
  → Host: localhost
  → Port: 5432 (DDEV forwards this)
  → Database: db
  → User: db
  → Password: db
  → Test Connection
```

Now you can query the database directly in PhpStorm.

### 6. R Environment Setup

```bash
# Terminal (Alt+F12 in PhpStorm)
R --quiet --no-save << 'EOF'
packages <- c("shiny", "ggplot2", "plotly", "dplyr", "tidyr", "readr", "purrr",
              "shinytest2", "testthat", "styler", "lintr")
install.packages(packages, repos="https://cloud.r-project.org")
EOF
```

Verify in PhpStorm R Console (Tools > R Console):
```r
library(shiny)
library(ggplot2)
```

---

## Daily Development Workflow

### Scenario 1: Developing a New Lab (R Shiny)

**Goal**: Create interactive regression lab with slider controls.

**In PhpStorm**:
1. Right-click `shiny-apps/lab-01-simple-regression` → New File → `app.R`
2. Write Shiny UI and server code
3. Terminal (Alt+F12):
   ```bash
   cd shiny-apps/lab-01-simple-regression
   Rscript -e "shiny::runApp(port=3838)"
   ```
4. Open browser: http://localhost:3838
5. **Hot reload**: Save → Browser auto-refreshes
6. Use PhpStorm **R Console** to test functions:
   ```r
   source("../shared/regression.R")
   x <- 1:20
   y <- 2*x + rnorm(20, 0, 3)
   result <- polynomial_regression(x, y, degree=3)
   print(result$r_squared)
   ```

**PhpStorm Features to Use**:
- **Code Completion**: Type `poly` → Shows available functions with parameters
- **Go to Definition**: Ctrl+Click `polynomial_regression()` → Jump to source
- **Find Usages**: Right-click function → Find all references across labs
- **Refactor > Rename**: Rename variables/functions across entire codebase

**File structure**:
```
shiny-apps/lab-01-simple-regression/
├── app.R              # ← Edit here: ui + server
├── data/sample.csv    # Sample dataset
└── tests/
    ├── test-app.R     # shinytest2 tests
    └── test-regression.R  # Unit tests
```

---

### Scenario 2: Customizing Drupal for Lab Embedding

**Goal**: Create Lab Exercise content type with iframe embedding.

**In PhpStorm**:
1. Open `drupal-site/web/modules/custom/cs109_labs`
2. Create `cs109_labs.module`:
   ```php
   <?php
   /**
    * @file
    * CS109 Labs module - Lab Exercise content type.
    */
   ```
3. Terminal: `ddev drush cache-rebuild`
4. Drupal automatically detects module changes
5. Verify in UI: http://drupal-playground.ddev.site/admin/content/types

**PhpStorm Drupal Features**:
- **Hook Autocomplete**: Type `hook_` → Lists all Drupal hooks
- **Service Autocomplete**: Type `\Drupal::` → Auto-completes services (database, entity, etc.)
- **Config File Validation**: YAML syntax checking for .yml files
- **Real-time Inspections**: Deprecated APIs highlighted automatically

---

### Scenario 3: Database Queries (SQLite)

**Goal**: Check Lab Exercise nodes and student progress.

**Via PhpStorm Database Tool**:
1. View > Tool Windows > Database (or Alt+Num 9)
2. Right-click SQLite connection > New Query
3. Write SQL:
   ```sql
   SELECT * FROM node WHERE type = 'lab_exercise';
   SELECT * FROM node__field_quiz_score LIMIT 10;
   ```
4. Ctrl+Enter to execute

**Via Terminal**:
```bash
sqlite3 .ddev/db/drupal.sqlite
> SELECT * FROM node WHERE type = 'lab_exercise';
> .exit
```

**Via Drupal CLI**:
```bash
ddev drush sql-cli
```

---

## Code Organization & Naming Conventions

### R Shiny Files
```
shiny-apps/
├── shared/
│   ├── regression.R          # linear_regression(), polynomial_regression()
│   ├── metrics.R             # calculate_metrics(), format_metrics()
│   └── plotting.R            # harvard_theme(), as_interactive_plot()
├── lab-NN-NAME/
│   ├── app.R                 # UI + server (main entry point)
│   ├── www/css/custom.css    # App-specific styling
│   ├── data/sample.csv       # Bundled datasets
│   └── tests/
│       ├── test-app.R        # shinytest2 interaction tests
│       └── test-regression.R # testthat unit tests
```

**Naming conventions**:
- **Functions**: `snake_case` — `polynomial_regression()`
- **Variables**: `camelCase` — `modelData`, `userInput`
- **Files**: `kebab-case` — `batch-process.R`
- **Modules**: `kebab-case` folders — `lab-01-simple-regression`

### Drupal Files
```
drupal-site/web/modules/custom/cs109_labs/
├── cs109_labs.module         # Hook implementations
├── cs109_labs.install        # Schema & migrations
├── cs109_labs.services.yml   # Service definitions
├── src/
│   ├── Plugin/Block/LabEmbedBlock.php
│   ├── Controller/LabController.php
│   └── Form/LabSettingsForm.php
├── config/install/
│   ├── node.type.lab_exercise.yml
│   └── field.storage.node__lab_url.yml
└── tests/
    ├── Unit/LabHelperTest.php
    └── Functional/LabExerciseTest.php
```

**Naming conventions**:
- **Classes**: `PascalCase` — `LabEmbedBlock`, `LabController`
- **Methods**: `camelCase` — `createLabExercise()`
- **Files**: `PascalCase.php` — `LabEmbedBlock.php`
- **Config files**: `entity.bundle.name.yml` — `node.type.lab_exercise.yml`

---

## Code Hot Reload & Live Development

### R Shiny (Auto-reload)
- Edit `app.R` → Save → Browser auto-refreshes (watch for errors in console)
- Edit `../shared/regression.R`:
  - **Quick reload**: In R console, `source("../shared/regression.R")`
  - **Full reload**: Stop Shiny (Ctrl+C), re-run `Rscript -e "shiny::runApp()"`

### Drupal (Cache rebuild)
- Edit module code → Terminal: `ddev drush cache-rebuild`
- Edit theme CSS → No rebuild needed (static file; clear browser cache)
- Edit content type config → Export config, commit:
  ```bash
  ddev drush config-export
  git add drupal-site/config/
  git commit -m "Update Lab Exercise content type"
  ```

---

## Database & Sample Data

### PostgreSQL Database (via DDEV)

**Managed by DDEV**: Database runs in container; DDEV handles startup/shutdown

**Backup & Restore**:
```bash
# Backup database
ddev export-db > drupal-backup.sql

# Restore from backup
ddev import-db < drupal-backup.sql
ddev drush cache-rebuild
```

**Reset to clean state**:
```bash
ddev stop
ddev start
# Database is automatically recreated
ddev drush install --yes
ddev drush pm-install paragraphs asset_injector samlauth
```

**Query via PhpStorm**:
1. View > Database (or Alt+Num 9)
2. Right-click PostgreSQL connection > New Query
3. Write and execute SQL

**Query via command line**:
```bash
ddev drush sql-cli
# or
ddev drush sql-dump > export.sql
```

### R Sample Data

Place CSV files in `shiny-apps/lab-NN/data/`:

**Create sample data** (in PhpStorm R Console):
```r
set.seed(42)
sample_data <- data.frame(
  x = 1:30,
  y = 2 * (1:30) + rnorm(30, 0, 5)
)
write.csv(sample_data, "shiny-apps/lab-01-simple-regression/data/sample.csv", row.names = FALSE)
```

---

## Debugging Techniques

### R Shiny Debugging

**Method 1: Browser pause in R Console**
```r
source("shiny-apps/lab-01-simple-regression/app.R")
browser()  # Execution pauses; inspect variables
```

**Method 2: Print debugging**
```r
output$plot <- renderPlotly({
  cat("DEBUG: input$degree =", input$degree, "\n")
  cat("DEBUG: nrow(data()) =", nrow(data()), "\n")
  ggplot(...) %>% ggplotly()
})
```

**Method 3: Browser DevTools** (F12)
- Console: JavaScript errors
- Network: API calls to Shiny server
- Performance: Script execution time

### Drupal Debugging

**Via Drupal logs**:
```bash
ddev drush watchdog-show --limit=20
ddev drush watchdog-delete all
```

**Via SQLite queries** (PhpStorm Database):
```sql
SELECT * FROM watchdog WHERE type = 'php' ORDER BY timestamp DESC LIMIT 10;
```

**Via PhpStorm XDebug**:
1. Settings > PHP > Debug > XDebug
2. Set breakpoint (Ctrl+Shift+F8)
3. Start debug listener (Ctrl+Alt+D)
4. Navigate to page → Execution pauses at breakpoint

---

## Testing During Development

### R Unit Tests (testthat)

```bash
cd shiny-apps
R -e "testthat::test_dir('tests/testthat')"
```

### Shiny UI Tests (shinytest2)

```bash
cd shiny-apps/lab-01-simple-regression
R -e "shinytest2::test_app()"
```

### Drupal Tests (PHPUnit)

```bash
cd drupal-site
./vendor/bin/phpunit --bootstrap=web/autoload.php web/modules/custom/cs109_labs
```

See [TESTING.md](./TESTING.md) for comprehensive testing strategies.

---

## Git Workflow in PhpStorm

### Create Feature Branch
1. **Git** menu → **Branches** → **New Branch**
2. Name: `feature/lab-04-clustering`
3. Base: `main`

### Commit Changes
1. Ctrl+K or **Git** menu → **Commit**
2. Select files, write message, click **Commit**

### Push to GitHub
1. Ctrl+Shift+K or **Git** menu → **Push**
2. Verify remote and click **Push**

---

## Performance Optimization

### R Shiny

```r
# Profile code
library(profvis)
profvis({
  polynomial_regression(x, y, 5)
})

# Cache expensive computations
reactive({
  bindCache(
    polynomial_regression(x, y, input$degree),
    input$degree
  )
})
```

### Drupal with SQLite

**Note**: SQLite is single-user, single-process. Fine for local development; switch to PostgreSQL for staging/production with multiple concurrent users.

```bash
# Monitor performance
ddev drush config-set system.performance page.cache.max_age 0
ddev drush watchdog-show --severity=warning
```

---

## PhpStorm Shortcuts & Tips

| Action | Shortcut |
|--------|----------|
| Open file by name | Ctrl+N |
| Find in all files | Ctrl+Shift+F |
| Go to line | Ctrl+G |
| Find usages | Alt+F7 |
| Refactor > Rename | Shift+F6 |
| Terminal | Alt+F12 |
| Git commit | Ctrl+K |
| Git push | Ctrl+Shift+K |
| Split editor | Ctrl+\ |
| Reformat code | Ctrl+Alt+L |
| Database tool | Alt+Num 9 |

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| DDEV won't start | `ddev restart`, check `ddev logs` |
| PostgreSQL connection refused | `ddev start`, verify with `ddev drush sql-cli` |
| Database permission errors | Run `ddev drush cache-rebuild` and retry |
| R packages won't install | `install.packages(..., repos="https://cloud.r-project.org")` |
| Drupal module changes not reflected | `ddev drush cache-rebuild` |
| PhpStorm can't find PHP | Settings > PHP > CLI Interpreter > Configure DDEV |
| Shiny app won't reload | Stop (Ctrl+C), re-run `Rscript -e "shiny::runApp()"` |
| PostgreSQL not in Database tool | Settings > Database > [+] PostgreSQL > Configure (host: localhost, port: 5432, db: db, user: db, pass: db) |

---

## Reference: Command Cheat Sheet

| Task | Command |
|------|---------|
| Start DDEV | `ddev start` |
| Stop DDEV | `ddev stop` |
| SSH into Drupal | `ddev ssh` |
| Drupal CLI | `ddev drush <cmd>` |
| Rebuild Drupal cache | `ddev drush cache-rebuild` |
| Start Shiny server | `Rscript -e "shiny::runApp()"` |
| Query SQLite | `sqlite3 .ddev/db/drupal.sqlite` |
| Install R packages | `install.packages("pkg")` (R console) |
| Run R tests | `R -e "testthat::test_dir(...)"` |
| Run Shiny tests | `R -e "shinytest2::test_app()"` |
| Run Drupal tests | `./vendor/bin/phpunit ...` |

See [TESTING.md](./TESTING.md) for comprehensive testing strategies.
