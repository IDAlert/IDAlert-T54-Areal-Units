suppressWarnings({
  options(stringsAsFactors = FALSE)
})

source(file.path("analysis", "r", "power_analysis", "power_simulation.R"))

default_municipality_counts_csv <- file.path(
  "analysis", "r", "power_analysis", "output", "empirical_weekly_counts_municipality.csv"
)

default_coverage_grid <- data.frame(
  coverage_label = c("25pct", "50pct", "75pct", "100pct"),
  spain_share = c(0.25, 0.50, 0.75, 1.00),
  greece_share = c(0.25, 0.50, 0.75, 1.00),
  stringsAsFactors = FALSE
)

count_country_units <- function(weekly_counts_csv) {
  weekly_counts <- read_empirical_weekly_counts(weekly_counts_csv)
  unit_counts <- aggregate(unit_name ~ country, data = unique(weekly_counts[c("country", "unit_name")]), FUN = length)
  names(unit_counts)[names(unit_counts) == "unit_name"] <- "n_units"
  unit_counts
}

shares_to_target_counts <- function(unit_counts, spain_share, greece_share) {
  spain_total <- unit_counts$n_units[unit_counts$country == "Spain"]
  greece_total <- unit_counts$n_units[unit_counts$country == "Greece"]

  c(
    Spain = max(3L, min(spain_total, as.integer(round(spain_total * spain_share)))),
    Greece = max(3L, min(greece_total, as.integer(round(greece_total * greece_share))))
  )
}

run_municipality_coverage_sensitivity <- function(
  coverage_grid = default_coverage_grid,
  n_sims = 200L,
  empirical_weekly_counts_csv = default_municipality_counts_csv
) {
  if (!file.exists(empirical_weekly_counts_csv)) {
    stop(
      "Municipality-level empirical counts not found at ",
      empirical_weekly_counts_csv,
      ". Run build_empirical_weekly_counts.R municipality first."
    )
  }

  unit_counts <- count_country_units(empirical_weekly_counts_csv)
  results <- vector("list", nrow(coverage_grid))

  for (index in seq_len(nrow(coverage_grid))) {
    scenario <- coverage_grid[index, , drop = FALSE]
    target_counts <- shares_to_target_counts(
      unit_counts,
      spain_share = scenario$spain_share,
      greece_share = scenario$greece_share
    )

    cat(
      "Running", scenario$coverage_label,
      "with", target_counts[["Spain"]], "Spanish municipalities and",
      target_counts[["Greece"]], "Greek municipalities\n"
    )

    sim <- simulate_power(
      n_sims = n_sims,
      seed = 500 + index,
      start_date = "2026-06-01",
      end_date = "2026-11-01",
      every_days = 14L,
      pre_window_days = 7L,
      post_window_days = 7L,
      arm_effects = c(
        neutral = 1.00,
        prevention_focus = 1.10,
        promotion_focus = 1.10
      ),
      empirical_weekly_counts_csv = empirical_weekly_counts_csv,
      targetable_spain_n = unname(target_counts[["Spain"]]),
      targetable_greece_n = unname(target_counts[["Greece"]])
    )

    summary_row <- sim$summary
    summary_row$coverage_label <- scenario$coverage_label
    summary_row$spain_share <- scenario$spain_share
    summary_row$greece_share <- scenario$greece_share
    results[[index]] <- summary_row
  }

  coverage_table <- do.call(rbind, results)
  coverage_table <- coverage_table[, c(
    "coverage_label",
    "n_sims",
    "every_days",
    "pre_window_days",
    "post_window_days",
    "n_waves",
    "spain_units",
    "greece_units",
    "targetable_spain_n",
    "targetable_greece_n",
    "spain_share",
    "greece_share",
    "prevention_focus_power",
    "promotion_focus_power",
    "joint_power"
  )]

  output_path <- file.path(
    "analysis", "r", "power_analysis", "output", "municipality_coverage_sensitivity.csv"
  )
  write.csv(coverage_table, output_path, row.names = FALSE)
  coverage_table
}

if (sys.nframe() == 0) {
  results <- run_municipality_coverage_sensitivity()
  print(results)
}