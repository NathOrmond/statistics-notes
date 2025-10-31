# Project Documentation

This directory contains technical documentation for the stats-concepts project.

## Development Setup

This project uses `renv` to ensure a reproducible R environment. All required packages are listed in the `renv.lock` file.

To get started, follow these steps in your R console:

1.  **Restore the Environment:**
    This command installs the exact versions of all R packages used in the project.
    ```r
    renv::restore()
    ```

2.  **Developing and Adding Packages:**
    If you need to add a new package for your analysis, use:
    ```r
    renv::install("new-package-name")
    ```

3.  **Save Your Changes:**
    After installing or updating packages, save your changes to the lockfile. This is crucial for reproducibility.
    ```r
    renv::snapshot()
    ```
    Commit the updated `renv.lock` file to your Git repository.

---

## Available Documentation

### [Routing System](./routing-system.md)
Comprehensive guide to the automated navigation/routing system:
- How navigation is generated from directory structure
- How titles are extracted from YAML headers
- Configuration options and customisation
- Troubleshooting guide
- Best practices

### [Testing CI Locally](./testing-ci-locally.md)
Guide to testing GitHub Actions workflows locally using `act`:
- Installation and setup
- Running workflows locally
- Testing build pipelines
- Troubleshooting common issues

### [Tech Specs](./tech-specs/)
Technical specifications and implementation details for components of the project.