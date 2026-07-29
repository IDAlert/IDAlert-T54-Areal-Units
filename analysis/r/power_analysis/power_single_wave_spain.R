# Power analysis for the finalized design:
#   - Spain only
#   - 50 GADM provinces as areal units
#   - one randomization / campaign date: 15 August 2026
#   - three arms: neutral, prevention_focus, promotion_focus
#   - outcome: province report counts in the pre window vs the post window
#
# The data-generating process is calibrated to observed Mosquito Alert reports
# in Spain (analysis/r/power_analysis/output/spain_province_daily_counts.csv).
#
# The important calibration quantity is `tau`: the SD, on the log scale, of the
# province-specific shock to the post/pre ratio that is NOT explained by Poisson
# counting noise. Historical data show tau is roughly 0.6-1.0 at every window
# length tried. Earlier versions of this power analysis implicitly assumed
# tau = 0, which is why they reported much higher power. Setting `tau = 0` here
# reproduces that optimistic case for comparison.

suppressWarnings({
  options(stringsAsFactors = FALSE)
})

default_daily_counts_csv <- file.path(
  "analysis", "r", "power_analysis", "output", "spain_province_daily_counts.csv"
)

default_arm_effects <- c(
  neutral = 1.00,
  prevention_focus = 1.10,
  promotion_focus = 1.10
)

# ---------------------------------------------------------------------------
# Empirical calibration
# ---------------------------------------------------------------------------

read_daily_counts <- function(csv_path = default_daily_counts_csv) {
  if (!file.exists(csv_path)) {
    stop(
      "Province daily counts not found at ", csv_path,
      ". Run build_spain_province_daily_counts.R first."
    )
  }

  daily_counts <- read.csv(csv_path)
  daily_counts$date <- as.Date(daily_counts$date)
  daily_counts
}

# Pre/post window totals per province for one calendar year.
window_totals_for_year <- function(
  daily_counts,
  year,
  campaign_month_day = "08-15",
  pre_window_days = 91L,
  post_window_days = 91L
) {
  treatment_date <- as.Date(sprintf("%d-%s", year, campaign_month_day))
  pre_start <- treatment_date - pre_window_days
  post_end <- treatment_date + post_window_days - 1

  if (min(daily_counts$date) > pre_start || max(daily_counts$date) < post_end) {
    return(NULL)
  }

  pre_rows <- daily_counts[daily_counts$date >= pre_start & daily_counts$date < treatment_date, ]
  post_rows <- daily_counts[daily_counts$date >= treatment_date & daily_counts$date <= post_end, ]

  pre_totals <- aggregate(n_reports ~ unit_name, data = pre_rows, FUN = sum)
  post_totals <- aggregate(n_reports ~ unit_name, data = post_rows, FUN = sum)
  names(pre_totals)[2] <- "pre"
  names(post_totals)[2] <- "post"

  totals <- merge(pre_totals, post_totals, by = "unit_name")
  totals$year <- year
  totals
}

# Method-of-moments split of the observed log-ratio variance into Poisson
# counting noise and residual province-level heterogeneity (tau^2).
estimate_tau <- function(window_panel) {
  per_year <- lapply(split(window_panel, window_panel$year), function(year_rows) {
    log_ratio <- log((year_rows$post + 0.5) / (year_rows$pre + 0.5))
    sampling_var <- 1 / (year_rows$pre + 0.5) + 1 / (year_rows$post + 0.5)

    data.frame(
      year = unique(year_rows$year),
      n_units = nrow(year_rows),
      total_var = var(log_ratio),
      mean_sampling_var = mean(sampling_var),
      tau2 = max(0, var(log_ratio) - mean(sampling_var))
    )
  })

  by_year <- do.call(rbind, per_year)
  by_year$tau <- sqrt(by_year$tau2)
  rownames(by_year) <- NULL

  list(
    by_year = by_year,
    tau_pooled = sqrt(mean(by_year$tau2))
  )
}

