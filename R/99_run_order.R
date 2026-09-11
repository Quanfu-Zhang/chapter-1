# ==============================================================================
# Chapter 1 orchestration
# ------------------------------------------------------------------------------
# Sample extraction and address linkage remain explicit secure-environment steps
# because they require Data Lab connections and refresh-specific table names.
# Once `treated/`, `control_pool/`, and the baseline matched outputs exist, this
# file can run the complete estimation and validation pipeline.
# ==============================================================================

source(file.path("R", "00_config.R"))
source(file.path("R", "01_hes_schema_adapter.R"))
source(file.path("R", "03_psm_matching.R"))
source(file.path("R", "04_main_did.R"))
source(file.path("R", "05_expenditure_models.R"))
source(file.path("R", "06_event_study.R"))
source(file.path("R", "07_psm_robustness.R"))
source(file.path("R", "07b_matching_sensitivity.R"))
source(file.path("R", "08_pseudo_outcomes.R"))
source(file.path("R", "09_descriptives_migration.R"))
source(file.path("R", "10_alternative_specs.R"))
source(file.path("R", "11_att_ipw.R"))
source(file.path("R", "12_output_builders.R"))
source(file.path("R", "13_validate_manuscript.R"))
source(file.path("R", "14_census_context.R"))
source(file.path("R", "15_appendix_diagnostics.R"))

run_chapter1_analysis <- function(
    rebuild_baseline_psm = FALSE,
    rebuild_psm_robustness = FALSE,
    run_validation = TRUE) {

  message("Chapter 1: starting analysis stage")

  psm_results <- NULL
  if (rebuild_baseline_psm) {
    message("1/10 Running baseline wave-specific PSM")
    psm_results <- run_all_wave_psm()
  }

  message("2/10 Main DiD models")
  matched <- load_matched_analysis_data()
  main_models <- fit_main_models(matched)

  message("3/10 Detailed expenditure and income heterogeneity")
  exp_data <- prepare_expenditure_outcomes(matched)
  expenditure_models <- fit_expenditure_categories(exp_data)
  heterogeneity_models <- fit_income_heterogeneity(matched)

  message("4/10 Event study and pre-trend tests")
  event_study <- fit_event_study_models(matched)

  if (rebuild_psm_robustness) {
    message("5/10 Rebuilding PSM robustness samples")
    run_reported_psm_checks()
  } else {
    message("5/10 Using existing PSM robustness samples")
  }
  psm_robustness <- fit_reported_psm_robustness()

  message("6/10 Pseudo-outcome diagnostics")
  pseudo_covariates <- fit_key_covariate_pseudo_outcomes()
  pseudo_composition <- fit_household_composition_pseudo_outcomes()

  message("7/10 Descriptive and relocation analyses")
  table_d1 <- build_table_d1()
  table_d2 <- build_table_d2()
  relocation_models <- fit_relocation_models()

  message("8/10 Alternative MMI/age specifications and ATT-IPW")
  continuous_mmi <- fit_continuous_mmi_models()
  age_bridge <- fit_age_bridge_models(matched)
  att_ipw <- fit_appendix_i()

  message("9/10 Figure data / public context")
  figure2_data <- build_figure2_data(expenditure_models)
  figure3_data <- build_figure3_data(heterogeneity_models)
  table_f1 <- build_table_f1()

  validation <- NULL
  if (run_validation) {
    message("10/10 Validating against accepted-manuscript targets")
    validation <- run_manuscript_validation(psm_results)
  }

  invisible(list(
    psm_results = psm_results,
    main_models = main_models,
    expenditure_models = expenditure_models,
    heterogeneity_models = heterogeneity_models,
    event_study = event_study,
    psm_robustness = psm_robustness,
    pseudo_covariates = pseudo_covariates,
    pseudo_composition = pseudo_composition,
    table_d1 = table_d1,
    table_d2 = table_d2,
    relocation_models = relocation_models,
    continuous_mmi = continuous_mmi,
    age_bridge = age_bridge,
    att_ipw = att_ipw,
    figure2_data = figure2_data,
    figure3_data = figure3_data,
    table_f1 = table_f1,
    validation = validation
  ))
}

message("Chapter 1 replication functions loaded.")
message("See docs/REPRODUCTION_GUIDE.md before running restricted-data stages.")
