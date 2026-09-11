# ==============================================================================
# Chapter 1 methodological code: configuration
# ==============================================================================
# Analytical constants reported in the accepted paper. Local paths are kept
# generic so that no restricted data locations or environment-specific database
# details are committed to the public repository.

options(stringsAsFactors = FALSE)

WAVES <- c(
  "0607", "0708", "0809", "0910", "1011", "1112",
  "1213", "1314", "1415", "1516", "1617", "1718"
)

WAVE_LABELS <- c(
  "0607" = "2006/07", "0708" = "2007/08", "0809" = "2008/09",
  "0910" = "2009/10", "1011" = "2010/11", "1112" = "2011/12",
  "1213" = "2012/13", "1314" = "2013/14", "1415" = "2014/15",
  "1516" = "2015/16", "1617" = "2016/17", "1718" = "2017/18"
)

FULL_EXPENDITURE_WAVES <- c("0607", "0910", "1213", "1516")
POST_WAVES <- c("1112", "1213", "1314", "1415", "1516", "1617", "1718")
PRE_WAVES <- setdiff(WAVES, POST_WAVES)

CANTERBURY_REGION_CODE <- 13L
NORTH_ISLAND_REGION_CODES <- 1:9
LOW_MMI_MIN <- 4
HIGH_MMI_MIN <- 7

ADDRESS_WINDOW_START <- as.Date("2010-01-01")
EARTHQUAKE_DATE <- as.Date("2011-02-22")
IR_LOOKBACK_START <- as.Date("2000-01-01")
HES_SAMPLE_START <- as.Date("2006-07-01")
HES_SAMPLE_END <- as.Date("2018-06-30")

legacy_wave <- function(wave) as.integer(wave) <= 1415L
clean_read_wave <- function(wave) as.integer(wave) >= 1516L

PSM_CALIPER <- 0.2
PSM_RATIO <- 2L
PSM_REPLACE <- FALSE
PSM_RAW_CALIPER <- TRUE
MATCH_SEED <- 2024L

# Restricted-data execution must take place in the controlled Stats NZ IDI
# environment by researchers approved for the relevant project, in accordance
# with Stats NZ requirements.
DATA_ROOT <- Sys.getenv("CH1_DATA_ROOT", unset = "data")
OUTPUT_ROOT <- Sys.getenv("CH1_OUTPUT_ROOT", unset = "output")

RAW_WAVE_DIR <- file.path(DATA_ROOT, "wave_extracts")
TREATED_FULL_DIR <- file.path(DATA_ROOT, "treated_full")
TREATED_DIR <- file.path(DATA_ROOT, "treated")
CONTROL_POOL_DIR <- file.path(DATA_ROOT, "control_pool")
MATCHED_TREATED_DIR <- file.path(DATA_ROOT, "matched_treated")
MATCHED_CONTROL_DIR <- file.path(DATA_ROOT, "matched_control")
ROBUSTNESS_DIR <- file.path(DATA_ROOT, "matching_variants")
ANALYSIS_DIR <- file.path(DATA_ROOT, "analysis")

FIGURE_DIR <- file.path(OUTPUT_ROOT, "figures")
TABLE_DIR <- file.path(OUTPUT_ROOT, "tables")
DIAGNOSTIC_DIR <- file.path(OUTPUT_ROOT, "diagnostics")

MMI_LOOKUP_PATH <- Sys.getenv(
  "CH1_MMI_LOOKUP_PATH",
  unset = file.path(DATA_ROOT, "public", "meshblock_mmi_lookup.csv")
)
