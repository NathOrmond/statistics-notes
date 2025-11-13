# Bible Society "Quiet Revival" Claim - Initial Analysis
# Script 01: Data Loading, Red Flag Detection, and Preliminary Tests

library(tidyverse)
library(scales)
library(gt)
library(patchwork)

# Set working directory to project root
# setwd(here::here())

# Load data
attendance_data <- read_csv("church_attendance_extracted.csv")
survey_meta <- read_csv("survey_metadata.csv", comment = "#")

# ============================================================================
# SECTION 1: RED FLAG DETECTION
# ============================================================================

cat("\n", rep("=", 70), "\n")
cat("BIBLE SOCIETY 'QUIET REVIVAL' CLAIM - RED FLAG ANALYSIS\n")
cat(rep("=", 70), "\n\n")

# Red Flag #1: Internal Consistency in 2024 Data
cat("RED FLAG #1: Internal Consistency Check (2024 Survey)\n")
cat(rep("-", 70), "\n")

# Note: The "Church service" binary question measures Bible engagement at
# church services, not attendance. It's part of a question about Bible
# engagement in different locations. These are different constructs, so
# we would not expect them to match exactly.

freq_2024 <- attendance_data %>%
  filter(year == 2024, question_type == "frequency") %>%
  filter(response_category %in% c("Daily/almost daily", "A few times a week", 
                                   "About once a week", "About once a fortnight",
                                   "About once a month", "A few times a year",
                                   "About once a year"))

binary_2024 <- attendance_data %>%
  filter(year == 2024, question_type == "binary", 
         response_category == "Yes - in the past year")

freq_sum_total <- sum(freq_2024$total_pct, na.rm = TRUE)
binary_total <- binary_2024$total_pct

cat(sprintf("Sum of frequency categories (past year): %.0f%%\n", freq_sum_total))
cat(sprintf("Binary 'Yes - in the past year' response: %.0f%%\n", binary_total))
cat(sprintf("Discrepancy: %.0f percentage points\n\n", freq_sum_total - binary_total))

cat("Note: These measure different constructs (Bible engagement vs attendance),\n")
cat("so differences are expected. The fact that Bible engagement (24%) is\n")
cat("slightly lower than attendance frequency (26%) is logical: not everyone\n")
cat("who attends church engages with the Bible during services.\n\n")

# Red Flag #2: Sample Size Reduction
cat("RED FLAG #2: Sample Size Comparison\n")
cat(rep("-", 70), "\n")

n_2018 <- 19875
n_2024 <- 12455
pct_reduction <- (1 - n_2024/n_2018) * 100

cat(sprintf("2018 Weighted Sample: %s\n", format(n_2018, big.mark = ",")))
cat(sprintf("2024 Weighted Sample: %s\n", format(n_2024, big.mark = ",")))
cat(sprintf("Reduction: %.1f%%\n\n", pct_reduction))

if (pct_reduction > 20) {
  cat("🚩 MODERATE RED FLAG: Substantial sample size reduction\n")
  cat("   May indicate: sampling frame changes, response rate changes,\n")
  cat("   or methodology differences.\n\n")
} else {
  cat("✓ Sample sizes reasonably comparable.\n\n")
}

# Correction: Question Format
cat("CORRECTION: Question Format\n")
cat(rep("-", 70), "\n")
cat("After reviewing the actual survey PDFs:\n")
cat("2018: Frequency question about church attendance\n")
cat("2024: Same frequency question as 2018\n\n")
cat("✓ Both surveys use the same attendance frequency question.\n")
cat("  The 2024 survey also includes a separate question about\n")
cat("  Bible engagement at church services, but this measures a\n")
cat("  different construct than attendance.\n\n")
cat("  There is no question order effect from a binary attendance\n")
cat("  question, as no such question exists.\n\n")

# ============================================================================
# SECTION 2: BASIC POINT ESTIMATES WITH CONFIDENCE INTERVALS
# ============================================================================

cat("\n", rep("=", 70), "\n")
cat("SECTION 2: POINT ESTIMATES WITH 95% CONFIDENCE INTERVALS\n")
cat(rep("=", 70), "\n\n")

