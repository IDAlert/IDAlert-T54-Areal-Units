# How far apart are a single participant's reports?
#
# This sets the spatial scale of contamination for a geographically randomized
# design. Two distinct leakage channels matter:
#
#   1. Ad delivery error. Google's inferred device location is imprecise, so ads
#      intended for unit A are served in neighbouring units. Jones et al. 2012
#      (J Med Internet Res 14(3):e84) found only ~21-25% of recruited visitors
#      were actually inside the targeted UK postcode areas, with leakage
#      concentrated in *adjacent* areas.
#   2. Participant movement. A person exposed at home may report from somewhere
#      else entirely, so the report lands in a different unit than the exposure.
#
# Channel 1 cannot be measured from our data. Channel 2 can, and it puts a floor
# under the separation needed between differently-treated units.
#
# Usage: Rscript analysis/r/power_analysis/measure_spillover_scale.R

suppressWarnings({
  options(stringsAsFactors = FALSE)
})

suppressPackageStartupMessages({
  library(dplyr)
  library(sf)
  library(geodata)
})

.data <- rlang::.data
output_dir <- file.path("analysis", "r", "power_analysis", "output")

android_start_date <- as.Date("2014-06-14")
ios_start_date <- as.Date("2014-06-24")

message("Reading raw reports")
reports <- readRDS(file.path("data", "raw", "mosquito_alert_raw_reports.Rds")) %>%
  mutate(
    lon = dplyr::case_when(
      .data$location_choice == "selected" ~ .data$selected_location_lon,
      TRUE ~ .data$current_location_lon),
    lat = dplyr::case_when(
      .data$location_choice == "selected" ~ .data$selected_location_lat,
      TRUE ~ .data$current_location_lat),
    date = as.Date(.data$creation_time),
    os = dplyr::case_when(
      .data$os == "Android" ~ "Android",
      .data$os %in% c("iOS", "iPhone OS", "iPadOS") ~ "iOS",
      TRUE ~ as.character(.data$os))) %>%
  filter(
    !is.na(.data$lon), !is.na(.data$lat), !is.na(.data$user), !is.na(.data$date),
    .data$type != "mission", .data$date >= as.Date("2021-01-01"),
    ((.data$date >= android_start_date & .data$os == "Android") |
       (.data$date >= ios_start_date & .data$os == "iOS")),
    .data$lon >= -19, .data$lon <= 5, .data$lat >= 27, .data$lat <= 44.5)

message(nrow(reports), " Spanish reports from ", length(unique(reports$user)), " users")

# --------------------------------------------------------------------------
# Displacement within a 60-day campaign window
# --------------------------------------------------------------------------
#
# For each user-season, distance from each report to that user's own median
# location. This is the radius within which that user's reports actually fall.

season_windows <- lapply(2021:2025, function(year) {
  treatment_date <- as.Date(sprintf("%d-08-15", year))
  window <- reports[reports$date >= treatment_date - 60 &
                      reports$date < treatment_date + 60, ]
  if (nrow(window) == 0) return(NULL)
  window$season <- year
  window
})
window_reports <- do.call(rbind, season_windows[!vapply(season_windows, is.null, logical(1))])

user_season <- paste(window_reports$user, window_reports$season, sep = "|")
split_reports <- split(
  data.frame(lon = window_reports$lon, lat = window_reports$lat), user_season)

message("Computing displacement for ", length(split_reports), " user-seasons")

displacement <- lapply(split_reports, function(rows) {
  if (nrow(rows) < 2) return(NULL)
  centre <- c(median(rows$lon), median(rows$lat))
  points <- sf::st_as_sf(rows, coords = c("lon", "lat"), crs = 4326)
  centre_point <- sf::st_sfc(sf::st_point(centre), crs = 4326)
  distances <- as.numeric(sf::st_distance(points, centre_point)) / 1000
  data.frame(n_reports = nrow(rows), max_km = max(distances),
             median_km = median(distances), p90_km = quantile(distances, 0.9))
})

