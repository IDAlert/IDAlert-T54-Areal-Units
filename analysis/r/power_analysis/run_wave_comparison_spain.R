# How much would repeated re-randomized waves buy, relative to the single
# 15 August 2026 wave?
#
# Motivation: the single-wave design is limited by tau, the province-level
# log-scale shock to the post/pre ratio. Empirically the province shocks are
# essentially uncorrelated across waves within a season (mean cross-wave
# correlation of province log-ratios in 2023 and 2024 is about -0.08), so each
# additional re-randomized wave adds close to a full set of independent
# unit-observations.
#
# Usage:  Rscript analysis/r/power_analysis/run_wave_comparison_spain.R [n_sims]

suppressWarnings({
  options(stringsAsFactors = FALSE)
})

source(file.path("analysis", "r", "power_analysis", "power_single_wave_spain.R"))

output_dir <- file.path("analysis", "r", "power_analysis", "output")
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

args <- commandArgs(trailingOnly = TRUE)
n_sims <- if (length(args) >= 1) as.integer(args[[1]]) else 1000L

daily_counts <- read_daily_counts()

# Per-wave expected pre-window counts and the Spain-wide post/pre ratio for that
# wave, taken from the reference season.
build_wave_calibration <- function(
  daily_counts,
  reference_year = 2024L,
  start_month_day = "06-01",
  every_days = 14L,
  window_days = 14L,
  n_waves = 11L
) {
  start_date <- as.Date(sprintf("%d-%s", reference_year, start_month_day))
  wave_dates <- start_date + every_days * seq(0, n_waves - 1)

  lapply(seq_along(wave_dates), function(wave_index) {
    treatment_date <- wave_dates[wave_index]
    pre_rows <- daily_counts[
      daily_counts$date >= treatment_date - window_days & daily_counts$date < treatment_date, ]
    post_rows <- daily_counts[
      daily_counts$date >= treatment_date & daily_counts$date < treatment_date + window_days, ]

    pre_totals <- aggregate(n_reports ~ unit_name, data = pre_rows, FUN = sum)
    post_totals <- aggregate(n_reports ~ unit_name, data = post_rows, FUN = sum)
    names(pre_totals)[2] <- "pre"
    names(post_totals)[2] <- "post"
    totals <- merge(pre_totals, post_totals, by = "unit_name")
    totals <- totals[order(totals$unit_name), ]

    list(
      wave = wave_index,
      treatment_date = treatment_date,
      unit_name = totals$unit_name,
      lambda_pre = totals$pre,
      post_pre_ratio = sum(totals$post) / max(sum(totals$pre), 1)
    )
  })
}

simulate_power_multiwave <- function(
  wave_calibration,
  effect,
  tau,
  n_sims = 1000L,
  alpha = 0.05,
  seed = 4242
) {
  set.seed(seed)
  arm_effects <- c(neutral = 1, prevention_focus = effect, promotion_focus = effect)
  arm_levels <- names(arm_effects)
  n_units <- length(wave_calibration[[1]]$unit_name)
  n_waves <- length(wave_calibration)

  p_prevention <- numeric(n_sims)

  for (sim_index in seq_len(n_sims)) {
    wave_frames <- lapply(wave_calibration, function(wave) {
      arm_assignment <- assign_arms_blocked(wave$lambda_pre, arm_levels)
      shock <- exp(rnorm(n_units, mean = -tau^2 / 2, sd = tau))

      pre_count <- rpois(n_units, lambda = pmax(wave$lambda_pre, 1e-8))
      post_count <- rpois(
        n_units,
        lambda = pmax(wave$lambda_pre * wave$post_pre_ratio * shock *
                        arm_effects[arm_assignment], 1e-8)
      )

      data.frame(
        wave = factor(wave$wave, levels = seq_len(n_waves)),
        arm = factor(arm_assignment, levels = arm_levels),
        log_ratio = log((post_count + 0.5) / (pre_count + 0.5))
      )
    })

    panel <- do.call(rbind, wave_frames)
    panel$arm <- relevel(panel$arm, ref = "neutral")

    model <- if (n_waves > 1) {
      lm(log_ratio ~ wave + arm, data = panel)
    } else {
      lm(log_ratio ~ arm, data = panel)
    }
    coef_test <- lmtest::coeftest(model, vcov. = sandwich::vcovHC(model, type = "HC3"),
                                  df = df.residual(model))
    p_prevention[sim_index] <- if ("armprevention_focus" %in% rownames(coef_test)) {
      coef_test["armprevention_focus", 4]
    } else {
      NA_real_
    }
  }

  data.frame(
    n_waves = n_waves,
    n_units = n_units,
    unit_waves = n_units * n_waves,
    effect = effect,
    effect_percent = 100 * (effect - 1),
    tau = tau,
    power = mean(p_prevention < alpha, na.rm = TRUE)
  )
}

