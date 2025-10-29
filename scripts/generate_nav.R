#!/usr/bin/env Rscript
# Generate navigation structure for _quarto.yml based on directory structure
# Run this script when you add new pages to automatically update navigation

library(yaml)
library(fs)

# Configuration
src_dir <- "src"
output_file <- "_quarto_nav.yml"  # Generated nav structure
exclude_patterns <- c("template\\.qmd$", "index\\.qmd$")  # Files to exclude from auto-nav

# Function to extract title from YAML header
extract_title <- function(file_path) {
  lines <- readLines(file_path, n = 20)
  yaml_start <- which(grepl("^---\\s*$", lines))
  if (length(yaml_start) < 2) {
    return(NULL)
  }
  yaml_content <- lines[(yaml_start[1] + 1):(yaml_start[2] - 1)]
  yaml_data <- tryCatch(
    yaml::yaml.load(paste(yaml_content, collapse = "\n")),
    error = function(e) NULL
  )
  return(yaml_data$title %||% tools::file_path_sans_ext(basename(file_path)))
}

# Function to convert file path to href (relative to project root)
path_to_href <- function(path) {
  # Keep full relative path from project root (including src/)
  href <- path
  return(href)
}

# Function to build navigation from directory
build_nav <- function(dir_path, base_path = "", depth = 0) {
  nav_items <- list()
  # Get all .qmd files in current directory
  qmd_files <- dir_ls(dir_path, regexp = "\\.qmd$", type = "file")
  # Filter out excluded patterns
  for (pattern in exclude_patterns) {
    qmd_files <- qmd_files[!grepl(pattern, qmd_files)]
  }
  # Add QMD files as menu items
  for (file in qmd_files) {
    rel_path <- path_rel(file, ".")
    title <- extract_title(file) %||% tools::file_path_sans_ext(basename(file))
    # Format title (capitalise, replace hyphens with spaces)
    title <- gsub("-", " ", title)
    title <- gsub("_", " ", title)
    # Simple capitalisation - capitalise first letter of each word
    title <- gsub("\\b([a-z])", "\\U\\1", title, perl = TRUE)
    item <- list(
      href = path_to_href(rel_path),
      text = title
    )
    nav_items[[length(nav_items) + 1]] <- item
  }
  
  # Get subdirectories
  subdirs <- dir_ls(dir_path, type = "directory")
  for (subdir in subdirs) {
    dir_name <- basename(subdir)
    # Skip if directory is empty or only has excluded files
    subdir_files <- dir_ls(subdir, regexp = "\\.qmd$", type = "file")
    if (length(subdir_files) == 0) {
      next
    }
    # Check if there's an index file
    index_file <- path(subdir, "index.qmd")
    has_index <- file_exists(index_file)
    # Build menu for subdirectory
    submenu <- build_nav(subdir, base_path, depth + 1)
    # Format directory name for display
    display_name <- gsub("-", " ", dir_name)
    display_name <- gsub("_", " ", display_name)
    display_name <- gsub("\\b([a-z])", "\\U\\1", display_name, perl = TRUE)
    # Handle nested structure (like paper-reviews/chatbot-mental-health/)
    if (depth == 0) {
      # Top-level category
      menu_item <- list(
        text = display_name,
        menu = submenu
      )
      # Add index if exists
      if (has_index) {
        index_title <- extract_title(index_file) %||% "Overview"
        overview_item <- list(
          href = path_to_href(path_rel(index_file, ".")),
          text = "Overview"
        )
        submenu <- c(list(overview_item), submenu)
        menu_item$menu <- submenu
      }
      nav_items[[length(nav_items) + 1]] <- menu_item
    } else {
      # Nested category (e.g., Blog > Paper Reviews)
      if (has_index && length(submenu) > 0) {
        # Add index as first item in submenu
        overview_item <- list(
          href = path_to_href(path_rel(index_file, ".")),
          text = "Overview"
        )
        submenu <- c(list(overview_item), submenu)
      }
      menu_item <- list(
        text = display_name,
        menu = submenu
      )
      nav_items[[length(nav_items) + 1]] <- menu_item
    }
  }
  
  return(nav_items)
}

