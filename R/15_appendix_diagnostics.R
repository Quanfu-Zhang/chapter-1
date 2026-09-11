# ==============================================================================
# Appendix A-B diagnostic table builders
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(tibble)
})

source(file.path("R", "03_psm_matching.R"))
source(file.path("R", "04_main_did.R"))
source(file.path("R", "08_pseudo_outcomes.R"))

# Tables A1-A2 are built from the per-wave objects returned by
# build_wave_samples(). Counts must pass Stats NZ output checking before release.
build_table_a1 <- function(wave_builds) {
  imap_dfr(wave_builds, function(x, wave) {
    d <- x$classified_reference_persons
    tibble(
      wave = WAVE_LABELS[[wave]],
      group1 = sum(d$group == "Group 1", na.rm = TRUE),
      group2 = sum(d$group == "Group 2", na.rm = TRUE),
      group3 = sum(d$group == "Group 3", na.rm = TRUE),
      group4 = sum(d$group == "Group 4", na.rm = TRUE)
    )
  })
}

build_table_a2 <- function(wave_builds) {
  imap_dfr(wave_builds, function(x, wave) {
    d <- x$classified_reference_persons
    total <- nrow(d)
    unmatched <- sum(d$group == "Missing address", na.rm = TRUE)
    tibble(
      wave = WAVE_LABELS[[wave]],
      valid_hes_households = total,
      unmatched_addresses = unmatched,
      unmatched_rate_pct = 100 * unmatched / total
    )
  })
}

# Table A3 was a separate Census linkage diagnostic. This helper deliberately
# accepts a secure, pre-built linkage flag rather than assuming a particular
# Census table/refresh. Required columns: wave and matched_census_address.
build_table_a3 <- function(census_linkage) {
  stopifnot(all(c("wave", "matched_census_address") %in% names(census_linkage)))

  census_linkage %>%
    mutate(
      wave = as.character(wave),
      matched_census_address = as.logical(matched_census_address)
    ) %>%
    group_by(wave) %>%
    summarise(
      matched = sum(matched_census_address %in% TRUE, na.rm = TRUE),
      unmatched = sum(matched_census_address %in% FALSE, na.rm = TRUE),
      unmatched_rate_pct = 100 * unmatched / (matched + unmatched),
      .groups = "drop"
    ) %>%
    mutate(wave = unname(WAVE_LABELS[wave]))
}

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
        sample_size = n(),
        mean = mean(.data[[var]], na.rm = TRUE),
        sd = sd(.data[[var]], na.rm = TRUE),
        .groups = "drop"
      ) %>%
      mutate(outcome = label, .before = 1L)
  })
}
