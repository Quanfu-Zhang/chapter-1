# ==============================================================================
# Appendix B diagnostic helpers
# ------------------------------------------------------------------------------
# This public module retains non-count balance and composition diagnostics only.
# Restricted tabular outputs remain subject to Stats NZ requirements.
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(tibble)
})

source(file.path("R", "03_psm_matching.R"))
source(file.path("R", "04_main_did.R"))
source(file.path("R", "08_pseudo_outcomes.R"))

# Table B1: least favourable SMD and variance ratio in each wave.
balance_summary_one_wave <- function(balance_object, wave) {
  b <- balance_object$Balance
  smd_col <- intersect(c("Diff.Adj", "Diff.Adjusted"), names(b))
  vr_col <- intersect(c("V.Ratio.Adj", "V.Ratio.Adjusted"), names(b))

  if (!length(smd_col)) stop("Could not find adjusted SMD column in cobalt balance object.")
  if (!length(vr_col)) stop("Could not find adjusted variance-ratio column in cobalt balance object.")

  tibble(
    wave = WAVE_LABELS[[wave]],
    max_abs_smd = max(abs(b[[smd_col[[1L]]]]), na.rm = TRUE),
    max_variance_ratio = max(b[[vr_col[[1L]]]], na.rm = TRUE)
  )
}

build_table_b1 <- function(psm_results) {
  imap_dfr(psm_results, ~ balance_summary_one_wave(.x$balance, .y))
}

# Table B2: four-cell means for key composition covariates. The manuscript uses
# the four full-expenditure waves to align this diagnostic with expenditure.
build_table_b2 <- function(df = load_pseudo_outcome_data()) {
  dat <- df %>% filter(as.character(wave) %in% FULL_EXPENDITURE_WAVES)

  vars <- c(
    ref_age = "Age",
    hh_size = "Household size",
    female = "Female reference person",
    owned_trust = "Owned/trust housing",
    higher_education = "Higher education"
  )

  imap_dfr(vars, function(label, var) {
    dat %>%
      filter(!is.na(.data[[var]])) %>%
      group_by(treated_area, post) %>%
      summarise(
        mean = mean(.data[[var]], na.rm = TRUE),
        sd = sd(.data[[var]], na.rm = TRUE),
        .groups = "drop"
      ) %>%
      mutate(outcome = label, .before = 1L)
  })
}
