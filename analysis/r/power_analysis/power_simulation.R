# SUPERSEDED -- kept for reference and reproducibility of earlier results.
#
# This file implements the earlier multi-country, multi-wave exploration (Spain
# + Greece, 14/30-day cadences, province and municipality units). The finalized
# design is Spain-only, provinces, a single campaign on 15 August 2026. See
# power_single_wave_spain.R and run_final_design_spain.R.
#
# Two warnings about the numbers this file produced:
#
# 1. `fit_power_model` uses a fixed-effects Poisson GLM. That model assumes the
#    only source of post-period variation beyond unit and wave effects is
#    Poisson counting noise. Spanish province data violate this badly: the
#    province-level log-scale shock to the post/pre ratio has SD of roughly
#    0.7-0.9 after removing counting noise. Simulating from a DGP with that
#    heterogeneity and testing with this model gives a Type I error rate near
#    0.90 at a nominal 0.05. The "power" figures previously reported from this
#    model are therefore close to its false-positive rate, not power.
#
# 2. The hurdle DGP applies the arm multiplier to both the activation
#    probability and the conditional count, so a nominal "10% effect" is close
#    to a 21% increase in the expected count.
#
# `power_single_wave_spain.R` addresses both: it calibrates the province-level
# shock from history and uses randomization inference, which is correctly sized.

suppressWarnings({
  options(stringsAsFactors = FALSE)
})

default_arm_effects <- c(
  neutral = 1.00,
  prevention_focus = 1.10,
  promotion_focus = 1.10
)

default_empirical_weekly_counts_csv <- file.path(
  "analysis", "r", "power_analysis", "output", "empirical_weekly_counts.csv"
)

default_empirical_weekly_counts_municipality_csv <- file.path(
  "analysis", "r", "power_analysis", "output", "empirical_weekly_counts_municipality.csv"
)

build_schedule <- function(start_date, end_date, every_days = 14L) {
  seq.Date(as.Date(start_date), as.Date(end_date), by = paste(every_days, "days"))
}

