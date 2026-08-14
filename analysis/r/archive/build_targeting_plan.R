# Campaign-ready targeting plan for the municipality design, plus the power
# consequence of Google Ads' limited named-location coverage.
#
# Produces, for every Spanish municipality:
#   - its Google Ads Criteria ID where one exists (preferred targeting method)
#   - its centroid and a suggested radius, for proximity targeting otherwise
#   - its area, so that spillover risk from circular footprints can be judged
#
# Output:
#   output/targeting_plan_spain_municipalities.csv
#   output/targeting_power_by_coverage.csv
#
# Usage: Rscript analysis/r/power_analysis/build_targeting_plan.R

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

crosswalk <- read.csv(
  file.path(output_dir, "google_ads_spain_municipality_crosswalk.csv"),
  colClasses = c(google_criteria_id = "character"))

# `unit_name` (municipality + province) is not unique in GADM: a handful of
# names repeat within a province and some municipalities are stored as several
# polygons. Collapse to one row per name so the join below cannot fan out.
crosswalk <- crosswalk[!duplicated(crosswalk$unit_name), ]

message("Loading municipality geometry")
admin <- geodata::gadm(country = "ESP", level = 4, path = file.path("data", "raw"))
municipalities <- sf::st_as_sf(admin) %>%
  filter(.data$TYPE_4 == "Municipality") %>%
  transmute(unit_name = paste(.data$NAME_4, .data$NAME_2, sep = ", ")) %>%
  group_by(.data$unit_name) %>%
  summarize(.groups = "drop")

# Equal-area projection for area; centroids taken on the projected geometry then
# transformed back, so they are not distorted by latitude.
projected <- sf::st_transform(municipalities, 3035)
municipalities$area_km2 <- as.numeric(sf::st_area(projected)) / 1e6
centroids <- sf::st_transform(
  sf::st_point_on_surface(projected), 4326)
coordinates <- sf::st_coordinates(centroids)
municipalities$centroid_lon <- coordinates[, 1]
municipalities$centroid_lat <- coordinates[, 2]

plan <- municipalities %>%
  sf::st_drop_geometry() %>%
  left_join(crosswalk[, c("unit_name", "province", "google_criteria_id",
                          "google_canonical_name", "google_target_type",
                          "match_type")],
            by = "unit_name") %>%
  mutate(
    # Radius of a circle with the same area as the municipality, floored at the
    # 1 km Google Ads minimum.
    equivalent_radius_km = sqrt(.data$area_km2 / pi),
    suggested_radius_km = pmax(1, round(.data$equivalent_radius_km, 1)),
    targeting_method = ifelse(
      .data$match_type %in% c("name+community", "name only"),
      "geo_target_id", "proximity_radius")
  ) %>%
  select("unit_name", "province", "area_km2", "centroid_lon", "centroid_lat",
         "equivalent_radius_km", "suggested_radius_km", "targeting_method",
         "google_criteria_id", "google_canonical_name", "google_target_type",
         "match_type") %>%
  arrange(.data$unit_name)

write.csv(plan, file.path(output_dir, "targeting_plan_spain_municipalities.csv"),
          row.names = FALSE)

cat("=== Targeting plan ===\n")
print(table(plan$targeting_method))
cat("\nMunicipality size (km2):\n")
print(round(quantile(plan$area_km2, c(0, .1, .25, .5, .75, .9, 1)), 1))
cat("\nMunicipalities smaller than a 1 km-radius circle (3.14 km2):",
    sum(plan$area_km2 < pi), "of", nrow(plan), "\n")
cat("For these the Google Ads minimum radius necessarily overspills the",
    "municipality boundary.\n")

# --------------------------------------------------------------------------
# Power consequence
# --------------------------------------------------------------------------

counts <- read.csv(file.path(output_dir, "spain_municipality_daily_counts.csv"))
counts$date <- as.Date(counts$date)
all_municipalities <- read.csv(
  file.path(output_dir, "spain_municipality_index.csv"))$unit_name

window_days <- 60L
window_totals <- function(year) {
  treatment_date <- as.Date(sprintf("%d-08-15", year))
  totals <- function(rows) {
    aggregated <- aggregate(n_reports ~ unit_name, data = rows, FUN = sum)
    values <- aggregated$n_reports[match(all_municipalities, aggregated$unit_name)]
    ifelse(is.na(values), 0, values)
  }
  data.frame(
    unit_name = all_municipalities,
    pre = totals(counts[counts$date >= treatment_date - window_days &
                          counts$date < treatment_date, ]),
    post = totals(counts[counts$date >= treatment_date &
                           counts$date < treatment_date + window_days, ]),
    year = year)
}

panel <- do.call(rbind, lapply(2021:2024, window_totals))
named_targetable <- plan$unit_name[plan$targeting_method == "geo_target_id"]

evaluate_coverage <- function(units, label) {
  subset_panel <- panel[panel$unit_name %in% units, ]
  active <- subset_panel[subset_panel$pre >= 1, ]
  silent <- subset_panel[subset_panel$pre == 0, ]

  n_active <- nrow(active) / 4
  n_silent <- nrow(silent) / 4
  activation <- mean(silent$post > 0)

  intensive_sd <- summary(lm(log((active$post + 0.5) / (active$pre + 0.5)) ~
                               factor(active$year)))$sigma
  intensive_se <- intensive_sd * sqrt(2 / (n_active / 3))
  extensive_se <- sqrt((1 - activation) / activation * (2 / (n_silent / 3)))

  combined_se <- sqrt(1 / (1 / intensive_se^2 + 1 / extensive_se^2))
  mde <- function(se) 100 * (exp((qnorm(0.975) + qnorm(0.8)) * se) - 1)

  data.frame(
    scenario = label,
    n_units = length(units),
    n_active = round(n_active),
    n_silent = round(n_silent),
    activation_rate = activation,
    mde_intensive = mde(intensive_se),
    mde_extensive = mde(extensive_se),
    mde_combined = mde(combined_se))
}

coverage <- rbind(
  evaluate_coverage(all_municipalities, "all municipalities (needs radius targeting)"),
  evaluate_coverage(named_targetable, "Google Ads named locations only"))

write.csv(coverage, file.path(output_dir, "targeting_power_by_coverage.csv"),
          row.names = FALSE)

cat("\n=== Power consequence of targeting coverage (60-day windows) ===\n")
print(coverage, row.names = FALSE, digits = 3)

cat("\nOutputs written to", output_dir, "\n")
