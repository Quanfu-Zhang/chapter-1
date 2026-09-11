# ==============================================================================
# HES schema adapter
# ------------------------------------------------------------------------------
# Purpose: isolate the variable-name change from 2015/16 onward. Downstream code
# works only with the canonical names defined below while retaining any additional
# analysis variables (for example, MMI or expenditure-category columns).
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
})

canonicalise_hes <- function(df, wave) {
  stopifnot(length(wave) == 1L)

  if (legacy_wave(wave)) {
    required <- c(
      "snz_hes_hhld_uid", "hes_inc_reference_person_code",
      "hes_inc_age_nbr", "hes_inc_highest_qual_code", "hes_inc_sex_snz_code",
      "hes_hhd_household_size_nbr", "hes_hhd_tenure_code",
      "hes_hhd_weight_non_resp_nbr", "hes_hhd_total_hhold_income_amt",
      "hes_hhd_total_hhold_reginc_amt", "hes_hhd_total_hhold_expend_amt",
      "hes_add_ta_code", "hes_add_region_code", "hes_add_meshblock_code"
    )
    missing <- setdiff(required, names(df))
    if (length(missing)) stop("Legacy HES variables missing: ", paste(missing, collapse = ", "))

    out <- df %>%
      mutate(
        wave = as.character(wave),
        snz_uid = if ("snz_uid" %in% names(df)) as.character(snz_uid) else NA_character_,
        ref_person = hes_inc_reference_person_code == "Yes",
        ref_age = as.numeric(hes_inc_age_nbr),
        ref_education = as.character(hes_inc_highest_qual_code),
        ref_sex = as.character(hes_inc_sex_snz_code),
        hh_size = as.numeric(hes_hhd_household_size_nbr),
        tenure_code = as.character(hes_hhd_tenure_code),
        survey_weight = as.numeric(hes_hhd_weight_non_resp_nbr),
        total_income = as.numeric(hes_hhd_total_hhold_income_amt),
        regular_income = as.numeric(hes_hhd_total_hhold_reginc_amt),
        total_expenditure = as.numeric(hes_hhd_total_hhold_expend_amt),
        ta_code = as.character(hes_add_ta_code),
        hes_region_code = as.character(hes_add_region_code),
        meshblock_code = as.character(hes_add_meshblock_code)
      )
  } else {
    required <- c(
      "snz_hes_hhld_uid", "Ref_Person", "DVAge", "DVHqual", "Sex",
      "DVHHSize_Nbr", "DVHHTenure", "FinalWgt", "Total_Household_AllInc",
      "Total_Household_RegInc", "DVTot_HOU_Exp", "hes_add_ta_code",
      "hes_add_region_code", "hes_add_meshblock_code"
    )
    missing <- setdiff(required, names(df))
    if (length(missing)) stop("Clean Read HES variables missing: ", paste(missing, collapse = ", "))

    out <- df %>%
      mutate(
        wave = as.character(wave),
        snz_uid = if ("snz_uid" %in% names(df)) as.character(snz_uid) else NA_character_,
        ref_person = as.character(Ref_Person) == "1",
        ref_age = as.numeric(DVAge),
        ref_education = as.character(DVHqual),
        ref_sex = as.character(Sex),
        hh_size = as.numeric(DVHHSize_Nbr),
        tenure_code = as.character(DVHHTenure),
        survey_weight = as.numeric(FinalWgt),
        total_income = as.numeric(Total_Household_AllInc),
        regular_income = as.numeric(Total_Household_RegInc),
        total_expenditure = as.numeric(DVTot_HOU_Exp),
        ta_code = as.character(hes_add_ta_code),
        hes_region_code = as.character(hes_add_region_code),
        meshblock_code = as.character(hes_add_meshblock_code)
      )
  }

  out
}

recode_education <- function(x) {
  x <- as.character(x)
  dplyr::case_when(
    x == "9" ~ "1",
    x %in% c("10", "11") ~ "2",
    x %in% as.character(0:8) ~ x,
    TRUE ~ NA_character_
  )
}

recode_tenure <- function(x) {
  n <- suppressWarnings(as.integer(as.character(x)))
  dplyr::case_when(
    n %in% c(10:12, 30:32) ~ "Owned/Trust",
    n %in% 20:22 ~ "Rented",
    TRUE ~ NA_character_
  )
}

recode_female <- function(x) {
  z <- trimws(tolower(as.character(x)))
  dplyr::case_when(
    z %in% c("2", "female", "f") ~ 1L,
    z %in% c("1", "male", "m") ~ 0L,
    TRUE ~ NA_integer_
  )
}
