# The separation-versus-power tradeoff for a geographically randomized design.
#
# Power wants many units. Contamination wants few, widely separated ones. These
# pull in opposite directions and the design has to pick a point on the curve.
#
# Contamination has two channels:
#   1. Ad delivery error -- Google serves the ad outside the intended unit.
#      Jones et al. 2012 (J Med Internet Res 14(3):e84) found only ~21-25% of
#      recruited visitors were inside the targeted UK postcode areas, with
#      leakage concentrated in adjacent areas. Their control areas were 35-160
#      miles from any intervention area, and control contamination was ~1%.
#   2. Participant movement -- measured here at 10.2% of Spanish reports falling
#      outside their reporter's modal municipality, with 84% of reports within
#      1 km of the reporter's own centre but a long tail.
#
# A buffer only helps with channel 1, and only by ensuring that leaked exposure
# lands in unassigned territory rather than in a differently-armed unit.
#
# Usage: Rscript analysis/r/power_analysis/run_buffer_design_tradeoff.R

suppressWarnings({
  options(stringsAsFactors = FALSE)
})

suppressPackageStartupMessages({
  library(dplyr)
  library(sf)
})

.data <- rlang::.data
output_dir <- file.path("analysis", "r", "power_analysis", "output")

plan <- read.csv(file.path(output_dir, "targeting_plan_spain_municipalities.csv"),
                 colClasses = c(google_criteria_id = "character"))
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

activity <- aggregate(cbind(pre, post) ~ unit_name, panel, sum)
plan <- merge(plan, activity, by = "unit_name", all.x = TRUE)
plan$pre[is.na(plan$pre)] <- 0
plan$post[is.na(plan$post)] <- 0
plan <- plan[!is.na(plan$centroid_lon), ]

# Projected coordinates in metres for fast distance work.
projected <- sf::st_transform(
  sf::st_as_sf(plan, coords = c("centroid_lon", "centroid_lat"), crs = 4326), 3035)
coordinates <- sf::st_coordinates(projected)
plan$x <- coordinates[, 1]
plan$y <- coordinates[, 2]

# Greedy thinning: walk municipalities from most to least active, keeping one
# only if it is at least `separation_km` from everything kept so far. Preferring
# active units keeps the intensive margin, which carries most of the power.
select_separated <- function(separation_km) {
  order_index <- order(-(plan$pre + plan$post))
  separation_m <- separation_km * 1000
  kept_x <- numeric(0)
  kept_y <- numeric(0)
  kept <- logical(nrow(plan))

  for (index in order_index) {
    if (length(kept_x) == 0) {
      kept[index] <- TRUE
      kept_x <- plan$x[index]; kept_y <- plan$y[index]
      next
    }
    distances <- sqrt((kept_x - plan$x[index])^2 + (kept_y - plan$y[index])^2)
    if (min(distances) >= separation_m) {
      kept[index] <- TRUE
      kept_x <- c(kept_x, plan$x[index]); kept_y <- c(kept_y, plan$y[index])
    }
  }
  plan$unit_name[kept]
}

# Hurdle MDE for a given set of units, plus the attenuation a given leakage
# fraction implies.
evaluate <- function(units, label, separation_km, leakage = 0) {
  subset_panel <- panel[panel$unit_name %in% units, ]
  active <- subset_panel[subset_panel$pre >= 1, ]
  silent <- subset_panel[subset_panel$pre == 0, ]

  n_active <- nrow(active) / 4
  n_silent <- nrow(silent) / 4
  if (n_active < 10 || n_silent < 10) return(NULL)

  activation <- mean(silent$post > 0)
  intensive_sd <- summary(lm(log((active$post + 0.5) / (active$pre + 0.5)) ~
                               factor(active$year)))$sigma
  intensive_se <- intensive_sd * sqrt(2 / (n_active / 3))
  extensive_se <- sqrt((1 - activation) / activation * (2 / (n_silent / 3)))
  combined_se <- sqrt(1 / (1 / intensive_se^2 + 1 / extensive_se^2))

  # Symmetric leakage to units of random arm attenuates the observed contrast
  # by roughly (1 - leakage); the effect needed to be detected inflates by the
  # reciprocal.
  multiplier <- qnorm(0.975) + qnorm(0.8)
  mde_log <- multiplier * combined_se / (1 - leakage)

  data.frame(
    design = label,
    separation_km = separation_km,
    n_units = length(units),
    n_active = round(n_active),
    n_silent = round(n_silent),
    reports_retained = sum(subset_panel$pre + subset_panel$post) /
      sum(panel$pre + panel$post),
    assumed_leakage = leakage,
    mde_percent = 100 * (exp(mde_log) - 1))
}

separations <- c(0, 2, 5, 10, 20, 30, 50)
results <- do.call(rbind, lapply(separations, function(separation_km) {
  units <- if (separation_km == 0) plan$unit_name else select_separated(separation_km)
  message("separation ", separation_km, " km -> ", length(units), " units")
  evaluate(units, "all municipalities", separation_km, leakage = 0)
}))

write.csv(results, file.path(output_dir, "buffer_design_tradeoff.csv"),
          row.names = FALSE)

cat("\n=== Separation vs power, Spanish municipalities (no leakage assumed) ===\n")
print(results[, c("separation_km", "n_units", "n_active", "n_silent",
                  "reports_retained", "mde_percent")],
      row.names = FALSE, digits = 3)

# The same curve, but charging each design the leakage it plausibly suffers:
# no separation means adjacent units in different arms, so leakage is high.
leakage_assumption <- c("0" = 0.45, "2" = 0.35, "5" = 0.25, "10" = 0.15,
                        "20" = 0.10, "30" = 0.08, "50" = 0.05)

with_leakage <- do.call(rbind, lapply(separations, function(separation_km) {
  units <- if (separation_km == 0) plan$unit_name else select_separated(separation_km)
  evaluate(units, "with assumed leakage", separation_km,
           leakage = leakage_assumption[[as.character(separation_km)]])
}))

write.csv(with_leakage, file.path(output_dir, "buffer_design_tradeoff_leakage.csv"),
          row.names = FALSE)

cat("\n=== Same curve, charging each design its plausible leakage ===\n")
cat("Leakage is the share of treatment contrast lost to differently-armed\n")
cat("neighbours; it falls as separation rises. These values are judgement,\n")
cat("anchored on Jones et al., not estimated from our data.\n\n")
print(with_leakage[, c("separation_km", "n_units", "assumed_leakage",
                       "mde_percent")], row.names = FALSE, digits = 3)

cat("\nOutputs written to", output_dir, "\n")
