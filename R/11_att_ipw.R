# ==============================================================================
# ATT-IPW robustness and bridge specifications (Appendix I)
# ------------------------------------------------------------------------------
# The accepted manuscript identifies eight bridge columns:
#   A PSM basic; B PSM main; C PSM richer; D full-pool unweighted;
#   E full-pool ATT-IPW; F ATT-IPW richer; G ATT-IPW composition;
#   H trimmed ATT-IPW.
#
# Propensity scores for ATT-IPW are estimated separately within each survey wave.
# Core PS covariates: age, age^2, household size, sex, education.
# Richer PS: + tenure. Composition PS: + broad household composition.
# Treated weight = 1; control weight = p/(1-p).
#
# The manuscript labels column H as "trimmed ATT-IPW" without specifying a
# numerical trimming threshold. The methodological code therefore exposes the
# winsorisation quantiles as arguments so that this implementation choice is
# transparent.
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(purrr)
  library(fixest)
  library(cobalt)
})

source(file.path("R", "00_config.R"))
source(file.path("R", "01_hes_schema_adapter.R"))
source(file.path("R", "04_main_did.R"))

load_full_pool_wave <- function(wave) {
  t_path <- file.path(TREATED_DIR, paste0(wave, ".csv"))
  c_path <- file.path(CONTROL_POOL_DIR, paste0("CGP", wave, ".csv"))
  if (!file.exists(t_path)) stop("Treated analysis file not found: ", t_path)
  if (!file.exists(c_path)) stop("Control-pool file not found: ", c_path)

  t <- read_csv(t_path, show_col_types = FALSE) %>%
    canonicalise_hes(wave) %>% mutate(treated = 1L)
  c <- read_csv(c_path, show_col_types = FALSE) %>%
    canonicalise_hes(wave) %>% mutate(treated = 0L)

  bind_rows(t, c) %>%
    normalise_expense_names() %>%
    filter(ref_person) %>%
    distinct(snz_hes_hhld_uid, .keep_all = TRUE) %>%
    mutate(
      post = as.integer(wave %in% POST_WAVES),
      ref_age_sq = ref_age^2,
      female = recode_female(ref_sex),
      education_match = factor(recode_education(ref_education)),
      hh_tenure = factor(recode_tenure(tenure_code), levels = c("Owned/Trust", "Rented")),
      household_comp_group = factor(recode_household_comp(household_comp)),
      mmi_intensity = suppressWarnings(as.numeric(mmi_intensity)),
      mmi_group = case_when(
        treated == 0L ~ "Control",
        treated == 1L & mmi_intensity >= LOW_MMI_MIN & mmi_intensity < HIGH_MMI_MIN ~ "Low",
        treated == 1L & mmi_intensity >= HIGH_MMI_MIN ~ "High",
        TRUE ~ NA_character_
      ),
      mmi_group = factor(mmi_group, levels = c("Control", "Low", "High")),
      wave = factor(as.character(wave), levels = WAVES),
      ta_code = factor(ta_code)
    ) %>%
    filter(
      !is.na(mmi_group), !is.na(ref_age), !is.na(hh_size),
      !is.na(female), !is.na(education_match), !is.na(ta_code)
    )
}

load_full_pool_data <- function(waves = WAVES) {
  map_dfr(waves, load_full_pool_wave)
}

ps_formula <- function(profile = c("core", "richer", "composition")) {
  profile <- match.arg(profile)
  rhs <- c("ref_age", "ref_age_sq", "hh_size", "female", "education_match")
  if (profile %in% c("richer", "composition")) rhs <- c(rhs, "hh_tenure")
  if (profile == "composition") rhs <- c(rhs, "household_comp_group")
  reformulate(rhs, response = "treated")
}

estimate_wave_att_weights <- function(df, profile = c("core", "richer", "composition")) {
  profile <- match.arg(profile)
  dat <- df
  if (profile %in% c("richer", "composition")) dat <- dat %>% filter(!is.na(hh_tenure))
  if (profile == "composition") dat <- dat %>% filter(!is.na(household_comp_group))

  fit <- glm(ps_formula(profile), data = dat, family = binomial(link = "logit"))
  p <- pmin(pmax(predict(fit, type = "response"), 1e-6), 1 - 1e-6)

  dat %>%
    mutate(
      propensity_score = p,
      att_weight = if_else(treated == 1L, 1, propensity_score / (1 - propensity_score)),
      ps_profile = profile
    )
}

