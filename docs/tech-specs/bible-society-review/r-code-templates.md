# R Code Templates for Bible Society Analysis

## Template 1: Confidence Intervals with Design Effect

```r
# Calculate 95% CI for a proportion with design effect correction
calc_prop_ci <- function(p, n, deff = 1.5, conf_level = 0.95) {
  n_eff <- n / deff
  z <- qnorm((1 + conf_level) / 2)
  se <- sqrt(p * (1 - p) / n_eff)
  
  ci_lower <- max(0, p - z * se)
  ci_upper <- min(1, p + z * se)
  
  tibble(
    estimate = p,
    se = se,
    ci_lower = ci_lower,
    ci_upper = ci_upper,
    ci_width = ci_upper - ci_lower,
    n_effective = n_eff
  )
}

# Usage
calc_prop_ci(p = 0.07, n = 19875, deff = 1.5)
```

## Template 2: Two-Proportion Z-Test

```r
# Test for difference between two proportions
test_prop_difference <- function(p1, n1, p2, n2, deff = 1.5) {
  n1_eff <- n1 / deff
  n2_eff <- n2 / deff
  
  p_pooled <- (p1 * n1_eff + p2 * n2_eff) / (n1_eff + n2_eff)
  se_pooled <- sqrt(p_pooled * (1 - p_pooled) * (1/n1_eff + 1/n2_eff))
  
  z <- (p2 - p1) / se_pooled
  p_value <- 2 * pnorm(-abs(z))
  
  tibble(
    p1 = p1,
    p2 = p2,
    difference = p2 - p1,
    difference_pct = (p2 - p1) * 100,
    z_statistic = z,
    p_value = p_value,
    significant = p_value < 0.05
  )
}

# Usage
test_prop_difference(p1 = 0.07, n1 = 19875, p2 = 0.11, n2 = 12455)
```

## Template 3: Cohen's h Effect Size

```r
# Calculate Cohen's h for proportion differences
cohens_h <- function(p1, p2) {
  h <- 2 * (asin(sqrt(p2)) - asin(sqrt(p1)))
  
  magnitude <- case_when(
    abs(h) < 0.2 ~ "Negligible",
    abs(h) < 0.5 ~ "Small",
    abs(h) < 0.8 ~ "Medium",
    TRUE ~ "Large"
  )
  
  tibble(
    p1 = p1,
    p2 = p2,
    cohens_h = h,
    magnitude = magnitude
  )
}

# Usage
cohens_h(p1 = 0.07, p2 = 0.11)
```

## Template 4: Demographic Standardisation

```r
# Direct standardisation: Apply reference population weights to study rates
direct_standardisation <- function(rates_df, pop_df, 
                                    rate_var = "rate", 
                                    group_var = "group",
                                    weight_var = "population_weight") {
  
  # Join rates with population weights
  standardised <- rates_df %>%
    left_join(pop_df, by = group_var) %>%
    mutate(
      weighted_rate = !!sym(rate_var) * !!sym(weight_var)
    )
  
  # Calculate age-standardised rate
  asr <- standardised %>%
    summarise(
      age_standardised_rate = sum(weighted_rate),
      crude_rate = weighted.mean(!!sym(rate_var), !!sym(weight_var))
    )
  
  return(asr)
}

# Example usage:
# rates_2024 <- tibble(
#   age_group = c("18-34", "35-54", "55+"),
#   rate = c(0.26, 0.18, 0.27)
# )
# 
# pop_2018 <- tibble(
#   age_group = c("18-34", "35-54", "55+"),
#   population_weight = c(0.3, 0.35, 0.35)
# )
# 
# direct_standardisation(rates_2024, pop_2018, 
#                        rate_var = "rate", 
#                        group_var = "age_group")
```

## Template 5: Compositional Effect Decomposition

