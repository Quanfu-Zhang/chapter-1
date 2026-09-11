# ==============================================================================
# HES schema adapter
# ------------------------------------------------------------------------------
# The HES variables used in this study change naming convention from 2015/16.
# This adapter is the ONLY place where those source names should appear.
# Downstream scripts operate on canonical names and therefore use one analytical
# pipeline for all survey waves.
#
# The adapter is deliberately idempotent: secure intermediate files created by
# the sample-construction stage are already canonical, and can be passed through
# this function again without requiring the original HES source names.
# ==============================================================================

suppressPackageStartupMessages(library(dplyr))

first_existing <- function(df, candidates, default = NA) {
  hit <- candidates[candidates %in% names(df)]
  if (!length(hit)) return(rep(default, nrow(df)))
  df[[hit[[1L]]]]
}

canonical_columns <- c(
  "snz_hes_hhld_uid", "ref_person", "ref_age", "ref_education", "ref_sex",
  "hh_size", "tenure_code", "survey_weight", "total_income", "regular_income",
  "total_expenditure", "ta_code", "hes_region_code", "meshblock_code"
)

canonicalise_hes <- function(df, wave) {
  stopifnot(length(wave) == 1L, wave %in% WAVES)

  # Secure intermediate files produced by R/idi/02_build_wave_samples.R are
  # already canonical. Re-standardise types, retain all provenance columns, and
  # return them unchanged otherwise.
  if (all(canonical_columns %in% names(df))) {
    if (!"wave" %in% names(df)) df$wave <- wave
    if (!"snz_uid" %in% names(df)) df$snz_uid <- NA_character_
    if (!"household_comp" %in% names(df)) df$household_comp <- NA_character_
    if (!"interview_date" %in% names(df)) df$interview_date <- as.Date(NA)

    return(df %>%
      mutate(
        wave = as.character(wave),
        snz_uid = as.character(snz_uid),
        snz_hes_hhld_uid = as.character(snz_hes_hhld_uid),
        ref_person = as.logical(ref_person),
        ref_age = suppressWarnings(as.numeric(ref_age)),
        ref_education = as.character(ref_education),
        ref_sex = as.character(ref_sex),
        hh_size = suppressWarnings(as.numeric(hh_size)),
        tenure_code = as.character(tenure_code),
        household_comp = as.character(household_comp),
        survey_weight = suppressWarnings(as.numeric(survey_weight)),
        total_income = suppressWarnings(as.numeric(total_income)),
        regular_income = suppressWarnings(as.numeric(regular_income)),
        total_expenditure = suppressWarnings(as.numeric(total_expenditure)),
        ta_code = as.character(ta_code),
        hes_region_code = as.character(hes_region_code),
        meshblock_code = as.character(meshblock_code),
        interview_date = as.Date(interview_date)
      ))
  }

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
    if (length(missing)) {
      stop("Legacy HES variables missing: ", paste(missing, collapse = ", "))
    }

    out <- df %>%
      mutate(
        wave = as.character(wave),
        snz_uid = as.character(first_existing(df, c("snz_uid"), NA_character_)),
        snz_hes_hhld_uid = as.character(snz_hes_hhld_uid),
        ref_person = as.character(hes_inc_reference_person_code) == "Yes",
        ref_age = suppressWarnings(as.numeric(hes_inc_age_nbr)),
        ref_education = as.character(hes_inc_highest_qual_code),
        ref_sex = as.character(hes_inc_sex_snz_code),
        hh_size = suppressWarnings(as.numeric(hes_hhd_household_size_nbr)),
        tenure_code = as.character(hes_hhd_tenure_code),
        household_comp = as.character(first_existing(
          df, c("hes_hhd_hhold_comp_code"), NA_character_
        )),
        survey_weight = suppressWarnings(as.numeric(hes_hhd_weight_non_resp_nbr)),
        total_income = suppressWarnings(as.numeric(hes_hhd_total_hhold_income_amt)),
        regular_income = suppressWarnings(as.numeric(hes_hhd_total_hhold_reginc_amt)),
        total_expenditure = suppressWarnings(as.numeric(hes_hhd_total_hhold_expend_amt)),
        ta_code = as.character(hes_add_ta_code),
        hes_region_code = as.character(hes_add_region_code),
        meshblock_code = as.character(hes_add_meshblock_code),
        interview_date = as.Date(first_existing(
          df, c("hes_add_interview_date"), NA_character_
        ))
      )
  } else {
    required <- c(
      "snz_hes_hhld_uid", "Ref_Person", "DVAge", "DVHqual", "Sex",
      "DVHHSize_Nbr", "DVHHTenure", "FinalWgt", "Total_Household_AllInc",
      "Total_Household_RegInc", "DVTot_HOU_Exp", "hes_add_ta_code",
      "hes_add_region_code", "hes_add_meshblock_code"
    )
    missing <- setdiff(required, names(df))
    if (length(missing)) {
      stop("Clean Read HES variables missing: ", paste(missing, collapse = ", "))
    }

    out <- df %>%
      mutate(
        wave = as.character(wave),
        snz_uid = as.character(first_existing(df, c("snz_uid"), NA_character_)),
        snz_hes_hhld_uid = as.character(snz_hes_hhld_uid),
        ref_person = as.character(Ref_Person) == "1",
        ref_age = suppressWarnings(as.numeric(DVAge)),
        ref_education = as.character(DVHqual),
        ref_sex = as.character(Sex),
        hh_size = suppressWarnings(as.numeric(DVHHSize_Nbr)),
        tenure_code = as.character(DVHHTenure),
        household_comp = as.character(first_existing(df, c("DVHHComp2"), NA_character_)),
        survey_weight = suppressWarnings(as.numeric(FinalWgt)),
        total_income = suppressWarnings(as.numeric(Total_Household_AllInc)),
        regular_income = suppressWarnings(as.numeric(Total_Household_RegInc)),
        total_expenditure = suppressWarnings(as.numeric(DVTot_HOU_Exp)),
        ta_code = as.character(hes_add_ta_code),
        hes_region_code = as.character(hes_add_region_code),
        meshblock_code = as.character(hes_add_meshblock_code),
        interview_date = as.Date(first_existing(
          df, c("hes_add_interview_date", "Interview_Date"), NA_character_
        ))
      )
  }

  out
}

