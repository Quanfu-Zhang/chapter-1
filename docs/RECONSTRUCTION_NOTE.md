# Reconstruction provenance

## Why this repository is reconstructed

The original Chapter 1 code was developed incrementally during analysis inside the Stats NZ Data Lab. It contains duplicated pre-/post-2015/16 HES code, exploratory blocks, absolute Data Lab paths, and intermediate specifications. Several final reviewer-revision routines were not preserved as a single archival script.

For that reason, this repository is a **clean reconstruction of the final analytical workflow**, not a claim that every line is the historical source code that was executed during the project.

## Authority hierarchy

When the surviving working scripts and the accepted paper disagree, the reconstruction follows this order:

1. **Accepted manuscript and final approved numerical outputs** — authoritative for analytical specification and published results.
2. **Surviving project scripts** — authoritative for source-table names, variable-name regimes, coding clues, and implementation details that are consistent with the manuscript.
3. **Explicit reconstruction choices** — used only where neither source uniquely identifies the implementation; such choices are documented and subjected to numerical validation.

This avoids preserving known obsolete code merely because it happened to survive on disk.

## Major reconciliations

### HES schema change

Earlier HES waves use `hes_hhd_*`, `hes_inc_*`, and related names. From 2015/16 onward the Clean Read HES products use names such as `DVAge`, `DVHqual`, `DVHHSize_Nbr`, and `Total_Household_AllInc`. `R/01_hes_schema_adapter.R` maps both regimes to one canonical schema. Downstream analysis is therefore written once.

### Post-earthquake timing

The surviving early DiD script used 2012/13 as the first post wave in places. The accepted manuscript defines 2011/12 as the first post-earthquake wave for annual income outcomes. The reconstructed configuration follows the manuscript. The full-expenditure sample naturally has 2012/13 as its first observed post wave because expenditure is available only every third year.

### Main DiD controls

The accepted specification includes age, age squared, reference-person sex, and household size, plus survey-year and territorial-authority fixed effects and TA-clustered standard errors. These replace earlier exploratory versions that omitted some controls.

### Detailed expenditure outcomes

The accepted paper estimates category models using `log(1 + |expenditure|)`. Earlier raw-level category regressions are not part of the replication pipeline.

### Income-group heterogeneity

The accepted paper defines above/below-income groups relative to the **contemporaneous survey-wave median**. A pooled-median split found in early working code is not used.

### Residence classification

The surviving extraction scripts selected address records partly through a hard-coded source priority. The accepted manuscript instead describes the most recent usable pre-earthquake address across linked sources, an extended IR lookback for otherwise unresolved cases, a meshblock bridge for missing-region records, and a small Group 2 pre-earthquake-move exclusion. `R/idi/02_build_wave_samples.R` implements the manuscript description.

### Matching

The accepted paper specifies wave-specific 1:2 nearest-neighbour matching without replacement, a logit propensity score, and a 0.2 caliper on the **raw propensity-score scale**. The reconstructed code sets `std.caliper = FALSE` explicitly and does not rely on MatchIt defaults.

The early PSM scripts passed HES survey weights to `matchit()`, while the accepted manuscript does not describe survey-weighted propensity-score estimation. The baseline reconstruction therefore does not use survey weights for PSM. This choice is validated against the final sample sizes and regression targets.

## Reconstruction-dependent items

A few implementation details are not uniquely specified by the manuscript itself and therefore remain validation-sensitive:

- the exact coding threshold underlying the Appendix B “Higher education” binary indicator;
- the interpretation of the “Weighted” household-composition pseudo-outcome rows in Table B4 (the reconstruction uses HES survey weights);
- the exact winsorisation threshold used for the “Trimmed ATT-IPW” column in Appendix I; the manuscript does not state it, so `R/11_att_ipw.R` exposes the threshold as a parameter and defaults to the 1st/99th percentiles without dropping observations;
- source-specific geography fields required to implement the missing-region meshblock bridge can differ by IDI refresh and must be mapped in the secure extraction layer.

These are not silently treated as known historical facts. They are documented and must be resolved by the numerical validation harness before the final archival tag.

## Validation principle

The accepted manuscript supplies multiple independent numerical constraints: wave-specific sample counts, matching-balance diagnostics, observation counts, regression coefficients, standard errors, pre-trend p values, robustness estimates, and appendix results. `R/13_validate_manuscript.R` encodes major published targets. The reconstruction is considered verified only when the secure run reproduces those targets jointly, rather than merely matching one headline coefficient.
