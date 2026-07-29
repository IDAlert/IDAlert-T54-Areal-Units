# Postal codes as the areal unit.
#
# Motivation: Google's ad delivery may be more accurate for a NAMED areal unit
# than for a radius. Google's own location inference is frequently only
# place-level (an IP resolves to a city or postal-code centroid, not a
# coordinate). Matching a place-level estimate against a named place target is
# exact; forcing that same coarse estimate through a fine geometric test, as
# radius targeting does, can only add error. If that is right, named units leak
# less than circles of the same size.
#
# This script asks the separate, answerable question: how many units and how
# much power would Spanish postal codes actually give?
#
# Inputs:
#   - Google geo target CSV (Postal Code rows, Country Code ES)
#   - GeoNames postal centroids, https://download.geonames.org/export/zip/ES.zip
#
# Usage: Rscript run_postal_code_design.R <geotargets.csv> <geonames_ES.txt>

suppressWarnings({
  options(stringsAsFactors = FALSE)
})

suppressPackageStartupMessages({
  library(dplyr)
  library(sf)
})

.data <- rlang::.data
output_dir <- file.path("analysis", "r", "power_analysis", "output")
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) stop("Usage: Rscript run_postal_code_design.R <geotargets.csv> <geonames_ES.txt>")

window_days <- 60L
seasons <- 2021:2024
separation_km <- 8

# --------------------------------------------------------------------------
# Postal code universe and the targetable subset
# --------------------------------------------------------------------------

geo <- read.csv(args[[1]], colClasses = "character")
names(geo) <- gsub("[^A-Za-z]", "_", names(geo))
targetable <- geo[geo$Country_Code == "ES" & geo$Target_Type == "Postal Code" &
                    geo$Status == "Active", c("Criteria_ID", "Name")]
names(targetable) <- c("criteria_id", "postal_code")

geonames <- read.delim(args[[2]], header = FALSE, colClasses = "character",
                       quote = "")
names(geonames)[c(2, 10, 11)] <- c("postal_code", "lat", "lon")
centroids <- geonames %>%
  transmute(postal_code = .data$postal_code,
            lat = as.numeric(.data$lat), lon = as.numeric(.data$lon)) %>%
  filter(!is.na(.data$lat), !is.na(.data$lon)) %>%
  group_by(.data$postal_code) %>%
  summarize(lat = mean(.data$lat), lon = mean(.data$lon), .groups = "drop")

cat("Spanish postal codes in GeoNames:", nrow(centroids), "\n")
cat("Targetable in Google Ads:", nrow(targetable), "\n")
matched <- merge(targetable, centroids, by = "postal_code")
cat("Targetable with known location:", nrow(matched), "\n\n")

# --------------------------------------------------------------------------
# Assign reports to postal codes by nearest centroid (Voronoi approximation)
# --------------------------------------------------------------------------

android_start <- as.Date("2014-06-14"); ios_start <- as.Date("2014-06-24")
reports <- readRDS(file.path("data", "raw", "mosquito_alert_raw_reports.Rds")) %>%
  mutate(
    lon = ifelse(.data$location_choice == "selected",
                 .data$selected_location_lon, .data$current_location_lon),
    lat = ifelse(.data$location_choice == "selected",
                 .data$selected_location_lat, .data$current_location_lat),
    date = as.Date(.data$creation_time),
    os = ifelse(.data$os %in% c("iOS", "iPhone OS", "iPadOS"), "iOS",
                as.character(.data$os))) %>%
  filter(!is.na(.data$lon), !is.na(.data$lat), !is.na(.data$date),
         .data$type != "mission",
         ((.data$date >= android_start & .data$os == "Android") |
            (.data$date >= ios_start & .data$os == "iOS")),
         .data$lon >= -19, .data$lon <= 5, .data$lat >= 27, .data$lat <= 44.5,
         .data$date >= as.Date("2020-06-01"))

project <- function(frame, lon_col = "lon", lat_col = "lat") {
  point <- sf::st_transform(
    sf::st_as_sf(frame, coords = c(lon_col, lat_col), crs = 4326), 3035)
  sf::st_coordinates(point)
}

centroid_xy <- project(centroids)
report_xy <- project(reports)

message("Assigning ", nrow(reports), " reports to nearest postal centroid")
nearest <- sf::st_nearest_feature(
  sf::st_as_sf(as.data.frame(report_xy), coords = c("X", "Y"), crs = 3035),
  sf::st_as_sf(as.data.frame(centroid_xy), coords = c("X", "Y"), crs = 3035))
reports$postal_code <- centroids$postal_code[nearest]
reports$distance_km <- sqrt(rowSums((report_xy - centroid_xy[nearest, ])^2)) / 1000