# Function to calculate CI for proportions with design effect
calc_ci <- function(p, n, deff = 1.5, conf_level = 0.95) {
  n_eff <- n / deff
  z <- qnorm((1 + conf_level) / 2)
  se <- sqrt(p * (1 - p) / n_eff)
  
  ci_lower <- p - z * se
  ci_upper <- p + z * se
  
  # Ensure bounds are between 0 and 1
  ci_lower <- max(0, ci_lower)
  ci_upper <- min(1, ci_upper)
  
  list(
    estimate = p,
    ci_lower = ci_lower,
    ci_upper = ci_upper,
    se = se,
    n_eff = n_eff
  )
}

# Calculate CIs for key metrics
key_metrics <- tribble(
  ~year, ~metric, ~percentage, ~n,
  2018, "At least once a week", 7, 19875,
  2024, "At least once a week", 11, 12455,
  2018, "Never", 63, 19875,
  2024, "Never", 59, 12455,
  2024, "Attended in past year (binary)", 24, 12455
)

# Note: Calculate "at least once a week" for 2024 from frequency data
weekly_2024 <- freq_2024 %>%
  filter(response_category %in% c("Daily/almost daily", "A few times a week", 
                                   "About once a week")) %>%
  pull(total_pct) %>%
  sum()

key_metrics$percentage[key_metrics$year == 2024 & 
                        key_metrics$metric == "At least once a week"] <- weekly_2024

# Calculate CIs (assuming design effect of 1.5, conservative estimate)
results <- key_metrics %>%
  mutate(
    p = percentage / 100,
    ci_calcs = map2(p, n, calc_ci, deff = 1.5)
  ) %>%
  unnest_wider(ci_calcs) %>%
  mutate(
    estimate_pct = estimate * 100,
    ci_lower_pct = ci_lower * 100,
    ci_upper_pct = ci_upper * 100,
    ci_width = ci_upper_pct - ci_lower_pct
  )

# Display results
results %>%
  select(year, metric, estimate_pct, ci_lower_pct, ci_upper_pct, ci_width) %>%
  mutate(
    `95% CI` = sprintf("[%.1f%%, %.1f%%]", ci_lower_pct, ci_upper_pct),
    `CI Width` = sprintf("%.1fpp", ci_width)
  ) %>%
  select(Year = year, Metric = metric, `Estimate (%)` = estimate_pct, 
         `95% CI`, `CI Width`) %>%
  gt() %>%
  fmt_number(columns = `Estimate (%)`, decimals = 1) %>%
  tab_header(
    title = "Church Attendance Estimates with 95% Confidence Intervals",
    subtitle = "Design effect = 1.5 assumed for YouGov panel"
  ) %>%
  tab_source_note("Note: Wider CIs indicate greater uncertainty in estimates") %>%
  print()

# ============================================================================
# SECTION 3: STATISTICAL SIGNIFICANCE TESTS
# ============================================================================

cat("\n", rep("=", 70), "\n")
cat("SECTION 3: HYPOTHESIS TESTS FOR CHANGES 2018 → 2024\n")
cat(rep("=", 70), "\n\n")

# Two-proportion z-test for key comparisons
prop_test <- function(p1, n1, p2, n2, deff = 1.5) {
  # Adjust for design effect
  n1_eff <- n1 / deff
  n2_eff <- n2 / deff
  
  # Pooled proportion
  p_pooled <- (p1 * n1_eff + p2 * n2_eff) / (n1_eff + n2_eff)
  
  # Test statistic
  se_pooled <- sqrt(p_pooled * (1 - p_pooled) * (1/n1_eff + 1/n2_eff))
  z <- (p2 - p1) / se_pooled
  
  # P-value (two-tailed)
  p_value <- 2 * pnorm(-abs(z))
  
  list(
    z_statistic = z,
    p_value = p_value,
    difference = (p2 - p1) * 100,
    significant = p_value < 0.05
  )
}

# Test 1: Change in "At least once a week"
test1_data <- results %>% filter(metric == "At least once a week")
test1 <- prop_test(
  test1_data$p[test1_data$year == 2018],
  test1_data$n[test1_data$year == 2018],
  test1_data$p[test1_data$year == 2024],
  test1_data$n[test1_data$year == 2024]
)

cat("Test 1: Change in 'At least once a week' attendance\n")
cat(rep("-", 70), "\n")
cat(sprintf("2018: %.1f%%  →  2024: %.1f%%\n", 
            test1_data$estimate_pct[1], test1_data$estimate_pct[2]))
cat(sprintf("Difference: %+.1f percentage points\n", test1$difference))
cat(sprintf("Z-statistic: %.3f\n", test1$z_statistic))
cat(sprintf("P-value: %.4f %s\n", test1$p_value, 
            ifelse(test1$significant, "(*)", "")))

