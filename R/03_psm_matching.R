# ==============================================================================
# Wave-specific propensity-score matching
# ------------------------------------------------------------------------------
# Accepted-paper baseline:
#   * matching is performed separately within each HES wave;
#   * 1:2 nearest-neighbour matching without replacement;
#   * logit propensity score;
#   * raw propensity-score caliper = 0.2;
#   * matching covariates: reference-person age, household size, sex, education;
#   * ATT estimand.
#
# Inputs are immutable. Matched treated and control samples are written to new
# paths so that provenance is explicit.
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(MatchIt)
  library(cobalt)
})

source(file.path("R", "00_config.R"))
source(file.path("R", "01_hes_schema_adapter.R"))

prepare_matching_input <- function(treated_raw, control_raw, wave, include_sex = TRUE) {
  treated <- canonicalise_hes(treated_raw, wave) %>% mutate(treated = 1L)
  control <- canonicalise_hes(control_raw, wave) %>% mutate(treated = 0L)

  full <- bind_rows(treated, control) %>%
    filter(ref_person) %>%
    group_by(snz_hes_hhld_uid) %>%
    filter(n() == 1L) %>%
    ungroup() %>%
    mutate(
      ref_education_match = recode_education(ref_education),
      female = recode_female(ref_sex),
      treated = as.integer(treated)
    ) %>%
    filter(
      !is.na(ref_age),
      !is.na(hh_size),
      !is.na(ref_education_match),
      !is.na(snz_hes_hhld_uid)
    )

  if (include_sex) full <- full %>% filter(!is.na(female))
  full
}

run_wave_psm <- function(
    wave,
    treated_path = file.path(TREATED_DIR, paste0(wave, ".csv")),
    control_pool_path = file.path(CONTROL_POOL_DIR, paste0("CGP", wave, ".csv")),
    matched_treated_path = file.path(MATCHED_TREATED_DIR, paste0(wave, ".csv")),
    matched_control_path = file.path(MATCHED_CONTROL_DIR, paste0("CG", wave, ".csv")),
    caliper = PSM_CALIPER,
    ratio = PSM_RATIO,
    include_sex = TRUE,
    raw_caliper = PSM_RAW_CALIPER,
    write_outputs = TRUE) {

  stopifnot(wave %in% WAVES, ratio >= 1L, caliper > 0)

  treated_raw <- read_csv(treated_path, show_col_types = FALSE)
  control_raw <- read_csv(control_pool_path, show_col_types = FALSE)
  full <- prepare_matching_input(treated_raw, control_raw, wave, include_sex)

  rhs <- c("ref_age", "hh_size", "ref_education_match")
  if (include_sex) rhs <- c("ref_age", "hh_size", "female", "ref_education_match")
  fml <- reformulate(rhs, response = "treated")

  set.seed(MATCH_SEED)
  m <- matchit(
    formula = fml,
    data = full,
    method = "nearest",
    distance = "glm",
    link = "logit",
    replace = PSM_REPLACE,
    caliper = caliper,
    std.caliper = !raw_caliper,
    ratio = as.integer(ratio),
    estimand = "ATT"
  )

  matched <- match.data(m) %>%
    mutate(treated = as.integer(as.character(treated)))

  matched_treated_ids <- matched %>%
    filter(treated == 1L) %>%
    pull(snz_hes_hhld_uid)

  matched_control_ids <- matched %>%
    filter(treated == 0L) %>%
    pull(snz_hes_hhld_uid)

  if (write_outputs) {
    dir.create(dirname(matched_treated_path), recursive = TRUE, showWarnings = FALSE)
    dir.create(dirname(matched_control_path), recursive = TRUE, showWarnings = FALSE)

    write_csv(
      treated_raw %>%
        mutate(snz_hes_hhld_uid = as.character(snz_hes_hhld_uid)) %>%
        filter(snz_hes_hhld_uid %in% matched_treated_ids),
      matched_treated_path
    )

    write_csv(
      control_raw %>%
        mutate(snz_hes_hhld_uid = as.character(snz_hes_hhld_uid)) %>%
        filter(snz_hes_hhld_uid %in% matched_control_ids),
      matched_control_path
    )
  }

  balance <- bal.tab(
    m,
    stats = c("mean.diffs", "variance.ratios"),
    thresholds = c(m = 0.1, v = 2)
  )

  summary_row <- tibble(
    wave = wave,
    treated_eligible_for_matching = sum(full$treated == 1L),
    control_pool_eligible_for_matching = sum(full$treated == 0L),
    matched_treated = length(unique(matched_treated_ids)),
    matched_controls = length(unique(matched_control_ids)),
    caliper = caliper,
    ratio = ratio,
    include_sex = include_sex,
    raw_caliper = raw_caliper
  )

  list(
    matchit = m,
    balance = balance,
    summary = summary_row,
    matched_treated_ids = matched_treated_ids,
    matched_control_ids = matched_control_ids
  )
}

run_all_wave_psm <- function(waves = WAVES, ...) {
  results <- lapply(waves, function(w) run_wave_psm(w, ...))
  names(results) <- waves
  results
}
