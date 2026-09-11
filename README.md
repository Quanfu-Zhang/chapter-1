# Canterbury earthquakes, household income and expenditure — methodological code

Code accompanying:

> Zhang, Q., Noy, I., and Saglam, Y. **The impact of the Canterbury earthquakes on household income and expenditure in the Canterbury region in New Zealand.** *Natural Hazards and Earth System Sciences* (accepted).

The paper uses New Zealand's Household Economic Survey (HES), linked administrative address histories, and meshblock-level earthquake intensity to study household income and expenditure after the 2010–2011 Canterbury earthquakes.

## Purpose of this repository

This repository is intended for **academic communication and methodological transparency**. It presents a cleaned, readable reconstruction of the main analytical workflow used in the study: HES harmonisation, residence classification, earthquake-intensity assignment, propensity-score matching, difference-in-differences estimation, heterogeneity analysis, robustness checks, and figure/table construction.

The underlying HES and linked administrative microdata are held in Stats NZ's Integrated Data Infrastructure (IDI). Restricted-data components are intended to be run within the controlled Stats NZ IDI environment by researchers approved for the relevant project, in accordance with Stats NZ requirements.

The code serves as an illustration of the research design and implementation principles reported in the paper.

## Reconstruction note

The original Chapter 1 code was developed incrementally and included separate pre-/post-2015/16 HES scripts, exploratory blocks, Data Lab-specific paths, and intermediate specifications. The public codebase was reconstructed and cleaned from those surviving scripts together with the final accepted manuscript.

The repository does not claim that every line is the exact historical source code executed during the project. Where the surviving scripts and the accepted paper differ, the public code follows the final analytical specification described in the paper. See `docs/RECONSTRUCTION_NOTE.md`.

A major design feature is `R/01_hes_schema_adapter.R`. HES variable names changed from 2015/16 onward; instead of publishing duplicate “before” and “after” analysis scripts, both naming regimes are converted to one canonical schema before matching or estimation.

## Repository structure

```text
R/
  00_config.R                    Analysis constants and generic paths
  01_hes_schema_adapter.R        Pre-/post-2015/16 HES harmonisation
  idi/
    02_build_wave_samples.R      Illustrative residence classification and sample construction
  public/
    00_mmi_overlay.R             GeoNet × meshblock MMI construction
  03_psm_matching.R              Wave-specific propensity-score matching
  04_main_did.R                  Main income and expenditure DiD models
  05_expenditure_models.R        Detailed expenditure + income heterogeneity
  06_event_study.R               Event-study specification and pre-trend tests
  07_psm_robustness.R            Reported matching robustness checks
  07b_matching_sensitivity.R     Additional matching sensitivity checks
  08_pseudo_outcomes.R           Composition and covariate pseudo-outcomes
  09_descriptives_migration.R    Descriptive and stay/relocation analyses
  10_alternative_specs.R         Continuous-MMI and alternative-age specifications
  11_att_ipw.R                   ATT-IPW and bridge specifications
  12_output_builders.R           Figure/table builders
  14_census_context.R            Public Census regional-income comparison
  15_appendix_diagnostics.R      Balance and composition diagnostic helpers
  99_run_order.R                 Script map / load order

docs/
  CODE_GUIDE.md                  How the public code is organised
  DATA_ACCESS.md                 Restricted-data access requirements
  DATA_DICTIONARY.md             Canonical variables and schema mapping
  OUTPUT_MAP.md                  Paper outputs and corresponding code modules
  RECONSTRUCTION_NOTE.md         Provenance and reconstruction choices
```

## Core analytical specification

The code reflects the final paper's analytical design:

- HES waves: 2006/07–2017/18.
- Income outcomes: all 12 waves; the post-earthquake period begins in 2011/12.
- Full expenditure outcomes: 2006/07, 2009/10, 2012/13 and 2015/16 only.
- Treatment intensity: Low MMI = `[4, 7)`; High MMI = `>= 7`.
- Matching: separately within each survey wave; 1:2 nearest-neighbour matching without replacement; logit propensity scores; caliper 0.2; age, household size, sex and highest qualification as matching covariates.
- Main DiD controls: reference-person age, age squared, sex and household size, with survey-wave and territorial-authority fixed effects and TA-clustered standard errors.
- Detailed expenditure outcomes: `log(1 + |expenditure|)`.
- Income heterogeneity: contemporaneous survey-wave median income.

## Restricted-data components

Files under `R/idi/` document the logic used for restricted-data processing, including administrative-address harmonisation, residence groups, control-pool construction, and MMI assignment. They are published to explain the method and contain no restricted records or database connection configuration.

No restricted microdata, identifiers, confidential extracts, or unapproved outputs are included in this repository. The `.gitignore` blocks common microdata formats by default.

## Public-data components

`R/public/00_mmi_overlay.R` illustrates the spatial-overlay step used to assign GeoNet shaking intensity to Stats NZ meshblocks. `R/14_census_context.R` contains the aggregate regional comparison used for contextual analysis.

## Data access

The study was conducted under Stats NZ IDI project **MAA2024-54**. Restricted-data execution must take place in the controlled IDI environment by researchers approved for the relevant project and in accordance with Stats NZ requirements.

See `docs/DATA_ACCESS.md`.

## Use and citation

The code may be useful for understanding the paper's empirical design, teaching, methodological discussion, or adapting similar methods within an appropriately approved research environment.

Please cite the article and, where appropriate, this repository. Machine-readable citation metadata are provided in `CITATION.cff`.

## Licence

Code and documentation are released under the Creative Commons Attribution 4.0 International licence (CC BY 4.0).

## Contact

Quanfu Zhang  
School of Economics and Finance, Victoria University of Wellington  
`quanfu.zhang@vuw.ac.nz`