calibrate_design <- function(
  daily_counts = read_daily_counts(),
  reference_year = 2024L,
  calibration_years = 2021:2024,
  campaign_month_day = "08-15",
  pre_window_days = 91L,
  post_window_days = 91L
) {
  year_panels <- lapply(calibration_years, function(year) {
    window_totals_for_year(
      daily_counts = daily_counts,
      year = year,
      campaign_month_day = campaign_month_day,
      pre_window_days = pre_window_days,
      post_window_days = post_window_days
    )
  })

  year_panels <- year_panels[!vapply(year_panels, is.null, logical(1))]
  if (length(year_panels) == 0) {
    stop("No calibration year has complete pre and post windows in the daily counts")
  }

  window_panel <- do.call(rbind, year_panels)
  available_years <- sort(unique(window_panel$year))

  if (!reference_year %in% available_years) {
    stop(
      "reference_year ", reference_year, " has no complete windows. Available: ",
      paste(available_years, collapse = ", ")
    )
  }

  reference <- window_panel[window_panel$year == reference_year, ]
  reference <- reference[order(reference$unit_name), ]

  tau_estimates <- estimate_tau(window_panel)

  # The systematic post-period mean is the province's pre-period level times a
  # single Spain-wide seasonal ratio. Province-level departures from that ratio
  # are what `tau` represents, so they must NOT also be baked into the
  # reference year's realized post counts -- otherwise the simulated
  # heterogeneity is counted twice.
  post_pre_ratio <- sum(reference$post) / sum(reference$pre)

  list(
    units = data.frame(
      unit_name = reference$unit_name,
      lambda_pre = reference$pre,
      lambda_post = reference$pre * post_pre_ratio,
      observed_post = reference$post
    ),
    post_pre_ratio = post_pre_ratio,
    tau = tau_estimates,
    window_panel = window_panel,
    reference_year = reference_year,
    calibration_years = available_years,
    pre_window_days = pre_window_days,
    post_window_days = post_window_days
  )
}

# ---------------------------------------------------------------------------
# Randomization
# ---------------------------------------------------------------------------

assign_arms_simple <- function(n_units, arm_levels) {
  sample(rep(arm_levels, length.out = n_units), size = n_units, replace = FALSE)
}

# Blocked assignment: order provinces by baseline volume, form consecutive
# blocks of length = number of arms, permute arms within each block.
assign_arms_blocked <- function(baseline_volume, arm_levels) {
  n_units <- length(baseline_volume)
  n_arms <- length(arm_levels)
  volume_order <- order(baseline_volume, decreasing = TRUE)

  assignment <- character(n_units)
  for (block_start in seq(1, n_units, by = n_arms)) {
    block_indices <- volume_order[block_start:min(block_start + n_arms - 1, n_units)]
    assignment[block_indices] <- sample(arm_levels, length(block_indices), replace = FALSE)
  }

  assignment
}

# ---------------------------------------------------------------------------
# Data-generating process
# ---------------------------------------------------------------------------

simulate_one_dataset <- function(units, arm_effects, arm_assignment, tau, volume_scale = 1) {
  n_units <- nrow(units)
  arm_multiplier <- arm_effects[arm_assignment]

  # Province-specific shock to the post/pre ratio, centred so it does not shift
  # the overall post-period mean.
  post_shock <- exp(rnorm(n_units, mean = -tau^2 / 2, sd = tau))

  pre_count <- rpois(n_units, lambda = pmax(units$lambda_pre * volume_scale, 1e-8))
  post_count <- rpois(
    n_units,
    lambda = pmax(units$lambda_post * volume_scale * post_shock * arm_multiplier, 1e-8)
  )

  data.frame(
    unit_name = units$unit_name,
    arm = factor(arm_assignment, levels = names(arm_effects)),
    pre = pre_count,
    post = post_count
  )
}

# ---------------------------------------------------------------------------
# Estimators
# ---------------------------------------------------------------------------

safe_p <- function(expression) {
  result <- tryCatch(expression, error = function(e) NA_real_)
  if (length(result) != 1 || !is.finite(result)) NA_real_ else result
}

log_ratio_outcome <- function(sim_data) {
  log((sim_data$post + 0.5) / (sim_data$pre + 0.5))
}

# Method-of-moments tau estimated from a single realized dataset, as would be
# done in the real analysis. Used to form precision weights.
estimate_tau_from_data <- function(sim_data) {
  log_ratio <- log_ratio_outcome(sim_data)
  sampling_var <- 1 / (sim_data$pre + 0.5) + 1 / (sim_data$post + 0.5)
  sqrt(max(0, var(log_ratio) - mean(sampling_var)))
}

precision_weights <- function(sim_data, tau_value = NULL) {
  if (is.null(tau_value)) tau_value <- estimate_tau_from_data(sim_data)
  1 / (tau_value^2 + 1 / (sim_data$pre + 0.5) + 1 / (sim_data$post + 0.5))
}

