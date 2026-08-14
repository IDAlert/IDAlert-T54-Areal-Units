# =============================================================================
# Grid-masking geometry for Spanish municipalities.
#
# Background location tracks are masked to a 0.025 x 0.025 degree grid before
# aggregation. At Spanish latitudes one cell is roughly
#
#     2.78 km north-south  x  2.04-2.25 km east-west  =  5.7-6.3 km2
#
# which is larger than some municipalities and comparable to the width of many.
# Cells are assigned whole to the municipality containing their centroid: the
# municipality-level cell counts sum EXACTLY to the province totals in the
# supplied data (85,767 = 85,767 for 2024), and reconstructing the assignment by
# centroid here reproduces the recorded n_grid_cells for 98% of units.
#
# So cells partition cleanly -- no municipality's territory is double counted.
# What the grid does instead is blur the edges: a cell assigned to municipality A
# may physically extend into B, so activity in B's part of it is recorded as A.
#
# This script measures how bad that blurring is per municipality, and how close
# municipalities sit to one another, so that:
#
#   * the assignment file can carry an interior-cell fraction per unit, fixing
#     the pre-specified "core" robustness subset BEFORE unblinding rather than
#     after; and
#   * the power analysis can model treatment leakage between nearby units.
#
# Note that the grid's contribution to outcome NOISE needs no modelling: the
# historical counts used for calibration were built with the same masking, so
# that variance is already inside the observed unit-level noise. Only leakage of
# the treatment SIGNAL has to be reasoned about separately.
#
# Outputs
#   municipality_grid_geometry.csv     one row per municipality
#   municipality_neighbour_distances.csv  sparse pairs within NEIGHBOUR_MAX_KM
#
# Usage:
#   Rscript analysis/r/01_data_prep/build_municipality_grid_geometry.R
# =============================================================================

suppressWarnings({
  options(stringsAsFactors = FALSE)
})

suppressPackageStartupMessages({
  library(sf)
  library(terra)
})

sf::sf_use_s2(TRUE)

CELL_SIZE_DEG <- 0.025      # masking grid resolution, degrees
NEIGHBOUR_MAX_KM <- 10      # only pairs this close can plausibly exchange users

output_dir <- file.path("analysis", "r", "output")
gadm_path <- file.path("data", "raw", "gadm", "gadm41_ESP_4_pk.rds")
crosswalk_path <- file.path(output_dir,
                            "google_ads_spain_municipality_crosswalk.csv")

if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
}

# --- geometry ----------------------------------------------------------------

boundaries <- readRDS(gadm_path)
if (inherits(boundaries, "PackedSpatVector")) boundaries <- terra::vect(boundaries)
boundaries <- sf::st_as_sf(boundaries)
boundaries$unit_name <- paste(boundaries$NAME_4, boundaries$NAME_2, sep = ", ")
boundaries <- boundaries[!sf::st_is_empty(sf::st_geometry(boundaries)), ]

# Restrict to municipalities Google Ads can actually target by name. That is the
# largest the study pool can ever be, so there is nothing to gain from computing
# geometry for the other ~7,300 municipalities.
crosswalk <- read.csv(crosswalk_path, colClasses = "character")
targetable <- unique(crosswalk$unit_name[crosswalk$match_type == "name+community"])
geometry <- boundaries[boundaries$unit_name %in% targetable, ]

# Some municipalities span several GADM level-4 polygons (exclaves; 54 names in
# Spain, 18 of them targetable -- Murcia, Zaragoza, Malaga, ...). The
# participant data aggregates them (its n_gadm_units column), so the geometry
# must be their UNION. Keeping only the first polygon, as an earlier version
# did, computed area / cells / interior_frac / distances on a fragment.
duplicated_names <- unique(geometry$unit_name[duplicated(geometry$unit_name)])
if (length(duplicated_names) > 0) {
  cat("  unioning", length(duplicated_names),
      "municipalities that span multiple GADM polygons\n")
  keep <- !geometry$unit_name %in% duplicated_names
  merged <- do.call(rbind, lapply(duplicated_names, function(name) {
    parts <- geometry[geometry$unit_name == name, ]
    union_row <- parts[1, ]
    sf::st_geometry(union_row) <- sf::st_union(sf::st_geometry(parts))
    union_row
  }))
  geometry <- rbind(geometry[keep, ], merged)
}
stopifnot(!any(duplicated(geometry$unit_name)))

cat("=== municipalities to measure ===\n")
cat("  targetable by name in Google Ads:", length(targetable), "\n")
cat("  matched to GADM geometry:        ", nrow(geometry), "\n\n")

# --- cell counts per municipality --------------------------------------------
#
# For each municipality, lay the masking grid over its bounding box and count
#
#   cells_centroid : cells whose CENTROID falls inside  -> the cells the
#                    aggregation attributes to this municipality
#   cells_interior : cells lying ENTIRELY inside        -> the cells that carry
#                    no contamination from a neighbour
#
# interior_frac is the share of a municipality's own cells that are clean. A
# value of 1 would mean the municipality is exactly tiled by the grid; the
# observed median is around 0.22.