# Main execution
cat("Generating navigation structure from src/ directory...\n")

# Check if src directory exists
if (!dir_exists(src_dir)) {
  stop("src/ directory not found!")
}

# Build navigation structure
teaching_stats_path <- path(src_dir, "teaching-stats")
blog_path <- path(src_dir, "blog")
navbar <- list()
navbar$left <- list()

# Add home
navbar$left[[1]] <- list(href = "index.qmd", text = "Home")

# Add Teaching Stats section
# Use index.qmd pattern: link to index files instead of creating nested menus
if (dir_exists(teaching_stats_path)) {
  teaching_subdirs <- dir_ls(teaching_stats_path, type = "directory")
  teaching_nav <- list()
  
  for (subdir in teaching_subdirs) {
    dir_name <- basename(subdir)
    index_file <- path(subdir, "index.qmd")
    
    # Format directory name for display
    display_name <- gsub("-", " ", dir_name)
    display_name <- gsub("_", " ", display_name)
    display_name <- gsub("\\b([a-z])", "\\U\\1", display_name, perl = TRUE)
    
    # If index exists, link to it; otherwise create placeholder
    if (file_exists(index_file)) {
      teaching_nav[[length(teaching_nav) + 1]] <- list(
        href = path_to_href(path_rel(index_file, ".")),
        text = display_name
      )
    } else {
      # Create index if it doesn't exist (optional - can be manual)
      # For now, just skip directories without index files
      next
    }
  }
  
  # If we have navigation items, add Teaching Stats menu
  if (length(teaching_nav) > 0) {
    navbar$left[[length(navbar$left) + 1]] <- list(
      text = "Teaching Stats",
      menu = teaching_nav
    )
  }
}

# Add Blog section
# Use index.qmd pattern: link to index files instead of creating nested menus
if (dir_exists(blog_path)) {
  blog_subdirs <- dir_ls(blog_path, type = "directory")
  blog_nav <- list()
  
  for (subdir in blog_subdirs) {
    dir_name <- basename(subdir)
    index_file <- path(subdir, "index.qmd")
    
    # Format directory name for display
    display_name <- gsub("-", " ", dir_name)
    display_name <- gsub("_", " ", display_name)
    display_name <- gsub("\\b([a-z])", "\\U\\1", display_name, perl = TRUE)
    
    # If index exists, link to it; skip if no index (can't have empty menus)
    if (file_exists(index_file)) {
      blog_nav[[length(blog_nav) + 1]] <- list(
        href = path_to_href(path_rel(index_file, ".")),
        text = display_name
      )
    }
    # Skip directories without index.qmd (empty directories won't appear in nav)
  }
  
  if (length(blog_nav) > 0) {
    navbar$left[[length(navbar$left) + 1]] <- list(
      text = "Blog",
      menu = blog_nav
    )
  }
}

# Add About
navbar$left[[length(navbar$left) + 1]] <- list(href = "about.qmd", text = "About")

# Update _quarto.yml with new navigation
quarto_yml <- "_quarto.yml"

if (file_exists(quarto_yml)) {
  # Read existing _quarto.yml
  existing_yaml <- read_yaml(quarto_yml)
  # Update navbar section
  if (!is.null(existing_yaml$website)) {
    existing_yaml$website$navbar <- navbar
  } else {
    existing_yaml$website <- list(navbar = navbar)
  }
  # Write updated YAML
  write_yaml(existing_yaml, quarto_yml, handlers = list(
    logical = function(x) {
      result <- ifelse(x, "true", "false")
      class(result) <- "verbatim"
      return(result)
    }
  ))
  
  cat(sprintf("✅ Navigation updated in %s\n", quarto_yml))
} else {
  # Write just navbar to separate file if _quarto.yml doesn't exist
  write_yaml(list(navbar = navbar), output_file)
  cat(sprintf("⚠️  %s not found. Navigation written to %s\n", quarto_yml, output_file))
}

