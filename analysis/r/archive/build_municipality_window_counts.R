# Municipality-level pre/post window counts around 15 August, for the
# extensive-margin (activation) design.
#
# Output: output/spain_municipality_daily_counts.csv

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

build_municipality_daily_counts <- function(
  raw_path = file.path("data", "raw", "mosquito_alert_raw_reports.Rds"),
  boundary_path = file.path("data", "raw"),
  output_path = file.path(
    "analysis", "r", "power_analysis", "output",
    "spain_municipality_daily_counts.csv"
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
      !is.na(.data$lon), !is.na(.data$lat),
      .data$type != "mission",
      !is.na(.data$date),
      .data$date >= as.Date(min_report_date),
      .data$date <= Sys.Date(),
      ((.data$date >= android_start_date & .data$os == "Android") |
         (.data$date >= ios_start_date & .data$os == "iOS")),
      .data$lon >= -19, .data$lon <= 5, .data$lat >= 27, .data$lat <= 44.5
    )

  message("Loading Spain municipalities (GADM level 4)")
  admin <- geodata::gadm(country = "ESP", level = 4, path = boundary_path)
  municipalities <- sf::st_as_sf(admin) %>%
    filter(.data$TYPE_4 == "Municipality") %>%
    transmute(unit_name = paste(.data$NAME_4, .data$NAME_2, sep = ", "))

  message("Joining ", nrow(reports), " reports to ",
          nrow(municipalities), " municipalities")
  points <- st_as_sf(reports, coords = c("lon", "lat"), crs = 4326)
  joined <- st_join(points, municipalities, join = st_within, left = FALSE)

  observed <- joined %>%
    st_drop_geometry() %>%
    filter(!is.na(.data$unit_name)) %>%
    count(.data$unit_name, .data$date, name = "n_reports")

  # Store sparsely: the vast majority of municipality-days are zero, and the
  # full grid would be ~8,200 x 2,400 rows. Downstream code completes it.
  result <- observed %>%
    arrange(.data$unit_name, .data$date)

  all_units <- data.frame(unit_name = sort(unique(municipalities$unit_name)))

  output_dir <- dirname(output_path)
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }
  write.csv(result, output_path, row.names = FALSE)
  write.csv(all_units,
            file.path(output_dir, "spain_municipality_index.csv"),
            row.names = FALSE)

  list(
    counts = result,
    all_units = all_units,
    output_path = output_path,
    n_municipalities_total = nrow(all_units),
    n_municipalities_with_reports = length(unique(result$unit_name)),
    date_range = range(result$date)
  )
}

if (sys.nframe() == 0) {
  results <- build_municipality_daily_counts()
  cat("Municipalities total:", results$n_municipalities_total, "\n")
  cat("Municipalities with any report:", results$n_municipalities_with_reports, "\n")
  cat("Date range:", format(results$date_range), "\n")
  cat("Written to:", results$output_path, "\n")
}
