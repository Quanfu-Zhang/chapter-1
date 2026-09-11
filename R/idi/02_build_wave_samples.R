# ==============================================================================
# IDI-only sample construction
# ------------------------------------------------------------------------------
# Reconstructed from the accepted manuscript and the surviving working scripts.
# This file implements the residence-classification semantics described in Sect.
# 3.1 of the paper. It operates on secure in-memory extracts and never contains
# microdata itself.
#
# Required inputs
#   hes_wave:          one HES wave, already canonicalised with
#                      R/01_hes_schema_adapter.R
#   admin_addresses:   long address history with at least
#                      snz_uid, address_date, region_code, source; and preferably
#                      meshblock_code for the missing-region bridge
#   mmi_lookup:        meshblock_code, mmi_intensity
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

source(file.path("R", "00_config.R"))
source(file.path("R", "01_hes_schema_adapter.R"))

standardise_admin_addresses <- function(x) {
  required <- c("snz_uid", "address_date", "region_code", "source")
  missing <- setdiff(required, names(x))
  if (length(missing)) stop("Address fields missing: ", paste(missing, collapse = ", "))
  if (!"meshblock_code" %in% names(x)) x$meshblock_code <- NA_character_

  x %>%
    transmute(
      snz_uid = as.character(snz_uid),
      address_date = as.Date(address_date),
      region_code = suppressWarnings(as.integer(as.character(region_code))),
      meshblock_code = as.character(meshblock_code),
      source = toupper(as.character(source))
    ) %>%
    filter(!is.na(snz_uid), !is.na(address_date))
}

resolve_prequake_address <- function(admin_addresses) {
  a <- standardise_admin_addresses(admin_addresses)

  in_window <- a %>%
    filter(address_date >= ADDRESS_WINDOW_START, address_date <= EARTHQUAKE_DATE)

  latest_window <- in_window %>%
    arrange(snz_uid, desc(address_date), source) %>%
    group_by(snz_uid) %>%
    slice(1L) %>%
    ungroup() %>%
    mutate(address_rule = "reference_window")

  ids_with_window <- unique(latest_window$snz_uid)

  # The accepted manuscript describes the long IR lookback as a recovery rule
  # for otherwise unresolved cases, rather than a source-priority rule.
  ir_lookback <- a %>%
    filter(
      source == "IR",
      address_date >= IR_LOOKBACK_START,
      address_date < ADDRESS_WINDOW_START,
      !snz_uid %in% ids_with_window
    ) %>%
    arrange(snz_uid, desc(address_date)) %>%
    group_by(snz_uid) %>%
    slice(1L) %>%
    ungroup() %>%
    mutate(address_rule = "ir_lookback")

  selected <- bind_rows(latest_window, ir_lookback)

  pre_nonmissing <- a %>%
    filter(address_date <= EARTHQUAKE_DATE, !is.na(region_code), !is.na(meshblock_code)) %>%
    arrange(snz_uid, desc(address_date)) %>%
    group_by(snz_uid) %>%
    slice(1L) %>%
    ungroup() %>%
    select(
      snz_uid,
      prior_region = region_code,
      prior_meshblock = meshblock_code,
      prior_date = address_date
    )

  first_post <- a %>%
    filter(address_date > EARTHQUAKE_DATE, !is.na(meshblock_code)) %>%
    arrange(snz_uid, address_date) %>%
    group_by(snz_uid) %>%
    slice(1L) %>%
    ungroup() %>%
    select(
      snz_uid,
      post_region = region_code,
      post_meshblock = meshblock_code,
      post_date = address_date
    )

  selected %>%
    left_join(pre_nonmissing, by = "snz_uid") %>%
    left_join(first_post, by = "snz_uid") %>%
    mutate(
      bridge_same_meshblock =
        is.na(region_code) &
        !is.na(prior_meshblock) & !is.na(post_meshblock) &
        prior_meshblock == post_meshblock &
        (prior_region == CANTERBURY_REGION_CODE | post_region == CANTERBURY_REGION_CODE),
      region_code = if_else(bridge_same_meshblock, CANTERBURY_REGION_CODE, region_code),
      meshblock_code = if_else(
        bridge_same_meshblock & is.na(meshblock_code), prior_meshblock, meshblock_code
      ),
      address_rule = if_else(
        bridge_same_meshblock,
        paste0(address_rule, "+meshblock_bridge"),
        address_rule
      )
    ) %>%
    select(
      snz_uid, address_date, region_code, meshblock_code, source,
      address_rule, bridge_same_meshblock
    )
}

ever_canterbury_ids <- function(admin_addresses) {
  standardise_admin_addresses(admin_addresses) %>%
    filter(region_code == CANTERBURY_REGION_CODE) %>%
    distinct(snz_uid) %>%
    pull(snz_uid)
}

# The manuscript describes the comparison pool as households that consistently
# resided in the North Island over the study period. The surviving working code
# also provides evidence for a less restrictive historical screen. Both rules are
# retained explicitly so the methodological distinction remains transparent.
north_island_history_status <- function(admin_addresses) {
  standardise_admin_addresses(admin_addresses) %>%
    filter(
      address_date >= HES_SAMPLE_START,
      address_date <= HES_SAMPLE_END,
      !is.na(region_code)
    ) %>%
    group_by(snz_uid) %>%
    summarise(
      all_known_sample_period_addresses_north = all(region_code %in% NORTH_ISLAND_REGION_CODES),
      .groups = "drop"
    )
}