recode_education <- function(x) {
  x <- as.character(x)
  case_when(
    x == "9" ~ "1",
    x %in% c("10", "11") ~ "2",
    x %in% as.character(0:8) ~ x,
    TRUE ~ NA_character_
  )
}

# The manuscript's supplementary "higher education" pseudo-outcome is kept as
# an explicit helper rather than embedded in model code. If the Data Lab metadata
# for a particular refresh uses a different qualification coding, alter this one
# function and document the change in docs/DATA_DICTIONARY.md.
recode_higher_education <- function(x) {
  z <- suppressWarnings(as.integer(recode_education(x)))
  as.integer(!is.na(z) & z >= 4L)
}

recode_tenure <- function(x) {
  n <- suppressWarnings(as.integer(as.character(x)))
  case_when(
    n %in% c(10:12, 30:32) ~ "Owned/Trust",
    n %in% 20:22 ~ "Rented",
    TRUE ~ NA_character_
  )
}

recode_female <- function(x) {
  z <- trimws(tolower(as.character(x)))
  case_when(
    z %in% c("2", "female", "f") ~ 1L,
    z %in% c("1", "male", "m") ~ 0L,
    TRUE ~ NA_integer_
  )
}

# Canonical broad household-composition labels used in Appendix B and the
# ATT-IPW composition specification. The exact HES labels/codes can differ by
# schema; this function preserves already-readable labels and groups sparse or
# unknown values into an explicit residual category.
recode_household_comp <- function(x) {
  z <- trimws(tolower(as.character(x)))
  case_when(
    grepl("one[- ]?family|^1$", z) ~ "One-family household",
    grepl("two[- ]?family|^2$", z) ~ "Two-family household",
    grepl("three|3[+]|three-or-more", z) ~ "Three-or-more-family household",
    grepl("one[- ]?person|single person", z) ~ "One-person household",
    grepl("non[- ]?family|other multi", z) ~ "Other multi-person household",
    grepl("unident|unknown|not ident", z) ~ "Unidentifiable household",
    is.na(z) | z == "" ~ "Other or sparsely observed composition",
    TRUE ~ as.character(x)
  )
}

# Convert expenditure-category names produced by pivot_wider() into stable R
# identifiers while retaining the `expense_` prefix used by the working scripts.
normalise_expense_names <- function(df) {
  old <- grep("^expense_", names(df), value = TRUE)
  if (!length(old)) return(df)
  new <- paste0("expense_", make.names(sub("^expense_", "", old)))
  names(df)[match(old, names(df))] <- new
  df
}
