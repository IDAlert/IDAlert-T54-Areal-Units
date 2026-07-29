# Build a province-by-day panel of ALL candidate outcome measures, from the
# Mosquito Alert sampling-effort dataset (Zenodo record 21466159).
#
# That dataset carries much more than sampling effort: per 0.05-degree cell per
# day it has participant counts, two sampling-effort estimates, validated
# species-level report counts, and unique-reporter counts. This lets us compare
# candidate outcomes on the one quantity that decides power for this design --
# tau, the province-level idiosyncratic variation in the post/pre ratio.
#
# Input:  sampling_effort_daily_cellres_05.csv.gz
# Output: output/province_outcome_daily_<country>.csv

suppressWarnings({
  options(stringsAsFactors = FALSE)
})

suppressPackageStartupMessages({
  library(dplyr)
  library(sf)
  library(geodata)
  library(giscoR)
})

.data <- rlang::.data

cell_resolution <- 0.05

outcome_columns <- c(
  "n_participants", "SE_expected", "SE",
  "n_reports_albopictus", "n_reports_bite", "n_reports_culex",
  "n_reports_japonicus", "n_reports_aegypti", "n_reports_koreicus",
  "n_reporters_albopictus", "n_reporters_bite", "n_reporters_culex"
)

country_config <- list(
  Spain = list(
    bbox = c(xmin = -19, xmax = 5, ymin = 27, ymax = 44.5),
    loader = function(path) {
      admin <- geodata::gadm(country = "ESP", level = 2, path = path)
      sf::st_as_sf(admin) %>%
        filter(.data$TYPE_2 == "Provincia") %>%
        transmute(unit_name = .data$NAME_2)
    }
  ),
  Greece = list(
    bbox = c(xmin = 19, xmax = 30, ymin = 34, ymax = 42),
    loader = function(path) {
      giscoR::gisco_get_nuts(nuts_level = 3, year = "2021", epsg = "4326") %>%
        filter(.data$CNTR_CODE == "EL") %>%
        transmute(unit_name = .data$NAME_LATN)
    }
  )
)

build_province_outcome_panel <- function(
  sampling_effort_csv,
  country = c("Spain", "Greece"),
  boundary_path = file.path("data", "raw"),
  output_dir = file.path("analysis", "r", "power_analysis", "output")
) {
  country <- match.arg(country)
  config <- country_config[[country]]

  message("Reading sampling effort data")
  cells <- read.csv(sampling_effort_csv)
  cells$date <- as.Date(cells$date)

  present <- intersect(outcome_columns, names(cells))
  missing <- setdiff(outcome_columns, names(cells))
  if (length(missing) > 0) {
    message("Columns not present in this release: ", paste(missing, collapse = ", "))
  }

  # Cell centroid, not the SW corner the file records.
  cells$lon <- cells$masked_lon + cell_resolution / 2
  cells$lat <- cells$masked_lat + cell_resolution / 2

  cells <- cells[
    cells$lon >= config$bbox[["xmin"]] & cells$lon <= config$bbox[["xmax"]] &
      cells$lat >= config$bbox[["ymin"]] & cells$lat <= config$bbox[["ymax"]], ]

  if (nrow(cells) == 0) {
    stop("No sampling-effort cells fall inside the ", country, " bounding box")
  }

  message("Loading ", country, " areal units")
  units <- config$loader(boundary_path)

  # Assign each distinct cell once, then join back to the daily rows.
  distinct_cells <- unique(cells[, c("TigacellID", "lon", "lat")])
  message("Assigning ", nrow(distinct_cells), " distinct cells to areal units")

  cell_points <- st_as_sf(distinct_cells, coords = c("lon", "lat"), crs = 4326)
  assigned <- st_join(cell_points, units, join = st_within, left = FALSE)
  cell_lookup <- data.frame(
    TigacellID = assigned$TigacellID,
    unit_name = assigned$unit_name
  )
  cell_lookup <- cell_lookup[!is.na(cell_lookup$unit_name), ]

  message(nrow(cell_lookup), " cells fell inside an areal unit")

  panel <- cells %>%
    inner_join(cell_lookup, by = "TigacellID") %>%
    group_by(.data$unit_name, .data$date) %>%
    summarize(across(all_of(present), ~ sum(.x, na.rm = TRUE)), .groups = "drop")

  # Complete the grid: absent cell-days mean no recorded activity, i.e. zero.
  all_dates <- seq(min(panel$date), max(panel$date), by = "1 day")
  complete_panel <- expand.grid(
    unit_name = sort(unique(units$unit_name)),
    date = all_dates,
    stringsAsFactors = FALSE
  ) %>%
    left_join(panel, by = c("unit_name", "date")) %>%
    mutate(across(all_of(present), ~ ifelse(is.na(.x), 0, .x))) %>%
    mutate(country = country) %>%
    select("country", "unit_name", "date", all_of(present)) %>%
    arrange(.data$unit_name, .data$date)

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  output_path <- file.path(
    output_dir, paste0("province_outcome_daily_", tolower(country), ".csv")
  )
  write.csv(complete_panel, output_path, row.names = FALSE)

  list(
    panel = complete_panel,
    output_path = output_path,
    n_units = length(unique(complete_panel$unit_name)),
    date_range = range(complete_panel$date),
    outcomes = present
  )
}

if (sys.nframe() == 0) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) < 1) {
    stop("Usage: Rscript build_province_outcome_panel.R <sampling_effort_csv> [country]")
  }
  country <- if (length(args) >= 2) args[[2]] else "Spain"

  results <- build_province_outcome_panel(args[[1]], country = country)
  cat("Country:", country, "| units:", results$n_units, "\n")
  cat("Date range:", format(results$date_range), "\n")
  cat("Outcomes:", paste(results$outcomes, collapse = ", "), "\n")
  cat("Written to:", results$output_path, "\n")
}
