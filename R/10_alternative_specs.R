# ==============================================================================
# Alternative intensity and functional-form checks (Appendix H)
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(fixest)
  library(purrr)
})

source(file.path("R", "04_main_did.R"))
source(file.path("R", "09_descriptives_migration.R"))

# Appendix H1: continuous MMI within earthquake-exposed Canterbury households.
# The accepted manuscript states that this sample is restricted to treated
# households with non-missing MMI. It is therefore built from the full treated
# sample, not by re-introducing matched North Island controls.
fit_continuous_mmi <- function(data, outcome) {
  stopifnot(outcome %in% names(data))

  fml <- as.formula(paste0(
    outcome,
    " ~ mmi_intensity:post + mmi_intensity + ref_age + I(ref_age^2) + female + hh_size | wave + ta_code"
  ))

  feols(fml, data = data, cluster = ~ta_code)
}

fit_continuous_mmi_models <- function() {
  dat <- load_full_treated_data() %>%
    mutate(
      ta_code = factor(ta_code),
      female = recode_female(ref_sex),
      mmi_intensity = suppressWarnings(as.numeric(mmi_intensity))
    ) %>%
    filter(
      !is.na(mmi_intensity), !is.na(ref_age), !is.na(female),
      !is.na(hh_size), !is.na(ta_code)
    )

  list(
    total_income = fit_continuous_mmi(dat, "total_income"),
    regular_income = fit_continuous_mmi(dat, "regular_income"),
    total_expenditure = fit_continuous_mmi(
      filter(dat, as.character(wave) %in% FULL_EXPENDITURE_WAVES),
      "total_expenditure"
    )
  )
}

# Appendix H2: linear age, quadratic age (baseline), and age bins.
add_age_bins <- function(df) {
  df %>%
    mutate(
      age_bin = case_when(
        ref_age < 25 ~ "Below 25",
        ref_age >= 25 & ref_age <= 44 ~ "25-44",
        ref_age >= 45 & ref_age <= 64 ~ "45-64",
        ref_age >= 65 ~ "65+",
        TRUE ~ NA_character_
      ),
      age_bin = factor(age_bin, levels = c("25-44", "Below 25", "45-64", "65+"))
    )
}

fit_age_form <- function(df, outcome, form = c("linear", "quadratic", "bins")) {
  form <- match.arg(form)
  age_rhs <- switch(
    form,
    linear = "ref_age",
    quadratic = "ref_age + ref_age_sq",
    bins = "age_bin"
  )

  dat <- if (form == "bins") add_age_bins(df) else df
  fml <- as.formula(paste0(
    outcome,
    " ~ i(mmi_group, post, ref = 'Control') + ", age_rhs,
    " + female + hh_size | wave + ta_code"
  ))

  feols(fml, data = dat, cluster = ~ta_code)
}

fit_age_bridge_models <- function(df = load_matched_analysis_data()) {
  outcomes <- c("total_income", "regular_income", "total_expenditure")
  forms <- c("linear", "quadratic", "bins")

  out <- list()
  for (form in forms) {
    out[[form]] <- set_names(outcomes) %>% map(function(outcome) {
      dat <- df
      if (outcome == "total_expenditure") {
        dat <- dat %>% filter(as.character(wave) %in% FULL_EXPENDITURE_WAVES)
      }
      fit_age_form(dat, outcome, form)
    })
  }
  out
}
