# Canonical analysis data dictionary

The methodological code harmonises two HES naming regimes before matching or regression. Source-specific names appear only in the schema-adapter layer.

## Core canonical variables

| Canonical name | Meaning | Legacy HES (through 2014/15) | Clean Read HES (2015/16 onward) |
|---|---|---|---|
| `snz_uid` | linked person identifier | `snz_uid` | `snz_uid` (linked from HES person/address records) |
| `snz_hes_hhld_uid` | HES household identifier | `snz_hes_hhld_uid` | `snz_hes_hhld_uid` |
| `wave` | HES wave code (`0607` … `1718`) | constructed | constructed |
| `ref_person` | household reference-person indicator | `hes_inc_reference_person_code == "Yes"` | `Ref_Person == "1"` |
| `ref_age` | age of reference person | `hes_inc_age_nbr` | `DVAge` |
| `ref_education` | highest qualification code | `hes_inc_highest_qual_code` | `DVHqual` |
| `ref_sex` | sex of reference person | `hes_inc_sex_snz_code` | `Sex` |
| `hh_size` | household size | `hes_hhd_household_size_nbr` | `DVHHSize_Nbr` |
| `tenure_code` | HES tenure code | `hes_hhd_tenure_code` | `DVHHTenure` |
| `household_comp` | household-composition code/label | `hes_hhd_hhold_comp_code` | `DVHHComp2` |
| `survey_weight` | HES non-response/final weight | `hes_hhd_weight_non_resp_nbr` | `FinalWgt` |
| `total_income` | total household income | `hes_hhd_total_hhold_income_amt` | `Total_Household_AllInc` |
| `regular_income` | total household regular income | `hes_hhd_total_hhold_reginc_amt` | `Total_Household_RegInc` |
| `total_expenditure` | HES total household expenditure | `hes_hhd_total_hhold_expend_amt` | `DVTot_HOU_Exp` |
| `ta_code` | HES territorial authority | `hes_add_ta_code` | `hes_add_ta_code` |
| `hes_region_code` | HES survey region | `hes_add_region_code` | `hes_add_region_code` |
| `meshblock_code` | HES meshblock/geography | `hes_add_meshblock_code` | `hes_add_meshblock_code` |
| `interview_date` | HES interview date where available | `hes_add_interview_date` | refresh-specific HES address field |

The exact Clean Read source names are preserved from the surviving project scripts. If a later IDI refresh changes a source field, update the mapping in `R/01_hes_schema_adapter.R`; do not change downstream analysis code.

## Derived analytical variables

| Variable | Definition |
|---|---|
| `post` | 1 for HES waves 2011/12–2017/18; 0 otherwise |
| `ref_age_sq` | `ref_age^2` |
| `female` | 1 = female reference person, 0 = male |
| `hh_tenure` | `Owned/Trust` for tenure codes 10–12 or 30–32; `Rented` for 20–22 |
| `log_income` | `log(1 + total_income)` when total income > -1 |
| `mmi_intensity` | maximum Modified Mercalli Intensity assigned to the household's pre-earthquake meshblock |
| `mmi_group` | `Control`, `Low` for 4 ≤ MMI < 7, `High` for MMI ≥ 7 |
| `treated_area` | 1 for treated Canterbury household, 0 for matched/eligible North Island comparison household |
| `relocation` | 1 for Group 2 households, 0 for Group 1 households |
| `household_comp_group` | broad household-composition category used in robustness checks |

## Residence-classification variables

`R/idi/02_build_wave_samples.R` creates the following provenance fields:

| Variable | Meaning |
|---|---|
| `prequake_address_date` | date of selected pre-earthquake administrative address |
| `prequake_region` | selected pre-earthquake region |
| `prequake_meshblock` | selected/bridged pre-earthquake meshblock |
| `prequake_source` | administrative source supplying the selected record |
| `prequake_address_rule` | `reference_window`, `ir_lookback`, or a meshblock-bridge variant |
| `bridge_same_meshblock` | flag for the missing-region surrounding-meshblock rule |
| `prequake_exit_evidence` | Group 2 exclusion flag for evidence of a pre-earthquake move out of Canterbury |
| `group` | Group 1, 2, 3, 4, or missing address |
| `treated_full` | Groups 1–2 after the pre-earthquake-move exclusion |
| `treated_analysis` | `treated_full` with MMI in the Low/High analysis range |
| `eligible_control` | Group 4, North Island, and never recorded in Canterbury in linked address histories |

## Expenditure categories

The analysis uses the HES expenditure categories reported in the paper:

1. domestic fuel and power;
2. housing costs;
3. receipts and refunds;
4. general insurance;
5. miscellaneous payments;
6. mortgages and loans;
7. other property;
8. transportation;
9. retirement savings and contribution schemes;
10. medical and health;
11. diary-recorded day-to-day purchases;
12. travel;
13. telecommunications;
14. fees and subscriptions;
15. education, recreation, sport and culture;
16. household operations;
17. household maintenance;
18. credit and debit accounts.

Category models use `log(1 + |y|)` and are restricted to the four full-expenditure waves: 2006/07, 2009/10, 2012/13 and 2015/16.

## Address-history input contract

The secure sample builder expects a long administrative address table with these canonical fields:

- `snz_uid`
- `address_date`
- `region_code`
- `source` (`IR`, `HLFS`, `ACC`, `MSD`, or `NOTIFY`)
- `meshblock_code` where available

Source-specific secure extraction can rename the underlying IDI fields into this contract before calling `build_wave_samples()`.

## Public MMI lookup contract

The public spatial step produces a lookup with:

- `meshblock_code`
- `mmi_intensity`

No confidential household information belongs in that lookup.
