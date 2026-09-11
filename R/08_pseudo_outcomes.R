# ==============================================================================
# Pseudo-outcome composition diagnostics (Appendix B)
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(purrr)
  library(fixest)
})

source(file.path("R", "00_config.R"))
source(file.path("R", "01_hes_schema_adapter.R"))
source(file.path("R", "04_main_did.R"))

# A deliberately light loader: pseudo-outcome regressions should not condition
# the sample on the variable that is itself being tested as an outcome.
load_pseudo_outcome_data <- function(waves = WAVES) {
  map_dfr(waves, function(w) {
    raw <- load_one_matched_wave(w)
    raw %>%
      filter(ref_person) %>%
      group_by(wave, snz_hes_hhld_uid) %>%
      slice(1L) %>%
      ungroup() %>%
      mutate(
        wave = factor(as.character(wave), levels = WAVES),
        post = as.integer(as.character(wave) %in% POST_WAVES),
        ta_code = factor(ta_code),
        treated_area = as.integer(treated == 1L),
        female = recode_female(ref_sex),
        owned_trust = as.integer(recode_tenure(tenure_code) == "Owned/Trust"),
        higher_education = recode_higher_education(ref_education),
        household_comp_group = recode_household_comp(household_comp)
      )
  })
}

fit_pseudo_outcome <- function(df, outcome, weights = NULL) {
  fml <- as.formula(paste0(outcome, " ~ treated_area:post | wave + ta_code"))
  if (is.null(weights)) {
    feols(fml, data = df, cluster = ~ta_code)
  } else {
    feols(fml, data = df, weights = weights, cluster = ~ta_code)
  }
}

fit_key_covariate_pseudo_outcomes <- function(df = load_pseudo_outcome_data()) {
  dat <- df %>% filter(as.character(wave) %in% FULL_EXPENDITURE_WAVES)
  vars <- c("ref_age", "hh_size", "female", "owned_trust", "higher_education")
  set_names(vars) %>% map(~ fit_pseudo_outcome(dat, .x))
}

composition_indicators <- function(df) {
  categories <- c(
    "One-family household",
    "Two-family household",
    "Three-or-more-family household",
    "Other multi-person household",
    "One-person household",
    "Unidentifiable household"
  )

  out <- df
  for (cat in categories) {
    nm <- make.names(cat)
    out[[paste0("comp_", nm)]] <- as.integer(out$household_comp_group == cat)
  }

  out$comp_Non.family.or.one.person.household <- as.integer(
    out$household_comp_group %in% c("Other multi-person household", "One-person household")
  )
  out
}

fit_household_composition_pseudo_outcomes <- function(
    df = load_pseudo_outcome_data(),
    analysis_weights = NULL) {

  dat <- composition_indicators(df)
  vars <- grep("^comp_", names(dat), value = TRUE)

  list(
    unweighted = set_names(vars) %>% map(~ fit_pseudo_outcome(dat, .x)),
    weighted = if (is.null(analysis_weights)) NULL else
      set_names(vars) %>% map(~ fit_pseudo_outcome(dat, .x, weights = analysis_weights))
  )
}
