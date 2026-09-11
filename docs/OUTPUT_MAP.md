# Manuscript output map

This file maps the accepted manuscript's reported outputs to the methodological modules that describe the corresponding analysis.

| Paper output | Repository code | Notes |
|---|---|---|
| Figure 1 | `R/public/00_mmi_overlay.R` | Public GeoNet shaking × Stats NZ meshblock overlay |
| Table 1 | `R/idi/02_build_wave_samples.R`, `R/03_psm_matching.R` | Sample-construction and matching definitions |
| Table 2 | `R/04_main_did.R` | Total and regular household income |
| Table 3 | `R/04_main_did.R` | Total household expenditure; four full-expenditure waves |
| Figure 2 | `R/05_expenditure_models.R`, `R/12_output_builders.R` | `100 * (exp(beta) - 1)` from `log(1 + |y|)` category models |
| Figure 3 | `R/05_expenditure_models.R`, `R/12_output_builders.R` | Survey-wave median-income heterogeneity |
| Table 4 | `R/09_descriptives_migration.R` | Post-earthquake stay/relocation conditional associations |
| Tables 5–7 | `R/07_psm_robustness.R` | Caliper 0.1, 1:1 matching, exclude-sex variants |
| Appendix A1–A2 | `R/idi/02_build_wave_samples.R` | Residence-group and missing-address classification logic |
| Appendix A3 | manuscript documentation | Census-linkage diagnostic reported in the paper |
| Appendix B1 | `R/03_psm_matching.R`, `R/15_appendix_diagnostics.R` | Standardised mean differences and variance-ratio diagnostics |
| Appendix B2–B4 | `R/08_pseudo_outcomes.R`, `R/15_appendix_diagnostics.R` | Four-cell means and pseudo-outcomes |
| Appendix C1–C2 | `R/06_event_study.R` | Event-study estimates and joint pre-trend Wald tests |
| Appendix D1–D2 | `R/09_descriptives_migration.R` | Descriptive statistics by exposure and migration group |
| Appendix E1 | `R/05_expenditure_models.R` | Detailed expenditure categories |
| Appendix F1 | `R/14_census_context.R` | Public Census regional-income context |
| Appendix G1–G2 | `R/05_expenditure_models.R` | Above-median and at/below-median category models |
| Appendix H1 | `R/10_alternative_specs.R` | Continuous-MMI specification among treated households |
| Appendix H2 | `R/10_alternative_specs.R` | Linear, quadratic and age-bin bridge specifications |
| Appendix I1–I3 | `R/11_att_ipw.R` | PSM/full-pool/ATT-IPW bridge specifications |

Additional matching sensitivity checks described in Sect. 5.5 are in `R/07b_matching_sensitivity.R`.
