# ==============================================================================
# Public-data construction of meshblock-level Modified Mercalli Intensity (MMI)
# ------------------------------------------------------------------------------
# The paper assigns the maximum shaking intensity of the 22 February 2011 event
# to Stats NZ meshblocks by spatially overlaying GeoNet shaking data with
# meshblock boundaries. This helper is intentionally independent of IDI data.
#
# Required public inputs:
#   meshblocks      sf polygon object containing a meshblock identifier
#   shaking_points  sf point object containing a numeric MMI field
#
# If the downloaded GeoNet product is a raster/grid rather than an sf point
# layer, first convert cell centres to points (e.g. terra::as.points()) and pass
# the result here. No household coordinates are used in this public step.
# ==============================================================================

suppressPackageStartupMessages({
  library(sf)
  library(dplyr)
  library(ggplot2)
})

build_meshblock_mmi <- function(
    meshblocks,
    shaking_points,
    meshblock_id,
    mmi_field) {

  stopifnot(inherits(meshblocks, "sf"), inherits(shaking_points, "sf"))
  if (!meshblock_id %in% names(meshblocks)) stop("Meshblock ID field not found: ", meshblock_id)
  if (!mmi_field %in% names(shaking_points)) stop("MMI field not found: ", mmi_field)

  shaking_points <- st_transform(shaking_points, st_crs(meshblocks))

  joined <- st_join(
    shaking_points[, mmi_field, drop = FALSE],
    meshblocks[, meshblock_id, drop = FALSE],
    join = st_within,
    left = FALSE
  )

  mmi_by_mb <- joined %>%
    st_drop_geometry() %>%
    group_by(.data[[meshblock_id]]) %>%
    summarise(
      mmi_intensity = max(as.numeric(.data[[mmi_field]]), na.rm = TRUE),
      .groups = "drop"
    )

  meshblocks %>%
    left_join(mmi_by_mb, by = setNames(meshblock_id, meshblock_id))
}

mmi_lookup_from_sf <- function(meshblock_mmi_sf, meshblock_id) {
  meshblock_mmi_sf %>%
    st_drop_geometry() %>%
    transmute(
      meshblock_code = as.character(.data[[meshblock_id]]),
      mmi_intensity = as.numeric(mmi_intensity)
    )
}

plot_mmi_map <- function(
    meshblock_mmi_sf,
    epicentre = NULL,
    xlim = NULL,
    ylim = NULL,
    title = NULL) {

  p <- ggplot(meshblock_mmi_sf) +
    geom_sf(aes(fill = mmi_intensity), linewidth = 0.05) +
    scale_fill_viridis_c(name = "MMI intensity", na.value = "grey90") +
    labs(title = title, x = "Longitude", y = "Latitude") +
    theme_minimal(base_size = 10)

  if (!is.null(epicentre)) {
    stopifnot(inherits(epicentre, "sf"))
    p <- p + geom_sf(data = st_transform(epicentre, st_crs(meshblock_mmi_sf)), shape = 8, size = 2.5)
  }

  if (!is.null(xlim) || !is.null(ylim)) {
    p <- p + coord_sf(xlim = xlim, ylim = ylim, expand = FALSE)
  }

  p
}
