# ==============================================================================
# Main difference-in-differences models
# ------------------------------------------------------------------------------
# Paper-aligned specification:
#   - post period begins in 2011/12
#   - MMI groups: [4,7) low; >=7 high; matched North Island = control
#   - controls: age, age^2, sex, household size
#   - survey-wave and TA fixed effects
#   - standard errors clustered by TA
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(purrr)
  library(fixest)
})

source(file.path("R", "00_config.R"))
source(file.path("R", "01_hes_schema_adapter.R"))

load_matched_analysis_data <- function(waves = WAVES) {
  one_wave <- function(wave) {
    t_path <- file.path(TREATED_DIR, paste0(wave, ".csv"))
    c_path <- file.path(MATCHED_CONTROL_DIR, paste0("CG", wave, ".csv"))

    t <- read_csv(t_path, show_col_types = FALSE) %>%
      canonicalise_hes(wave) %>% mutate(treated = 1L)
    c <- read_csv(c_path, show_col_types = FALSE) %>%
      canonicalise_hes(wave) %>% mutate(treated = 0L)

    bind_rows(t, c)
  }

  map_dfr(waves, one_wave) %>%
    filter(ref_person) %>%
    mutate(
      post = as.integer(wave %in% POST_WAVES),
      ref_age_sq = ref_age^2,
      female = recode_female(ref_sex),
      mmi_intensity = suppressWarnings(as.numeric(mmi_intensity)),
      mmi_group = case_when(
        treated == 0L ~ "Control",
        treated == 1L & mmi_intensity >= LOW_MMI_MIN & mmi_intensity < HIGH_MMI_MIN ~ "Low",
        treated == 1L & mmi_intensity >= HIGH_MMI_MIN ~ "High",
        TRUE ~ NA_character_
      ),
      mmi_group = factor(mmi_group, levels = c("Control", "Low", "High")),
      wave = factor(wave, levels = WAVES),
      ta_code = factor(ta_code)
    ) %>%
    filter(!is.na(mmi_group), !is.na(ref_age), !is.na(female), !is.na(hh_size), !is.na(ta_code))
}

fit_main_did <- function(data, outcome) {
  fml <- as.formula(paste0(
    outcome,
    " ~ i(mmi_group, post, ref = 'Control') + ref_age + ref_age_sq + female + hh_size | wave + ta_code"
  ))

  feols(fml, data = data, cluster = ~ta_code)
}

# Example:
# df <- load_matched_analysis_data()
# model_total_income <- fit_main_did(df, "total_income")
# model_regular_income <- fit_main_did(df, "regular_income")
# model_total_expenditure <- fit_main_did(
#   filter(df, as.character(wave) %in% FULL_EXPENDITURE_WAVES),
#   "total_expenditure"
# )
