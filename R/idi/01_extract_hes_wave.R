# ==============================================================================
# Secure HES wave extraction
# ------------------------------------------------------------------------------
# Parameterised reconstruction of the HES extraction used in the surviving
# project scripts. This is the only secure module that knows the two underlying
# HES source layouts. It returns one canonical person/household analysis extract
# and does not write confidential data unless the caller explicitly does so.
#
# Required: an open DBI connection with read access to the IDI source databases.
# ==============================================================================

suppressPackageStartupMessages({
  library(DBI)
  library(dplyr)
  library(tidyr)
  library(glue)
})

source(file.path("R", "00_config.R"))
source(file.path("R", "01_hes_schema_adapter.R"))

sql_collect <- function(con, sql) DBI::dbGetQuery(con, as.character(sql))

extract_legacy_hes_wave <- function(con, wave) {
  stopifnot(wave %in% WAVES, legacy_wave(wave))

  address <- sql_collect(con, glue_sql(
    "SELECT
       snz_uid,
       snz_hes_hhld_uid,
       hes_add_hes_year_code,
       hes_add_interview_date,
       hes_add_ta_code,
       hes_add_region_code,
       hes_add_meshblock_code
     FROM [{`IDI_REFRESH`}].[hes_clean].[hes_address]
     WHERE hes_add_hes_year_code = {wave}",
    .con = con
  ))

  household <- sql_collect(con, glue_sql(
    "SELECT
       snz_hes_hhld_uid,
       hes_hhd_hes_year_code,
       hes_hhd_hhold_comp_code,
       hes_hhd_weight_non_resp_nbr,
       hes_hhd_household_size_nbr,
       hes_hhd_tenure_code,
       hes_hhd_total_hhold_reginc_amt,
       hes_hhd_total_hhold_income_amt,
       hes_hhd_total_hhold_expend_amt
     FROM [{`IDI_REFRESH`}].[hes_clean].[hes_household]
     WHERE hes_hhd_hes_year_code = {wave}",
    .con = con
  ))

  income <- sql_collect(con, glue_sql(
    "SELECT
       snz_uid,
       hes_inc_hes_year_code,
       hes_inc_age_nbr,
       hes_inc_highest_qual_code,
       hes_inc_reference_person_code,
       hes_inc_sex_snz_code,
       hes_inc_family_relationship_code,
       hes_inc_in_parent_role_code,
       hes_inc_with_partner_code,
       hes_inc_in_child_role_code
     FROM [{`IDI_REFRESH`}].[hes_clean].[hes_income]
     WHERE hes_inc_hes_year_code = {wave}",
    .con = con
  ))

  expenditure <- sql_collect(con, glue_sql(
    "SELECT
       snz_hes_hhld_uid,
       hes_exp_coding_topic_group_text AS expense_code,
       SUM(hes_exp_amount_amt) AS total_amount
     FROM [{`IDI_REFRESH`}].[hes_clean].[hes_expend]
     WHERE hes_exp_hes_year_code = {wave}
     GROUP BY snz_hes_hhld_uid, hes_exp_coding_topic_group_text",
    .con = con
  ))

  expenditure_wide <- expenditure %>%
    mutate(expense_code = paste0("expense_", make.names(expense_code))) %>%
    pivot_wider(
      id_cols = snz_hes_hhld_uid,
      names_from = expense_code,
      values_from = total_amount,
      values_fill = 0,
      values_fn = sum
    )

  address %>%
    inner_join(household, by = "snz_hes_hhld_uid") %>%
    inner_join(income, by = "snz_uid") %>%
    left_join(expenditure_wide, by = "snz_hes_hhld_uid") %>%
    canonicalise_hes(wave) %>%
    normalise_expense_names()
}

extract_clean_read_hes_wave <- function(con, wave) {
  stopifnot(wave %in% WAVES, clean_read_wave(wave))

  # The surviving post-2014/15 scripts continue to obtain linked geography from
  # the standard HES address table, while household/income/expenditure fields are
  # read from IDI_Adhoc.clean_read_HES wave-specific tables.
  address <- sql_collect(con, glue_sql(
    "SELECT
       snz_uid,
       snz_hes_uid,
       snz_hes_hhld_uid,
       hes_add_hes_year_code,
       hes_add_interview_date,
       hes_add_ta_code,
       hes_add_region_code,
       hes_add_meshblock_code
     FROM [{`IDI_REFRESH`}].[hes_clean].[hes_address]
     WHERE hes_add_hes_year_code = {wave}",
    .con = con
  ))

  clean_read_prefix <- gsub("^\\[|\\]$", "", CLEAN_READ_HES_SCHEMA)

  household_table <- paste0(CLEAN_READ_HES_SCHEMA, ".[hes_household_", wave, "]")
  income_table <- paste0(CLEAN_READ_HES_SCHEMA, ".[hes_income_", wave, "]")
  expenditure_table <- paste0(CLEAN_READ_HES_SCHEMA, ".[hes_expenditure_", wave, "]")

  household <- sql_collect(con, glue_sql(
    "SELECT
       snz_hes_hhld_uid,
       HES_Year,
       DVHHComp2,
       FinalWgt,
       DVHHSize_Nbr,
       DVHHTenure,
       Total_Household_RegInc,
       Total_Household_AllInc,
       DVTot_HOU_Exp
     FROM {DBI::SQL(household_table)}
     WHERE HES_Year = {wave}",
    .con = con
  ))

  income <- sql_collect(con, glue_sql(
    "SELECT
       snz_hes_uid,
       HES_Year,
       DVAge,
       DVHqual,
       Ref_Person,
       Sex,
       DVFamRel,
       DVFam_ParentRole,
       DVFam_WithPartner,
       DVFam_ChildRole
     FROM {DBI::SQL(income_table)}
     WHERE HES_Year = {wave}",
    .con = con
  ))

  expenditure <- sql_collect(con, glue_sql(
    "SELECT
       snz_hes_hhld_uid,
       Coding_Topic_Group AS expense_code,
       SUM(DVAmount) AS total_amount
     FROM {DBI::SQL(expenditure_table)}
     WHERE HES_Year = {wave}
     GROUP BY snz_hes_hhld_uid, Coding_Topic_Group",
    .con = con
  ))

  expenditure_wide <- expenditure %>%
    mutate(expense_code = paste0("expense_", make.names(expense_code))) %>%
    pivot_wider(
      id_cols = snz_hes_hhld_uid,
      names_from = expense_code,
      values_from = total_amount,
      values_fill = 0,
      values_fn = sum
    )

  address %>%
    inner_join(household, by = "snz_hes_hhld_uid") %>%
    inner_join(income, by = "snz_hes_uid") %>%
    left_join(expenditure_wide, by = "snz_hes_hhld_uid") %>%
    canonicalise_hes(wave) %>%
    normalise_expense_names()
}

extract_hes_wave <- function(con, wave) {
  stopifnot(wave %in% WAVES)
  if (legacy_wave(wave)) {
    extract_legacy_hes_wave(con, wave)
  } else {
    extract_clean_read_hes_wave(con, wave)
  }
}
