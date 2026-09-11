# ==============================================================================
# Publication table and figure builders
# ------------------------------------------------------------------------------
# These functions convert fitted fixest objects into release-ready tables and the
# percentage-change plots used for the detailed expenditure results.
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(tidyr)
  library(readr)
  library(ggplot2)
})

source(file.path("R", "05_expenditure_models.R"))

fixest_tidy <- function(model) {
  ct <- as.data.frame(coeftable(model))
  tibble(
    term = rownames(ct),
    estimate = ct[[1]],
    std_error = ct[[2]],
    statistic = ct[[3]],
    p_value = ct[[4]]
  )
}

interaction_rows <- function(model) {
  fixest_tidy(model) %>%
    filter(grepl("mmi_group::(Low|High):post", term)) %>%
    mutate(
      intensity = case_when(
        grepl("mmi_group::Low:post", term) ~ "Low intensity",
        grepl("mmi_group::High:post", term) ~ "High intensity",
        TRUE ~ NA_character_
      )
    )
}

expense_label <- function(x) {
  x <- sub("^logabs_expense_", "", x)
  labels <- c(
    "DOMESTIC.FUEL...POWER" = "Domestic fuel and power",
    "HOUSING.COSTS" = "Housing costs",
    "RECEIPTS...REFUNDS" = "Receipts and refunds",
    "GENERAL.INSURANCE" = "General insurance",
    "MISCELLANEOUS.PAYMENTS" = "Miscellaneous payments",
    "MORTGAGES...LOANS" = "Mortgages and loans",
    "OTHER.PROPERTY" = "Other property",
    "TRANSPORTATION" = "Transportation",
    "CONTRIBUTION.SCHEMES" = "Retirement savings and contribution schemes",
    "MEDICAL...HEALTH" = "Medical and health",
    "DIARY" = "Diary-recorded purchases",
    "TRAVEL" = "Travel",
    "TELECOMMUNICATIONS" = "Telecommunications",
    "FEES.AND.SUBS" = "Fees and subscriptions",
    "ED..REC..SPORT...CULTURE" = "Education, recreation, sport and culture",
    "HOUSEHOLD.OPERATIONS" = "Household operations",
    "HOUSEHOLD.MAINTENANCE" = "Household maintenance",
    "CREDIT.DEBIT.ACCOUNTS" = "Credit and debit accounts"
  )
  unname(ifelse(x %in% names(labels), labels[x], x))
}

collect_expenditure_interactions <- function(models, sample = "Full sample") {
  imap_dfr(models, function(model, outcome) {
    interaction_rows(model) %>%
      mutate(
        outcome = outcome,
        expenditure_category = expense_label(outcome),
        sample = sample,
        percentage_change = log_coefficient_to_percent(estimate),
        significant_05 = p_value < 0.05
      )
  })
}

significance_stars <- function(p) {
  case_when(
    p < 0.001 ~ "***",
    p < 0.01 ~ "**",
    p < 0.05 ~ "*",
    TRUE ~ ""
  )
}

build_figure2_data <- function(models) {
  dat <- collect_expenditure_interactions(models)
  keep <- dat %>%
    group_by(expenditure_category) %>%
    summarise(any_sig = any(significant_05), .groups = "drop") %>%
    filter(any_sig) %>%
    pull(expenditure_category)

  dat %>%
    filter(expenditure_category %in% keep) %>%
    mutate(
      stars = significance_stars(p_value),
      label = paste0(sprintf("%.2f", percentage_change), stars)
    )
}

plot_figure2 <- function(models, file = file.path(FIGURE_DIR, "figure2_expenditure_by_intensity.pdf")) {
  dat <- build_figure2_data(models)
  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)

  p <- ggplot(
    dat,
    aes(x = percentage_change, y = reorder(expenditure_category, percentage_change), fill = intensity)
  ) +
    geom_col(position = position_dodge(width = 0.8), width = 0.72) +
    geom_text(
      aes(label = label),
      position = position_dodge(width = 0.8),
      hjust = -0.08,
      size = 3
    ) +
    labs(
      x = "Percentage change",
      y = NULL,
      fill = NULL
    ) +
    theme_minimal(base_size = 11) +
    theme(legend.position = "bottom")

  ggsave(file, p, width = 8.5, height = 5.4)
  p
}

build_figure3_data <- function(heterogeneity_models) {
  bind_rows(
    collect_expenditure_interactions(heterogeneity_models$above_median, "Above median income"),
    collect_expenditure_interactions(heterogeneity_models$at_or_below_median, "At/below median income")
  ) %>%
    group_by(sample, expenditure_category) %>%
    filter(any(significant_05)) %>%
    ungroup() %>%
    mutate(
      stars = significance_stars(p_value),
      label = paste0(sprintf("%.2f", percentage_change), stars)
    )
}

plot_figure3 <- function(
    heterogeneity_models,
    file = file.path(FIGURE_DIR, "figure3_expenditure_by_income_group.pdf")) {

  dat <- build_figure3_data(heterogeneity_models)
  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)

  p <- ggplot(
    dat,
    aes(x = percentage_change, y = expenditure_category, fill = intensity)
  ) +
    geom_col(position = position_dodge(width = 0.8), width = 0.72) +
    geom_text(
      aes(label = label),
      position = position_dodge(width = 0.8),
      hjust = -0.08,
      size = 2.8
    ) +
    facet_wrap(~ sample, scales = "free_y") +
    labs(x = "Percentage change", y = NULL, fill = NULL) +
    theme_minimal(base_size = 10) +
    theme(legend.position = "bottom")

  ggsave(file, p, width = 10, height = 6.5)
  p
}

write_model_table <- function(models, file) {
  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
  dat <- imap_dfr(models, function(m, name) fixest_tidy(m) %>% mutate(model = name, .before = 1L))
  write_csv(dat, file)
  invisible(dat)
}
