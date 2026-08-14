suppressWarnings({
  options(stringsAsFactors = FALSE)
})

source(file.path("analysis", "r", "power_analysis", "power_simulation.R"))

default_scenarios <- data.frame(
  scenario_id = c(
    "baseline_14d_7pre_7post",
    "faster_10d_5pre_5post",
    "faster_10d_7pre_7post",
    "overlap_10d_10pre_10post",
    "dense_7d_5pre_5post"
  ),
  every_days = c(14L, 10L, 10L, 10L, 7L),
  pre_window_days = c(7L, 5L, 7L, 10L, 5L),
  post_window_days = c(7L, 5L, 7L, 10L, 5L),
  stringsAsFactors = FALSE
)

run_scenarios <- function(
  scenarios = default_scenarios,
  n_sims = 100L,
  empirical_weekly_counts_csv = file.path("analysis", "r", "power_analysis", "output", "empirical_weekly_counts.csv")
) {
  results <- vector("list", nrow(scenarios))

  for (index in seq_len(nrow(scenarios))) {
    scenario <- scenarios[index, , drop = FALSE]
    cat("Running", scenario$scenario_id, "\n")

    scenario_result <- simulate_power(
      n_sims = n_sims,
      seed = 123 + index,
      start_date = "2026-06-01",
      end_date = "2026-11-01",
      every_days = scenario$every_days,
      pre_window_days = scenario$pre_window_days,
      post_window_days = scenario$post_window_days,
      arm_effects = c(
        neutral = 1.00,
        prevention_focus = 1.10,
        promotion_focus = 1.10
      ),
      empirical_weekly_counts_csv = empirical_weekly_counts_csv
    )

    scenario_summary <- scenario_result$summary
    scenario_summary$scenario_id <- scenario$scenario_id
    results[[index]] <- scenario_summary
  }

  scenario_table <- do.call(rbind, results)
  scenario_table <- scenario_table[, c(
    "scenario_id",
    "n_sims",
    "every_days",
    "pre_window_days",
    "post_window_days",
    "overlap_days",
    "has_overlap",
    "n_waves",
    "spain_units",
    "greece_units",
    "prevention_focus_power",
    "promotion_focus_power",
    "joint_power"
  )]

  output_path <- file.path("analysis", "r", "power_analysis", "output", "power_scenarios.csv")
  write.csv(scenario_table, output_path, row.names = FALSE)
  scenario_table
}

if (sys.nframe() == 0) {
  results <- run_scenarios()
  print(results)
}