if (test1$significant) {
  cat("\n✓ Statistically significant change (p < 0.05)\n")
} else {
  cat("\n✗ Not statistically significant (p ≥ 0.05)\n")
}

cat("\nInterpretation: ")
if (test1$significant) {
  cat("There is statistical evidence of an increase in weekly attendance.\n")
  cat("However, statistical significance ≠ practical significance!\n")
  cat(sprintf("The %.1fpp change is small and could be explained by:\n", test1$difference))
  cat("  - Note: Both surveys use the same frequency question\n")
  cat("  - Demographic composition changes\n")
  cat("  - Measurement error\n")
} else {
  cat("No statistical evidence of change in weekly attendance.\n")
}

# Test 2: Change in "Never" attendance
test2_data <- results %>% filter(metric == "Never")
test2 <- prop_test(
  test2_data$p[test2_data$year == 2018],
  test2_data$n[test2_data$year == 2018],
  test2_data$p[test2_data$year == 2024],
  test2_data$n[test2_data$year == 2024]
)

cat("\n", rep("-", 70), "\n")
cat("Test 2: Change in 'Never' attended\n")
cat(rep("-", 70), "\n")
cat(sprintf("2018: %.1f%%  →  2024: %.1f%%\n", 
            test2_data$estimate_pct[1], test2_data$estimate_pct[2]))
cat(sprintf("Difference: %+.1f percentage points\n", test2$difference))
cat(sprintf("Z-statistic: %.3f\n", test2$z_statistic))
cat(sprintf("P-value: %.4f %s\n\n", test2$p_value, 
            ifelse(test2$significant, "(*)", "")))

# ============================================================================
# SECTION 4: EFFECT SIZE CALCULATIONS
# ============================================================================

cat("\n", rep("=", 70), "\n")
cat("SECTION 4: EFFECT SIZE (PRACTICAL SIGNIFICANCE)\n")
cat(rep("=", 70), "\n\n")

# Cohen's h for proportion differences
cohens_h <- function(p1, p2) {
  2 * (asin(sqrt(p2)) - asin(sqrt(p1)))
}

h1 <- cohens_h(test1_data$p[1], test1_data$p[2])
h2 <- cohens_h(test2_data$p[1], test2_data$p[2])

interpret_h <- function(h) {
  abs_h <- abs(h)
  if (abs_h < 0.2) return("Negligible")
  if (abs_h < 0.5) return("Small")
  if (abs_h < 0.8) return("Medium")
  return("Large")
}

cat("Cohen's h effect sizes:\n")
cat(rep("-", 70), "\n")
cat(sprintf("Weekly attendance change: h = %.3f (%s)\n", 
            h1, interpret_h(h1)))
cat(sprintf("'Never' attendance change: h = %.3f (%s)\n\n", 
            h2, interpret_h(h2)))

cat("Interpretation guidelines for Cohen's h:\n")
cat("  h < 0.2  : Negligible effect\n")
cat("  0.2 ≤ h < 0.5 : Small effect\n")
cat("  0.5 ≤ h < 0.8 : Medium effect\n")
cat("  h ≥ 0.8  : Large effect\n\n")

# ============================================================================
# SECTION 5: PRELIMINARY VISUALISATION
# ============================================================================

cat("\n", rep("=", 70), "\n")
cat("SECTION 5: CREATING PRELIMINARY VISUALISATIONS\n")
cat(rep("=", 70), "\n\n")

# Visualisation 1: Point estimates with error bars
p1 <- results %>%
  filter(metric %in% c("At least once a week", "Never")) %>%
  ggplot(aes(x = factor(year), y = estimate_pct, colour = factor(year))) +
  geom_point(size = 4) +
  geom_errorbar(aes(ymin = ci_lower_pct, ymax = ci_upper_pct), 
                width = 0.2, linewidth = 1) +
  facet_wrap(~metric, scales = "free_y") +
  scale_colour_manual(values = c("2018" = "#D55E00", "2024" = "#0072B2")) +
  labs(
    title = "Church Attendance: 2018 vs 2024",
    subtitle = "Point estimates with 95% confidence intervals (design effect = 1.5)",
    x = "Survey Year",
    y = "Percentage (%)",
    caption = "Source: Bible Society UK / YouGov Surveys"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "none",
    plot.title = element_text(face = "bold", size = 14),
    panel.grid.minor = element_blank()
  )