# --- Randomization inference -----------------------------------------------
#
# With 50 units, a heavy-tailed outcome and a known assignment mechanism,
# randomization inference gives an exactly-valid test where robust-SE
# approximations are noticeably liberal. The reference set of assignments only
# depends on the design, so it is generated once and reused across simulations.

build_ri_reference <- function(baseline_volume, arm_levels, randomization, n_perm = 1000L) {
  n_units <- length(baseline_volume)

  permutations <- replicate(n_perm, {
    if (identical(randomization, "blocked")) {
      assign_arms_blocked(baseline_volume, arm_levels)
    } else {
      assign_arms_simple(n_units, arm_levels)
    }
  })

  indicators <- lapply(arm_levels, function(arm_level) {
    matrix(as.numeric(t(permutations == arm_level)), nrow = n_perm, ncol = n_units)
  })
  names(indicators) <- arm_levels

  list(indicators = indicators, n_perm = n_perm, arm_levels = arm_levels)
}

# Weighted arm means for the observed assignment and for every reference
# assignment, then two-sided randomization p-values for each contrast.
ri_test <- function(outcome, weights, arm_assignment, reference) {
  arm_levels <- reference$arm_levels
  weighted_outcome <- weights * outcome

  observed_mean <- vapply(arm_levels, function(arm_level) {
    in_arm <- arm_assignment == arm_level
    sum(weighted_outcome[in_arm]) / sum(weights[in_arm])
  }, numeric(1))

  permuted_mean <- lapply(arm_levels, function(arm_level) {
    indicator <- reference$indicators[[arm_level]]
    as.vector(indicator %*% weighted_outcome) / as.vector(indicator %*% weights)
  })
  names(permuted_mean) <- arm_levels

  contrast_p <- function(arm_level) {
    observed_contrast <- observed_mean[[arm_level]] - observed_mean[["neutral"]]
    permuted_contrast <- permuted_mean[[arm_level]] - permuted_mean[["neutral"]]
    keep <- is.finite(permuted_contrast)
    (1 + sum(abs(permuted_contrast[keep]) >= abs(observed_contrast))) / (1 + sum(keep))
  }

  treated_levels <- setdiff(arm_levels, "neutral")

  observed_joint <- sum(vapply(treated_levels, function(arm_level) {
    (observed_mean[[arm_level]] - observed_mean[["neutral"]])^2
  }, numeric(1)))

  permuted_joint <- Reduce(`+`, lapply(treated_levels, function(arm_level) {
    (permuted_mean[[arm_level]] - permuted_mean[["neutral"]])^2
  }))
  keep_joint <- is.finite(permuted_joint)

  list(
    prevention_p = contrast_p("prevention_focus"),
    promotion_p = contrast_p("promotion_focus"),
    joint_p = (1 + sum(permuted_joint[keep_joint] >= observed_joint)) / (1 + sum(keep_joint)),
    prevention_estimate = observed_mean[["prevention_focus"]] - observed_mean[["neutral"]],
    promotion_estimate = observed_mean[["promotion_focus"]] - observed_mean[["neutral"]]
  )
}

# Unit-level log-ratio regression with heteroskedasticity-robust SEs, kept as a
# reference specification (it is what would be used to report a confidence
# interval alongside the randomization p-value).
fit_log_ratio <- function(sim_data, weights = NULL) {
  sim_data$log_ratio <- log_ratio_outcome(sim_data)
  sim_data$arm <- relevel(sim_data$arm, ref = "neutral")

  model <- if (is.null(weights)) {
    lm(log_ratio ~ arm, data = sim_data)
  } else {
    lm(log_ratio ~ arm, data = sim_data, weights = weights)
  }

  vcov_robust <- sandwich::vcovHC(model, type = "HC3")
  residual_df <- df.residual(model)
  coef_test <- lmtest::coeftest(model, vcov. = vcov_robust, df = residual_df)

  null_model <- if (is.null(weights)) {
    lm(log_ratio ~ 1, data = sim_data)
  } else {
    lm(log_ratio ~ 1, data = sim_data, weights = weights)
  }

  joint_test <- lmtest::waldtest(null_model, model, vcov = vcov_robust, test = "F")

  get_p <- function(term) {
    if (!term %in% rownames(coef_test)) return(NA_real_)
    coef_test[term, 4]
  }

  list(
    prevention_p = get_p("armprevention_focus"),
    promotion_p = get_p("armpromotion_focus"),
    joint_p = safe_p(joint_test$`Pr(>F)`[2])
  )
}

