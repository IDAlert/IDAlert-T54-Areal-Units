# Free circle placement versus municipality-centred circles.
#
# If units are radius-targeted circles anyway, nothing forces their centres onto
# municipality centroids. Free placement can:
#   - put a circle where the people and reports actually are, rather than at the
#     geometric centre of a polygon (which for a large rural municipality can be
#     an empty field);
#   - subdivide dense metros that municipality-centring collapses into one unit
#     (Barcelona is a single municipality carrying ~8,000 reports);
#   - use a candidate set defined by audience rather than by administration.
#
# Candidate centres are the 0.025-degree sampling-effort cells that have ever
# recorded a participant (Zenodo record 21466159). That restricts placement to
# places with an app-relevant audience, which is what the extensive margin needs.
#
# Usage: Rscript analysis/r/power_analysis/run_free_circle_placement.R <se025.csv>

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
if (length(args) < 1) stop("Usage: Rscript run_free_circle_placement.R <sampling_effort_025.csv>")

circle_radius_km <- 2
separation_km <- 5
window_days <- 60L
seasons <- 2021:2024

# --------------------------------------------------------------------------
# Candidate centres
# --------------------------------------------------------------------------

message("Reading sampling-effort cells")
cells <- read.csv(args[[1]])
cells <- cells[cells$masked_lon >= -19 & cells$masked_lon <= 5 &
                 cells$masked_lat >= 27 & cells$masked_lat <= 44.5, ]
cells$lon <- cells$masked_lon + 0.0125
cells$lat <- cells$masked_lat + 0.0125

audience <- aggregate(n_participants ~ lon + lat, data = cells, FUN = sum)
names(audience)[3] <- "participants"
audience <- audience[audience$participants > 0, ]
message(nrow(audience), " candidate centres with recorded participants")

# --------------------------------------------------------------------------
# Historical reports within each candidate circle
# --------------------------------------------------------------------------

message("Reading reports")
android_start <- as.Date("2014-06-14"); ios_start <- as.Date("2014-06-24")
reports <- readRDS(file.path("data", "raw", "mosquito_alert_raw_reports.Rds")) %>%
  mutate(
    lon = ifelse(.data$location_choice == "selected",
                 .data$selected_location_lon, .data$current_location_lon),
    lat = ifelse(.data$location_choice == "selected",
                 .data$selected_location_lat, .data$current_location_lat),
    date = as.Date(.data$creation_time),
    os = ifelse(.data$os %in% c("iOS", "iPhone OS", "iPadOS"), "iOS", as.character(.data$os))) %>%
  filter(!is.na(.data$lon), !is.na(.data$lat), !is.na(.data$date),
         .data$type != "mission",
         ((.data$date >= android_start & .data$os == "Android") |
            (.data$date >= ios_start & .data$os == "iOS")),
         .data$lon >= -19, .data$lon <= 5, .data$lat >= 27, .data$lat <= 44.5)

centres <- sf::st_transform(
  sf::st_as_sf(audience, coords = c("lon", "lat"), crs = 4326), 3035)
centre_xy <- sf::st_coordinates(centres)
audience$x <- centre_xy[, 1]; audience$y <- centre_xy[, 2]

report_points <- sf::st_transform(
  sf::st_as_sf(reports, coords = c("lon", "lat"), crs = 4326), 3035)
report_xy <- sf::st_coordinates(report_points)
reports$x <- report_xy[, 1]; reports$y <- report_xy[, 2]

# Bin reports onto a 500 m grid, then for each candidate sum the grid cells
# whose centres fall inside the circle. Much faster than a pairwise distance
# computation and accurate to the bin size.
bin_size <- 500
reports$bx <- floor(reports$x / bin_size)
reports$by <- floor(reports$y / bin_size)

count_within <- function(subset_reports) {
  if (nrow(subset_reports) == 0) return(rep(0L, nrow(audience)))
  binned <- as.data.frame(table(paste(subset_reports$bx, subset_reports$by, sep = "_")),
                          stringsAsFactors = FALSE)
  names(binned) <- c("key", "n")
  parts <- do.call(rbind, strsplit(binned$key, "_"))
  bin_x <- (as.numeric(parts[, 1]) + 0.5) * bin_size
  bin_y <- (as.numeric(parts[, 2]) + 0.5) * bin_size

  offsets <- ceiling(circle_radius_km * 1000 / bin_size)
  bin_index <- split(seq_along(bin_x),
                     paste(floor(bin_x / 5000), floor(bin_y / 5000), sep = "_"))

  vapply(seq_len(nrow(audience)), function(i) {
    cx <- audience$x[i]; cy <- audience$y[i]
    keys <- as.vector(outer(floor((cx - 5000) / 5000):floor((cx + 5000) / 5000),
                            floor((cy - 5000) / 5000):floor((cy + 5000) / 5000),
                            function(a, b) paste(a, b, sep = "_")))
    candidate_bins <- unlist(bin_index[keys[keys %in% names(bin_index)]], use.names = FALSE)
    if (length(candidate_bins) == 0) return(0L)
    inside <- (bin_x[candidate_bins] - cx)^2 + (bin_y[candidate_bins] - cy)^2 <=
      (circle_radius_km * 1000)^2
    as.integer(sum(binned$n[candidate_bins][inside]))
  }, integer(1))
}