cat("Report distance to its postal centroid (km):\n")
print(round(quantile(reports$distance_km, c(0.5, 0.75, 0.9, 0.95)), 2))
cat("\n")

# --------------------------------------------------------------------------
# Window counts per postal code
# --------------------------------------------------------------------------

all_codes <- centroids$postal_code
panel <- do.call(rbind, lapply(seasons, function(year) {
  treatment_date <- as.Date(sprintf("%d-08-15", year))
  totals <- function(rows) {
    counted <- as.data.frame(table(rows$postal_code), stringsAsFactors = FALSE)
    values <- counted$Freq[match(all_codes, counted$Var1)]
    ifelse(is.na(values), 0, values)
  }
  data.frame(
    postal_code = all_codes,
    pre = totals(reports[reports$date >= treatment_date - window_days &
                           reports$date < treatment_date, ]),
    post = totals(reports[reports$date >= treatment_date &
                            reports$date < treatment_date + window_days, ]),
    year = year)
}))

evaluate <- function(codes, label) {
  subset_panel <- panel[panel$postal_code %in% codes, ]
  active <- subset_panel[subset_panel$pre >= 1, ]
  silent <- subset_panel[subset_panel$pre == 0, ]
  n_active <- nrow(active) / length(seasons)
  n_silent <- nrow(silent) / length(seasons)
  if (n_active < 10 || n_silent < 10) return(NULL)

  activation <- mean(silent$post > 0)
  intensive_sd <- summary(lm(log((active$post + 0.5) / (active$pre + 0.5)) ~
                               factor(active$year)))$sigma
  intensive_se <- intensive_sd * sqrt(2 / (n_active / 3))
  extensive_se <- sqrt((1 - activation) / activation * (2 / (n_silent / 3)))
  combined_se <- sqrt(1 / (1 / intensive_se^2 + 1 / extensive_se^2))
  multiplier <- qnorm(0.975) + qnorm(0.8)

  data.frame(design = label, n_units = length(codes),
             n_active = round(n_active), n_silent = round(n_silent),
             activation_rate = activation,
             reports_covered = sum(subset_panel$pre + subset_panel$post),
             mde_combined = 100 * (exp(multiplier * combined_se) - 1))
}

# Thinning for separation, preferring active codes.
select_separated <- function(codes, gap_km) {
  pool <- centroids[centroids$postal_code %in% codes, ]
  activity <- aggregate(cbind(pre, post) ~ postal_code, panel, sum)
  pool <- merge(pool, activity, by = "postal_code", all.x = TRUE)
  pool$pre[is.na(pool$pre)] <- 0; pool$post[is.na(pool$post)] <- 0
  xy <- project(pool)
  pool$x <- xy[, 1]; pool$y <- xy[, 2]

  order_index <- order(-(pool$pre + pool$post))
  separation_m <- gap_km * 1000
  kept_x <- numeric(0); kept_y <- numeric(0); kept <- character(0)
  for (index in order_index) {
    if (length(kept_x) == 0 ||
        min((kept_x - pool$x[index])^2 + (kept_y - pool$y[index])^2) >= separation_m^2) {
      kept <- c(kept, pool$postal_code[index])
      kept_x <- c(kept_x, pool$x[index]); kept_y <- c(kept_y, pool$y[index])
    }
  }
  kept
}

results <- rbind(
  evaluate(all_codes, "all Spanish postal codes (not targetable)"),
  evaluate(matched$postal_code, "Google-targetable postal codes"),
  evaluate(select_separated(matched$postal_code, separation_km),
           sprintf("targetable, thinned to %d km", separation_km)))

write.csv(results, file.path(output_dir, "postal_code_design.csv"), row.names = FALSE)

cat("=== Postal codes as the areal unit, 60-day windows ===\n")
print(results, row.names = FALSE, digits = 3)

total_reports <- sum(panel$pre + panel$post)
cat("\nTotal Spanish reports in the windows:", total_reports, "\n")
cat("Share inside Google-targetable postal codes:",
    sprintf("%.0f%%", 100 * results$reports_covered[2] / total_reports), "\n")

# Median spacing between targetable postal codes, to judge how much of a buffer
# they leave on their own.
targetable_xy <- project(matched)
distance_matrix <- sf::st_distance(
  sf::st_as_sf(as.data.frame(targetable_xy), coords = c("X", "Y"), crs = 3035))
diag(distance_matrix) <- Inf
nearest_neighbour <- apply(distance_matrix, 1, min) / 1000
cat("\nDistance from each targetable postal code to its nearest neighbour (km):\n")
print(round(quantile(nearest_neighbour, c(0.1, 0.25, 0.5, 0.75, 0.9)), 2))

cat("\nOutputs written to", output_dir, "\n")
