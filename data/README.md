# Data Directory

This directory contains data for various analysis projects. Each project has its own subdirectory with a consistent structure.

## Directory Structure

```
data/
├── [project-name]/
│   ├── raw/           # Raw/extracted data from source documents
│   └── processed/     # Cleaned, standardised, analysis-ready datasets
```

## Project Structure

Each project subdirectory follows this pattern:

- **`raw/`**: Contains raw or initially extracted data (e.g., text extracted from PDFs, images, initial extractions). This data may require cleaning and validation.
- **`processed/`**: Contains cleaned, standardised datasets ready for analysis. These files should be:
  - Well-documented (column names, units, etc.)
  - Consistent in format
  - Suitable for direct use in analysis scripts

## Current Projects

### bible-society-uk-revival

Analysis of Bible Society UK survey data comparing 2018 and 2024 church attendance patterns.

- **Source documents**: `resources/papers/BibleSoc_Results_2018.pdf`, `BibleSoc_Results_2024.pdf`
- **Extracted data**: See `bible-society-uk-revival/processed/` for CSV files extracted from the PDFs

## File Naming Conventions

- Use lowercase with hyphens for file names: `survey-metadata.csv` not `Survey_Metadata.csv`
- Include project identifier if files might be moved or shared: `church-attendance-extracted.csv`
- Use descriptive names that indicate content and source

## Data Formats

For this project, data is stored as **CSV files** which are:
- Human-readable
- Easy to work with in R (via `readr`, `data.table`, etc.)
- Version control friendly (small files, text-based)

For larger datasets or relational data needs, consider SQLite databases.

## Notes

- Source documents (PDFs, original reports) remain in `resources/papers/`
- Data extraction notes and documentation are in `docs/tech-specs/[project-name]/`
- All data paths in analysis scripts should be relative to the project root

