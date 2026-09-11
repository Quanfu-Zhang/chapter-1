# Code guide

This repository is a **methodological code archive for academic communication**. It explains how the empirical analysis reported in the paper was organised. Restricted-data components are intended to be run within the controlled Stats NZ IDI environment by researchers approved for the relevant project, in accordance with Stats NZ requirements.

## Reading order

For most readers, the recommended order is:

1. `R/00_config.R` — study waves, earthquake timing, MMI thresholds, and common constants.
2. `R/01_hes_schema_adapter.R` — harmonisation of the two HES variable-naming regimes.
3. `R/idi/02_build_wave_samples.R` — illustrative restricted-data logic for residence classification, treatment/control construction, and MMI assignment.
4. `R/03_psm_matching.R` — wave-specific propensity-score matching.
5. `R/04_main_did.R` — main difference-in-differences specification.
6. `R/05_expenditure_models.R` — detailed expenditure outcomes and income heterogeneity.
7. `R/06_event_study.R` — event-study specification and pre-trend tests.
8. `R/07_psm_robustness.R` and `R/07b_matching_sensitivity.R` — matching robustness checks.
9. `R/08_pseudo_outcomes.R` — compositional diagnostics.
10. `R/09_descriptives_migration.R` — descriptive and stay/relocation analyses.
11. `R/10_alternative_specs.R` — continuous-MMI and alternative-age specifications.
12. `R/11_att_ipw.R` — ATT-IPW and bridge specifications.
13. `R/12_output_builders.R`, `R/14_census_context.R`, and `R/15_appendix_diagnostics.R` — presentation and appendix utilities.

`R/99_run_order.R` is a script map that loads the modules in this sequence and documents how they relate.

## Why there is one schema adapter

The HES variable naming convention changes from 2015/16 onward. The original working code therefore had separate “before” and “after” scripts. The public archive instead maps both naming regimes to canonical variables such as `ref_age`, `hh_size`, `total_income`, `regular_income`, and `total_expenditure`.

This keeps the substantive matching and regression code independent of source-variable naming changes.

## Restricted-data code

Files under `R/idi/` describe the logic applied to restricted IDI data. They are included because the treatment/control definitions and address-history reconstruction are central to the research design.

The public files contain methodological logic only; they do not include database connection configuration or restricted records. Execution with IDI data must take place within the controlled Stats NZ IDI environment by researchers approved for the relevant project and following Stats NZ requirements.

## Public-data code

Files under `R/public/` can be understood independently of the restricted household microdata. In particular, `R/public/00_mmi_overlay.R` documents the meshblock-level earthquake-intensity overlay.

## Relationship to the paper

The accepted manuscript is the primary description of the empirical design and results. The code is intended to make that design more transparent and easier to discuss. Where an implementation detail is not uniquely recoverable from the surviving historical scripts, the public code uses a clean implementation consistent with the final paper rather than pretending to preserve an exact historical line-for-line record.

See `docs/RECONSTRUCTION_NOTE.md` for provenance details and `docs/OUTPUT_MAP.md` for the link between paper outputs and code modules.
