# Runs the finalized power analysis for the Spain / provinces / 15 August 2026
# single-wave design and writes result tables to output/.
#
# Usage:  Rscript analysis/r/power_analysis/run_final_design_spain.R [n_sims]

suppressWarnings({
  options(stringsAsFactors = FALSE)
})

suppressPackageStartupMessages({
  library(sandwich)
  library(lmtest)
})

source(file.path("analysis", "r", "power_analysis", "power_single_wave_spain.R"))

output_dir <- file.path("analysis", "r", "power_analysis", "output")
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

args <- commandArgs(trailingOnly = TRUE)
n_sims <- if (length(args) >= 1) as.integer(args[[1]]) else 2000L

daily_counts <- read_daily_counts()

# --------------------------------------------------------------------------
# 1. Calibration
# --------------------------------------------------------------------------

calibration <- calibrate_design(
  daily_counts = daily_counts,
  reference_year = 2024L,
  calibration_years = 2021:2024,
  pre_window_days = 91L,
  post_window_days = 91L
)

cat("=== Calibration: 91-day windows around 15 August ===\n")
print(calibration$tau$by_year, row.names = FALSE)
cat("pooled tau:", round(calibration$tau$tau_pooled, 3), "\n")
cat("reference year:", calibration$reference_year,
    "| provinces:", nrow(calibration$units),
    "| expected pre total:", sum(calibration$units$lambda_pre),
    "| expected post total:", sum(calibration$units$lambda_post), "\n\n")

write.csv(
  calibration$tau$by_year,
  file.path(output_dir, "final_spain_tau_calibration.csv"),
  row.names = FALSE
)

# tau across alternative window lengths, for the record
window_grid <- do.call(rbind, lapply(c(30L, 45L, 60L, 91L), function(window_days) {
  window_calibration <- calibrate_design(
    daily_counts = daily_counts,
    reference_year = 2024L,
    calibration_years = 2021:2024,
    pre_window_days = window_days,
    post_window_days = window_days
  )
  by_year <- window_calibration$tau$by_year
  by_year$window_days <- window_days
  by_year$tau_pooled <- window_calibration$tau$tau_pooled
  by_year
}))

write.csv(
  window_grid,
  file.path(output_dir, "final_spain_tau_by_window.csv"),
  row.names = FALSE
)

cat("=== tau by window length ===\n")
print(window_grid[, c("window_days", "year", "n_units", "total_var",
                      "mean_sampling_var", "tau", "tau_pooled")], row.names = FALSE)
cat("\n")

tau_hat <- calibration$tau$tau_pooled

# --------------------------------------------------------------------------
# 2. Type I error under the null (validates the estimators)
# --------------------------------------------------------------------------

cat("=== Type I error at tau =", round(tau_hat, 3), "(all arms null) ===\n")
null_run <- simulate_power_single_wave(
  calibration = calibration,
  arm_effects = c(neutral = 1, prevention_focus = 1, promotion_focus = 1),
  tau = tau_hat,
  n_sims = n_sims,
  seed = 11111
)
null_summary <- null_run$summary
names(null_summary)[names(null_summary) == "prevention_focus_power"] <- "prevention_type1"
names(null_summary)[names(null_summary) == "promotion_focus_power"] <- "promotion_type1"
names(null_summary)[names(null_summary) == "joint_power"] <- "joint_type1"
print(null_summary[, c("estimator", "prevention_type1", "promotion_type1", "joint_type1")],
      row.names = FALSE)
cat("\n")

write.csv(
  null_summary,
  file.path(output_dir, "final_spain_type1_error.csv"),
  row.names = FALSE
)

# --------------------------------------------------------------------------
# 3. Power across effect sizes, at the stated design
# --------------------------------------------------------------------------

effect_grid <- c(1.05, 1.10, 1.20, 1.30, 1.50, 1.75, 2.00)

power_rows <- lapply(seq_along(effect_grid), function(index) {
  effect <- effect_grid[index]
  cat("Power at effect =", effect, "\n")
  run <- simulate_power_single_wave(
    calibration = calibration,
    arm_effects = c(neutral = 1, prevention_focus = effect, promotion_focus = effect),
    tau = tau_hat,
    n_sims = n_sims,
    seed = 20260815 + index
  )
  run$summary
})

power_table <- do.call(rbind, power_rows)
write.csv(
  power_table,
  file.path(output_dir, "final_spain_power_by_effect.csv"),
  row.names = FALSE
)

cat("\n=== Power by effect size (Spain, 50 provinces, single wave, 91d windows) ===\n")
print(power_table[, c("estimator", "prevention_focus_effect", "prevention_focus_power",
                      "promotion_focus_power", "joint_power")], row.names = FALSE)
cat("\n")

# --------------------------------------------------------------------------
# 4. Sensitivity of the 10% case to tau (tau = 0 reproduces the earlier result)
# --------------------------------------------------------------------------

tau_grid <- c(0, 0.2, 0.4, 0.6, tau_hat, 1.0)

tau_rows <- lapply(seq_along(tau_grid), function(index) {
  tau_value <- tau_grid[index]
  cat("Power at 10% effect, tau =", round(tau_value, 3), "\n")
  run <- simulate_power_single_wave(
    calibration = calibration,
    arm_effects = c(neutral = 1, prevention_focus = 1.10, promotion_focus = 1.10),
    tau = tau_value,
    n_sims = n_sims,
    seed = 777000 + index
  )
  run$summary
})

tau_table <- do.call(rbind, tau_rows)
write.csv(
  tau_table,
  file.path(output_dir, "final_spain_power_by_tau.csv"),
  row.names = FALSE
)

cat("\n=== Power at a 10% effect, by assumed tau ===\n")
print(tau_table[, c("estimator", "tau", "prevention_focus_power", "joint_power")],
      row.names = FALSE)
cat("\n")

# --------------------------------------------------------------------------
# 5. Minimum detectable effect
# --------------------------------------------------------------------------

mde_table <- do.call(rbind, lapply(c(0.4, 0.6, tau_hat, 1.0), function(tau_value) {
  minimum_detectable_effect(calibration, tau = tau_value, n_sims = n_sims,
                            randomization = "blocked")
}))

write.csv(
  mde_table,
  file.path(output_dir, "final_spain_mde.csv"),
  row.names = FALSE
)

cat("=== Minimum detectable effect, 80% power, one arm vs neutral ===\n")
print(mde_table[, c("weighting", "tau", "n_units", "contrast_se_log",
                    "mde_ratio", "mde_percent")], row.names = FALSE)
cat("\n")

# --------------------------------------------------------------------------
# 6. What sample size would the stated effect sizes require?
# --------------------------------------------------------------------------

requirement_table <- do.call(rbind, lapply(c(0.6, tau_hat), function(tau_value) {
  do.call(rbind, lapply(c(1.05, 1.10, 1.20, 1.50, 2.00), function(effect) {
    required_units_for_effect(effect, tau = tau_value)
  }))
}))

write.csv(
  requirement_table,
  file.path(output_dir, "final_spain_units_required.csv"),
  row.names = FALSE
)

cat("=== Areal units required for 80% power (3 arms, large-count limit) ===\n")
print(requirement_table, row.names = FALSE)

cat("\nOutputs written to", output_dir, "\n")
