# ==============================================================================
# Detailed expenditure models and income-group heterogeneity
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(fixest)
  library(purrr)
})

source(file.path("R", "00_config.R"))
source(file.path("R", "04_main_did.R"))

prepare_expenditure_outcomes <- function(df) {
  exp_vars <- grep("^expense_", names(df), value = TRUE)

  df %>%
    filter(as.character(wave) %in% FULL_EXPENDITURE_WAVES) %>%
    mutate(
      across(all_of(exp_vars), ~ suppressWarnings(as.numeric(.x))),
      across(all_of(exp_vars), ~ log1p(abs(.x)), .names = "logabs_{.col}")
    )
}

fit_expenditure_categories <- function(df) {
  out_vars <- grep("^logabs_expense_", names(df), value = TRUE)

  set_names(out_vars) %>%
    map(function(outcome) {
      fml <- as.formula(paste0(
        outcome,
        " ~ i(mmi_group, post, ref = 'Control') + ref_age + ref_age_sq + female + hh_size | wave + ta_code"
      ))
      feols(fml, data = df, cluster = ~ta_code)
    })
}

add_wave_income_group <- function(df) {
  df %>%
    group_by(wave) %>%
    mutate(
      wave_median_income = median(total_income, na.rm = TRUE),
      income_group = if_else(total_income > wave_median_income, "Above median", "At/below median")
    ) %>%
    ungroup()
}

# Example:
# df <- load_matched_analysis_data() %>% prepare_expenditure_outcomes() %>% add_wave_income_group()
# all_models <- fit_expenditure_categories(df)
# high_models <- fit_expenditure_categories(filter(df, income_group == "Above median"))
# low_models  <- fit_expenditure_categories(filter(df, income_group == "At/below median"))
