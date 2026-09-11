# ==============================================================================
# Freeze software environment metadata after the validated Data Lab run
# ==============================================================================

write_session_info <- function(path = file.path("docs", "sessionInfo.txt")) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  info <- capture.output(sessionInfo())
  writeLines(info, path)
  message("Wrote R session information to ", path)
  invisible(path)
}

if (identical(Sys.getenv("CH1_WRITE_SESSION_INFO"), "1")) {
  write_session_info()
}