# Count-scale difference-in-differences GLM (the estimator used by the earlier
# version of this analysis). Included to document its behaviour under a
# realistic DGP, not as a recommended primary specification.
fit_count_did <- function(sim_data, family_name = c("poisson", "quasipoisson")) {
  family_name <- match.arg(family_name)

  long_data <- rbind(
    data.frame(unit_name = sim_data$unit_name, arm = sim_data$arm, post = 0L, count = sim_data$pre),
    data.frame(unit_name = sim_data$unit_name, arm = sim_data$arm, post = 1L, count = sim_data$post)
  )
  long_data$unit_name <- factor(long_data$unit_name)
  long_data$arm <- relevel(factor(long_data$arm, levels = levels(sim_data$arm)), ref = "neutral")

  glm_family <- if (identical(family_name, "poisson")) poisson() else quasipoisson()
  test_type <- if (identical(family_name, "poisson")) "Chisq" else "F"
  p_column <- if (identical(family_name, "poisson")) "Pr(>Chi)" else "Pr(>F)"

  full_model <- tryCatch(
    glm(count ~ unit_name + post + post:arm, family = glm_family, data = long_data),
    error = function(e) NULL
  )
  reduced_model <- tryCatch(
    glm(count ~ unit_name + post, family = glm_family, data = long_data),
    error = function(e) NULL
  )

  if (is.null(full_model) || is.null(reduced_model)) {
    return(list(prevention_p = NA_real_, promotion_p = NA_real_, joint_p = NA_real_))
  }

  coefficients <- summary(full_model)$coefficients
  get_p <- function(term) {
    if (!term %in% rownames(coefficients)) return(NA_real_)
    coefficients[term, 4]
  }

  lrt <- tryCatch(anova(reduced_model, full_model, test = test_type), error = function(e) NULL)

  list(
    prevention_p = get_p("post:armprevention_focus"),
    promotion_p = get_p("post:armpromotion_focus"),
    joint_p = if (is.null(lrt)) NA_real_ else safe_p(lrt[[p_column]][2])
  )
}

# ---------------------------------------------------------------------------
# Simulation driver
# ---------------------------------------------------------------------------

simulate_power_single_wave <- function(
  calibration,
  arm_effects = default_arm_effects,
  tau = NULL,
  n_sims = 2000L,
  alpha = 0.05,
  seed = 20260815,
  randomization = c("blocked", "simple"),
  volume_scale = 1,
  n_perm = 1000L,
  estimators = c("ri_weighted", "ri_unweighted", "logratio_hc3",
                 "poisson_did", "quasipoisson_did")
) {
  randomization <- match.arg(randomization)
  if (is.null(tau)) tau <- calibration$tau$tau_pooled

  set.seed(seed)

  units <- calibration$units
  arm_levels <- names(arm_effects)
  baseline_volume <- units$lambda_pre + units$lambda_post

  needs_reference <- any(c("ri_weighted", "ri_unweighted") %in% estimators)
  reference <- if (needs_reference) {
    build_ri_reference(baseline_volume, arm_levels, randomization, n_perm = n_perm)
  } else {
    NULL
  }

  p_values <- lapply(estimators, function(x) {
    matrix(NA_real_, nrow = n_sims, ncol = 3,
           dimnames = list(NULL, c("prevention", "promotion", "joint")))
  })
  names(p_values) <- estimators

  for (sim_index in seq_len(n_sims)) {
    arm_assignment <- if (identical(randomization, "blocked")) {
      assign_arms_blocked(baseline_volume, arm_levels)
    } else {
      assign_arms_simple(nrow(units), arm_levels)
    }

    sim_data <- simulate_one_dataset(
      units = units,
      arm_effects = arm_effects,
      arm_assignment = arm_assignment,
      tau = tau,
      volume_scale = volume_scale
    )

    outcome <- log_ratio_outcome(sim_data)

    for (estimator in estimators) {
      fit <- switch(
        estimator,
        ri_weighted = ri_test(outcome, precision_weights(sim_data), arm_assignment, reference),
        ri_unweighted = ri_test(outcome, rep(1, nrow(sim_data)), arm_assignment, reference),
        logratio_hc3 = fit_log_ratio(sim_data, weights = precision_weights(sim_data)),
        poisson_did = fit_count_did(sim_data, "poisson"),
        quasipoisson_did = fit_count_did(sim_data, "quasipoisson"),
        stop("Unknown estimator: ", estimator)
      )

      p_values[[estimator]][sim_index, ] <- c(fit$prevention_p, fit$promotion_p, fit$joint_p)
    }
  }

  rejection_rate <- function(p_column) mean(p_column < alpha, na.rm = TRUE)

  summary_rows <- lapply(estimators, function(estimator) {
    p_matrix <- p_values[[estimator]]
    data.frame(
      estimator = estimator,
      n_sims = n_sims,
      n_units = nrow(units),
      randomization = randomization,
      tau = tau,
      volume_scale = volume_scale,
      pre_window_days = calibration$pre_window_days,
      post_window_days = calibration$post_window_days,
      reference_year = calibration$reference_year,
      prevention_focus_effect = arm_effects[["prevention_focus"]],
      promotion_focus_effect = arm_effects[["promotion_focus"]],
      prevention_focus_power = rejection_rate(p_matrix[, "prevention"]),
      promotion_focus_power = rejection_rate(p_matrix[, "promotion"]),
      joint_power = rejection_rate(p_matrix[, "joint"])
    )
  })

  list(
    summary = do.call(rbind, summary_rows),
    p_values = p_values
  )
}