suppressPackageStartupMessages({
  library(sandwich)
  library(lmtest)
})

# tau at the 14-day window used for the multi-wave option.
#
# Restricted to 2023-2024. The method-of-moments estimator is truncated at zero,
# and in 2021-2022 the 14-day windows carry so few reports that Poisson noise
# alone exceeds the observed log-ratio variance, so those years return exactly
# zero and drag a pooled estimate downward for a purely mechanical reason.
short_window_calibration <- calibrate_design(
  daily_counts = daily_counts,
  reference_year = 2024L,
  calibration_years = 2023:2024,
  pre_window_days = 14L,
  post_window_days = 14L
)
tau_short <- short_window_calibration$tau$tau_pooled
cat("tau at 14-day windows (pooled 2023-2024):", round(tau_short, 3), "\n")
print(short_window_calibration$tau$by_year, row.names = FALSE)
cat("\n")

# All configurations use a 14-day cadence with 14-day pre/post windows, so the
# post window of one wave never overlaps the pre window of the next. 11 waves is
# what fits between 1 June and 1 November. A 7-day cadence would double the
# wave count but each observation would carry roughly twice the counting noise
# and consecutive windows would overlap, so it is not evaluated here.
wave_grid <- c(1L, 6L, 11L)
effect_grid <- c(1.10, 1.15, 1.20, 1.25, 1.30, 1.40, 1.50, 1.75, 2.00)

results <- do.call(rbind, lapply(wave_grid, function(n_waves) {
  wave_calibration <- build_wave_calibration(
    daily_counts = daily_counts,
    reference_year = 2024L,
    every_days = 14L,
    window_days = 14L,
    n_waves = n_waves
  )

  do.call(rbind, lapply(seq_along(effect_grid), function(index) {
    cat("waves =", n_waves, " effect =", effect_grid[index], "\n")
    simulate_power_multiwave(
      wave_calibration = wave_calibration,
      effect = effect_grid[index],
      tau = tau_short,
      n_sims = n_sims,
      seed = 4242 + 100 * n_waves + index
    )
  }))
}))

write.csv(results, file.path(output_dir, "final_spain_wave_comparison.csv"),
          row.names = FALSE)

cat("\n=== Power by number of re-randomized waves (Spain, 50 provinces) ===\n")
print(results, row.names = FALSE)

# MDE read off the simulated power curve rather than from the large-count
# formula, which ignores counting noise and is materially optimistic at these
# window lengths.
interpolate_mde <- function(effect_percent, power, target_power = 0.80) {
  if (all(power < target_power)) return(NA_real_)
  crossing <- which(power >= target_power)[1]
  if (crossing == 1) return(effect_percent[1])
  x <- effect_percent[(crossing - 1):crossing]
  y <- power[(crossing - 1):crossing]
  x[1] + (target_power - y[1]) * diff(x) / diff(y)
}

mde <- do.call(rbind, lapply(wave_grid, function(n_waves) {
  rows <- results[results$n_waves == n_waves, ]
  rows <- rows[order(rows$effect_percent), ]
  data.frame(
    n_waves = n_waves,
    unit_waves = 50 * n_waves,
    tau = tau_short,
    mde_percent = interpolate_mde(rows$effect_percent, rows$power)
  )
}))

write.csv(mde, file.path(output_dir, "final_spain_wave_mde.csv"), row.names = FALSE)
cat("\n=== Simulated MDE (80% power) by wave count ===\n")
print(mde, row.names = FALSE)
