# Canterbury earthquakes, household income and expenditure — replication code

Replication repository for:

> Zhang, Q., Noy, I., and Saglam, Y. **The impact of the Canterbury earthquakes on household income and expenditure in the Canterbury region in New Zealand.** *Natural Hazards and Earth System Sciences* (accepted).

The paper uses New Zealand's Household Economic Survey (HES), linked administrative address histories, and meshblock-level earthquake intensity to estimate propensity-score-matched difference-in-differences models of household income and expenditure after the 2010–2011 Canterbury earthquakes.

## What this repository contains

This is a **code-only replication repository**. The underlying HES and linked administrative microdata are confidential and cannot be redistributed. Researchers with authorised Stats NZ Data Lab / IDI access can use the code to reconstruct the study sample and rerun the reported specifications.

The public codebase was reconstructed and cleaned from the original working scripts and the final accepted manuscript. The accepted manuscript is treated as the authoritative analytical specification. Numerical targets from the published tables are encoded in `R/13_validate_manuscript.R` so the reconstructed pipeline can be checked against the final results inside the secure Data Lab.

A major design feature is the HES schema adapter in `R/01_hes_schema_adapter.R`. HES variable names changed from 2015/16 onward; instead of maintaining duplicate “before” and “after” analysis scripts, both naming regimes are converted to a single canonical schema before matching or estimation.

## Repository structure

```text
R/
  00_config.R                    Analysis constants and paths
  01_hes_schema_adapter.R        Pre-/post-2015/16 HES harmonisation
  idi/
    02_build_wave_samples.R      Residence groups, control pool, MMI linkage
  public/
    00_mmi_overlay.R             Public GeoNet × meshblock MMI construction
  03_psm_matching.R              Baseline wave-specific PSM
  04_main_did.R                  Main income and expenditure DiD models
  05_expenditure_models.R        18 expenditure categories + income heterogeneity
  06_event_study.R               Event study and pre-trend Wald tests
  07_psm_robustness.R            Caliper / 1:1 / exclude-sex checks
  07b_matching_sensitivity.R     Probit, LPM, leave-one-covariate-out checks
  08_pseudo_outcomes.R           Composition and covariate pseudo-outcomes
  09_descriptives_migration.R    Appendix D and stay/relocation regressions
  10_alternative_specs.R         Continuous MMI and alternative age controls
  11_att_ipw.R                   ATT-IPW and Appendix I bridge specifications
  12_output_builders.R           Tables and Figures 2–3
  13_validate_manuscript.R       Numerical regression tests against the paper
  14_census_context.R            Public Census regional-income comparison
  15_appendix_diagnostics.R      Appendix A–B diagnostic table builders
  99_run_order.R                 Orchestration / run order

docs/
  DATA_ACCESS.md                 Restricted-data and confidentiality notes
  DATA_DICTIONARY.md             Canonical variables and schema mapping
  RECONSTRUCTION_NOTE.md         Provenance of the reconstructed codebase
  REPRODUCTION_GUIDE.md          Secure-environment reproduction workflow
  REPRODUCIBILITY_AUDIT.md       Validation status and remaining checks
```

## Core analytical specification

The baseline code follows the accepted paper:

- HES waves: 2006/07–2017/18.
- Income outcomes: all 12 waves; the post-earthquake period begins in 2011/12.
- Full expenditure outcomes: 2006/07, 2009/10, 2012/13 and 2015/16 only.
- Treatment intensity: Low MMI = `[4, 7)`; High MMI = `>= 7`.
- Matching: separately within each survey wave; 1:2 nearest-neighbour matching without replacement; logit propensity scores; raw propensity-score caliper 0.2; age, household size, sex and highest qualification as matching covariates.
- Main DiD controls: reference-person age, age squared, sex and household size, with survey-wave and territorial-authority fixed effects and TA-clustered standard errors.
- Detailed expenditure outcomes: `log(1 + |expenditure|)`.
- Income heterogeneity: contemporaneous survey-wave median income.

## Reproduction workflow

The secure run has two stages.

**1. Inside the Stats NZ Data Lab**

Construct wave-specific HES extracts and linked address histories, run `R/idi/02_build_wave_samples.R`, then run the PSM and analysis scripts. No row-level output should leave the secure environment.

**2. Validate before release**

Run `R/13_validate_manuscript.R`. It compares reconstructed estimates and sample sizes with the accepted manuscript, including the main DiD, PSM robustness checks, relocation regressions, continuous-MMI specification and event-study pre-trend tests. A release should only be tagged after all substantive validation checks pass or any remaining discrepancy is explicitly documented.

See `docs/REPRODUCTION_GUIDE.md` for the detailed sequence.

## Public-data components

`R/public/00_mmi_overlay.R` provides the public spatial-overlay step used to assign maximum GeoNet shaking intensity to Stats NZ meshblocks. `R/14_census_context.R` reconstructs the aggregate 2006–2013 regional household-income comparison reported in Appendix F.

Public source data are not duplicated here when they can be obtained from their original provider. See the documentation for expected input fields and licences.

## Restricted data and confidentiality

The study was conducted in the Stats NZ Integrated Data Infrastructure under approved project **MAA2024-54**. Raw HES records, linked administrative data, confidential identifiers and unapproved outputs are not part of this repository. The `.gitignore` blocks common microdata formats by default.

See `docs/DATA_ACCESS.md` before running or modifying the IDI components.

## Reconstruction provenance

The original project code was written incrementally and was not a single archival pipeline. This repository therefore does **not** claim that every line is the historical source code executed during analysis. It is a cleaned reconstruction of the final analytical workflow, grounded in the surviving scripts and the accepted manuscript and designed to reproduce the final reported results. See `docs/RECONSTRUCTION_NOTE.md`.

## Citation

Please cite the article and this repository. Machine-readable citation metadata are provided in `CITATION.cff`.

## Licence

Code and documentation are released under the Creative Commons Attribution 4.0 International licence (CC BY 4.0), consistent with the licence stated in the surviving project scripts.

## Contact

Quanfu Zhang  
School of Economics and Finance, Victoria University of Wellington  
`quanfu.zhang@vuw.ac.nz`