displacement <- do.call(rbind, displacement[!vapply(displacement, is.null, logical(1))])

cat("\n=== Within-user displacement, 60-day windows around 15 August ===\n")
cat("User-seasons with 2+ reports:", nrow(displacement), "\n\n")
cat("Distance from a user's own median location to their reports (km):\n")
probs <- c(0.5, 0.75, 0.9, 0.95, 0.99)
cat("  median per user-season: "); print(round(quantile(displacement$median_km, probs), 2))
cat("  maximum per user-season: "); print(round(quantile(displacement$max_km, probs), 2))

# Share of individual reports falling within a given distance of the user's centre
all_distances <- unlist(lapply(split_reports, function(rows) {
  if (nrow(rows) < 2) return(NULL)
  centre <- c(median(rows$lon), median(rows$lat))
  points <- sf::st_as_sf(rows, coords = c("lon", "lat"), crs = 4326)
  centre_point <- sf::st_sfc(sf::st_point(centre), crs = 4326)
  as.numeric(sf::st_distance(points, centre_point)) / 1000
}))

cat("\nShare of reports within X km of the reporting user's own centre:\n")
for (radius in c(1, 2, 5, 10, 20, 30, 50)) {
  cat(sprintf("  %3d km: %5.1f%%\n", radius, 100 * mean(all_distances <= radius)))
}

# --------------------------------------------------------------------------
# Cross-municipality leakage
# --------------------------------------------------------------------------

message("Assigning reports to municipalities")
admin <- geodata::gadm(country = "ESP", level = 4, path = file.path("data", "raw"))
municipalities <- sf::st_as_sf(admin) %>%
  filter(.data$TYPE_4 == "Municipality") %>%
  transmute(unit_name = paste(.data$NAME_4, .data$NAME_2, sep = ", ")) %>%
  group_by(.data$unit_name) %>%
  summarize(.groups = "drop")

points <- sf::st_as_sf(window_reports, coords = c("lon", "lat"), crs = 4326, remove = FALSE)
joined <- sf::st_join(points, municipalities, join = sf::st_within, left = FALSE)
joined <- sf::st_drop_geometry(joined)
joined <- joined[!is.na(joined$unit_name), ]

leakage <- joined %>%
  mutate(user_season = paste(.data$user, .data$season, sep = "|")) %>%
  group_by(.data$user_season) %>%
  summarize(
    n_reports = dplyr::n(),
    n_municipalities = dplyr::n_distinct(.data$unit_name),
    modal_share = max(table(.data$unit_name)) / dplyr::n(),
    .groups = "drop")

multi <- leakage[leakage$n_reports >= 2, ]

cat("\n=== Municipality-level leakage from participant movement ===\n")
cat("User-seasons with 2+ reports:", nrow(multi), "\n")
cat(sprintf("  reporting from more than one municipality: %.1f%%\n",
            100 * mean(multi$n_municipalities > 1)))
cat(sprintf("  share of reports in the user's modal municipality: %.1f%% (median %.0f%%)\n",
            100 * weighted.mean(multi$modal_share, multi$n_reports),
            100 * median(multi$modal_share)))
cat(sprintf("  overall: %.1f%% of reports fall outside their reporter's modal municipality\n",
            100 * (1 - weighted.mean(multi$modal_share, multi$n_reports))))

summary_table <- data.frame(
  metric = c("reports within 1km of user centre", "within 5km", "within 10km",
             "within 20km", "within 50km",
             "user-seasons spanning >1 municipality",
             "reports outside reporter's modal municipality"),
  value = c(mean(all_distances <= 1), mean(all_distances <= 5),
            mean(all_distances <= 10), mean(all_distances <= 20),
            mean(all_distances <= 50),
            mean(multi$n_municipalities > 1),
            1 - weighted.mean(multi$modal_share, multi$n_reports)))

write.csv(summary_table, file.path(output_dir, "spillover_scale.csv"), row.names = FALSE)
cat("\nWritten to", file.path(output_dir, "spillover_scale.csv"), "\n")
