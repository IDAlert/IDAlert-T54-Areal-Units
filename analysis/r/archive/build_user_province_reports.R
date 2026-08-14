# Report-level table with user UUID, date and province, for the user-level
# (closed-cohort) design.
#
# Output: output/spain_user_province_reports.csv
#   user, date, unit_name

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

build_user_province_reports <- function(
  raw_path = file.path("data", "raw", "mosquito_alert_raw_reports.Rds"),
  boundary_path = file.path("data", "raw"),
  output_path = file.path(
    "analysis", "r", "power_analysis", "output", "spain_user_province_reports.csv"
  ),
  min_report_date = "2019-01-01"
) {
  message("Reading raw reports")
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
      os = dplyr::case_when(
        .data$os == "Android" ~ "Android",
        .data$os %in% c("iOS", "iPhone OS", "iPadOS") ~ "iOS",
        TRUE ~ as.character(.data$os)
      )
    ) %>%
    filter(
      !is.na(.data$lon), !is.na(.data$lat), !is.na(.data$user),
      .data$type != "mission",
      !is.na(.data$date),
      .data$date >= as.Date(min_report_date),
      .data$date <= Sys.Date(),
      ((.data$date >= android_start_date & .data$os == "Android") |
         (.data$date >= ios_start_date & .data$os == "iOS")),
      .data$lon >= -19, .data$lon <= 5, .data$lat >= 27, .data$lat <= 44.5
    )

  message("Loading Spain provinces")
  provinces <- geodata::gadm(country = "ESP", level = 2, path = boundary_path)
  provinces <- sf::st_as_sf(provinces) %>%
    filter(.data$TYPE_2 == "Provincia") %>%
    transmute(unit_name = .data$NAME_2)

  message("Joining ", nrow(reports), " reports to provinces")
  points <- st_as_sf(reports, coords = c("lon", "lat"), crs = 4326)
  joined <- st_join(points, provinces, join = st_within, left = FALSE)

  result <- joined %>%
    st_drop_geometry() %>%
    filter(!is.na(.data$unit_name)) %>%
    transmute(user = .data$user, date = .data$date, unit_name = .data$unit_name) %>%
    arrange(.data$user, .data$date)

  output_dir <- dirname(output_path)
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }
  write.csv(result, output_path, row.names = FALSE)

  list(
    reports = result,
    output_path = output_path,
    n_reports = nrow(result),
    n_users = length(unique(result$user)),
    date_range = range(result$date)
  )
}

if (sys.nframe() == 0) {
  results <- build_user_province_reports()
  cat("Reports:", results$n_reports, "| users:", results$n_users, "\n")
  cat("Date range:", format(results$date_range), "\n")
  cat("Written to:", results$output_path, "\n")
}