calculate_overlap_days <- function(every_days, pre_window_days, post_window_days) {
  max(0, pre_window_days + post_window_days - every_days)
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

read_empirical_weekly_counts <- function(csv_path) {
  weekly_counts <- read.csv(csv_path)
  required_columns <- c("country", "unit_name", "week_start", "weekly_count")

  missing_columns <- setdiff(required_columns, names(weekly_counts))
  if (length(missing_columns) > 0) {
    stop(
      "Empirical weekly-count CSV is missing required columns: ",
      paste(missing_columns, collapse = ", ")
    )
  }

  weekly_counts$week_start <- as.Date(weekly_counts$week_start)
  weekly_counts
}

make_empirical_hurdle_components <- function(weekly_counts) {
  unit_keys <- paste(weekly_counts$country, weekly_counts$unit_name, sep = "||")
  unit_splits <- split(weekly_counts$weekly_count, unit_keys)

  lapply(unit_splits, function(unit_counts) {
    positive_pool <- unit_counts[unit_counts > 0]

    list(
      active_prob = mean(unit_counts > 0),
      positive_pool = if (length(positive_pool) > 0) positive_pool else numeric(0)
    )
  })
}

draw_zero_truncated_poisson <- function(lambda_value) {
  if (lambda_value <= 0) {
    return(0L)
  }

  repeat {
    draw <- rpois(1, lambda = lambda_value)
    if (draw > 0L) {
      return(draw)
    }
  }
}

simulate_hurdle_window_count <- function(component, window_days, margin_effect) {
  if (is.null(component) || component$active_prob <= 0 || length(component$positive_pool) == 0) {
    return(0L)
  }

  weeks_in_window <- window_days / 7
  n_full_weeks <- floor(weeks_in_window)
  partial_week_fraction <- weeks_in_window - n_full_weeks
  weekly_active_prob <- min(component$active_prob * margin_effect, 1)

  simulate_subwindow <- function(week_fraction) {
    subwindow_active_prob <- 1 - (1 - weekly_active_prob)^week_fraction

    if (runif(1) > subwindow_active_prob) {
      return(0L)
    }

    base_positive_count <- sample(component$positive_pool, size = 1, replace = TRUE)
    lambda_value <- base_positive_count * week_fraction * margin_effect
    draw_zero_truncated_poisson(lambda_value)
  }

  total_count <- 0L

  if (n_full_weeks > 0) {
    for (week_index in seq_len(n_full_weeks)) {
      total_count <- total_count + simulate_subwindow(1)
    }
  }

  if (partial_week_fraction > 0) {
    total_count <- total_count + simulate_subwindow(partial_week_fraction)
  }

  total_count
}

make_unit_baselines_from_weekly_counts <- function(weekly_counts) {
  units <- aggregate(
    weekly_count ~ country + unit_name,
    data = weekly_counts,
    FUN = mean
  )

  names(units)[names(units) == "weekly_count"] <- "baseline_mean"

  country_prefixes <- c(
    Spain = "ES",
    Greece = "GR",
    Germany = "DE",
    Netherlands = "NL"
  )

  do.call(rbind, lapply(split(units, units$country), function(country_units) {
    country_name <- unique(country_units$country)
    prefix <- if (country_name %in% names(country_prefixes)) {
      unname(country_prefixes[[country_name]])
    } else {
      toupper(substr(gsub("[^A-Za-z]", "", country_name), 1, 2))
    }

    country_units$unit_id <- sprintf("%s_%02d", prefix, seq_len(nrow(country_units)))
    country_units
  }))
}

subset_units_for_targetability <- function(
  units,
  targetable_spain_n = NULL,
  targetable_greece_n = NULL
) {
  targetable_by_country <- c(
    Spain = targetable_spain_n,
    Greece = targetable_greece_n
  )

  subset_country <- function(country_name, target_n) {
    country_units <- units[units$country == country_name, , drop = FALSE]

    if (is.null(target_n)) {
      return(country_units)
    }

    if (target_n <= 0) {
      stop("Targetable unit counts must be positive when provided")
    }

    target_n <- min(as.integer(target_n), nrow(country_units))
    selected_rows <- sample(seq_len(nrow(country_units)), size = target_n, replace = FALSE)
    country_units[selected_rows, , drop = FALSE]
  }

  do.call(rbind, lapply(unique(units$country), function(country_name) {
    target_n <- if (country_name %in% names(targetable_by_country)) targetable_by_country[[country_name]] else NULL
    subset_country(country_name, target_n)
  }))
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
  dispersion_size = Inf,
  empirical_weekly_counts = NULL,
  empirical_hurdle_components = NULL,
  dgp = c("poisson", "hurdle"),
  pre_window_days = 7L,
  post_window_days = 7L
) {
  dgp <- match.arg(dgp)
  n_waves <- nlevels(assignments$wave)

  if (is.null(seasonal_multipliers)) {
    seasonal_multipliers <- rep(1, n_waves)
  }

  if (length(seasonal_multipliers) != n_waves) {
    stop("seasonal_multipliers must have one value per wave")
  }

  assignments$wave_index <- as.integer(assignments$wave)
  pre_scale <- pre_window_days / 7
  post_scale <- post_window_days / 7

  if (is.null(empirical_weekly_counts)) {
    assignments$pre_mean <- assignments$baseline_mean * pre_scale * seasonal_multipliers[assignments$wave_index]
    assignments$post_mean <- assignments$baseline_mean * post_scale * seasonal_multipliers[assignments$wave_index] * arm_effects[as.character(assignments$arm)]
  } else if (identical(dgp, "hurdle")) {
    simulated_counts <- lapply(seq_len(nrow(assignments)), function(row_index) {
      component_key <- paste(assignments$country[row_index], assignments$unit_name[row_index], sep = "||")
      component <- empirical_hurdle_components[[component_key]]

      pre_count <- simulate_hurdle_window_count(
        component = component,
        window_days = pre_window_days,
        margin_effect = seasonal_multipliers[assignments$wave_index[row_index]]
      )

      post_count <- simulate_hurdle_window_count(
        component = component,
        window_days = post_window_days,
        margin_effect = seasonal_multipliers[assignments$wave_index[row_index]] * arm_effects[as.character(assignments$arm[row_index])]
      )

      c(pre_count = pre_count, post_count = post_count)
    })

    simulated_counts <- do.call(rbind, simulated_counts)
    assignments$pre_count <- simulated_counts[, "pre_count"]
    assignments$post_count <- simulated_counts[, "post_count"]
  } else {
    sampled_counts <- lapply(seq_len(nrow(assignments)), function(row_index) {
      unit_name <- assignments$unit_name[row_index]
      country_name <- assignments$country[row_index]
      pool <- empirical_weekly_counts[
        empirical_weekly_counts$country == country_name & empirical_weekly_counts$unit_name == unit_name,
        "weekly_count"
      ]

      if (length(pool) == 0) {
        return(assignments$baseline_mean[row_index])
      }

      sample(pool, size = 1, replace = TRUE)
    })

    sampled_baseline <- as.numeric(unlist(sampled_counts))
    assignments$pre_mean <- sampled_baseline * pre_scale * seasonal_multipliers[assignments$wave_index]
    assignments$post_mean <- sampled_baseline * post_scale * seasonal_multipliers[assignments$wave_index] * arm_effects[as.character(assignments$arm)]
  }

  draw_counts <- function(mean_values) {
    if (is.infinite(dispersion_size)) {
      rpois(length(mean_values), lambda = mean_values)
    } else {
      rnbinom(length(mean_values), mu = mean_values, size = dispersion_size)
    }
  }

  if (!identical(dgp, "hurdle") || is.null(empirical_weekly_counts)) {
    assignments$pre_count <- draw_counts(assignments$pre_mean)
    assignments$post_count <- draw_counts(assignments$post_mean)
  }

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
  include_wave <- nlevels(analysis_data$wave) > 1

  model_data <- analysis_data

  full_formula <- if (include_wave) {
    count ~ unit_id + wave + post * arm
  } else {
    model_data$post_num <- as.integer(as.character(model_data$post))
    count ~ unit_id + post_num + post_num:arm
  }

  reduced_formula <- if (include_wave) {
    count ~ unit_id + wave + post + arm
  } else {
    count ~ unit_id + post_num
  }

  full_model <- glm(
    full_formula,
    family = poisson(),
    data = model_data
  )

  reduced_model <- glm(
    reduced_formula,
    family = poisson(),
    data = model_data
  )

  full_summary <- summary(full_model)
  lrt <- anova(reduced_model, full_model, test = "Chisq")

  prevention_term <- if (include_wave) {
    "post1:armprevention_focus"
  } else {
    "post_num:armprevention_focus"
  }

  promotion_term <- if (include_wave) {
    "post1:armpromotion_focus"
  } else {
    "post_num:armpromotion_focus"
  }

  list(
    prevention_p = extract_term_p_value(full_summary, prevention_term),
    promotion_p = extract_term_p_value(full_summary, promotion_term),
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
  dgp = c("poisson", "hurdle"),
  baseline_csv = NULL,
  empirical_weekly_counts_csv = NULL,
  targetable_spain_n = NULL,
  targetable_greece_n = NULL,
  pre_window_days = 7L,
  post_window_days = 7L
) {
  dgp <- match.arg(dgp)
  set.seed(seed)

  full_schedule <- build_schedule(start_date, end_date, every_days = every_days)
  schedule <- trim_schedule(full_schedule, end_date)

  empirical_weekly_counts <- NULL
  empirical_hurdle_components <- NULL

  if (!is.null(empirical_weekly_counts_csv)) {
    empirical_weekly_counts <- read_empirical_weekly_counts(empirical_weekly_counts_csv)
    units <- make_unit_baselines_from_weekly_counts(empirical_weekly_counts)
    if (identical(dgp, "hurdle")) {
      empirical_hurdle_components <- make_empirical_hurdle_components(empirical_weekly_counts)
    }
  } else if (!is.null(baseline_csv)) {
    units <- read_unit_baselines(baseline_csv)
  } else {
    units <- make_synthetic_units()
  }

  units <- subset_units_for_targetability(
    units,
    targetable_spain_n = targetable_spain_n,
    targetable_greece_n = targetable_greece_n
  )

  if (!is.null(empirical_weekly_counts)) {
    empirical_weekly_counts <- merge(
      empirical_weekly_counts,
      unique(units[, c("country", "unit_name")]),
      by = c("country", "unit_name")
    )
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
      dispersion_size = dispersion_size,
      empirical_weekly_counts = empirical_weekly_counts,
      empirical_hurdle_components = empirical_hurdle_components,
      dgp = dgp,
      pre_window_days = pre_window_days,
      post_window_days = post_window_days
    )

    p_values <- fit_power_model(analysis_data)
    simulation_results$prevention_p[simulation_index] <- p_values$prevention_p
    simulation_results$promotion_p[simulation_index] <- p_values$promotion_p
    simulation_results$joint_p[simulation_index] <- p_values$joint_p
  }

  summary_row <- data.frame(
    n_sims = n_sims,
    every_days = every_days,
    pre_window_days = pre_window_days,
    post_window_days = post_window_days,
    overlap_days = calculate_overlap_days(every_days, pre_window_days, post_window_days),
    has_overlap = calculate_overlap_days(every_days, pre_window_days, post_window_days) > 0,
    n_waves = length(schedule),
    start_date = as.character(min(schedule)),
    end_date = as.character(max(schedule)),
    total_units = nrow(units),
    spain_units = sum(units$country == "Spain"),
    greece_units = sum(units$country == "Greece"),
    germany_units = sum(units$country == "Germany"),
    netherlands_units = sum(units$country == "Netherlands"),
    neutral_effect = arm_effects[["neutral"]],
    prevention_focus_effect = arm_effects[["prevention_focus"]],
    promotion_focus_effect = arm_effects[["promotion_focus"]],
    dgp = dgp,
    empirical_baseline_source = ifelse(
      is.null(empirical_weekly_counts_csv),
      "synthetic_or_unit_baseline_csv",
      empirical_weekly_counts_csv
    ),
    targetable_spain_n = sum(units$country == "Spain"),
    targetable_greece_n = sum(units$country == "Greece"),
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
  empirical_counts_available <- file.exists(default_empirical_weekly_counts_csv)

  results <- simulate_power(
    n_sims = 500L,
    seed = 123,
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
    dispersion_size = Inf,
    empirical_weekly_counts_csv = if (empirical_counts_available) default_empirical_weekly_counts_csv else NULL
  )

  output_dir <- file.path("analysis", "r", "power_analysis", "output")
  write_results(results, output_dir)

  cat("Treatment dates:\n")
  print(results$schedule)
  cat("\nPower summary:\n")
  print(results$summary)

  invisible(results)
}

if (sys.nframe() == 0) {
  run_default_analysis()
}