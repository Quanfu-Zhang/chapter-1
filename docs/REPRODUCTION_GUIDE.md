# Reproduction guide

This study uses restricted Stats NZ microdata. The full reproduction workflow must therefore be run inside an authorised Data Lab / IDI environment. This repository contains code but no row-level study data.

## 1. Clone the repository in the authorised environment

Use the release/tag corresponding to the paper. Do not add confidential data to the repository directory.

Set two optional environment variables if you do not want the default local layout:

```text
CH1_DATA_ROOT=/secure/path/to/chapter1/data
CH1_OUTPUT_ROOT=/secure/path/to/chapter1/output
```

The code also supports `CH1_IDI_SCHEMA`, `CH1_IDI_REFRESH`, `CH1_CLEAN_READ_HES_SCHEMA`, and `CH1_MMI_LOOKUP_PATH` for refresh- or project-specific configuration.

## 2. Install R dependencies

Core packages used by the analysis are:

- `DBI`, `dbplyr`, `odbc`, `glue`
- `dplyr`, `tidyr`, `purrr`, `readr`, `tibble`
- `MatchIt`, `cobalt`
- `fixest`
- `ggplot2`
- `sf` for the public MMI spatial overlay

The exact package versions used for the final archival run should be recorded with `sessionInfo()` after numerical validation.

## 3. Build the public meshblock-MMI lookup

The MMI construction is independent of restricted HES microdata.

1. Obtain the 22 February 2011 GeoNet shaking/intensity product used for the paper.
2. Obtain the corresponding Stats NZ meshblock boundaries.
3. Convert the GeoNet grid/raster to an `sf` point layer if necessary.
4. Use `R/public/00_mmi_overlay.R` to assign the maximum observed/modelled MMI to each meshblock.
5. Save a two-column lookup containing `meshblock_code` and `mmi_intensity` in a secure/local data path.

Do not commit any derived file that has subsequently been joined to confidential household records.

## 4. Construct wave-specific HES extracts

For each wave from 2006/07 to 2017/18:

1. extract the HES address, household, income and expenditure fields required in `docs/DATA_DICTIONARY.md`;
2. aggregate expenditure to household × HES category where required;
3. join the household and reference-person information;
4. run `canonicalise_hes()` from `R/01_hes_schema_adapter.R`.

The adapter handles the HES naming change from 2015/16 onward. Downstream files should use canonical variable names only.

## 5. Construct administrative address histories

For the HES reference persons, create a long address-history object with the canonical fields:

```text
snz_uid
address_date
region_code
meshblock_code
source
```

The five sources described in the paper are IR, HLFS, ACC, MSD, and the cross-agency address notification dataset. Apply source-specific validity filters before harmonising names (for example, the IR valid-address status rule used in the original scripts).

Run `R/idi/02_build_wave_samples.R` for each wave. The script:

- selects the most recent usable address in 1 January 2010–22 February 2011;
- uses the extended IR lookback to 1 January 2000 only for otherwise unresolved cases;
- implements the missing-region surrounding-meshblock bridge where geography is available;
- creates Groups 1–4;
- applies the Group 2 pre-earthquake-move exclusion;
- screens the comparison pool to North Island households never recorded in Canterbury;
- attaches meshblock-level MMI;
- writes the full treated sample, the Low/High-MMI treated analysis sample, and the eligible control pool to separate secure files.

## 6. Run wave-specific propensity-score matching

Source:

```r
source("R/03_psm_matching.R")
psm_results <- run_all_wave_psm()
```

Baseline matching is performed separately within each HES wave using 1:2 nearest-neighbour matching without replacement, logit propensity scores, a raw-score caliper of 0.2, and age, household size, sex, and highest qualification.

Inspect both the sample-size summary and the `cobalt` balance objects. `R/15_appendix_diagnostics.R` converts these into Table 1 / Appendix B diagnostics.

## 7. Run the main and appendix analyses

Recommended order:

```r
source("R/04_main_did.R")
main_models <- fit_main_models()

source("R/05_expenditure_models.R")
exp_data <- prepare_expenditure_outcomes(load_matched_analysis_data())
exp_models <- fit_expenditure_categories(exp_data)
heterogeneity_models <- fit_income_heterogeneity(load_matched_analysis_data())

source("R/06_event_study.R")
event_models <- fit_event_study_models()

source("R/07_psm_robustness.R")
# First generate variant matched samples:
run_reported_psm_checks()
psm_robustness <- fit_reported_psm_robustness()

source("R/08_pseudo_outcomes.R")
pseudo_covariates <- fit_key_covariate_pseudo_outcomes()
pseudo_composition <- fit_household_composition_pseudo_outcomes()

source("R/09_descriptives_migration.R")
table_d1 <- build_table_d1()
table_d2 <- build_table_d2()
relocation_models <- fit_relocation_models()

source("R/10_alternative_specs.R")
continuous_mmi <- fit_continuous_mmi_models()
age_bridge <- fit_age_bridge_models()

source("R/11_att_ipw.R")
att_ipw <- fit_appendix_i()
```

`R/07b_matching_sensitivity.R` contains the additional probit, linear-probability, and leave-one-matching-covariate-out checks described in Sect. 5.5.

## 8. Build figures and tables

Use `R/12_output_builders.R` to extract model results and reproduce the detailed expenditure figures. Appendix F's public Census comparison is in `R/14_census_context.R`. Appendix A–B diagnostic builders are in `R/15_appendix_diagnostics.R`.

All confidential tabular outputs must undergo the appropriate Stats NZ output checking before leaving the Data Lab.

## 9. Validate against the accepted manuscript

This step is mandatory for the reconstructed codebase:

```r
source("R/13_validate_manuscript.R")
checks <- run_manuscript_validation(psm_results)
```

The validator checks published sample sizes, headline DiD coefficients and standard errors, Tables 5–7 robustness results, Table 4 relocation models, Appendix H continuous-MMI estimates, and event-study pre-trend p values.

A failed check is diagnostic information, not something to suppress. Trace the discrepancy upstream until the analysis and published output agree, or document why a printed target is affected by confidentiality rounding.

## 10. Freeze the archival release

After all substantive validation checks pass:

1. save `sessionInfo()` to `docs/sessionInfo.txt`;
2. ensure no restricted data or unapproved outputs are present in Git history;
3. merge the release-preparation PR;
4. create a version tag/release (for example `v1.0.0`);
5. update `CITATION.cff` with the final article DOI if available;
6. make the repository public only after the authors are satisfied that the release is confidentiality-safe.