cell_counts <- function(polygon) {
  bbox <- sf::st_bbox(polygon)
  x0 <- floor(bbox[["xmin"]] / CELL_SIZE_DEG) * CELL_SIZE_DEG
  y0 <- floor(bbox[["ymin"]] / CELL_SIZE_DEG) * CELL_SIZE_DEG
  x1 <- ceiling(bbox[["xmax"]] / CELL_SIZE_DEG) * CELL_SIZE_DEG
  y1 <- ceiling(bbox[["ymax"]] / CELL_SIZE_DEG) * CELL_SIZE_DEG

  frame <- sf::st_as_sfc(sf::st_bbox(c(xmin = x0, xmax = x1, ymin = y0, ymax = y1),
                                     crs = sf::st_crs(polygon)))
  grid <- sf::st_make_grid(frame, cellsize = CELL_SIZE_DEG, offset = c(x0, y0))

  shape <- sf::st_geometry(polygon)
  centroid_inside <- lengths(sf::st_within(sf::st_centroid(grid), shape)) > 0
  fully_inside <- lengths(sf::st_within(grid, shape)) > 0
  c(centroid = sum(centroid_inside), interior = sum(fully_inside))
}

counts <- matrix(0L, nrow = nrow(geometry), ncol = 2,
                 dimnames = list(NULL, c("centroid", "interior")))
for (i in seq_len(nrow(geometry))) {
  counts[i, ] <- cell_counts(geometry[i, ])
  if (i %% 200 == 0) cat("  measured", i, "of", nrow(geometry), "\n")
}

result <- data.frame(
  unit_name = geometry$unit_name,
  gid_4 = geometry$GID_4,
  province = geometry$NAME_2,
  area_km2 = round(as.numeric(sf::st_area(geometry)) / 1e6, 3),
  cells_centroid = as.integer(counts[, "centroid"]),
  cells_interior = as.integer(counts[, "interior"]))
result$interior_frac <- ifelse(result$cells_centroid > 0,
                               round(result$cells_interior / result$cells_centroid, 4), 0)

# --- distances between municipalities ----------------------------------------
#
# Polygon-to-polygon distance, so 0 means the two municipalities touch. Only
# pairs within NEIGHBOUR_MAX_KM are written; anything further apart cannot
# realistically exchange app users over a 60-day window.

distances <- sf::st_distance(geometry)
units(distances) <- NULL
distances <- distances / 1000
diag(distances) <- Inf

pairs <- which(distances <= NEIGHBOUR_MAX_KM, arr.ind = TRUE)
neighbours <- data.frame(
  unit_name = result$unit_name[pairs[, 1]],
  neighbour_name = result$unit_name[pairs[, 2]],
  distance_km = round(distances[pairs], 4))
neighbours <- neighbours[order(neighbours$unit_name, neighbours$distance_km), ]

result$nearest_targetable_km <- round(apply(distances, 1, min), 4)
result$n_touching <- as.integer(rowSums(distances < 0.001))

geometry_path <- file.path(output_dir, "municipality_grid_geometry.csv")
neighbour_path <- file.path(output_dir, "municipality_neighbour_distances.csv")
write.csv(result, geometry_path, row.names = FALSE)
write.csv(neighbours, neighbour_path, row.names = FALSE)

# --- report ------------------------------------------------------------------

cat("\n=== cell size at Spanish latitudes ===\n")
for (lat in c(36, 40, 43)) {
  ns <- CELL_SIZE_DEG * 111.32
  ew <- CELL_SIZE_DEG * 111.32 * cos(lat * pi / 180)
  cat(sprintf("  %d N: %.2f km NS x %.2f km EW = %.1f km2\n", lat, ns, ew, ns * ew))
}

cat("\n=== municipality area (km2) ===\n")
print(summary(result$area_km2))
cat(sprintf("  smaller than one cell: %d\n", sum(result$area_km2 < 6)))

cat("\n=== fraction of a municipality's cells lying fully inside it ===\n")
print(summary(result$interior_frac))
cat(sprintf("  with no fully interior cell: %d (%.0f%%)\n",
            sum(result$cells_interior == 0), 100 * mean(result$cells_interior == 0)))
for (threshold in c(0.25, 0.50)) {
  cat(sprintf("  interior_frac >= %.2f: %d\n", threshold,
              sum(result$interior_frac >= threshold)))
}

cat("\n=== proximity between targetable municipalities ===\n")
cat(sprintf("  touching at least one other: %d (%.0f%%)\n",
            sum(result$n_touching > 0), 100 * mean(result$n_touching > 0)))
cat("  distance to nearest other targetable municipality (km):\n")
print(summary(result$nearest_targetable_km))

cat("\nWritten:\n  ", geometry_path, "\n   ", neighbour_path, "\n", sep = "")
