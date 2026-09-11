# ==============================================================================
# Intended orchestration for the archival release
# ==============================================================================
# This file is intentionally conservative while the release audit remains open.

source(file.path("R", "00_config.R"))
source(file.path("R", "01_hes_schema_adapter.R"))

message("Chapter 1 release candidate loaded.")
message("Resolve docs/REPRODUCIBILITY_AUDIT.md before running an end-to-end archive build.")
