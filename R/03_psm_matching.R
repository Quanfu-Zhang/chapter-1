# ==============================================================================
# Wave-specific propensity-score matching
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(MatchIt)
  library(cobalt)
})

source(file.path("R", "00_config.R"))
source(file.path("R", "01_hes_schema_adapter.R"))

run_wave_psm <- function(
    wave,
    treated_path = file.path(TREATED_DIR, paste0(wave, ".csv")),
    control_pool_path = file.path(CONTROL_POOL_DIR, paste0("CGP", wave, ".csv")),
    matched_control_path = file.path(MATCHED_CONTROL_DIR, paste0("CG", wave, ".csv")),
    caliper = 0.2,
    ratio = 2L,
    include_sex = TRUE,
    raw_caliper = TRUE) {

  treated_raw <- read_csv(treated_path, show_col_types = FALSE)
  control_raw <- read_csv(control_pool_path, show_col_types = FALSE)

  treated <- canonicalise_hes(treated_raw, wave) %>% mutate(treated = 1L)
  control <- canonicalise_hes(control_raw, wave) %>% mutate(treated = 0L)

  full <- bind_rows(treated, control) %>%
    filter(ref_person) %>%
    mutate(
      ref_education = recode_education(ref_education),
      hh_tenure = recode_tenure(tenure_code),
      treated = factor(treated, levels = c(0, 1))
    ) %>%
    filter(
      !is.na(ref_age), !is.na(hh_size), !is.na(ref_education),
      !is.na(ref_sex), !is.na(snz_hes_hhld_uid)
    )

  rhs <- c("ref_age", "hh_size", "ref_education")
  if (include_sex) rhs <- append(rhs, "ref_sex", after = 2L)
  fml <- reformulate(rhs, response = "treated")

  set.seed(MATCH_SEED)
  m <- matchit(
    formula = fml,
    data = full,
    method = "nearest",
    distance = "glm",
    link = "logit",
    replace = FALSE,
    caliper = caliper,
    std.caliper = !raw_caliper,
    ratio = ratio,
    estimand = "ATT"
  )

  matched <- match.data(m)
  matched_treated_ids <- matched %>%
    filter(as.character(treated) == "1") %>%
    pull(snz_hes_hhld_uid)
  matched_control_ids <- matched %>%
    filter(as.character(treated) == "0") %>%
    pull(snz_hes_hhld_uid)

  # Never overwrite input files. Write matched outputs to separate locations.
  dir.create(dirname(matched_control_path), recursive = TRUE, showWarnings = FALSE)
  write_csv(
    control_raw %>% filter(snz_hes_hhld_uid %in% matched_control_ids),
    matched_control_path
  )

  balance <- bal.tab(
    m,
    stats = c("mean.diffs", "variance.ratios"),
    thresholds = c(m = 0.1, v = 2)
  )

  list(
    matchit = m,
    balance = balance,
    matched_treated_ids = matched_treated_ids,
    matched_control_ids = matched_control_ids
  )
}

# Example:
# result <- run_wave_psm("0607")
# print(result$balance)
