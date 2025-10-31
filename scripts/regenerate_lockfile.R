# This script regenerates the renv.lock file.
# It scans the project for R package dependencies and updates the lockfile.
# Please run this script from your R console:
# source("scripts/regenerate_lockfile.R")

renv::snapshot()
