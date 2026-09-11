# ==============================================================================
# Numerical validation against the accepted manuscript
# ------------------------------------------------------------------------------
# The accepted paper is the authoritative specification for this reconstructed
# repository. These targets act as regression tests inside the Data Lab.
# Published counts are confidentiality-rounded, so Table 1 count comparisons use
# a small tolerance. Regression coefficients and SEs are compared to the rounded
# values printed in the accepted manuscript.
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(purrr)
  library(readr)
})

source(file.path("R", "04_main_did.R"))
source(file.path("R", "06_event_study.R"))
source(file.path("R", "07_psm_robustness.R"))
source(file.path("R", "09_descriptives_migration.R"))
source(file.path("R", "10_alternative_specs.R"))

TABLE1_TARGETS <- tribble(
  ~wave, ~treated, ~eligible_control, ~matched_control,
  "0607", 417, 1512, 831,
  "0708", 462, 1917, 924,
  "0809", 459, 1887, 921,
  "0910", 432, 1692, 867,
  "1011", 432, 1971, 867,
  "1112", 486, 1938, 972,
  "1213", 411, 1608, 822,
  "1314", 438, 1896, 873,
  "1415", 705, 3135, 1407,
  "1516", 420, 1995, 840,
  "1617", 456, 2118, 909,
  "1718", 633, 3165, 1263
)

MAIN_TARGETS <- tribble(
  ~outcome, ~intensity, ~estimate, ~std_error, ~observations,
  "total_income", "Low", 7043.47, 2889.43, 17193,
  "total_income", "High", 7251.79, 3559.44, 17193,
  "regular_income", "Low", 7924.42, 2673.83, 17193,
  "regular_income", "High", 7411.86, 3286.86, 17193,
  "total_expenditure", "Low", 3413.71, 2507.03, 5022,
  "total_expenditure", "High", 2010.89, 1469.80, 5022
)

PSM_ROBUSTNESS_TARGETS <- tribble(
  ~variant, ~outcome, ~intensity, ~estimate, ~observations,
  "baseline", "total_income", "Low", 7043.47, 17193,
  "baseline", "total_income", "High", 7251.79, 17193,
  "caliper_01", "total_income", "Low", 7686.24, 17166,
  "caliper_01", "total_income", "High", 7841.80, 17166,
  "one_to_one", "total_income", "Low", 8088.52, 11457,
  "one_to_one", "total_income", "High", 8265.12, 11457,
  "no_sex", "total_income", "Low", 7736.24, 17190,
  "no_sex", "total_income", "High", 7888.43, 17190,
  "baseline", "regular_income", "Low", 7924.42, 17193,
  "baseline", "regular_income", "High", 7411.86, 17193,
  "caliper_01", "regular_income", "Low", 8408.67, 17166,
  "caliper_01", "regular_income", "High", 7862.88, 17166,
  "one_to_one", "regular_income", "Low", 9345.04, 11457,
  "one_to_one", "regular_income", "High", 8821.37, 11457,
  "no_sex", "regular_income", "Low", 8491.53, 17190,
  "no_sex", "regular_income", "High", 7941.28, 17190,
  "baseline", "total_expenditure", "Low", 3413.71, 5022,
  "baseline", "total_expenditure", "High", 2010.89, 5022,
  "caliper_01", "total_expenditure", "Low", 2525.22, 5016,
  "caliper_01", "total_expenditure", "High", 1310.34, 5016,
  "one_to_one", "total_expenditure", "Low", 2340.68, 3354,
  "one_to_one", "total_expenditure", "High", 1019.43, 3354,
  "no_sex", "total_expenditure", "Low", 2984.13, 5025,
  "no_sex", "total_expenditure", "High", 1715.67, 5025
)

RELOCATION_TARGETS <- tribble(
  ~outcome, ~estimate, ~std_error, ~observations,
  "total_income", 427.33, 5112.98, 3546,
  "regular_income", 1005.00, 4687.53, 3546,
  "total_expenditure", 664.48, 1217.04, 3546,
  "housing_cost", 24901.31, 4464.28, 3546,
  "other_property", -606.05, 488.30, 3546,
  "mortgages_loans", -9585.52, 4242.43, 3546
)

CONTINUOUS_MMI_TARGETS <- tribble(
  ~outcome, ~estimate, ~std_error, ~observations,
  "total_income", -1114.46, 1917.09, 5697,
  "regular_income", -1036.31, 1790.38, 5697,
  "total_expenditure", -1001.20, 630.66, 1662
)

PRETREND_P_TARGETS <- c(
  total_income = 0.814,
  regular_income = 0.624,
  total_expenditure = 0.544
)

coef_match <- function(model, regex) {
  b <- coef(model)
  idx <- grep(regex, names(b))
  if (length(idx) != 1L) {
    stop("Expected one coefficient matching /", regex, "/; found ", length(idx),
         ". Available: ", paste(names(b), collapse = ", "))
  }
  nm <- names(b)[idx]
  c(estimate = unname(b[nm]), std_error = unname(se(model)[nm]))
}

mmi_interaction <- function(model, intensity) {
  coef_match(model, paste0("mmi_group::", intensity, ".*post|", intensity, ".*post"))
}