```r
# Decompose change into compositional and behavioural effects
decompose_change <- function(rates_2018, weights_2018, 
                              rates_2024, weights_2024) {
  
  # Overall rates
  overall_2018 <- sum(rates_2018 * weights_2018)
  overall_2024 <- sum(rates_2024 * weights_2024)
  total_change <- overall_2024 - overall_2018
  
  # Compositional effect (population structure change)
  # Hold rates constant at 2018, apply 2024 weights
  compositional_effect <- sum(rates_2018 * weights_2024) - overall_2018
  
  # Behavioural effect (rate changes within groups)
  # Hold weights constant at 2024, apply 2024 rates
  behavioural_effect <- overall_2024 - sum(rates_2018 * weights_2024)
  
  tibble(
    overall_2018 = overall_2018,
    overall_2024 = overall_2024,
    total_change = total_change,
    compositional_effect = compositional_effect,
    behavioural_effect = behavioural_effect,
    pct_compositional = 100 * compositional_effect / total_change,
    pct_behavioural = 100 * behavioural_effect / total_change
  )
}

# Example usage:
# rates_2018 <- c(0.26, 0.18, 0.27)  # Age groups: 18-34, 35-54, 55+
# weights_2018 <- c(0.29, 0.34, 0.37)
# rates_2024 <- c(0.26, 0.18, 0.27)  # Assume rates unchanged (null hypothesis)
# weights_2024 <- c(0.26, 0.33, 0.40)  # Shifted towards older
# 
# decompose_change(rates_2018, weights_2018, rates_2024, weights_2024)
```

## Template 6: Stratified Analysis with Forest Plot

```r
# Perform analysis within each subgroup and create forest plot
stratified_analysis <- function(data, strata_var, outcome_var, year_var) {
  
  results <- data %>%
    group_by(!!sym(strata_var)) %>%
    summarise(
      rate_2018 = mean(!!sym(outcome_var)[!!sym(year_var) == 2018]),
      rate_2024 = mean(!!sym(outcome_var)[!!sym(year_var) == 2024]),
      n_2018 = sum(!!sym(year_var) == 2018),
      n_2024 = sum(!!sym(year_var) == 2024),
      .groups = "drop"
    ) %>%
    mutate(
      difference = rate_2024 - rate_2018,
      # Calculate CIs
      ci_lower = difference - 1.96 * sqrt(
        rate_2018 * (1 - rate_2018) / n_2018 + 
        rate_2024 * (1 - rate_2024) / n_2024
      ),
      ci_upper = difference + 1.96 * sqrt(
        rate_2018 * (1 - rate_2018) / n_2018 + 
        rate_2024 * (1 - rate_2024) / n_2024
      )
    )
  
  # Create forest plot
  p <- ggplot(results, aes(x = !!sym(strata_var), y = difference)) +
    geom_hline(yintercept = 0, linetype = "dashed", colour = "grey50") +
    geom_pointrange(aes(ymin = ci_lower, ymax = ci_upper),
                    size = 0.5, fatten = 2) +
    coord_flip() +
    labs(
      title = "Stratified Analysis: Change in Attendance Rate",
      subtitle = "2018 to 2024",
      x = NULL,
      y = "Difference in Rate (2024 - 2018) with 95% CI"
    ) +
    theme_minimal()
  
  list(results = results, plot = p)
}
```

## Template 7: Sensitivity Analysis

```r
# Test robustness of conclusions to different assumptions
sensitivity_analysis <- function(p1, n1, p2, n2, 
                                  deff_range = c(1.0, 1.5, 2.0, 2.5, 3.0)) {
  
  map_df(deff_range, function(deff) {
    test_result <- test_prop_difference(p1, n1, p2, n2, deff = deff)
    ci_result <- calc_prop_ci(p2, n2, deff = deff)
    
    tibble(
      design_effect = deff,
      difference_pct = test_result$difference_pct,
      p_value = test_result$p_value,
      significant = test_result$significant,
      ci_lower = ci_result$ci_lower,
      ci_upper = ci_result$ci_upper,
      ci_width = ci_result$ci_width
    )
  })
}

# Usage
sensitivity_results <- sensitivity_analysis(
  p1 = 0.07, n1 = 19875, 
  p2 = 0.11, n2 = 12455
)

# Visualise
ggplot(sensitivity_results, aes(x = design_effect, y = difference_pct)) +
  geom_line() +
  geom_ribbon(aes(ymin = ci_lower * 100, ymax = ci_upper * 100), 
              alpha = 0.3) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(
    title = "Sensitivity to Design Effect Assumption",
    x = "Design Effect",
    y = "Estimated Difference (%)"
  ) +
  theme_minimal()
```

