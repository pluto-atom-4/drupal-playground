# GitHub Copilot Instructions - Drupal Playground Project

This file provides project-specific guidance for GitHub Copilot CLI when working on the drupal-playground repository.

## Project Context

**Project**: Decoupled Visualization Platform  
**Purpose**: Bridge Drupal content management with R Shiny interactive applications for Harvard CS109  
**Tech Stack**: Drupal 10.x, R Shiny, Bootstrap 5, Docker/DDEV

See `CLAUDE.md` for comprehensive architecture documentation.

## Drupal Development Standards

### Theme Development
- **Active Theme**: harvard_crimson (custom Bootstrap 5 theme)
- **CSS Location**: `drupal-site/web/themes/custom/harvard_crimson/css/`
- **Templates**: `drupal-site/web/themes/custom/harvard_crimson/templates/`
- **Color Scheme**: Harvard Crimson (#A51C30) with supporting grays

### Module Development
- **Custom Modules**: `drupal-site/web/modules/custom/`
- **Module Structure**: Follow Drupal 10 standards with .info.yml, .routing.yml, src/
- **Naming Convention**: snake_case for file names, PascalCase for PHP classes

### Configuration
- **DDEV**: Used for local development (docker-compose-based)
- **Database**: PostgreSQL (vs SQLite)
- **Installation Profile**: Standard

## Git Workflow for This Project

### Branch Naming
- Feature: `feature/description`
- Fix: `fix/issue-N` (for GitHub issues)
- Refactor: `refactor/description`

### Commit Format
```
type: Short description (Fixes #N)

Optional longer explanation.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
```

**Types**: fix, feat, refactor, docs, test, perf, chore

### PR Requirements
- Link to related issues
- Describe changes clearly
- Include testing instructions
- Request review before merge
- Use `/delegate` or `gh pr create` for creation

## R Shiny Development Standards

### Directory Structure
- Labs in `shiny-apps/lab-NN-NAME/`
- Shared utilities in `shiny-apps/shared/`
- Tests in `shiny-apps/lab-NN-NAME/tests/`

### Code Style
- Use tidyverse naming conventions
- Prefer dplyr/tidyr for data manipulation
- Use plotly for interactive visualizations
- Include reactive() expressions clearly

## Testing Requirements

### Drupal Testing
- PHPUnit for custom modules: `./vendor/bin/phpunit`
- Drush for integration testing
- Clear cache after changes: `ddev drush cache-rebuild`

### R Shiny Testing
- shinytest2 for UI testing
- Run with: `R -e "shinytest2::test_app()"`

### Before Creating PR
1. Run relevant tests
2. Clear Drupal cache
3. Review with `/diff`
4. Run `/review` for automated feedback

## Common Tasks

### Creating a New Lab Exercise
1. Create directory: `shiny-apps/lab-NN-NAME/`
2. Copy `app.R` from existing lab
3. Create Drupal node of type "Lab Exercise"
4. Add iframe linking to app
5. Test and commit

### Fixing a UI Issue
1. Identify the template file
2. Update HTML or CSS
3. Clear cache: `ddev drush cache-rebuild`
4. Test in browser
5. Create PR with before/after description

### Adding a New Feature
1. Plan scope with `/plan`
2. Create feature branch
3. Implement incrementally
4. Test thoroughly
5. Document changes
6. Create PR with detailed description

## Important Commands

### Drupal/DDEV
```bash
cd drupal-site
ddev start                    # Start development environment
ddev drush cache-rebuild      # Clear cache
ddev logs web                 # View web logs
```

### Git/GitHub
```bash
git status                    # Check status
git diff                      # Preview changes
gh pr create --title "..."    # Create PR
/delegate                     # Auto-create PR via Copilot
```

### R Shiny
```bash
Rscript -e "shiny::runApp()"  # Run app locally
R -e "shinytest2::test_app()" # Run tests
```

## Context & Dependencies

### Must Include When Working On
- **Theme Changes**: Mention Bootstrap version (5.3.3) and CSS files
- **Drupal Changes**: Specify custom modules and configuration
- **Shiny Changes**: Reference shared utilities used
- **PR Changes**: Use `@drupal-site/web/` for file mentions

### Files to Reference
- `CLAUDE.md` - Full architecture
- `.github/copilot-instructions.md` - This file
- `docker-compose.yml` - Services configuration
- `drupal-site/composer.json` - PHP dependencies

## Performance Considerations

### Drupal Performance
- Use block caching: `#cache` property on blocks
- Leverage Drupal's render pipeline
- Optimize database queries
- Use drush efficiently

### Shiny Performance
- Use bindCache() for expensive computations
- Implement reactive() strategically
- Limit data frame sizes
- Cache at appropriate levels

## Security Checklist

- [ ] No secrets in code (use environment variables)
- [ ] Input validation on all user inputs
- [ ] SQL injection prevention (use Drupal API)
- [ ] XSS prevention in templates
- [ ] Authentication/Authorization enforced
- [ ] HTTPS enforced in production

## Documentation Requirements

- Update README.md for new features
- Document breaking changes clearly
- Include examples for new functionality
- Reference CLAUDE.md for architecture questions
- Keep deployment instructions current

## Code Review Checklist

Before creating PR, verify:
- [ ] All tests pass
- [ ] Cache cleared
- [ ] Code follows project standards
- [ ] Documentation updated
- [ ] No hard-coded values
- [ ] Security best practices followed
- [ ] Performance optimized
- [ ] Commit messages clear

## Helpful Links

- **Drupal Docs**: https://www.drupal.org/docs/drupal-apis
- **R Shiny**: https://shiny.rstudio.com/
- **Bootstrap 5**: https://getbootstrap.com/docs/5.3/
- **GitHub API**: https://docs.github.com/en/rest
- **Project Architecture**: See `CLAUDE.md`

---

**Last Updated**: 2026-04-01  
**Project**: drupal-playground  
**Maintained By**: Development Team
