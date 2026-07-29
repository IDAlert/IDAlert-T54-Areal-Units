# Build Spain province-by-day Mosquito Alert report counts.
#
# The finalized design uses a single treatment date (15 August) with multi-month
# pre and post windows, so the weekly aggregation used by the earlier scripts is
# too coarse. This builds a complete province-by-date panel that any window
# length can be aggregated from.

suppressWarnings({
  options(stringsAsFactors = FALSE)
})

suppressPackageStartupMessages({
  library(dplyr)
  library(sf)
  library(geodata)
})

.data <- rlang::.data

android_start_date <- as.Date("2014-06-14")
ios_start_date <- as.Date("2014-06-24")

spain_bbox <- list(xmin = -25, xmax = 10, ymin = 27, ymax = 45)

prepare_report_points <- function(raw_path) {
  reports <- readRDS(raw_path) %>%
    mutate(
      lon = dplyr::case_when(
        .data$location_choice == "selected" ~ .data$selected_location_lon,
        TRUE ~ .data$current_location_lon
      ),
      lat = dplyr::case_when(
        .data$location_choice == "selected" ~ .data$selected_location_lat,
        TRUE ~ .data$current_location_lat
      ),
      date = as.Date(.data$creation_time),
      report_type = .data$type,
      os = dplyr::case_when(
        .data$os == "Android" ~ "Android",
        .data$os %in% c("iOS", "iPhone OS", "iPadOS") ~ "iOS",
        TRUE ~ as.character(.data$os)
      )
    ) %>%
    filter(
      !is.na(.data$lon),
      !is.na(.data$lat),
      .data$report_type != "mission",
      !is.na(.data$date),
      .data$date <= Sys.Date(),
      ((.data$date >= android_start_date & .data$os == "Android") |
         (.data$date >= ios_start_date & .data$os == "iOS"))
    )

  st_as_sf(reports, coords = c("lon", "lat"), crs = 4326, remove = FALSE)
}

get_spain_provinces <- function(path) {
  spain_admin <- geodata::gadm(country = "ESP", level = 2, path = path)
  sf::st_as_sf(spain_admin) %>%
    filter(.data$TYPE_2 == "Provincia") %>%
    transmute(unit_name = .data$NAME_2)
}

build_spain_province_daily_counts <- function(
  raw_path = file.path("data", "raw", "mosquito_alert_raw_reports.Rds"),
  boundary_path = file.path("data", "raw"),
  output_path = file.path(
    "analysis", "r", "power_analysis", "output", "spain_province_daily_counts.csv"
  ),
  min_report_date = "2019-01-01",
  max_report_date = NULL
) {
  message("Reading raw reports")
  points_sf <- prepare_report_points(raw_path)

  points_sf <- points_sf[
    points_sf$lon >= spain_bbox$xmin & points_sf$lon <= spain_bbox$xmax &
      points_sf$lat >= spain_bbox$ymin & points_sf$lat <= spain_bbox$ymax,
  ]

  if (!is.null(min_report_date)) {
    points_sf <- points_sf[points_sf$date >= as.Date(min_report_date), ]
  }

  if (!is.null(max_report_date)) {
    points_sf <- points_sf[points_sf$date <= as.Date(max_report_date), ]
  }

  if (nrow(points_sf) == 0) {
    stop("No reports remain after applying the requested filters")
  }

  message("Loading Spain provinces")
  provinces <- get_spain_provinces(boundary_path)

  message("Joining ", nrow(points_sf), " reports to provinces")
  joined <- sf::st_join(points_sf, provinces, join = sf::st_within, left = FALSE)

  observed <- joined %>%
    st_drop_geometry() %>%
    filter(!is.na(.data$unit_name)) %>%
    count(.data$unit_name, .data$date, name = "n_reports")

  all_dates <- seq(min(observed$date), max(observed$date), by = "1 day")

  daily_counts <- expand.grid(
    unit_name = sort(unique(provinces$unit_name)),
    date = all_dates,
    stringsAsFactors = FALSE
  ) %>%
    left_join(observed, by = c("unit_name", "date")) %>%
    mutate(
      country = "Spain",
      n_reports = ifelse(is.na(.data$n_reports), 0L, as.integer(.data$n_reports))
    ) %>%
    select("country", "unit_name", "date", "n_reports") %>%
    arrange(.data$unit_name, .data$date)

  output_dir <- dirname(output_path)
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  write.csv(daily_counts, output_path, row.names = FALSE)

  list(
    daily_counts = daily_counts,
    output_path = output_path,
    n_provinces = length(unique(daily_counts$unit_name)),
    date_range = range(daily_counts$date)
  )
}

if (sys.nframe() == 0) {
  results <- build_spain_province_daily_counts()
  cat("Provinces:", results$n_provinces, "\n")
  cat("Date range:", format(results$date_range), "\n")
  cat("Total reports:", sum(results$daily_counts$n_reports), "\n")
  cat("Written to:", results$output_path, "\n")
}
