# Reconstruction provenance

## Why this repository is reconstructed

The original Chapter 1 code was developed incrementally during analysis inside the Stats NZ Data Lab. It contained duplicated pre-/post-2015/16 HES code, exploratory blocks, absolute Data Lab paths, and intermediate specifications. Several final reviewer-revision routines were not preserved as a single archival script.

For that reason, this repository is a **clean methodological reconstruction of the final analytical workflow**, not a claim that every line is the historical source code executed during the project.

The public archive is designed for academic communication: readers should be able to see the research design, variable harmonisation, sample-construction logic, matching strategy, regression specifications, heterogeneity analyses, and robustness checks without exposing restricted microdata.

## Authority hierarchy

When the surviving working scripts and the accepted paper disagree, the reconstruction follows this order:

1. **Accepted manuscript** — authoritative for the analytical specification and interpretation reported publicly.
2. **Surviving project scripts** — used for source-table names, variable-name regimes, coding clues, and implementation details that are consistent with the final paper.
3. **Explicit reconstruction choices** — used where neither source uniquely identifies the historical implementation.

The purpose is not to recover an unverifiable line-for-line historical script. It is to present a coherent implementation of the methods described in the final paper.

## Major reconciliations

### HES schema change

Earlier HES waves use `hes_hhd_*`, `hes_inc_*`, and related names. From 2015/16 onward the Clean Read HES products use names such as `DVAge`, `DVHqual`, `DVHHSize_Nbr`, and `Total_Household_AllInc`. `R/01_hes_schema_adapter.R` maps both regimes to one canonical schema. Downstream analysis is therefore written once.

### Post-earthquake timing

The surviving early DiD script used 2012/13 as the first post wave in places. The accepted manuscript defines 2011/12 as the first post-earthquake wave for annual income outcomes. The public reconstruction follows the manuscript. The full-expenditure sample naturally has 2012/13 as its first observed post wave because the full expenditure module is available only every third year.

### Main DiD controls

The accepted specification includes age, age squared, reference-person sex, and household size, plus survey-year and territorial-authority fixed effects and TA-clustered standard errors. These replace earlier exploratory versions that omitted some controls.

### Detailed expenditure outcomes

The accepted paper estimates category models using `log(1 + |expenditure|)`. Earlier raw-level category regressions are not part of the public methodological code.

### Income-group heterogeneity

The accepted paper defines above-/below-income groups relative to the contemporaneous survey-wave median. A pooled-median split found in early working code is not used.

### Residence classification

The surviving extraction scripts selected address records partly through a hard-coded source priority. The accepted manuscript instead describes the most recent usable pre-earthquake address across linked sources, an extended IR lookback for otherwise unresolved cases, a meshblock bridge for missing-region records, and a small Group 2 pre-earthquake-move exclusion. `R/idi/02_build_wave_samples.R` presents a clean implementation of that published logic.

### Matching

The accepted paper describes wave-specific 1:2 nearest-neighbour matching without replacement using age, household size, sex, and highest qualification. The public code makes these analytical choices explicit rather than relying on package defaults.

## What this repository does not claim

This repository does **not** claim to be an independently executable replication archive for the restricted IDI analysis. The project data are governed by Stats NZ project-specific approval, and general Data Lab researcher status does not authorise access to project MAA2024-54 data.

It also does not claim that every implementation detail can be uniquely inferred from the surviving historical code. Where an exact historical choice cannot be recovered, the code uses a transparent implementation that is consistent with the final manuscript and suitable for methodological discussion.

## Appropriate use

The archive is intended to support:

- understanding and discussing the empirical design;
- demonstrating how the HES schema change was handled;
- illustrating address-history reconstruction and treatment/control definitions;
- communicating the matching, DiD, heterogeneity, and robustness specifications;
- adapting similar ideas within a researcher's own separately approved project and data environment.

For data-access limitations, see `docs/DATA_ACCESS.md`. For a file-by-file reading guide, see `docs/CODE_GUIDE.md`.
