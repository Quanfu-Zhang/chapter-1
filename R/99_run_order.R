# ==============================================================================
# Chapter 1 script map / load order
# ------------------------------------------------------------------------------
# This public repository is intended for methodological communication rather than
# independent execution of the restricted IDI project. This file therefore loads
# the analytical modules in a logical order and documents how they relate.
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
source(file.path("R", "14_census_context.R"))
source(file.path("R", "15_appendix_diagnostics.R"))

chapter1_module_map <- function() {
  data.frame(
    stage = c(
      "Configuration",
      "HES harmonisation",
      "Restricted-data sample construction",
      "Matching",
      "Main DiD",
      "Detailed expenditure",
      "Event study",
      "Matching robustness",
      "Pseudo-outcomes",
      "Migration/descriptives",
      "Alternative specifications",
      "ATT-IPW",
      "Outputs",
      "Public Census context",
      "Appendix diagnostics"
    ),
    file = c(
      "R/00_config.R",
      "R/01_hes_schema_adapter.R",
      "R/idi/02_build_wave_samples.R",
      "R/03_psm_matching.R",
      "R/04_main_did.R",
      "R/05_expenditure_models.R",
      "R/06_event_study.R",
      "R/07_psm_robustness.R and R/07b_matching_sensitivity.R",
      "R/08_pseudo_outcomes.R",
      "R/09_descriptives_migration.R",
      "R/10_alternative_specs.R",
      "R/11_att_ipw.R",
      "R/12_output_builders.R",
      "R/14_census_context.R",
      "R/15_appendix_diagnostics.R"
    ),
    stringsAsFactors = FALSE
  )
}

message("Chapter 1 methodological code loaded.")
message("See docs/CODE_GUIDE.md for the reading order and docs/DATA_ACCESS.md for access limitations.")