# Minimum detectable effect, from the sampling SD of the arm contrast under the
# null. Reported for both the unweighted and the precision-weighted contrast;
# the weighted one is the more favourable (and the one worth designing against).
minimum_detectable_effect <- function(
  calibration,
  tau = NULL,
  n_sims = 2000L,
  alpha = 0.05,
  target_power = 0.80,
  seed = 424242,
  randomization = c("blocked", "simple"),
  volume_scale = 1,
  units = NULL,
  label = "spain_50_provinces"
) {
  randomization <- match.arg(randomization)
  if (is.null(tau)) tau <- calibration$tau$tau_pooled
  if (is.null(units)) units <- calibration$units

  set.seed(seed)
  arm_levels <- names(default_arm_effects)
  baseline_volume <- units$lambda_pre + units$lambda_post
  null_effects <- c(neutral = 1, prevention_focus = 1, promotion_focus = 1)

  contrast_unweighted <- numeric(n_sims)
  contrast_weighted <- numeric(n_sims)

  for (sim_index in seq_len(n_sims)) {
    arm_assignment <- if (identical(randomization, "blocked")) {
      assign_arms_blocked(baseline_volume, arm_levels)
    } else {
      assign_arms_simple(nrow(units), arm_levels)
    }

    sim_data <- simulate_one_dataset(units, null_effects, arm_assignment, tau, volume_scale)
    outcome <- log_ratio_outcome(sim_data)
    weights <- precision_weights(sim_data)

    arm_mean <- function(w, arm_level) {
      in_arm <- arm_assignment == arm_level
      sum((w * outcome)[in_arm]) / sum(w[in_arm])
    }

    flat <- rep(1, nrow(sim_data))
    contrast_unweighted[sim_index] <- arm_mean(flat, "prevention_focus") - arm_mean(flat, "neutral")
    contrast_weighted[sim_index] <- arm_mean(weights, "prevention_focus") - arm_mean(weights, "neutral")
  }

  multiplier <- qnorm(1 - alpha / 2) + qnorm(target_power)

  do.call(rbind, lapply(
    list(unweighted = contrast_unweighted, weighted = contrast_weighted),
    function(contrasts) {
      contrast_se <- sd(contrasts)
      mde_log <- multiplier * contrast_se
      data.frame(
        contrast_se_log = contrast_se,
        mde_log = mde_log,
        mde_ratio = exp(mde_log),
        mde_percent = 100 * (exp(mde_log) - 1)
      )
    }
  )) -> mde_rows

  data.frame(
    design = label,
    weighting = rownames(mde_rows),
    tau = tau,
    n_units = nrow(units),
    randomization = randomization,
    mde_rows,
    row.names = NULL
  )
}

# How many equally-sized areal units would be needed to reach `target_power`
# for a given effect, holding tau fixed? Uses the large-sample approximation
# SE = tau * sqrt(2 / n_per_arm), which is the floor the weighted estimator
# approaches once every unit carries plenty of counts.
required_units_for_effect <- function(
  effect,
  tau,
  n_arms = 3L,
  alpha = 0.05,
  target_power = 0.80
) {
  multiplier <- qnorm(1 - alpha / 2) + qnorm(target_power)
  n_per_arm <- 2 * (tau * multiplier / log(effect))^2

  data.frame(
    effect = effect,
    effect_percent = 100 * (effect - 1),
    tau = tau,
    n_per_arm = ceiling(n_per_arm),
    n_units_total = ceiling(n_per_arm) * n_arms
  )
}
