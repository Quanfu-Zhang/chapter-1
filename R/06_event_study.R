# ==============================================================================
# Event-study estimates and joint pre-trend tests (Appendix C)
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(fixest)
})

source(file.path("R", "04_main_did.R"))

fit_event_study <- function(df, outcome, expenditure = FALSE) {
  dat <- df
  if (expenditure) {
    dat <- dat %>% filter(as.character(wave) %in% FULL_EXPENDITURE_WAVES)
  }

  fml <- as.formula(paste0(
    outcome,
    " ~ i(wave, treated_area, ref = '0607') + ref_age + ref_age_sq + female + hh_size | wave + ta_code"
  ))

  feols(fml, data = dat, cluster = ~ta_code)
}

run_pretrend_test <- function(model, expenditure = FALSE) {
  pre_waves <- if (expenditure) "0910" else c("0708", "0809", "0910", "1011")
  pattern <- paste0("wave::(", paste(pre_waves, collapse = "|"), "):treated_area")
  wald(model, keep = pattern)
}

fit_event_study_models <- function(df = load_matched_analysis_data()) {
  models <- list(
    total_income = fit_event_study(df, "total_income"),
    regular_income = fit_event_study(df, "regular_income"),
    total_expenditure = fit_event_study(df, "total_expenditure", expenditure = TRUE)
  )

  tests <- list(
    total_income = run_pretrend_test(models$total_income),
    regular_income = run_pretrend_test(models$regular_income),
    total_expenditure = run_pretrend_test(models$total_expenditure, expenditure = TRUE)
  )

  list(models = models, pretrend_tests = tests)
}
