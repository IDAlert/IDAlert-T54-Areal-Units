suppressWarnings({
  options(stringsAsFactors = FALSE)
})

source(file.path("analysis", "r", "power_analysis", "power_simulation.R"))

default_province_baselines_csv <- file.path(
  "analysis", "r", "power_analysis", "output", "empirical_unit_baselines_20230101_to_20251231.csv"
)

default_municipality_baselines_csv <- file.path(
  "analysis", "r", "power_analysis", "output", "empirical_unit_baselines_municipality_20230101_to_20251231.csv"
)

default_hybrid_scenarios <- data.frame(
  scenario_id = c(
    "province_regional_only",
    "plus_top_10_es_5_gr_municipalities",
    "plus_top_25_es_10_gr_municipalities",
    "plus_top_50_es_20_gr_municipalities",
    "plus_top_100_es_30_gr_municipalities",
    "plus_top_250_es_50_gr_municipalities"
  ),
  top_spain_municipalities = c(0L, 10L, 25L, 50L, 100L, 250L),
  top_greece_municipalities = c(0L, 5L, 10L, 20L, 30L, 50L),
  stringsAsFactors = FALSE
)

load_unit_baselines <- function(csv_path) {
  units <- read.csv(csv_path)
  required_columns <- c("country", "unit_id", "unit_name", "baseline_mean", "nonzero_share")
  missing_columns <- setdiff(required_columns, names(units))

  if (length(missing_columns) > 0) {
    stop("Missing columns in ", csv_path, ": ", paste(missing_columns, collapse = ", "))
  }

  units
}

make_unique_ids <- function(units, prefix) {
  units$unit_id <- paste(prefix, units$unit_id, sep = "_")
  units
}

select_top_municipalities <- function(
  municipality_units,
  top_spain_n,
  top_greece_n,
  min_nonzero_share = 0.05,
  min_baseline_mean = 0
) {
  select_one_country <- function(country_name, top_n) {
    if (top_n <= 0) {
      return(municipality_units[0, , drop = FALSE])
    }

    country_units <- municipality_units[
      municipality_units$country == country_name &
        municipality_units$nonzero_share >= min_nonzero_share &
        municipality_units$baseline_mean > min_baseline_mean,
      ,
      drop = FALSE
    ]

    if (nrow(country_units) == 0) {
      return(country_units)
    }

    country_units <- country_units[order(
      -country_units$baseline_mean,
      -country_units$nonzero_share,
      country_units$unit_name
    ), , drop = FALSE]

    head(country_units, top_n)
  }

  rbind(
    select_one_country("Spain", top_spain_n),
    select_one_country("Greece", top_greece_n)
  )
}

build_hybrid_baselines <- function(
  province_units,
  municipality_units,
  top_spain_n,
  top_greece_n,
  min_nonzero_share = 0.05
) {
  selected_municipalities <- select_top_municipalities(
    municipality_units = municipality_units,
    top_spain_n = top_spain_n,
    top_greece_n = top_greece_n,
    min_nonzero_share = min_nonzero_share
  )

  hybrid_units <- rbind(province_units, selected_municipalities)
  hybrid_units <- hybrid_units[, c("country", "unit_id", "baseline_mean")]

  list(
    hybrid_units = hybrid_units,
    selected_municipalities = selected_municipalities
  )
}

