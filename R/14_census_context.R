# ==============================================================================
# Appendix F: regional median household income context, 2006-2013
# ------------------------------------------------------------------------------
# These public aggregate values reproduce Table F1 of the accepted manuscript.
# Source cited in the paper: Stats NZ (2014). Values are nominal NZD.
# ==============================================================================

suppressPackageStartupMessages(library(tibble))

census_income <- tribble(
  ~region, ~income_2006, ~income_2013,
  "Auckland", 63400, 76500,
  "Canterbury", 47900, 65000,
  "Wellington", 59700, 74300,
  "Waikato", 49400, 59600,
  "Bay of Plenty", 45400, 54600,
  "Hawke's Bay", 44200, 53200,
  "Manawatu-Wanganui", 41200, 50000,
  "Northland", 40200, 46900,
  "Southland", 44200, 57400,
  "Otago", 44400, 56400,
  "West Coast", 37800, 55000,
  "Marlborough", 45500, 55200,
  "Nelson", 43900, 54300,
  "Tasman", 43000, 53500,
  "Gisborne", 41000, 50500,
  "Taranaki", 44700, 58400
)

build_table_f1 <- function() {
  census_income |>
    transform(
      annual_growth_pct = 100 * ((income_2013 / income_2006)^(1 / 7) - 1),
      absolute_increase = income_2013 - income_2006
    )
}
