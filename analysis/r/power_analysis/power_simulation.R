suppressWarnings({
  options(stringsAsFactors = FALSE)
})

default_arm_effects <- c(
  neutral = 1.00,
  prevention_focus = 1.10,
  promotion_focus = 1.10
)

build_schedule <- function(start_date, end_date, every_days = 14L) {
  seq.Date(as.Date(start_date), as.Date(end_date), by = paste(every_days, "days"))
}

trim_schedule <- function(schedule, end_date) {
  schedule[schedule <= as.Date(end_date)]
}

make_synthetic_units <- function(
  spain_n = 50L,
  greece_n = 74L,
  spain_range = c(5, 10),
  greece_range = c(5, 10)
) {
  spain <- data.frame(
    country = "Spain",
    unit_id = sprintf("ES_%02d", seq_len(spain_n)),
    baseline_mean = runif(spain_n, min = spain_range[1], max = spain_range[2])
  )

  greece <- data.frame(
    country = "Greece",
    unit_id = sprintf("GR_%02d", seq_len(greece_n)),
    baseline_mean = runif(greece_n, min = greece_range[1], max = greece_range[2])
  )

  rbind(spain, greece)
}

read_unit_baselines <- function(csv_path) {
  unit_data <- read.csv(csv_path)
  required_columns <- c("country", "unit_id", "baseline_mean")

  missing_columns <- setdiff(required_columns, names(unit_data))
  if (length(missing_columns) > 0) {
    stop(
      "Baseline CSV is missing required columns: ",
      paste(missing_columns, collapse = ", ")
    )
  }

  unit_data
}

balanced_arm_assignment <- function(n_units, arm_levels) {
  sample(rep(arm_levels, length.out = n_units), size = n_units, replace = FALSE)
}

assign_arms_by_wave <- function(unit_frame, schedule, arm_levels) {
  assignments <- vector("list", length(schedule))

  for (wave_index in seq_along(schedule)) {
    wave_rows <- vector("list", length(unique(unit_frame$country)))
    countries <- unique(unit_frame$country)

    for (country_index in seq_along(countries)) {
      country_name <- countries[country_index]
      country_units <- unit_frame[unit_frame$country == country_name, , drop = FALSE]
      country_units$wave <- factor(wave_index)
      country_units$treatment_date <- schedule[wave_index]
      country_units$arm <- balanced_arm_assignment(nrow(country_units), arm_levels)
      wave_rows[[country_index]] <- country_units
    }

    assignments[[wave_index]] <- do.call(rbind, wave_rows)
  }

  assignments_df <- do.call(rbind, assignments)
  assignments_df$arm <- factor(assignments_df$arm, levels = arm_levels)
  assignments_df$wave <- factor(assignments_df$wave, levels = seq_along(schedule))
  assignments_df
}

simulate_counts <- function(
  assignments,
  arm_effects,
  seasonal_multipliers = NULL,
  dispersion_size = Inf
) {
  n_waves <- nlevels(assignments$wave)

  if (is.null(seasonal_multipliers)) {
    seasonal_multipliers <- rep(1, n_waves)
  }

  if (length(seasonal_multipliers) != n_waves) {
    stop("seasonal_multipliers must have one value per wave")
  }

  assignments$wave_index <- as.integer(assignments$wave)
  assignments$pre_mean <- assignments$baseline_mean * seasonal_multipliers[assignments$wave_index]
  assignments$post_mean <- assignments$pre_mean * arm_effects[as.character(assignments$arm)]

  draw_counts <- function(mean_values) {
    if (is.infinite(dispersion_size)) {
      rpois(length(mean_values), lambda = mean_values)
    } else {
      rnbinom(length(mean_values), mu = mean_values, size = dispersion_size)
    }
  }

  assignments$pre_count <- draw_counts(assignments$pre_mean)
  assignments$post_count <- draw_counts(assignments$post_mean)

  pre_rows <- data.frame(
    unit_id = assignments$unit_id,
    country = assignments$country,
    wave = assignments$wave,
    treatment_date = assignments$treatment_date,
    arm = assignments$arm,
    post = 0L,
    count = assignments$pre_count
  )

  post_rows <- data.frame(
    unit_id = assignments$unit_id,
    country = assignments$country,
    wave = assignments$wave,
    treatment_date = assignments$treatment_date,
    arm = assignments$arm,
    post = 1L,
    count = assignments$post_count
  )

  analysis_data <- rbind(pre_rows, post_rows)
  analysis_data$unit_id <- factor(analysis_data$unit_id)
  analysis_data$wave <- factor(analysis_data$wave)
  analysis_data$arm <- relevel(factor(analysis_data$arm), ref = "neutral")
  analysis_data$post <- factor(analysis_data$post, levels = c(0L, 1L))
  analysis_data
}