panel <- do.call(rbind, lapply(seasons, function(year) {
  treatment_date <- as.Date(sprintf("%d-08-15", year))
  message("season ", year)
  pre <- reports[reports$date >= treatment_date - window_days &
                   reports$date < treatment_date, ]
  post <- reports[reports$date >= treatment_date &
                    reports$date < treatment_date + window_days, ]
  data.frame(centre_id = seq_len(nrow(audience)),
             participants = audience$participants,
             pre = count_within(pre), post = count_within(post), year = year)
}))

# --------------------------------------------------------------------------
# Greedy placement with minimum separation
# --------------------------------------------------------------------------

activity <- aggregate(cbind(pre, post) ~ centre_id, panel, sum)
audience$total_activity <- 0
audience$total_activity[activity$centre_id] <- activity$pre + activity$post

select_separated <- function(gap_km, max_units = Inf) {
  order_index <- order(-audience$total_activity, -audience$participants)
  separation_m <- gap_km * 1000
  kept_x <- numeric(0); kept_y <- numeric(0); kept <- integer(0)
  for (index in order_index) {
    if (length(kept) >= max_units) break
    if (length(kept_x) == 0 ||
        min((kept_x - audience$x[index])^2 + (kept_y - audience$y[index])^2) >=
          separation_m^2) {
      kept <- c(kept, index)
      kept_x <- c(kept_x, audience$x[index]); kept_y <- c(kept_y, audience$y[index])
    }
  }
  kept
}

selected <- select_separated(separation_km)
message("selected ", length(selected), " circles at ", separation_km, " km separation")

# --------------------------------------------------------------------------
# Power as a function of how many circles are used
# --------------------------------------------------------------------------

evaluate <- function(centre_ids, label) {
  subset_panel <- panel[panel$centre_id %in% centre_ids, ]
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

  data.frame(design = label, n_units = length(centre_ids),
             n_active = round(n_active), n_silent = round(n_silent),
             activation_rate = activation,
             reports_covered = sum(subset_panel$pre + subset_panel$post),
             mde_intensive = 100 * (exp(multiplier * intensive_se) - 1),
             mde_extensive = 100 * (exp(multiplier * extensive_se) - 1),
             mde_combined = 100 * (exp(multiplier * combined_se) - 1))
}

sizes <- c(500, 1000, 2000, 4000, 6000, length(selected))
sizes <- unique(sizes[sizes <= length(selected)])

results <- do.call(rbind, lapply(sizes, function(n) {
  evaluate(selected[seq_len(n)], sprintf("free placement, top %d", n))
}))

write.csv(results, file.path(output_dir, "free_circle_placement.csv"), row.names = FALSE)

cat("\n=== Free circle placement:", circle_radius_km, "km radius,",
    separation_km, "km minimum separation ===\n")
cat("Candidate centres:", nrow(audience), " | placeable at this separation:",
    length(selected), "\n\n")
print(results[, c("n_units", "n_active", "n_silent", "activation_rate",
                  "reports_covered", "mde_combined")],
      row.names = FALSE, digits = 3)

# How the design behaves as the buffer between circles widens. With a 2 km
# radius, a separation of D km leaves a gap of D - 4 km between circle edges.
separation_curve <- do.call(rbind, lapply(c(5, 8, 10, 15, 20), function(gap_km) {
  centre_ids <- select_separated(gap_km)
  row <- evaluate(centre_ids, sprintf("separation %d km", gap_km))
  if (is.null(row)) return(NULL)
  row$separation_km <- gap_km
  row$edge_gap_km <- gap_km - 2 * circle_radius_km
  row
}))

write.csv(separation_curve,
          file.path(output_dir, "free_circle_separation_curve.csv"),
          row.names = FALSE)

cat("\n=== Separation curve, free placement ===\n")
print(separation_curve[, c("separation_km", "edge_gap_km", "n_units", "n_active",
                           "n_silent", "activation_rate", "mde_combined")],
      row.names = FALSE, digits = 3)

total_reports <- sum(panel$pre + panel$post)
cat("\nTotal reports inside any candidate circle:", total_reports, "\n")

write.csv(
  data.frame(lon = audience$lon[selected], lat = audience$lat[selected],
             participants = audience$participants[selected],
             total_activity = audience$total_activity[selected],
             radius_km = circle_radius_km),
  file.path(output_dir, "free_circle_centres.csv"), row.names = FALSE)

cat("\nCentres written to", file.path(output_dir, "free_circle_centres.csv"), "\n")
