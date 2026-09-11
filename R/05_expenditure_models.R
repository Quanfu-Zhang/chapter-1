# ==============================================================================
# Detailed expenditure models and income-group heterogeneity
# ------------------------------------------------------------------------------
# Category outcomes are transformed as log(1 + |expenditure|), matching the
# accepted manuscript. The richer category specification includes housing tenure,
# female reference person, log household income, age, age squared, household
# size, wave fixed effects, TA fixed effects, and TA-clustered standard errors.
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(fixest)
  library(purrr)
})

source(file.path("R", "00_config.R"))
source(file.path("R", "04_main_did.R"))

PAPER_EXPENDITURE_VARS <- c(
  "expense_DOMESTIC.FUEL...POWER",
  "expense_HOUSING.COSTS",
  "expense_RECEIPTS...REFUNDS",
  "expense_GENERAL.INSURANCE",
  "expense_MISCELLANEOUS.PAYMENTS",
  "expense_MORTGAGES...LOANS",
  "expense_OTHER.PROPERTY",
  "expense_TRANSPORTATION",
  "expense_CONTRIBUTION.SCHEMES",
  "expense_MEDICAL...HEALTH",
  "expense_DIARY",
  "expense_TRAVEL",
  "expense_TELECOMMUNICATIONS",
  "expense_FEES.AND.SUBS",
  "expense_ED..REC..SPORT...CULTURE",
  "expense_HOUSEHOLD.OPERATIONS",
  "expense_HOUSEHOLD.MAINTENANCE",
  "expense_CREDIT.DEBIT.ACCOUNTS"
)

prepare_expenditure_outcomes <- function(df) {
  dat <- df %>% filter(as.character(wave) %in% FULL_EXPENDITURE_WAVES)
  present <- intersect(PAPER_EXPENDITURE_VARS, names(dat))

  if (!length(present)) {
    stop("No paper expenditure-category variables were found in the analysis data.")
  }

  dat %>%
    mutate(
      across(all_of(present), ~ suppressWarnings(as.numeric(.x))),
      across(all_of(present), ~ log1p(abs(.x)), .names = "logabs_{.col}")
    )
}

fit_one_expenditure_category <- function(df, outcome) {
  stopifnot(outcome %in% names(df))

  fml <- as.formula(paste0(
    outcome,
    " ~ i(mmi_group, post, ref = 'Control') + hh_tenure + female + log_income + ",
    "ref_age + ref_age_sq + hh_size | wave + ta_code"
  ))

  feols(fml, data = df, cluster = ~ta_code)
}

fit_expenditure_categories <- function(df) {
  out_vars <- grep("^logabs_expense_", names(df), value = TRUE)
  set_names(out_vars) %>% map(~ fit_one_expenditure_category(df, .x))
}

add_wave_income_group <- function(df) {
  df %>%
    group_by(wave) %>%
    mutate(
      wave_median_income = median(total_income, na.rm = TRUE),
      income_group = case_when(
        total_income > wave_median_income ~ "Above median",
        total_income <= wave_median_income ~ "At/below median",
        TRUE ~ NA_character_
      )
    ) %>%
    ungroup() %>%
    mutate(income_group = factor(income_group, levels = c("At/below median", "Above median")))
}

fit_income_heterogeneity <- function(df) {
  dat <- df %>%
    prepare_expenditure_outcomes() %>%
    add_wave_income_group()

  list(
    above_median = fit_expenditure_categories(
      filter(dat, income_group == "Above median")
    ),
    at_or_below_median = fit_expenditure_categories(
      filter(dat, income_group == "At/below median")
    )
  )
}

# Convert a log-scale treatment coefficient into the percentage-change measure
# shown in Figures 2 and 3: 100 * (exp(beta) - 1).
log_coefficient_to_percent <- function(beta) 100 * (exp(beta) - 1)