classify_residence_groups <- function(
    hes_wave,
    admin_addresses,
    control_rule = c("manuscript_strict", "hes_north_never_canterbury")) {

  control_rule <- match.arg(control_rule)

  ref <- hes_wave %>%
    filter(ref_person) %>%
    distinct(snz_hes_hhld_uid, .keep_all = TRUE) %>%
    mutate(
      snz_uid = as.character(snz_uid),
      hes_region_num = suppressWarnings(as.integer(hes_region_code))
    )

  if (anyDuplicated(ref$snz_hes_hhld_uid)) {
    stop("More than one reference-person record remains for at least one household.")
  }

  selected <- resolve_prequake_address(admin_addresses) %>%
    rename(
      prequake_address_date = address_date,
      prequake_region = region_code,
      prequake_meshblock = meshblock_code,
      prequake_source = source,
      prequake_address_rule = address_rule
    )

  ever_chc <- ever_canterbury_ids(admin_addresses)
  ni_history <- north_island_history_status(admin_addresses)

  ref %>%
    left_join(selected, by = "snz_uid") %>%
    left_join(ni_history, by = "snz_uid") %>%
    mutate(
      group = case_when(
        prequake_region == CANTERBURY_REGION_CODE & hes_region_num == CANTERBURY_REGION_CODE ~ "Group 1",
        prequake_region == CANTERBURY_REGION_CODE & hes_region_num != CANTERBURY_REGION_CODE ~ "Group 2",
        !is.na(prequake_region) & prequake_region != CANTERBURY_REGION_CODE & hes_region_num == CANTERBURY_REGION_CODE ~ "Group 3",
        !is.na(prequake_region) & prequake_region != CANTERBURY_REGION_CODE & hes_region_num != CANTERBURY_REGION_CODE ~ "Group 4",
        TRUE ~ "Missing address"
      ),
      prequake_exit_evidence =
        group == "Group 2" &
        !is.na(interview_date) &
        interview_date < EARTHQUAKE_DATE &
        !is.na(prequake_address_date) &
        interview_date > prequake_address_date,
      ever_canterbury_admin = snz_uid %in% ever_chc,
      treated_full = group %in% c("Group 1", "Group 2") & !prequake_exit_evidence,
      control_hes_north_never_canterbury =
        group == "Group 4" &
        hes_region_num %in% NORTH_ISLAND_REGION_CODES &
        !ever_canterbury_admin,
      control_manuscript_strict =
        control_hes_north_never_canterbury &
        prequake_region %in% NORTH_ISLAND_REGION_CODES &
        all_known_sample_period_addresses_north %in% TRUE,
      eligible_control = if_else(
        control_rule == "manuscript_strict",
        control_manuscript_strict,
        control_hes_north_never_canterbury
      ),
      control_rule = control_rule
    )
}

attach_mmi <- function(classified, mmi_lookup) {
  required <- c("meshblock_code", "mmi_intensity")
  missing <- setdiff(required, names(mmi_lookup))
  if (length(missing)) stop("MMI lookup fields missing: ", paste(missing, collapse = ", "))

  lookup <- mmi_lookup %>%
    transmute(
      prequake_meshblock = as.character(meshblock_code),
      mmi_intensity = suppressWarnings(as.numeric(mmi_intensity))
    ) %>%
    distinct(prequake_meshblock, .keep_all = TRUE)

  classified %>%
    left_join(lookup, by = "prequake_meshblock") %>%
    mutate(
      mmi_group = case_when(
        treated_full & !is.na(mmi_intensity) & mmi_intensity >= LOW_MMI_MIN & mmi_intensity < HIGH_MMI_MIN ~ "Low",
        treated_full & !is.na(mmi_intensity) & mmi_intensity >= HIGH_MMI_MIN ~ "High",
        TRUE ~ NA_character_
      ),
      treated_analysis = treated_full & !is.na(mmi_group)
    )
}

build_wave_samples <- function(
    hes_wave,
    admin_addresses,
    mmi_lookup,
    write_outputs = FALSE,
    wave = unique(hes_wave$wave),
    control_rule = c("manuscript_strict", "hes_north_never_canterbury")) {

  stopifnot(length(wave) == 1L, wave %in% WAVES)
  control_rule <- match.arg(control_rule)

  classified <- classify_residence_groups(
    hes_wave,
    admin_addresses,
    control_rule = control_rule
  ) %>% attach_mmi(mmi_lookup)

  labels <- classified %>%
    select(
      snz_hes_hhld_uid, group, prequake_exit_evidence,
      prequake_address_date, prequake_region, prequake_meshblock,
      prequake_source, prequake_address_rule, bridge_same_meshblock,
      mmi_intensity, mmi_group, treated_full, treated_analysis,
      control_hes_north_never_canterbury, control_manuscript_strict,
      eligible_control, control_rule
    )

  enriched <- hes_wave %>% left_join(labels, by = "snz_hes_hhld_uid")
  treated_full <- enriched %>% filter(treated_full %in% TRUE)
  treated_analysis <- enriched %>% filter(treated_analysis %in% TRUE)
  control_pool <- enriched %>% filter(eligible_control %in% TRUE)

  if (write_outputs) {
    dir.create(TREATED_FULL_DIR, recursive = TRUE, showWarnings = FALSE)
    dir.create(TREATED_DIR, recursive = TRUE, showWarnings = FALSE)
    dir.create(CONTROL_POOL_DIR, recursive = TRUE, showWarnings = FALSE)
    write_csv(treated_full, file.path(TREATED_FULL_DIR, paste0(wave, ".csv")))
    write_csv(treated_analysis, file.path(TREATED_DIR, paste0(wave, ".csv")))
    write_csv(control_pool, file.path(CONTROL_POOL_DIR, paste0("CGP", wave, ".csv")))
  }

  list(
    classified_reference_persons = classified,
    treated_full = treated_full,
    treated_analysis = treated_analysis,
    control_pool = control_pool
  )
}