ggsave("plot_01_point_estimates_ci.png", p1, width = 10, height = 6, dpi = 300)
cat("✓ Saved: plot_01_point_estimates_ci.png\n")

# Visualisation 2: Full frequency distribution comparison
freq_comparison <- attendance_data %>%
  filter(question_type == "frequency", 
         !response_category %in% c("At least once a week", "At least once a month",
                                    "Not answered")) %>%
  mutate(
    response_category = factor(response_category, levels = c(
      "Daily/almost daily", "A few times a week", "About once a week",
      "About once a fortnight", "About once a month", "A few times a year",
      "About once a year", "Hardly ever", "Never"
    ))
  )

p2 <- freq_comparison %>%
  ggplot(aes(x = response_category, y = total_pct, fill = factor(year))) +
  geom_col(position = "dodge", alpha = 0.8) +
  scale_fill_manual(values = c("2018" = "#D55E00", "2024" = "#0072B2"),
                    name = "Survey Year") +
  coord_flip() +
  labs(
    title = "Church Attendance Frequency Distribution",
    subtitle = "Comparison of 2018 and 2024 YouGov Surveys",
    x = NULL,
    y = "Percentage (%)",
    caption = "Source: Bible Society UK / YouGov Surveys\nNote: Different question formats used (see methodology)"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "bottom",
    panel.grid.major.y = element_blank()
  )

ggsave("plot_02_frequency_distribution.png", p2, width = 10, height = 6, dpi = 300)
cat("✓ Saved: plot_02_frequency_distribution.png\n")

# ============================================================================
# SECTION 6: SUMMARY AND CONCLUSIONS
# ============================================================================

cat("\n", rep("=", 70), "\n")
cat("PRELIMINARY ANALYSIS SUMMARY\n")
cat(rep("=", 70), "\n\n")

cat("KEY FINDINGS:\n")
cat("1. Weekly attendance: 7% (2018) → 11% (2024)\n")
cat(sprintf("   Change: +%.1fpp, p = %.4f %s\n", 
            test1$difference, test1$p_value,
            ifelse(test1$significant, "*", "")))
cat(sprintf("   Effect size: Cohen's h = %.3f (%s)\n\n", 
            h1, interpret_h(h1)))

cat("2. Never attended: 63% (2018) → 59% (2024)\n")
cat(sprintf("   Change: %.1fpp, p = %.4f %s\n", 
            test2$difference, test2$p_value,
            ifelse(test2$significant, "*", "")))
cat(sprintf("   Effect size: Cohen's h = %.3f (%s)\n\n", 
            h2, interpret_h(h2)))

cat("CRITICAL RED FLAGS IDENTIFIED:\n")
cat("✓ Both surveys use the same frequency question about attendance\n")
cat("🚩 Internal inconsistency in 2024 data (frequency sum ≠ binary response)\n")
cat("🚩 Sample size reduced by 37% between surveys\n")
cat("🚩 No demographic adjustment for immigration (217k-255k Ukrainians,\n")
cat("   163k+ Hong Kong BN(O) visa holders)\n")
cat("🚩 No triangulation with belief measures provided\n")
cat("🚩 Attendance ≠ belief or commitment\n\n")

cat("CONCLUSION:\n")
cat("While there are statistically significant changes in some attendance\n")
cat("measures, the evidence does NOT support a 'Quiet Revival' claim because:\n\n")
cat("  1. Effect sizes are small (Cohen's h < 0.5)\n")
cat("  2. Multiple methodological confounds present\n")
cat("  3. Note: The 'Church service' binary question measures Bible\n")
cat("     engagement, not attendance, so it's a different construct\n")
cat("  4. No evidence of belief or commitment changes\n")
cat("  5. Demographic composition changes not accounted for\n\n")

cat("NEXT STEPS RECOMMENDED:\n")
cat("  ☐ Extract full demographic breakdowns\n")
cat("  ☐ Perform demographic standardisation\n")
cat("  ☐ Analyse by age/ethnicity subgroups\n")
cat("  ☐ Calculate compositional effects\n")
cat("  ☐ Sensitivity analyses with different design effects\n")
cat("  ☐ Triangulate with belief measures\n\n")

cat(rep("=", 70), "\n")
cat("Analysis complete. Check output files for visualisations.\n")
cat(rep("=", 70), "\n\n")