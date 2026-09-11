# Reproducibility audit before public release

This document records discrepancies between the uploaded working scripts and the accepted manuscript. It is an **internal release checklist**. Every item below should be resolved before the repository is made public and tagged as the replication archive.

## 1. Final estimation script is not the accepted-paper specification

The uploaded `DID R codes.r` is an earlier working script. It differs materially from the accepted manuscript:

- it initially loads only the four full-expenditure waves, whereas the accepted income regressions use all 12 HES waves from 2006/07 to 2017/18;
- it defines the post period from 2012/13, whereas the accepted income specification begins the post period in 2011/12;
- the main income/expenditure regressions omit age squared and the reference person's sex;
- detailed expenditure outcomes are estimated in raw levels rather than `log(1 + |expenditure|)`;
- the income heterogeneity split uses a pooled median rather than the survey-wave median;
- it contains exploratory/unused code (`savings_rate`, plotting blocks, in-place exports) that should not appear in the archival release.

**Required action:** locate the exact final analysis scripts or reconstruct them from the accepted specification and verify every reported table/figure inside the Data Lab.

## 2. Missing analysis components

The uploaded files do not contain the final code for:

- meshblock-to-MMI linkage;
- pseudo-outcome composition tests (Appendix B);
- event-study joint Wald tests (Appendix C) in their final form;
- stay/relocation descriptive regressions (Table 4);
- continuous-MMI and age-functional-form checks (Appendix H);
- ATT-IPW diagnostics and bridge specifications (Appendix I);
- final publication figures and table builders.

**Required action:** add the exact scripts used for the final manuscript, or reconstruct and validate them against the accepted numerical results.

## 3. Sample-construction logic needs reconciliation

The working extraction scripts choose address records by a hard-coded source priority (`IR`, `HLFS`, `ACC`, `MSD`, `NOTIFY`) before sorting by date. This can allow an older IR record to dominate a later record from another source. The accepted manuscript instead describes the most recent pre-earthquake administrative address, with the long IR lookback used for IR-only cases.

The working scripts also do not visibly implement two rules described in the manuscript:

1. the special bridge for cases whose most recent pre-earthquake region is missing but whose surrounding meshblock evidence places them in Canterbury; and
2. exclusion of a small number of Group 2 households with evidence consistent with having left Canterbury before the earthquakes.

**Required action:** determine which exact implementation generated the accepted sample. The public code and manuscript must describe the same algorithm.

## 4. Control-pool definition

The manuscript states that controls are North Island households that were never exposed to the Canterbury earthquake sequence / never recorded as living in Canterbury in the linked address sources. The uploaded control-pool scripts primarily classify households using the selected pre-earthquake address plus the HES survey address.

**Required action:** confirm whether an "ever Canterbury" screen was applied elsewhere. If yes, add that code. If not, reconcile the manuscript wording before final submission/public release.

## 5. MatchIt caliper scale

The working PSM scripts call `matchit(..., caliper = 0.2, ...)` without explicitly setting `std.caliper`. The accepted manuscript says the caliper is 0.2 on the **raw propensity-score scale**.

**Required action:** record the MatchIt version used and confirm the effective caliper scale. In the archival code, set `std.caliper` explicitly so the result is not package-version dependent.

## 6. Matching weights

The working scripts compute survey weights and pass `weights = ~weight` to `matchit()`, while the accepted manuscript does not describe survey-weighted propensity-score estimation.

**Required action:** confirm whether HES survey weights were actually used in the final PSM. If they were, document this in the manuscript/repository. If not, remove the unused argument from the archival code.

## 7. In-place mutation of source files

The working PSM scripts overwrite the treated-group input CSV after matching. This is fragile and obscures provenance.

**Release fix:** archival code must treat inputs as immutable and write matched outputs to new paths.

## 8. Public-release hygiene

Before making the repository public:

- remove Data Lab absolute paths and use environment variables/configuration;
- remove misleading boilerplate authorship/date comments;
- add an explicit software licence chosen by the authors;
- add a tagged release matching the final manuscript;
- record R/package versions (preferably with `renv.lock` or a frozen session-info file);
- verify that no confidential microdata or unapproved outputs are present anywhere in Git history.
