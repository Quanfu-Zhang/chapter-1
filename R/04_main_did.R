# ==============================================================================
# Canonical matched analysis dataset and main DiD models
# ------------------------------------------------------------------------------
# Paper-aligned specification:
#   * post period begins in 2011/12 for annual income outcomes;
#   * low MMI = [4, 7), high MMI >= 7, matched North Island = control;
#   * controls: age, age^2, female reference person, household size;
#   * survey-wave and territorial-authority fixed effects;
#   * standard errors clustered by territorial authority;
#   * total expenditure uses the four full-expenditure waves only.
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(purrr)
  library(fixest)
})

source(file.path("R", "00_config.R"))
source(file.path("R", "01_hes_schema_adapter.R"))

load_one_matched_wave <- function(wave) {
  t_path <- file.path(MATCHED_TREATED_DIR, paste0(wave, ".csv"))
  c_path <- file.path(MATCHED_CONTROL_DIR, paste0("CG", wave, ".csv"))

  if (!file.exists(t_path)) {
    stop("Matched treated file not found: ", t_path, ". Run R/03_psm_matching.R first.")
  }
  if (!file.exists(c_path)) {
    stop("Matched control file not found: ", c_path, ". Run R/03_psm_matching.R first.")
  }

  treated <- read_csv(t_path, show_col_types = FALSE) %>%
    canonicalise_hes(wave) %>%
    mutate(treated = 1L)

  control <- read_csv(c_path, show_col_types = FALSE) %>%
    canonicalise_hes(wave) %>%
    mutate(treated = 0L)

  bind_rows(treated, control) %>% normalise_expense_names()
}

prepare_analysis_variables <- function(df) {
  if (!"mmi_intensity" %in% names(df)) df$mmi_intensity <- NA_real_
  if (!"group" %in% names(df)) df$group <- NA_character_

  df %>%
    filter(ref_person) %>%
    group_by(wave, snz_hes_hhld_uid) %>%
    slice(1L) %>%
    ungroup() %>%
    mutate(
      post = as.integer(wave %in% POST_WAVES),
      ref_age_sq = ref_age^2,
      female = recode_female(ref_sex),
      hh_tenure = factor(recode_tenure(tenure_code), levels = c("Owned/Trust", "Rented")),
      household_comp_group = factor(recode_household_comp(household_comp)),
      higher_education = recode_higher_education(ref_education),
      mmi_intensity = suppressWarnings(as.numeric(mmi_intensity)),
      treated_area = as.integer(treated == 1L),
      mmi_group = case_when(
        treated == 0L ~ "Control",
        treated == 1L & mmi_intensity >= LOW_MMI_MIN & mmi_intensity < HIGH_MMI_MIN ~ "Low",
        treated == 1L & mmi_intensity >= HIGH_MMI_MIN ~ "High",
        TRUE ~ NA_character_
      ),
      mmi_group = factor(mmi_group, levels = c("Control", "Low", "High")),
      wave = factor(as.character(wave), levels = WAVES),
      ta_code = factor(ta_code),
      log_income = if_else(total_income > -1, log1p(total_income), NA_real_),
      relocation = as.integer(group == "Group 2")
    ) %>%
    filter(
      !is.na(mmi_group),
      !is.na(ref_age),
      !is.na(female),
      !is.na(hh_size),
      !is.na(ta_code)
    )
}

load_matched_analysis_data <- function(waves = WAVES) {
  map_dfr(waves, load_one_matched_wave) %>% prepare_analysis_variables()
}

fit_main_did <- function(data, outcome) {
  stopifnot(outcome %in% names(data))

  fml <- as.formula(paste0(
    outcome,
    " ~ i(mmi_group, post, ref = 'Control') + ref_age + ref_age_sq + female + hh_size | wave + ta_code"
  ))

  feols(fml, data = data, cluster = ~ta_code)
}

fit_main_models <- function(df = load_matched_analysis_data()) {
  list(
    total_income = fit_main_did(df, "total_income"),
    regular_income = fit_main_did(df, "regular_income"),
    total_expenditure = fit_main_did(
      filter(df, as.character(wave) %in% FULL_EXPENDITURE_WAVES),
      "total_expenditure"
    )
  )
}
