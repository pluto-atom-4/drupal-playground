{
  description = "CS109 Interactive Labs - Drupal + R Shiny Development Environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # R with essential packages for Shiny development
        r-with-packages = pkgs.rWrapper.override {
          packages = with pkgs.rPackages; [
            # Core Shiny ecosystem
            shiny
            shinytest2
            plotly

            # Data manipulation
            dplyr
            tidyr
            readr
            purrr

            # Visualization
            ggplot2

            # Testing and code quality
            testthat
            styler
            lintr

            # Development tools
            devtools
            usethis
            roxygen2
          ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # R with packages
            r-with-packages

            # PHP/Drupal development
            php84
            php84Packages.composer

            # Utilities
            git
            curl
            wget
            jq

            # Docker (for DDEV)
            docker

            # Node.js (for frontend tooling if needed)
            nodejs

            # Text editors / IDE support
            vim
            nano
          ];

          # Set environment variables
          shellHook = ''
            echo "✅ CS109 Interactive Labs Development Environment"
            echo ""
            echo "📚 Available tools:"
            echo "  - R with Shiny packages"
            echo "  - PHP 8.4 with Composer"
            echo "  - Docker & Docker Compose"
            echo "  - Node.js"
            echo ""
            echo "🚀 Quick start:"
            echo "  cd ~/Documents/full-stack/drupal-playground"
            echo "  Rscript -e \"shiny::runApp('shiny-apps/lab-01-simple-regression')\""
            echo ""
            echo "📖 Documentation:"
            echo "  - docs/DEVELOPMENT.md - Local development guide"
            echo "  - docs/TESTING.md - Testing strategies"
            echo "  - CLAUDE.md - Architecture reference"
            echo ""
          '';
        };

        # Shell for deployment (minimal)
        devShells.prod = pkgs.mkShell {
          buildInputs = with pkgs; [
            docker
            git
          ];
        };
      }
    );
}
