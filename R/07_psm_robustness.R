# ==============================================================================
# Reported PSM robustness checks (Tables 5-7)
# ------------------------------------------------------------------------------
# Variants relative to the baseline:
#   1. caliper = 0.1, ratio = 1:2, matching on age/size/sex/education;
#   2. caliper = 0.2, ratio = 1:1, matching on age/size/sex/education;
#   3. caliper = 0.2, ratio = 1:2, matching on age/size/education only.
# ==============================================================================

source(file.path("R", "03_psm_matching.R"))
source(file.path("R", "04_main_did.R"))

variant_dirs <- function(name) {
  root <- file.path(ROBUSTNESS_DIR, name)
  list(
    treated = file.path(root, "matched_treated"),
    control = file.path(root, "matched_control")
  )
}

run_psm_variant <- function(wave, name, caliper, ratio, include_sex) {
  dirs <- variant_dirs(name)
  dir.create(dirs$treated, recursive = TRUE, showWarnings = FALSE)
  dir.create(dirs$control, recursive = TRUE, showWarnings = FALSE)

  run_wave_psm(
    wave = wave,
    caliper = caliper,
    ratio = ratio,
    include_sex = include_sex,
    matched_treated_path = file.path(dirs$treated, paste0(wave, ".csv")),
    matched_control_path = file.path(dirs$control, paste0("CG", wave, ".csv"))
  )
}

run_reported_psm_checks <- function(waves = WAVES) {
  specs <- list(
    caliper_01 = list(caliper = 0.1, ratio = 2L, include_sex = TRUE),
    one_to_one = list(caliper = 0.2, ratio = 1L, include_sex = TRUE),
    no_sex = list(caliper = 0.2, ratio = 2L, include_sex = FALSE)
  )

  lapply(names(specs), function(name) {
    s <- specs[[name]]
    out <- lapply(
      waves,
      function(w) run_psm_variant(w, name, s$caliper, s$ratio, s$include_sex)
    )
    names(out) <- waves
    out
  }) |> setNames(names(specs))
}

fit_variant_main_models <- function(name) {
  dirs <- variant_dirs(name)
  dat <- load_matched_analysis_data(
    matched_treated_dir = dirs$treated,
    matched_control_dir = dirs$control
  )
  fit_main_models(dat)
}

fit_reported_psm_robustness <- function() {
  list(
    baseline = fit_main_models(),
    caliper_01 = fit_variant_main_models("caliper_01"),
    one_to_one = fit_variant_main_models("one_to_one"),
    no_sex = fit_variant_main_models("no_sex")
  )
}
