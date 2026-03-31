# Drupal + R Shiny CS109 Interactive Labs

A decoupled web platform bridging Drupal (content management and authentication) with R Shiny (interactive data science applications) for Harvard CS109 Introduction to Data Science.

## Quick Start

### Prerequisites
- Docker & Docker Compose (or DDEV for Drupal + RStudio Desktop for Shiny)
- Git

### Development Setup

```bash
# Clone and install
git clone https://github.com/pluto-atom-4/drupal-playground.git
cd drupal-playground
docker-compose up -d
```

**Drupal**: http://localhost:8080
**Shiny Labs**: http://localhost:3838

See [CLAUDE.md](./CLAUDE.md) for detailed development guidance and architecture.

## What's Inside

- **`drupal-site/`** — Drupal 10 CMS with Lab Exercise content type
- **`shiny-apps/`** — Interactive R Shiny applications (regression labs, batch processing, diagnostics)
- **`docs/start-from-here.md`** — Architectural plan and design rationale
- **`CLAUDE.md`** — Comprehensive developer guide

## Labs Overview

- **lab-01-simple-regression** — Linear & polynomial regression with interactive degree slider
- **lab-02-batch-analysis** — CSV upload & batch multi-column regression
- **lab-03-diagnostics** — Residual plots, Q-Q diagnostics, linked visualizations

## Key Features

✨ **Reactive computation** — Sliders instantly trigger model re-evaluation
📊 **Interactive plots** — Hover tooltips, zooming, linked visualizations with Plotly
🔒 **Enrollment verified** — SimpleSAMLphp/OIDC ensures only students see labs
⚡ **Cached models** — Common polynomial degrees (1–3) cached to reduce server load
📈 **Real-time metrics** — R², RMSE, AIC update as models change

## Documentation

- [CLAUDE.md](./CLAUDE.md) — Complete development guide, API patterns, deployment
- [docs/start-from-here.md](./docs/start-from-here.md) — Architectural design and plan

## License

MIT
