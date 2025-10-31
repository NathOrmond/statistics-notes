# Bible Society UK Revival Analysis Data

This directory contains data for the Bible Society UK survey analysis comparing 2018 and 2024 church attendance patterns.

## Source Documents

Original survey reports are stored in `resources/papers/`:
- `BibleSoc_Results_2018.pdf` - 2018 survey results
- `BibleSoc_Results_2024.pdf` - 2024 survey results

## Data Files

### Processed Data

All extracted and cleaned data is in `processed/`:

- **`survey-metadata.csv`**: Metadata about the surveys (sample sizes, fieldwork dates, methodology notes)
- **`church-attendance-extracted.csv`**: Extracted church attendance data with demographic breakdowns by year

### Raw Data

The `raw/` directory is currently empty. It can be used for:
- Initial text extractions from PDFs
- Raw data exports before cleaning
- Intermediate processing files

## Data Extraction Notes

⚠️ **Important**: All data in this directory was manually extracted from PDF reports and may contain errors. Please verify against source documents.

For detailed extraction notes, methodological issues, and analysis plans, see:
- `docs/tech-specs/bible-society-review/overview.md`
- `docs/tech-specs/bible-society-review/red-flag-summary.md`

## Usage in Analysis

When loading data in R scripts or Quarto documents, use paths relative to the project root:

```r
# Load survey metadata
metadata <- read_csv("data/bible-society-uk-revival/processed/survey-metadata.csv")

# Load attendance data
attendance <- read_csv("data/bible-society-uk-revival/processed/church-attendance-extracted.csv")
```

