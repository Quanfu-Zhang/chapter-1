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
#
# The address input should contain records from IR, HLFS, ACC, MSD and the
# cross-agency address-notification dataset. IR records should already be limited
# to valid addresses if an address-status field is available.
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

# Select the latest address in the stated 2010-01-01 to 2011-02-22 reference
# window across all linked sources. The extended 2000-2009 IR lookback is used
# only when no reference-window address is available from any source.
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

  # Manuscript bridge: when the selected pre-earthquake record has a missing
  # region, use surrounding address evidence only if the most recent non-missing
  # pre-earthquake address and the first post-earthquake address point to the same
  # Canterbury meshblock. The bridge is applied only when meshblock identifiers
  # exist; otherwise the record remains unresolved and is visible in diagnostics.
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
      region_code = if_else(
        bridge_same_meshblock,
        CANTERBURY_REGION_CODE,
        region_code
      ),
      meshblock_code = if_else(
        bridge_same_meshblock & is.na(meshblock_code),
        prior_meshblock,
        meshblock_code
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

# Control households are required to have no Canterbury residence recorded in
# the linked administrative address histories. HES survey residence is checked
# separately below.
ever_canterbury_ids <- function(admin_addresses) {
  standardise_admin_addresses(admin_addresses) %>%
    filter(region_code == CANTERBURY_REGION_CODE) %>%
    distinct(snz_uid) %>%
    pull(snz_uid)
}

classify_residence_groups <- function(hes_wave, admin_addresses) {
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

  classified <- ref %>%
    left_join(selected, by = "snz_uid") %>%
    mutate(
      group = case_when(
        prequake_region == CANTERBURY_REGION_CODE & hes_region_num == CANTERBURY_REGION_CODE ~ "Group 1",
        prequake_region == CANTERBURY_REGION_CODE & hes_region_num != CANTERBURY_REGION_CODE ~ "Group 2",
        !is.na(prequake_region) & prequake_region != CANTERBURY_REGION_CODE & hes_region_num == CANTERBURY_REGION_CODE ~ "Group 3",
        !is.na(prequake_region) & prequake_region != CANTERBURY_REGION_CODE & hes_region_num != CANTERBURY_REGION_CODE ~ "Group 4",
        TRUE ~ "Missing address"
      ),
      # The manuscript excludes a small set of Group 2 cases with evidence that
      # the HES observation already recorded the household outside Canterbury
      # after its last Canterbury administrative record but before the earthquake.
      prequake_exit_evidence =
        group == "Group 2" &
        !is.na(interview_date) &
        interview_date < EARTHQUAKE_DATE &
        !is.na(prequake_address_date) &
        interview_date > prequake_address_date,
      ever_canterbury_admin = snz_uid %in% ever_chc,
      treated_full = group %in% c("Group 1", "Group 2") & !prequake_exit_evidence,
      eligible_control =
        group == "Group 4" &
        hes_region_num %in% NORTH_ISLAND_REGION_CODES &
        !ever_canterbury_admin &
        hes_region_num != CANTERBURY_REGION_CODE
    )

  classified
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
    wave = unique(hes_wave$wave)) {

  stopifnot(length(wave) == 1L, wave %in% WAVES)

  classified <- classify_residence_groups(hes_wave, admin_addresses) %>%
    attach_mmi(mmi_lookup)

  labels <- classified %>%
    select(
      snz_hes_hhld_uid, group, prequake_exit_evidence,
      prequake_address_date, prequake_region, prequake_meshblock,
      prequake_source, prequake_address_rule, bridge_same_meshblock,
      mmi_intensity, mmi_group, treated_full, treated_analysis,
      eligible_control
    )

  enriched <- hes_wave %>%
    left_join(labels, by = "snz_hes_hhld_uid")

  treated_full <- enriched %>% filter(treated_full %in% TRUE)
  treated_analysis <- enriched %>% filter(treated_analysis %in% TRUE)
  control_pool <- enriched %>% filter(eligible_control %in% TRUE)

  diagnostics <- classified %>%
    summarise(
      wave = wave,
      valid_reference_households = n(),
      group1 = sum(group == "Group 1", na.rm = TRUE),
      group2 = sum(group == "Group 2", na.rm = TRUE),
      group3 = sum(group == "Group 3", na.rm = TRUE),
      group4 = sum(group == "Group 4", na.rm = TRUE),
      missing_address = sum(group == "Missing address", na.rm = TRUE),
      prequake_exit_exclusions = sum(prequake_exit_evidence, na.rm = TRUE),
      treated_full = sum(treated_full, na.rm = TRUE),
      treated_with_low_or_high_mmi = sum(treated_analysis, na.rm = TRUE),
      eligible_control_pool = sum(eligible_control, na.rm = TRUE)
    )

  if (write_outputs) {
    dir.create(TREATED_DIR, recursive = TRUE, showWarnings = FALSE)
    dir.create(CONTROL_POOL_DIR, recursive = TRUE, showWarnings = FALSE)
    write_csv(treated_analysis, file.path(TREATED_DIR, paste0(wave, ".csv")))
    write_csv(control_pool, file.path(CONTROL_POOL_DIR, paste0("CGP", wave, ".csv")))
  }

  list(
    classified_reference_persons = classified,
    treated_full = treated_full,
    treated_analysis = treated_analysis,
    control_pool = control_pool,
    diagnostics = diagnostics
  )
}