run_hybrid_unit_scenarios <- function(
  scenarios = default_hybrid_scenarios,
  n_sims = 100L,
  seed = 900,
  start_date = "2026-06-01",
  end_date = "2026-11-01",
  every_days = 14L,
  arm_effects = c(
    neutral = 1.00,
    prevention_focus = 1.10,
    promotion_focus = 1.10
  ),
  province_baselines_csv = default_province_baselines_csv,
  municipality_baselines_csv = default_municipality_baselines_csv,
  min_nonzero_share = 0.05
) {
  province_units <- load_unit_baselines(province_baselines_csv)
  municipality_units <- load_unit_baselines(municipality_baselines_csv)

  province_units <- make_unique_ids(province_units, "ADM1")
  municipality_units <- make_unique_ids(municipality_units, "MUNI")

  province_units$unit_type <- "province_or_regional_proxy"
  municipality_units$unit_type <- "municipality"

  scenario_results <- vector("list", nrow(scenarios))
  municipality_selection_rows <- vector("list", nrow(scenarios))

  for (index in seq_len(nrow(scenarios))) {
    scenario <- scenarios[index, , drop = FALSE]
    hybrid_design <- build_hybrid_baselines(
      province_units = province_units,
      municipality_units = municipality_units,
      top_spain_n = scenario$top_spain_municipalities,
      top_greece_n = scenario$top_greece_municipalities,
      min_nonzero_share = min_nonzero_share
    )

    temp_baseline_csv <- tempfile(pattern = paste0("hybrid_baselines_", scenario$scenario_id, "_"), fileext = ".csv")
    write.csv(hybrid_design$hybrid_units, temp_baseline_csv, row.names = FALSE)

    simulation <- simulate_power(
      n_sims = n_sims,
      seed = seed + index,
      start_date = start_date,
      end_date = end_date,
      every_days = every_days,
      arm_effects = arm_effects,
      baseline_csv = temp_baseline_csv
    )

    summary_row <- simulation$summary
    selected <- hybrid_design$selected_municipalities
    summary_row$scenario_id <- scenario$scenario_id
    summary_row$total_units <- nrow(hybrid_design$hybrid_units)
    summary_row$selected_spain_municipalities <- sum(selected$country == "Spain")
    summary_row$selected_greece_municipalities <- sum(selected$country == "Greece")
    summary_row$selected_total_municipalities <- nrow(selected)
    summary_row$mean_selected_spain_municipality_baseline <- if (sum(selected$country == "Spain") > 0) {
      mean(selected$baseline_mean[selected$country == "Spain"])
    } else {
      NA_real_
    }
    summary_row$mean_selected_greece_municipality_baseline <- if (sum(selected$country == "Greece") > 0) {
      mean(selected$baseline_mean[selected$country == "Greece"])
    } else {
      NA_real_
    }

    scenario_results[[index]] <- summary_row

    if (nrow(selected) > 0) {
      selected$scenario_id <- scenario$scenario_id
      municipality_selection_rows[[index]] <- selected[, c(
        "scenario_id", "country", "unit_id", "unit_name", "baseline_mean", "nonzero_share"
      )]
    } else {
      municipality_selection_rows[[index]] <- NULL
    }
  }

  summary_table <- do.call(rbind, scenario_results)
  summary_table <- summary_table[, c(
    "scenario_id",
    "n_sims",
    "every_days",
    "n_waves",
    "start_date",
    "end_date",
    "spain_units",
    "greece_units",
    "total_units",
    "selected_spain_municipalities",
    "selected_greece_municipalities",
    "selected_total_municipalities",
    "mean_selected_spain_municipality_baseline",
    "mean_selected_greece_municipality_baseline",
    "prevention_focus_power",
    "promotion_focus_power",
    "joint_power"
  )]

  selected_table <- do.call(rbind, municipality_selection_rows)
  if (is.null(selected_table)) {
    selected_table <- data.frame()
  }

  output_dir <- file.path("analysis", "r", "power_analysis", "output")
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  write.csv(
    summary_table,
    file.path(output_dir, "hybrid_unit_scenarios_20230101_to_20251231.csv"),
    row.names = FALSE
  )

  write.csv(
    selected_table,
    file.path(output_dir, "hybrid_unit_selected_municipalities_20230101_to_20251231.csv"),
    row.names = FALSE
  )

  list(
    summary = summary_table,
    selected_municipalities = selected_table
  )
}

if (sys.nframe() == 0) {
  results <- run_hybrid_unit_scenarios()
  print(results$summary)
}