add_att_weights <- function(df, profile = c("core", "richer", "composition")) {
  profile <- match.arg(profile)
  split(df, as.character(df$wave)) %>%
    map_dfr(~ estimate_wave_att_weights(.x, profile)) %>%
    mutate(wave = factor(as.character(wave), levels = WAVES))
}

winsorise_att_weights <- function(df, probs = c(0.01, 0.99)) {
  stopifnot(length(probs) == 2L, probs[1] >= 0, probs[2] <= 1, probs[1] < probs[2])
  ctrl <- df$att_weight[df$treated == 0L & is.finite(df$att_weight)]
  limits <- quantile(ctrl, probs = probs, na.rm = TRUE, names = FALSE)

  df %>%
    mutate(
      att_weight_trimmed = if_else(
        treated == 1L,
        1,
        pmin(pmax(att_weight, limits[1]), limits[2])
      ),
      trim_lower_quantile = probs[1],
      trim_upper_quantile = probs[2],
      trim_lower_weight = limits[1],
      trim_upper_weight = limits[2]
    )
}

fit_bridge_model <- function(
    df,
    outcome,
    outcome_profile = c("basic", "main", "richer", "composition"),
    weights = NULL) {

  outcome_profile <- match.arg(outcome_profile)
  rhs <- switch(
    outcome_profile,
    basic = "ref_age + hh_size",
    main = "ref_age + ref_age_sq + female + hh_size",
    richer = "ref_age + ref_age_sq + female + hh_size + hh_tenure",
    composition = paste0(
      "ref_age + ref_age_sq + female + hh_size + hh_tenure + household_comp_group"
    )
  )

  fml <- as.formula(paste0(
    outcome,
    " ~ i(mmi_group, post, ref = 'Control') + ", rhs, " | wave + ta_code"
  ))

  if (is.null(weights)) {
    feols(fml, data = df, cluster = ~ta_code)
  } else {
    feols(fml, data = df, weights = weights, cluster = ~ta_code)
  }
}

fit_appendix_i_for_outcome <- function(
    outcome,
    matched_data,
    full_pool,
    trim_probs = c(0.01, 0.99)) {

  md <- matched_data
  fp <- full_pool
  if (outcome == "total_expenditure") {
    md <- md %>% filter(as.character(wave) %in% FULL_EXPENDITURE_WAVES)
    fp <- fp %>% filter(as.character(wave) %in% FULL_EXPENDITURE_WAVES)
  }

  ipw_core <- add_att_weights(fp, "core")
  ipw_richer <- add_att_weights(fp, "richer")
  ipw_comp <- add_att_weights(fp, "composition")
  ipw_trim <- winsorise_att_weights(ipw_richer, trim_probs)

  list(
    A_psm_basic = fit_bridge_model(md, outcome, "basic"),
    B_psm_main = fit_bridge_model(md, outcome, "main"),
    C_psm_richer = fit_bridge_model(md, outcome, "richer"),
    D_full_pool_unweighted = fit_bridge_model(fp, outcome, "basic"),
    E_full_pool_att_ipw = fit_bridge_model(ipw_core, outcome, "basic", ~att_weight),
    F_att_ipw_richer = fit_bridge_model(ipw_richer, outcome, "richer", ~att_weight),
    G_att_ipw_composition = fit_bridge_model(ipw_comp, outcome, "composition", ~att_weight),
    H_trimmed_att_ipw = fit_bridge_model(ipw_trim, outcome, "richer", ~att_weight_trimmed)
  )
}

fit_appendix_i <- function(trim_probs = c(0.01, 0.99)) {
  matched <- load_matched_analysis_data()
  full_pool <- load_full_pool_data()

  list(
    regular_income = fit_appendix_i_for_outcome(
      "regular_income", matched, full_pool, trim_probs
    ),
    total_income = fit_appendix_i_for_outcome(
      "total_income", matched, full_pool, trim_probs
    ),
    total_expenditure = fit_appendix_i_for_outcome(
      "total_expenditure", matched, full_pool, trim_probs
    )
  )
}

att_weight_diagnostics <- function(df, profile = "core") {
  dat <- add_att_weights(df, profile)
  tibble(
    profile = profile,
    max_weight = max(dat$att_weight, na.rm = TRUE),
    p99_weight = unname(quantile(dat$att_weight, 0.99, na.rm = TRUE)),
    p95_weight = unname(quantile(dat$att_weight, 0.95, na.rm = TRUE))
  )
}
