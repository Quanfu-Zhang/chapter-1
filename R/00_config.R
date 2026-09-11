# ==============================================================================
# Chapter 1 replication code: configuration
# ==============================================================================

options(stringsAsFactors = FALSE)

WAVES <- c(
  "0607", "0708", "0809", "0910", "1011", "1112",
  "1213", "1314", "1415", "1516", "1617", "1718"
)

FULL_EXPENDITURE_WAVES <- c("0607", "0910", "1213", "1516")
POST_WAVES <- c("1112", "1213", "1314", "1415", "1516", "1617", "1718")

CANTERBURY_REGION_CODE <- 13L
NORTH_ISLAND_REGION_CODES <- 1:9
LOW_MMI_MIN <- 4
HIGH_MMI_MIN <- 7

ADDRESS_WINDOW_START <- as.Date("2010-01-01")
EARTHQUAKE_DATE <- as.Date("2011-02-22")
IR_LOOKBACK_START <- as.Date("2000-01-01")

# The HES variable naming convention changes from 2015/16 onward.
legacy_wave <- function(wave) as.integer(wave) <= 1415L
clean_read_wave <- function(wave) as.integer(wave) >= 1516L

# Local paths should be set outside the repository. These defaults are deliberately
# non-sensitive and can be overridden with environment variables.
DATA_ROOT <- Sys.getenv("CH1_DATA_ROOT", unset = file.path("data"))
OUTPUT_ROOT <- Sys.getenv("CH1_OUTPUT_ROOT", unset = file.path("output"))

TREATED_DIR <- file.path(DATA_ROOT, "treated")
CONTROL_POOL_DIR <- file.path(DATA_ROOT, "control_pool")
MATCHED_CONTROL_DIR <- file.path(DATA_ROOT, "matched_control")

# IDI objects. Connection objects `con_table` and `con_user` must be created in
# the Data Lab session and are intentionally not stored in this repository.
IDI_SANDBOX_SCHEMA <- Sys.getenv("CH1_IDI_SCHEMA", unset = "DL-MAA2024-54")
IDI_REFRESH <- Sys.getenv("CH1_IDI_REFRESH", unset = "IDI_Clean_202503")
CLEAN_READ_HES_SCHEMA <- "[IDI_Adhoc].[clean_read_HES]"

# Reproducibility seed used for matching where random tie-breaking applies.
MATCH_SEED <- 2024L
