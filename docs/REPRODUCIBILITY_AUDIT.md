# Reproducibility audit

This document records the release status of the reconstructed Chapter 1 replication repository. The codebase is structurally complete, but the final archival tag should be created only after the secure Data Lab run has passed the numerical validation harness.

## Resolved in the reconstruction

### Final estimation specification

The early `DID R codes.r` script is no longer used as the archival analysis script. The reconstructed pipeline now follows the accepted manuscript:

- all 12 HES waves for annual income outcomes;
- 2011/12 as the first post-earthquake income wave;
- four full-expenditure waves only for total/detailed expenditure;
- age, age squared, sex and household size in the main DiD;
- survey-wave and TA fixed effects with TA-clustered standard errors;
- `log(1 + |expenditure|)` for detailed categories;
- contemporaneous survey-wave median income for heterogeneity.

### Missing analytical modules

The repository now includes reconstructed modules for:

- public meshblock-MMI overlay;
- pseudo-outcome diagnostics;
- final event-study and joint pre-trend tests;
- stay/relocation descriptives and regressions;
- continuous-MMI and age-functional-form checks;
- ATT-IPW bridge specifications and diagnostics;
- PSM robustness and propensity-link sensitivity checks;
- Figures 2–3 and tabular result extraction;
- Appendix A–B diagnostics and Appendix F public Census context;
- numerical validation against accepted-paper targets.

### HES naming change

The before/after-2015/16 duplication has been replaced by `R/01_hes_schema_adapter.R`. All downstream code uses one canonical variable schema.

### Sample construction

`R/idi/02_build_wave_samples.R` implements the manuscript description rather than the hard-coded source priority found in early scripts. It includes:

- the 2010-01-01 to 2011-02-22 reference window;
- extended IR lookback for otherwise unresolved cases;
- missing-region meshblock bridge;
- Groups 1–4;
- Group 2 pre-earthquake-move exclusion;
- North Island / never-Canterbury comparison-pool screen;
- MMI linkage and Low/High intensity restrictions.

### MatchIt caliper

The baseline code now explicitly sets a 0.2 caliper on the raw propensity-score scale (`std.caliper = FALSE`) and does not rely on package defaults.

### Provenance safety

PSM inputs are immutable. Matched treated and comparison datasets are written to new directories. Absolute Data Lab paths and credentials are excluded from the public configuration.

## Validation-sensitive reconstruction choices

The following details cannot be identified uniquely from the accepted manuscript plus surviving scripts and therefore require numerical confirmation inside the secure environment:

1. **Appendix B higher-education indicator.** The current adapter uses the documented recoded qualification scale and defines higher education as recoded level 4 or above. Confirm against Table B2/B3 means and coefficients.
2. **Appendix B weighted household-composition tests.** The current implementation interprets “Weighted” as HES survey weights. Confirm against Table B4.
3. **Appendix I trimmed ATT-IPW.** The manuscript does not report the numerical trimming threshold. The code implements weight winsorisation without dropping observations and exposes the quantiles as parameters; the default is 1st/99th percentile. Calibrate only if required to reproduce column H, then document the verified threshold.
4. **Refresh-specific geography fields.** The missing-region meshblock bridge requires a secure address-history extract containing meshblock identifiers. Source field names may vary by IDI refresh and should be mapped into the canonical address contract.
5. **Baseline PSM survey weights.** Early working code passed HES survey weights to MatchIt, whereas the accepted manuscript does not describe survey-weighted matching. The reconstructed baseline omits those weights. The Table 1 / B1 / main-model validation targets will determine whether that choice reproduces the accepted analysis.

## Mandatory pre-release numerical checks

Run `R/13_validate_manuscript.R` after reconstructing the secure sample. At minimum, confirm:

- Table 1 wave-specific treated, eligible-control and matched-control counts (allowing for Stats NZ confidentiality rounding);
- Table B1 matching balance;
- main total-income, regular-income and total-expenditure coefficients, SEs and observation counts;
- Appendix C event-study pre-trend p values;
- Table 4 stay/relocation coefficients, SEs and N;
- Tables 5–7 PSM robustness coefficients and sample sizes;
- Table E1 category coefficients and sample sizes;
- Appendix G income-heterogeneity results;
- Appendix H continuous-MMI and alternative-age specifications;
- Appendix I ATT-IPW bridge results and weight diagnostics.

The validator already encodes the major headline targets. Additional table-specific targets can be added if a discrepancy appears.

## Public-release hygiene checklist

Before changing repository visibility or tagging `v1.0.0`:

- [ ] Secure numerical validation completed.
- [ ] Validation output reviewed; no unexplained material discrepancies.
- [ ] Stats NZ output checking completed for any outputs to be published.
- [ ] `docs/sessionInfo.txt` generated from the validated run.
- [ ] Git history checked for raw microdata, row-level extracts, identifiers, credentials and unapproved counts.
- [ ] Final article DOI added to `CITATION.cff` when available.
- [ ] Draft release PR reviewed and merged.
- [ ] Repository visibility changed only after confidentiality review.

## Release criterion

The reconstructed code is considered **archival-ready** when the accepted manuscript's analytical results are reproduced jointly, rather than when one or two headline coefficients happen to match. The final paper is the specification; the surviving scripts are implementation evidence.