validation_row <- function(item, actual, target, tolerance) {
  tibble(
    item = item,
    actual = as.numeric(actual),
    target = as.numeric(target),
    difference = as.numeric(actual) - as.numeric(target),
    tolerance = tolerance,
    pass = abs(difference) <= tolerance
  )
}

validate_main_models <- function(models = fit_main_models()) {
  pmap_dfr(MAIN_TARGETS, function(outcome, intensity, estimate, std_error, observations) {
    m <- models[[outcome]]
    x <- mmi_interaction(m, intensity)
    bind_rows(
      validation_row(paste(outcome, intensity, "estimate"), x["estimate"], estimate, COEF_TOLERANCE),
      validation_row(paste(outcome, intensity, "SE"), x["std_error"], std_error, SE_TOLERANCE),
      validation_row(paste(outcome, "observations"), nobs(m), observations, 0)
    )
  }) %>% distinct()
}

validate_table1 <- function(psm_results) {
  actual <- map_dfr(psm_results, "summary") %>%
    transmute(
      wave,
      treated = treated_pre_match,
      eligible_control = control_pool_pre_match,
      matched_control = matched_controls
    )

  target_long <- TABLE1_TARGETS %>%
    pivot_longer(
      cols = c(treated, eligible_control, matched_control),
      names_to = "quantity",
      values_to = "target"
    )
  actual_long <- actual %>%
    pivot_longer(
      cols = c(treated, eligible_control, matched_control),
      names_to = "quantity",
      values_to = "actual"
    )

  target_long %>%
    left_join(actual_long, by = c("wave", "quantity")) %>%
    transmute(
      item = paste(wave, quantity),
      actual,
      target,
      difference = actual - target,
      tolerance = 3,
      pass = abs(difference) <= tolerance
    )
}

validate_psm_robustness <- function(models = fit_reported_psm_robustness()) {
  pmap_dfr(
    PSM_ROBUSTNESS_TARGETS,
    function(variant, outcome, intensity, estimate, observations) {
      m <- models[[variant]][[outcome]]
      x <- mmi_interaction(m, intensity)
      bind_rows(
        validation_row(
          paste("PSM", variant, outcome, intensity), x["estimate"], estimate, COEF_TOLERANCE
        ),
        validation_row(
          paste("PSM", variant, outcome, "N"), nobs(m), observations, 0
        )
      )
    }
  ) %>% distinct()
}

validate_relocation <- function(models = fit_relocation_models()) {
  pmap_dfr(RELOCATION_TARGETS, function(outcome, estimate, std_error, observations) {
    m <- models[[outcome]]
    x <- coef_match(m, "^relocation$")
    bind_rows(
      validation_row(paste("relocation", outcome, "estimate"), x["estimate"], estimate, COEF_TOLERANCE),
      validation_row(paste("relocation", outcome, "SE"), x["std_error"], std_error, SE_TOLERANCE),
      validation_row(paste("relocation", outcome, "N"), nobs(m), observations, 0)
    )
  })
}

validate_continuous_mmi <- function(models = fit_continuous_mmi_models()) {
  pmap_dfr(CONTINUOUS_MMI_TARGETS, function(outcome, estimate, std_error, observations) {
    m <- models[[outcome]]
    x <- coef_match(m, "mmi_intensity.*post|post.*mmi_intensity")
    bind_rows(
      validation_row(paste("continuous MMI", outcome, "estimate"), x["estimate"], estimate, COEF_TOLERANCE),
      validation_row(paste("continuous MMI", outcome, "SE"), x["std_error"], std_error, SE_TOLERANCE),
      validation_row(paste("continuous MMI", outcome, "N"), nobs(m), observations, 0)
    )
  })
}

wald_p_value <- function(x) {
  vals <- unlist(x)
  nm <- names(vals)
  hit <- grep("p|Pr", nm, ignore.case = TRUE)
  if (!length(hit)) stop("Could not identify p value in Wald-test object.")
  as.numeric(vals[hit[[1L]]])
}

validate_pretrends <- function(event_result = fit_event_study_models()) {
  imap_dfr(event_result$pretrend_tests, function(test, name) {
    validation_row(
      paste("pretrend", name, "p"),
      wald_p_value(test),
      PRETREND_P_TARGETS[[name]],
      P_TOLERANCE
    )
  })
}

run_manuscript_validation <- function(psm_results = NULL, write_csv_output = TRUE) {
  checks <- bind_rows(
    validate_main_models(),
    validate_psm_robustness(),
    validate_relocation(),
    validate_continuous_mmi(),
    validate_pretrends()
  )

  if (!is.null(psm_results)) checks <- bind_rows(validate_table1(psm_results), checks)

  if (write_csv_output) {
    dir.create(VALIDATION_DIR, recursive = TRUE, showWarnings = FALSE)
    write_csv(checks, file.path(VALIDATION_DIR, "manuscript_validation.csv"))
  }

  print(count(checks, pass))
  if (any(!checks$pass)) {
    warning("At least one manuscript target did not reproduce. Inspect validation output before release.")
  }
  invisible(checks)
}
