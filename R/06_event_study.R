# ==============================================================================
# Event-study estimates and joint pre-trend tests
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

  # Event-study uses treated area (all eligible MMI-treated households) rather than
  # separate low/high interactions. Controls are the matched North Island sample.
  dat <- dat %>% mutate(treated_area = as.integer(treated == 1L))

  fml <- as.formula(paste0(
    outcome,
    " ~ i(wave, treated_area, ref = '0607') + ref_age + ref_age_sq + female + hh_size | wave + ta_code"
  ))

  feols(fml, data = dat, cluster = ~ta_code)
}

# Joint pre-trend tests should be run on the exact coefficient names returned by
# `coefnames(model)` to avoid hard-coding package-version-dependent labels.
# Example:
# m_income <- fit_event_study(df, "total_income")
# coefnames(m_income)
# wald(m_income, keep = "treated_area.*(0708|0809|0910|1011)")