extract_term_p_value <- function(model_summary, term_name) {
  coefficients <- model_summary$coefficients
  if (!term_name %in% rownames(coefficients)) {
    return(NA_real_)
  }
  coefficients[term_name, "Pr(>|z|)"]
}

fit_power_model <- function(analysis_data) {
  full_model <- glm(
    count ~ unit_id + wave + post * arm,
    family = poisson(),
    data = analysis_data
  )

  reduced_model <- glm(
    count ~ unit_id + wave + post + arm,
    family = poisson(),
    data = analysis_data
  )

  full_summary <- summary(full_model)
  lrt <- anova(reduced_model, full_model, test = "Chisq")

  list(
    prevention_p = extract_term_p_value(full_summary, "post1:armprevention_focus"),
    promotion_p = extract_term_p_value(full_summary, "post1:armpromotion_focus"),
    joint_p = lrt$`Pr(>Chi)`[2]
  )
}

simulate_power <- function(
  n_sims = 500L,
  seed = 123,
  start_date = "2026-06-01",
  end_date = "2026-11-01",
  every_days = 14L,
  alpha = 0.05,
  arm_effects = default_arm_effects,
  seasonal_multipliers = NULL,
  dispersion_size = Inf,
  baseline_csv = NULL
) {
  set.seed(seed)

  full_schedule <- build_schedule(start_date, end_date, every_days = every_days)
  schedule <- trim_schedule(full_schedule, end_date)

  if (!is.null(baseline_csv)) {
    units <- read_unit_baselines(baseline_csv)
  } else {
    units <- make_synthetic_units()
  }

  arm_levels <- names(arm_effects)
  simulation_results <- data.frame(
    simulation = seq_len(n_sims),
    prevention_p = NA_real_,
    promotion_p = NA_real_,
    joint_p = NA_real_
  )

  for (simulation_index in seq_len(n_sims)) {
    assignments <- assign_arms_by_wave(units, schedule, arm_levels)
    analysis_data <- simulate_counts(
      assignments = assignments,
      arm_effects = arm_effects,
      seasonal_multipliers = seasonal_multipliers,
      dispersion_size = dispersion_size
    )

    p_values <- fit_power_model(analysis_data)
    simulation_results$prevention_p[simulation_index] <- p_values$prevention_p
    simulation_results$promotion_p[simulation_index] <- p_values$promotion_p
    simulation_results$joint_p[simulation_index] <- p_values$joint_p
  }

  summary_row <- data.frame(
    n_sims = n_sims,
    every_days = every_days,
    n_waves = length(schedule),
    start_date = as.character(min(schedule)),
    end_date = as.character(max(schedule)),
    spain_units = sum(units$country == "Spain"),
    greece_units = sum(units$country == "Greece"),
    neutral_effect = arm_effects[["neutral"]],
    prevention_focus_effect = arm_effects[["prevention_focus"]],
    promotion_focus_effect = arm_effects[["promotion_focus"]],
    prevention_focus_power = mean(simulation_results$prevention_p < alpha, na.rm = TRUE),
    promotion_focus_power = mean(simulation_results$promotion_p < alpha, na.rm = TRUE),
    joint_power = mean(simulation_results$joint_p < alpha, na.rm = TRUE)
  )

  list(
    summary = summary_row,
    simulation_results = simulation_results,
    schedule = schedule
  )
}

write_results <- function(results, output_dir) {
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  write.csv(
    results$summary,
    file = file.path(output_dir, "power_summary.csv"),
    row.names = FALSE
  )

  write.csv(
    results$simulation_results,
    file = file.path(output_dir, "simulation_p_values.csv"),
    row.names = FALSE
  )
}

run_default_analysis <- function() {
  results <- simulate_power(
    n_sims = 500L,
    seed = 123,
    start_date = "2026-06-01",
    end_date = "2026-11-01",
    every_days = 14L,
    arm_effects = c(
      neutral = 1.00,
      prevention_focus = 1.10,
      promotion_focus = 1.10
    ),
    dispersion_size = Inf
  )

  output_dir <- file.path("analysis", "r", "power_analysis", "output")
  write_results(results, output_dir)

  cat("Treatment dates:\n")
  print(results$schedule)
  cat("\nPower summary:\n")
  print(results$summary)

  invisible(results)
}

if (identical(environment(), globalenv())) {
  run_default_analysis()
}