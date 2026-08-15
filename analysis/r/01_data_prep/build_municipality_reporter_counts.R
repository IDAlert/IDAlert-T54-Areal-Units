# Unique REPORTERS per municipality per season, in the pre and post windows --
# the SECONDARY outcome's calibration and, in October 2026, its outcome file.
#
# Attribution is by REPORT LOCATION (point-in-polygon on GADM level 4), by
# design: reporting UUIDs are deliberately not linkable to background-tracking
# UUIDs, so the modal attribution used for the primary outcome cannot be computed
# here -- and most reporters report exactly once, so a modal-location rule
# would collapse to the report location anyway.
#
# Reports counted: every geolocated non-mission report (adult mosquitoes,
# bites, breeding sites), deduplicated to distinct users per municipality
# per window.
#
# Windows match the participants pipeline exactly: pre 16 Jun - 14 Aug,
# post 16 Aug - 14 Oct; the 15 Aug anchor day belongs to neither. A window is
# emitted only if the raw export fully covers it, so partial seasons appear
# with NA in the missing window rather than a misleading count.
#
# Output: output/municipality_reporter_counts.csv
#   unit_name, year, pre_reporters, post_reporters, pre_reports, post_reports
#
# Usage: Rscript analysis/r/01_data_prep/build_municipality_reporter_counts.R

suppressWarnings({
  options(stringsAsFactors = FALSE)
})

suppressPackageStartupMessages({
  library(dplyr)
  library(sf)
  library(geodata)
})

.data <- rlang::.data
output_dir <- file.path("analysis", "r", "output")

SEASONS <- 2021:2026
WINDOW_DAYS <- 60L
CAMPAIGN_MONTH_DAY <- "08-15"

android_start <- as.Date("2014-06-14")
ios_start <- as.Date("2014-06-24")

message("Reading raw reports")
reports <- readRDS(file.path("data", "raw", "mosquito_alert_raw_reports.Rds")) %>%
  mutate(
    lon = ifelse(.data$location_choice == "selected",
                 .data$selected_location_lon, .data$current_location_lon),
    lat = ifelse(.data$location_choice == "selected",
                 .data$selected_location_lat, .data$current_location_lat),
    date = as.Date(.data$creation_time),
    os = ifelse(.data$os %in% c("iOS", "iPhone OS", "iPadOS"), "iOS",
                as.character(.data$os))) %>%
  filter(!is.na(.data$lon), !is.na(.data$lat), !is.na(.data$user), !is.na(.data$date),
         .data$type != "mission",
         ((.data$date >= android_start & .data$os == "Android") |
            (.data$date >= ios_start & .data$os == "iOS")),
         .data$lon >= -19, .data$lon <= 5, .data$lat >= 27, .data$lat <= 44.5)

message("Loading municipalities")
admin <- geodata::gadm(country = "ESP", level = 4, path = file.path("data", "raw"))
municipalities <- sf::st_as_sf(admin) %>%
  filter(.data$TYPE_4 == "Municipality") %>%
  transmute(unit_name = paste(.data$NAME_4, .data$NAME_2, sep = ", ")) %>%
  group_by(.data$unit_name) %>%
  summarize(.groups = "drop")

message("Assigning ", nrow(reports), " reports to municipalities")
joined <- sf::st_join(
  sf::st_as_sf(reports, coords = c("lon", "lat"), crs = 4326),
  municipalities, join = sf::st_within, left = FALSE)
joined <- sf::st_drop_geometry(joined)
joined <- joined[!is.na(joined$unit_name), c("user", "date", "unit_name")]

all_units <- sort(unique(municipalities$unit_name))

window_counts <- function(rows, label) {
  if (nrow(rows) == 0) {
    return(data.frame(unit_name = all_units, reporters = 0L, reports = 0L))
  }
  reporters <- rows %>%
    distinct(.data$unit_name, .data$user) %>%
    count(.data$unit_name, name = "reporters")
  reports <- rows %>% count(.data$unit_name, name = "reports")

  data.frame(
    unit_name = all_units,
    reporters = ifelse(is.na(reporters$reporters[match(all_units, reporters$unit_name)]), 0L,
                       reporters$reporters[match(all_units, reporters$unit_name)]),
    reports = ifelse(is.na(reports$reports[match(all_units, reports$unit_name)]), 0L,
                     reports$reports[match(all_units, reports$unit_name)]))
}

panel <- do.call(rbind, lapply(SEASONS, function(year) {
  anchor <- as.Date(sprintf("%d-%s", year, CAMPAIGN_MONTH_DAY))
  # Pre window: the 60 days ending the day BEFORE the anchor (16 Jun - 14 Aug).
  # Post window: the 60 days starting the day AFTER it (16 Aug - 14 Oct).
  # This matches the participants pipeline's anchor-exclusion convention; an
  # earlier version used 15 Aug - 13 Oct, one day off at both ends.
  pre_complete <- max(joined$date) >= anchor - 1 &&
    min(joined$date) <= anchor - WINDOW_DAYS
  post_complete <- max(joined$date) >= anchor + WINDOW_DAYS
  if (!pre_complete && !post_complete) {
    message("season ", year, ": no complete window, skipping")
    return(NULL)
  }
  message("season ", year,
          if (!post_complete) " (pre window only; post incomplete -> NA)" else "")
  pre <- if (pre_complete) {
    window_counts(joined[joined$date >= anchor - WINDOW_DAYS &
                           joined$date < anchor, ])
  } else {
    data.frame(unit_name = all_units, reporters = NA_integer_,
               reports = NA_integer_)
  }
  post <- if (post_complete) {
    window_counts(joined[joined$date > anchor &
                           joined$date <= anchor + WINDOW_DAYS, ])
  } else {
    data.frame(unit_name = all_units, reporters = NA_integer_,
               reports = NA_integer_)
  }
  data.frame(
    unit_name = all_units, year = year,
    pre_reporters = pre$reporters, post_reporters = post$reporters,
    pre_reports = pre$reports, post_reports = post$reports)
}))
panel <- panel[!is.na(panel$pre_reporters) | !is.na(panel$post_reporters), ]

if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
output_path <- file.path(output_dir, "municipality_reporter_counts.csv")
write.csv(panel, output_path, row.names = FALSE)

cat("\nSeasons with complete windows:", paste(sort(unique(panel$year)), collapse = ", "), "\n")
cat("Municipality-seasons:", nrow(panel), "\n")
cat("Total unique-reporter counts, pre:", sum(panel$pre_reporters, na.rm = TRUE),
    " post:", sum(panel$post_reporters, na.rm = TRUE), "\n")
cat("Reports per reporter, post window:",
    round(sum(panel$post_reports, na.rm = TRUE) /
            sum(panel$post_reporters, na.rm = TRUE), 2), "\n")
cat("Written to", output_path, "\n")
