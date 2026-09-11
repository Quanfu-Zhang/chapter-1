# ==============================================================================
# Alternative PSM specifications reported in the paper
# ==============================================================================

source(file.path("R", "03_psm_matching.R"))

run_reported_psm_checks <- function(wave) {
  list(
    baseline = run_wave_psm(wave, caliper = 0.2, ratio = 2L, include_sex = TRUE),
    caliper_01 = run_wave_psm(wave, caliper = 0.1, ratio = 2L, include_sex = TRUE),
    one_to_one = run_wave_psm(wave, caliper = 0.2, ratio = 1L, include_sex = TRUE),
    no_sex = run_wave_psm(wave, caliper = 0.2, ratio = 2L, include_sex = FALSE)
  )
}

# Important: running these variants should write to variant-specific output
# directories in production code rather than overwrite the baseline matched sample.
