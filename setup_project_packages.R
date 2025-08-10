# This script installs all required packages for the project and updates renv.lock

# List of required packages
required_packages <- c("ggplot2", "dplyr", "gridExtra", "moments", "nortest", "tidyr")

# Install packages if not already installed
for(pkg in required_packages) {
  if(!require(pkg, character.only = TRUE, quietly = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
  }
}

# Ensure renv is loaded and snapshot the environment
if (!requireNamespace("renv", quietly = TRUE)) {
  install.packages("renv")
}
renv::snapshot()

message("All required packages installed and renv snapshot updated.")
