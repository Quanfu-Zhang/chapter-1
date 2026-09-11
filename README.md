# Canterbury earthquakes, household income and expenditure — replication code

This repository contains the empirical code for:

> Zhang, Q., Noy, I., and Saglam, Y. *The impact of the Canterbury earthquakes on household income and expenditure in the Canterbury region in New Zealand*. **Natural Hazards and Earth System Sciences** (accepted).

The analysis uses New Zealand's Household Economic Survey (HES) linked to administrative address histories and meshblock-level earthquake intensity inside Stats NZ's Integrated Data Infrastructure (IDI). The microdata cannot be redistributed. The repository is therefore designed as **code-only replication material**: eligible researchers with IDI/Data Lab access can recreate the analysis data and rerun the published specifications.

## Repository status

This branch is a **release-preparation candidate**, not yet the public archival release. The original working scripts were written incrementally during the project and used two HES naming conventions. From 2015/16 onward, the Clean Read HES tables use different variable names from the earlier HES tables. The release code isolates that schema change in one adapter so that the downstream matching and estimation code uses one canonical set of variable names.

Before public release, every item in `docs/REPRODUCIBILITY_AUDIT.md` must be resolved against the exact code that generated the accepted manuscript tables and figures.

## Intended run order

1. `R/00_config.R` — analysis constants, wave definitions, and local paths.
2. `R/01_hes_schema_adapter.R` — harmonises pre-2015/16 and 2015/16-onward HES variable names.
3. `R/idi/02_build_wave_samples.R` — IDI-only extraction and residence classification.
4. `R/03_psm_matching.R` — wave-specific propensity-score matching and balance diagnostics.
5. `R/04_main_did.R` — main income and total-expenditure DiD models.
6. `R/05_expenditure_models.R` — detailed expenditure outcomes and income-group heterogeneity.
7. `R/06_event_study.R` — event-study estimates and pre-trend tests.
8. `R/07_psm_robustness.R` — alternative caliper, ratio, and matching-covariate checks.

The ATT-IPW bridge specifications, pseudo-outcome balance checks, migration regressions, MMI linkage, and publication figure/table builders still need to be reconciled with the final analysis scripts before the archival release.

## Data access

The underlying HES and linked administrative microdata are confidential and are not included in this repository. They were accessed in the Stats NZ IDI under approved project MAA2024-54. Researchers who meet Stats NZ eligibility requirements may apply for Data Lab/IDI access. See `docs/DATA_ACCESS.md`.

## Confidentiality

Do **not** commit raw microdata, row-level extracts, confidential counts, credentials, connection strings, or unapproved outputs. The `.gitignore` intentionally blocks common data formats.

## Reproducibility principle

The public release should reproduce the accepted paper's analysis choices exactly. Code has therefore been separated into: (i) IDI extraction and variable harmonisation; (ii) sample construction and matching; and (iii) estimation. This makes the 2015/16 HES schema change explicit without maintaining two near-duplicate analysis pipelines.

## Contact

Quanfu Zhang — School of Economics and Finance, Victoria University of Wellington.
