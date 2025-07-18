# Statistics Concepts

An interactive website demonstrating fundamental statistical concepts through hands-on R code examples and visualizations.

## Overview

This project uses [Quarto](https://quarto.org/) to create an educational website that teaches statistical concepts through interactive demonstrations. Each concept page contains executable R code that automatically installs required packages and generates visualizations to help understand the underlying principles.

## Features

- **Interactive Demonstrations**: Run R code directly in the browser
- **Automatic Package Management**: Required packages are installed automatically
- **Visual Learning**: Rich plots and visualizations for each concept
- **Mathematical Foundation**: Formal mathematical notation and explanations
- **Responsive Design**: Works on desktop and mobile devices

## Current Topics

- **Central Limit Theorem**: Understanding how sampling distributions approach normality
- *More topics coming soon...*

## Project Structure

```
stats-concepts/
├── _quarto.yml                    # Quarto configuration
├── index.qmd                      # Homepage
├── about.qmd                      # About page
├── styles.css                     # Custom CSS styling
├── README.md                      # This file
│
├── concepts/                      # Statistical concept pages
│   ├── central-limit-theorem.qmd  # CLT demonstration
│   └── template.qmd               # Template for new concepts
│
├── data/                          # Data files
├── datasets/                      # Additional datasets
├── images/                        # Generated plots and images
│   ├── clt-demo/
│   └── plots/
│
├── renv/                          # R environment management
├── renv.lock                      # R package lock file
└── stats-concepts.Rproj           # RStudio project file
```

## Prerequisites

Before you begin, ensure you have the following installed:

### Required Software

1. **R** (version 4.0 or higher)
   - Download from [r-project.org](https://www.r-project.org/)
   - Or install via package manager:
     ```bash
     # macOS (using Homebrew)
     brew install r
     
     # Ubuntu/Debian
     sudo apt-get install r-base
     ```

2. **Quarto** (version 1.0 or higher)
   - Download from [quarto.org](https://quarto.org/docs/get-started/)
   - Or install via package manager:
     ```bash
     # macOS (using Homebrew)
     brew install quarto
     
     # Ubuntu/Debian
     wget https://github.com/quarto-dev/quarto-cli/releases/download/v1.4.549/quarto-1.4.549-linux-amd64.deb
     sudo dpkg -i quarto-1.4.549-linux-amd64.deb
     ```

3. **RStudio** (optional but recommended)
   - Download from [posit.co](https://posit.co/download/rstudio-desktop/)

### Verify Installation

Check that both R and Quarto are properly installed:

```bash
# Check R version
R --version

# Check Quarto version
quarto --version
```

## Setup Instructions

### 1. Clone or Download the Repository

```bash
# If using git
git clone <repository-url>
cd stats-concepts

# Or download and extract the ZIP file
```

### 2. Install R Dependencies

The project uses `renv` for R package management. All required packages will be automatically installed when you first run the code.

```bash
# Start R and restore the environment
R
```

In R:
```r
# Restore the R environment (this will install all required packages)
renv::restore()

# Exit R
q()
```

### 3. Verify Setup

Test that everything is working:

```bash
# Render the website
quarto render
```

If successful, you should see output indicating that the files were rendered to the `_site/` directory.

## How to Serve the Website

### Option 1: Local Development Server (Recommended)

For development and testing:

```bash
# Start a local development server
quarto preview

# Or with specific port
quarto preview --port 4242
```

This will:
- Start a local web server (usually at `http://localhost:4848`)
- Automatically reload when you make changes
- Show live preview of your edits

### Option 2: Build and Serve Static Files

For production deployment:

```bash
# Build the website
quarto render

# The built files will be in the _site/ directory
# You can serve these files with any web server
```

### Option 3: Using Python's Built-in Server

If you have Python installed:

```bash
# Build the site first
quarto render

# Serve the built files
cd _site
python -m http.server 8000
# Then visit http://localhost:8000
```

### Option 4: Using Node.js http-server

If you have Node.js installed:

```bash
# Install http-server globally
npm install -g http-server

# Build the site
quarto render

# Serve the built files
cd _site
http-server -p 8080
# Then visit http://localhost:8080
```

## Development Workflow

### Adding New Concepts

1. **Copy the template**:
   ```bash
   cp concepts/template.qmd concepts/your-concept-name.qmd
   ```

2. **Edit the new file**:
   - Update the YAML header with your concept name
   - Replace placeholder content with your demonstration
   - Add your R code in the code blocks

3. **Update navigation**:
   Edit `_quarto.yml` to add your new page to the navbar:
   ```yaml
   navbar:
     left:
       - href: concepts/your-concept-name.qmd
         text: Your Concept Name
   ```

4. **Test your changes**:
   ```bash
   quarto preview
   ```

### Code Block Best Practices

- Use `#| echo: true` to show code
- Use `#| warning: false` to suppress warnings
- Use `#| message: false` to suppress messages
- Always include the package installation code at the top
- Set `set.seed()` for reproducible results

### Example Code Block

```r
#| echo: true
#| warning: false
#| message: false

# Check and install required packages
required_packages <- c("ggplot2", "dplyr")

# Function to install packages if not already installed
install_if_missing <- function(packages) {
  for(pkg in packages) {
    if(!require(pkg, character.only = TRUE, quietly = TRUE)) {
      install.packages(pkg, dependencies = TRUE)
      library(pkg, character.only = TRUE)
    } else {
      library(pkg, character.only = TRUE)
    }
  }
}

# Install and load packages
install_if_missing(required_packages)

# Set seed for reproducibility
set.seed(123)

# Your demonstration code here
```

## Deployment

### GitHub Pages

1. Push your code to a GitHub repository
2. Enable GitHub Pages in repository settings
3. Set source to "GitHub Actions"
4. Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: r-lib/actions/setup-r@v2
      with:
        r-version: '4.2'
    - uses: r-lib/actions/setup-renv@v2
    - name: Install Quarto
      uses: quarto-dev/quarto-actions/install@v2
    - name: Render
      run: quarto render
    - name: Deploy
      uses: peaceiris/actions-gh-pages@v3
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        publish_dir: ./_site
```

### Netlify

1. Connect your repository to Netlify
2. Set build command: `quarto render`
3. Set publish directory: `_site`

### Vercel

1. Connect your repository to Vercel
2. Set build command: `quarto render`
3. Set output directory: `_site`

## Troubleshooting

### Common Issues

**"Package not found" errors:**
- Make sure you're using the `install_if_missing()` function
- Check that you have internet access for package downloads

**Rendering fails:**
- Verify R and Quarto are properly installed
- Check that all required packages are available
- Look for syntax errors in your R code

**Images not displaying:**
- Ensure image files are in the correct directory
- Check file paths are relative to the project root

**Navigation not working:**
- Verify `_quarto.yml` syntax is correct
- Check that file paths in navigation match actual file locations

### Getting Help

- Check the [Quarto documentation](https://quarto.org/docs/)
- Review R error messages for specific issues
- Ensure all prerequisites are properly installed

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally with `quarto preview`
5. Submit a pull request

## License

[Add your license information here]

## Acknowledgments

- Built with [Quarto](https://quarto.org/)
- Powered by [R](https://www.r-project.org/)
- Visualizations created with [ggplot2](https://ggplot2.tidyverse.org/) 