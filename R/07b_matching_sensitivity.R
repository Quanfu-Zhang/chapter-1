# ==============================================================================
# Additional matching sensitivity checks reported in Sect. 5.5
# ------------------------------------------------------------------------------
# These checks are discussed in the manuscript but are not the four columns of
# Tables 5-7: probit propensity scores, linear-probability propensity scores, and
# leave-one-matching-covariate-out diagnostics.
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(MatchIt)
  library(cobalt)
})

source(file.path("R", "03_psm_matching.R"))

matching_formula <- function(include = c("age", "size", "sex", "education")) {
  map <- c(
    age = "ref_age",
    size = "hh_size",
    sex = "female",
    education = "ref_education_match"
  )
  reformulate(unname(map[include]), response = "treated")
}

run_wave_psm_custom <- function(
    wave,
    ps_method = c("logit", "probit", "lpm"),
    include = c("age", "size", "sex", "education"),
    caliper = PSM_CALIPER,
    ratio = PSM_RATIO) {

  ps_method <- match.arg(ps_method)
  t_raw <- read_csv(file.path(TREATED_DIR, paste0(wave, ".csv")), show_col_types = FALSE)
  c_raw <- read_csv(file.path(CONTROL_POOL_DIR, paste0("CGP", wave, ".csv")), show_col_types = FALSE)
  dat <- prepare_matching_input(t_raw, c_raw, wave, include_sex = "sex" %in% include)
  fml <- matching_formula(include)

  set.seed(MATCH_SEED)
  if (ps_method %in% c("logit", "probit")) {
    m <- matchit(
      fml,
      data = dat,
      method = "nearest",
      distance = "glm",
      link = ps_method,
      replace = FALSE,
      caliper = caliper,
      std.caliper = FALSE,
      ratio = ratio,
      estimand = "ATT"
    )
  } else {
    # Linear probability model. Predictions are used only as a distance metric;
    # they are clipped to [0,1] to keep the score interpretable and stable.
    fit_lpm <- lm(fml, data = dat)
    p_lpm <- pmin(pmax(as.numeric(predict(fit_lpm)), 0), 1)
    m <- matchit(
      fml,
      data = dat,
      method = "nearest",
      distance = p_lpm,
      replace = FALSE,
      caliper = caliper,
      std.caliper = FALSE,
      ratio = ratio,
      estimand = "ATT"
    )
  }

  list(
    matchit = m,
    balance = bal.tab(
      m,
      stats = c("mean.diffs", "variance.ratios"),
      thresholds = c(m = 0.1, v = 2)
    )
  )
}

run_leave_one_covariate_out <- function(wave) {
  covariates <- c("age", "size", "sex", "education")
  out <- lapply(covariates, function(drop) {
    run_wave_psm_custom(wave, "logit", setdiff(covariates, drop))
  })
  names(out) <- paste0("without_", covariates)
  out
}