## Template 8: Publication-Quality Comparison Plot

```r
# Create comparison plot with error bars
create_comparison_plot <- function(data, measure_name) {
  
  p <- data %>%
    mutate(year = factor(year)) %>%
    ggplot(aes(x = year, y = estimate, colour = year)) +
    geom_pointrange(
      aes(ymin = ci_lower, ymax = ci_upper),
      size = 1,
      fatten = 3,
      position = position_dodge(width = 0.3)
    ) +
    scale_colour_manual(
      values = c("2018" = "#D55E00", "2024" = "#0072B2"),
      guide = "none"
    ) +
    scale_y_continuous(labels = percent_format(accuracy = 1)) +
    labs(
      title = str_glue("Church Attendance: {measure_name}"),
      subtitle = "Point estimates with 95% confidence intervals",
      x = "Survey Year",
      y = "Percentage",
      caption = str_glue(
        "Source: Bible Society UK / YouGov Surveys\n",
        "Error bars show 95% CIs with design effect = 1.5"
      )
    ) +
    theme_minimal(base_size = 13) +
    theme(
      plot.title = element_text(face = "bold", size = 15),
      plot.caption = element_text(hjust = 0, size = 9, colour = "grey50"),
      panel.grid.minor = element_blank()
    )
  
  return(p)
}
```

## Template 9: Summary Statistics Table

```r
# Create comprehensive summary table
create_summary_table <- function(results_df) {
  
  results_df %>%
    select(
      Metric = metric,
      `2018 (%)` = estimate_2018,
      `2024 (%)` = estimate_2024,
      `Change (pp)` = change,
      `95% CI` = ci,
      `P-value` = p_value,
      `Effect Size` = effect_size,
      Interpretation = interpretation
    ) %>%
    gt() %>%
    tab_header(
      title = "Church Attendance Changes: 2018 vs 2024",
      subtitle = "Statistical summary with confidence intervals and effect sizes"
    ) %>%
    fmt_number(columns = c(`2018 (%)`, `2024 (%)`, `Change (pp)`), 
               decimals = 1) %>%
    fmt_number(columns = `P-value`, decimals = 4) %>%
    tab_style(
      style = cell_fill(color = "lightyellow"),
      locations = cells_body(
        columns = everything(),
        rows = `P-value` < 0.05
      )
    ) %>%
    tab_footnote(
      footnote = "Highlighted rows are statistically significant (p < 0.05)",
      locations = cells_column_labels(columns = `P-value`)
    ) %>%
    tab_source_note(
      source_note = "Design effect = 1.5 assumed for YouGov panel sampling"
    )
}
```

## Template 10: Waterfall Chart for Decomposition

