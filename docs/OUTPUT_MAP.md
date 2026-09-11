# Manuscript output map

This file maps the accepted manuscript's reported outputs to the reconstruction modules that generate them.

| Paper output | Repository code | Notes |
|---|---|---|
| Figure 1 | `R/public/00_mmi_overlay.R` | Public GeoNet shaking × Stats NZ meshblock overlay |
| Table 1 | `R/03_psm_matching.R`, `R/15_appendix_diagnostics.R` | Wave-specific treated/control/matched counts; confidentiality rounding applies |
| Table 2 | `R/04_main_did.R` | Total and regular household income |
| Table 3 | `R/04_main_did.R` | Total household expenditure; four full-expenditure waves |
| Figure 2 | `R/05_expenditure_models.R`, `R/12_output_builders.R` | `100 * (exp(beta) - 1)` from `log(1 + |y|)` category models |
| Figure 3 | `R/05_expenditure_models.R`, `R/12_output_builders.R` | Survey-wave median-income heterogeneity |
| Table 4 | `R/09_descriptives_migration.R` | Post-earthquake stay/relocation conditional associations |
| Tables 5–7 | `R/07_psm_robustness.R` | Caliper 0.1, 1:1 matching, exclude-sex variants |
| Appendix A1–A2 | `R/idi/02_build_wave_samples.R`, `R/15_appendix_diagnostics.R` | Residence groups and missing-address diagnostics |
| Appendix A3 | `R/15_appendix_diagnostics.R` | Requires secure pre-built 2013 Census linkage flag |
| Appendix B1 | `R/03_psm_matching.R`, `R/15_appendix_diagnostics.R` | Maximum SMD and variance ratio by wave |
| Appendix B2–B4 | `R/08_pseudo_outcomes.R`, `R/15_appendix_diagnostics.R` | Four-cell means and pseudo-outcomes |
| Appendix C1–C2 | `R/06_event_study.R` | Event-study estimates and joint pre-trend Wald tests |
| Appendix D1–D2 | `R/09_descriptives_migration.R` | Descriptive statistics by exposure and migration group |
| Appendix E1 | `R/05_expenditure_models.R` | All 18 detailed expenditure categories |
| Appendix F1 | `R/14_census_context.R` | Public 2006/2013 Census regional-income context |
| Appendix G1–G2 | `R/05_expenditure_models.R` | Above-median and at/below-median category models |
| Appendix H1 | `R/10_alternative_specs.R` | Continuous-MMI specification among treated households |
| Appendix H2 | `R/10_alternative_specs.R` | Linear, quadratic and age-bin bridge specifications |
| Appendix I1–I3 | `R/11_att_ipw.R` | PSM/full-pool/ATT-IPW bridge specifications |
| Numerical audit | `R/13_validate_manuscript.R` | Regression tests against accepted-paper targets |

Additional matching sensitivity checks described in Sect. 5.5 but not displayed as the principal four-column robustness tables are in `R/07b_matching_sensitivity.R`.
