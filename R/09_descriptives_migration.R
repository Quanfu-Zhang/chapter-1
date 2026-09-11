# ==============================================================================
# Descriptive statistics (Appendix D) and stay/relocation analysis (Table 4)
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(purrr)
  library(fixest)
})

source(file.path("R", "00_config.R"))
source(file.path("R", "01_hes_schema_adapter.R"))
source(file.path("R", "04_main_did.R"))

load_full_treated_wave <- function(wave) {
  path <- file.path(TREATED_FULL_DIR, paste0(wave, ".csv"))
  if (!file.exists(path)) stop("Full treated file not found: ", path)
  read_csv(path, show_col_types = FALSE) %>%
    canonicalise_hes(wave) %>%
    normalise_expense_names() %>%
    filter(ref_person) %>%
    distinct(snz_hes_hhld_uid, .keep_all = TRUE)
}

load_full_treated_data <- function(waves = WAVES) {
  map_dfr(waves, load_full_treated_wave) %>%
    mutate(
      wave = factor(as.character(wave), levels = WAVES),
      post = as.integer(as.character(wave) %in% POST_WAVES),
      female = recode_female(ref_sex),
      owned_trust = as.integer(recode_tenure(tenure_code) == "Owned/Trust"),
      mmi_intensity = suppressWarnings(as.numeric(mmi_intensity)),
      mmi_group = case_when(
        mmi_intensity >= LOW_MMI_MIN & mmi_intensity < HIGH_MMI_MIN ~ "Low",
        mmi_intensity >= HIGH_MMI_MIN ~ "High",
        TRUE ~ NA_character_
      ),
      relocation = as.integer(group == "Group 2"),
      stay = as.integer(group == "Group 1")
    )
}

find_expense_col <- function(df, regex) {
  hits <- grep(regex, names(df), value = TRUE, ignore.case = TRUE)
  if (!length(hits)) return(NA_character_)
  hits[[1L]]
}

add_named_expenditure_outcomes <- function(df) {
  housing <- find_expense_col(df, "^expense_.*HOUSING.*COST")
  mortgages <- find_expense_col(df, "^expense_.*MORTGAGE.*LOAN")
  other_property <- find_expense_col(df, "^expense_.*OTHER.*PROPERTY")

  df$housing_cost <- if (is.na(housing)) NA_real_ else suppressWarnings(as.numeric(df[[housing]]))
  df$mortgages_loans <- if (is.na(mortgages)) NA_real_ else suppressWarnings(as.numeric(df[[mortgages]]))
  df$other_property <- if (is.na(other_property)) NA_real_ else suppressWarnings(as.numeric(df[[other_property]]))
  df
}

summarise_descriptive_group <- function(df) {
  df <- add_named_expenditure_outcomes(df)
  tibble(
    households = n_distinct(df$snz_hes_hhld_uid),
    age_mean = mean(df$ref_age, na.rm = TRUE),
    hh_size_mean = mean(df$hh_size, na.rm = TRUE),
    female_pct = 100 * mean(df$female, na.rm = TRUE),
    owned_trust_pct = 100 * mean(df$owned_trust, na.rm = TRUE),
    total_income_median = median(df$total_income, na.rm = TRUE),
    total_income_sd = sd(df$total_income, na.rm = TRUE),
    regular_income_median = median(df$regular_income, na.rm = TRUE),
    regular_income_sd = sd(df$regular_income, na.rm = TRUE),
    total_expenditure_median = median(df$total_expenditure, na.rm = TRUE),
    total_expenditure_sd = sd(df$total_expenditure, na.rm = TRUE),
    housing_cost_median = median(df$housing_cost, na.rm = TRUE),
    housing_cost_sd = sd(df$housing_cost, na.rm = TRUE),
    mortgages_loans_mean = mean(df$mortgages_loans, na.rm = TRUE),
    mortgages_loans_sd = sd(df$mortgages_loans, na.rm = TRUE)
  )
}

build_table_d1 <- function() {
  treated <- load_full_treated_data()
  controls <- load_matched_analysis_data() %>%
    filter(treated == 0L) %>%
    mutate(owned_trust = as.integer(hh_tenure == "Owned/Trust"))

  map_dfr(WAVES, function(w) {
    t <- treated %>% filter(as.character(wave) == w)
    c <- controls %>% filter(as.character(wave) == w)
    bind_rows(
      summarise_descriptive_group(t) %>% mutate(group = "Treated"),
      summarise_descriptive_group(filter(t, mmi_group == "Low")) %>% mutate(group = "-Low"),
      summarise_descriptive_group(filter(t, mmi_group == "High")) %>% mutate(group = "-High"),
      summarise_descriptive_group(c) %>% mutate(group = "Control")
    ) %>% mutate(wave = WAVE_LABELS[[w]], .before = 1L)
  })
}

build_table_d2 <- function() {
  treated <- load_full_treated_data()
  map_dfr(WAVES, function(w) {
    d <- treated %>% filter(as.character(wave) == w)
    bind_rows(
      summarise_descriptive_group(filter(d, relocation == 1L)) %>% mutate(group = "Relocation"),
      summarise_descriptive_group(filter(d, stay == 1L)) %>% mutate(group = "Stay")
    ) %>% mutate(wave = WAVE_LABELS[[w]], .before = 1L)
  })
}

fit_relocation_models <- function() {
  dat <- load_full_treated_data(POST_WAVES) %>%
    add_named_expenditure_outcomes() %>%
    filter(group %in% c("Group 1", "Group 2"), !is.na(female), !is.na(ref_age), !is.na(hh_size))

  outcomes <- c(
    "total_income", "regular_income", "total_expenditure",
    "housing_cost", "other_property", "mortgages_loans"
  )

  set_names(outcomes) %>% map(function(outcome) {
    fml <- as.formula(paste0(outcome, " ~ relocation + ref_age + female + hh_size"))
    feols(fml, data = dat, vcov = "iid")
  })
}