```r
# Visualise compositional vs behavioural effects
create_waterfall_plot <- function(decomp_result) {
  
  waterfall_data <- tribble(
    ~step, ~value, ~type,
    "2018 Rate", decomp_result$overall_2018, "base",
    "Compositional\nEffect", decomp_result$compositional_effect, "change",
    "Behavioural\nEffect", decomp_result$behavioural_effect, "change",
    "2024 Rate", decomp_result$overall_2024, "final"
  ) %>%
    mutate(
      step = factor(step, levels = step),
      cumulative = cumsum(replace_na(value, 0)),
      end = cumulative,
      start = lag(cumulative, default = 0)
    )
  
  ggplot(waterfall_data, aes(x = step, fill = type)) +
    geom_rect(aes(xmin = as.numeric(step) - 0.4, 
                  xmax = as.numeric(step) + 0.4,
                  ymin = start, ymax = end)) +
    geom_text(aes(y = (start + end) / 2, 
                  label = percent(value, accuracy = 0.1)),
              size = 4) +
    scale_fill_manual(
      values = c("base" = "grey70", "change" = "steelblue", "final" = "grey70"),
      guide = "none"
    ) +
    scale_y_continuous(labels = percent_format()) +
    labs(
      title = "Decomposition of Attendance Change",
      subtitle = "How much is demographic composition vs behavioural change?",
      x = NULL,
      y = "Attendance Rate",
      caption = "Compositional effect = change due to population demographics\nBehavioural effect = change in attendance rates within groups"
    ) +
    theme_minimal(base_size = 12) +
    theme(
      panel.grid.major.x = element_blank(),
      plot.caption = element_text(hjust = 0, size = 9, colour = "grey50")
    )
}
```

## Complete Workflow Example

```r
library(tidyverse)
library(scales)
library(gt)
library(patchwork)

# 1. Load data
attendance <- read_csv("data/church_attendance_extracted.csv")

# 2. Calculate 2018 estimates with CIs
results_2018 <- attendance %>%
  filter(year == 2018) %>%
  mutate(
    ci_results = map2(total_pct / 100, 19875, calc_prop_ci, deff = 1.5)
  ) %>%
  unnest_wider(ci_results)

# 3. Calculate 2024 estimates with CIs
results_2024 <- attendance %>%
  filter(year == 2024) %>%
  mutate(
    ci_results = map2(total_pct / 100, 12455, calc_prop_ci, deff = 1.5)
  ) %>%
  unnest_wider(ci_results)

# 4. Test for significant changes
key_comparisons <- tribble(
  ~measure, ~p1, ~p2,
  "Weekly+", 0.07, 0.11,
  "Never", 0.63, 0.59
) %>%
  mutate(
    test_results = map2(p1, p2, ~test_prop_difference(
      .x, 19875, .y, 12455, deff = 1.5
    ))
  ) %>%
  unnest_wider(test_results)

# 5. Calculate effect sizes
key_comparisons <- key_comparisons %>%
  mutate(
    effect_size = map2(p1, p2, cohens_h)
  ) %>%
  unnest_wider(effect_size)

# 6. Create visualisations
p1 <- create_comparison_plot(results_2024 %>% filter(metric == "Weekly+"),
                              "At Least Weekly Attendance")
p2 <- create_comparison_plot(results_2024 %>% filter(metric == "Never"),
                              "Never Attended")

combined_plot <- p1 + p2 + plot_layout(ncol = 2)
ggsave("outputs/comparison_plots.png", combined_plot, width = 14, height = 6)

# 7. Create summary table
summary_table <- create_summary_table(key_comparisons)
gtsave(summary_table, "outputs/summary_table.html")

# 8. Print key findings
cat("Key Findings:\n")
cat("=============\n\n")
print(key_comparisons %>% 
        select(measure, difference_pct, p_value, cohens_h, magnitude))
```

---

## Notes on Code Style

All code follows these principles:
- Uses tidyverse conventions (`%>%` pipe, `tibble`, `ggplot2`)
- Includes informative comments
- Returns tibbles for easy manipulation
- Creates publication-quality visualisations
- Handles edge cases (e.g., proportions bounded at 0 and 1)
- Includes design effect corrections throughout
- Uses consistent naming (`_` for functions, `.` avoided)

## Statistical Assumptions

All templates assume:
- Simple random sampling (adjusted by design effect)
- Independent observations
- Large sample sizes (normal approximation valid)
- Missing data MCAR (missing completely at random)

## Customisation

To adapt these templates:
1. Change `deff` parameter if you have better estimates
2. Adjust confidence level (`conf_level`) if needed
3. Modify plot aesthetics to match your preferences
4. Add additional demographic variables as needed