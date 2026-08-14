# Combined two-margin (hurdle) design over ALL Spanish municipalities.
#
# The extensive-margin design uses only municipalities that were silent in the
# pre-window; the intensive-margin design uses only those that were active. A
# real analysis would use both, which is what a hurdle or zero-inflated count
# model does: one parameter for whether a unit reports at all, another for how
# much it reports given that it does.
#
# This script simulates that design end to end and reports power for
#   - the extensive margin alone (silent municipalities, activation),
#   - the intensive margin alone (active municipalities, log ratio),
#   - the inverse-variance combination of the two.
#
# Inference is by randomization, not by a parametric hurdle GLM. A fitted
# Poisson/hurdle model was what produced this project's earlier 0.90 Type I
# error, so the combination is tested against its own randomization
# distribution and the Type I error is verified.
#
# Usage:  Rscript analysis/r/power_analysis/run_hurdle_combined_design.R [n_sims]

suppressWarnings({
  options(stringsAsFactors = FALSE)
})

output_dir <- file.path("analysis", "r", "power_analysis", "output")
args <- commandArgs(trailingOnly = TRUE)
n_sims <- if (length(args) >= 1) as.integer(args[[1]]) else 1000L

window_days <- 60L
campaign_month_day <- "08-15"
calibration_years <- 2021:2024
alpha <- 0.05
arm_levels <- c("neutral", "prevention_focus", "promotion_focus")

counts <- read.csv(file.path(output_dir, "spain_municipality_daily_counts.csv"))
counts$date <- as.Date(counts$date)
all_municipalities <- read.csv(
  file.path(output_dir, "spain_municipality_index.csv"))$unit_name

window_totals <- function(year) {
  treatment_date <- as.Date(sprintf("%d-%s", year, campaign_month_day))
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
    year = year
  )
}

panel <- do.call(rbind, lapply(calibration_years, window_totals))

# --------------------------------------------------------------------------
# Calibration targets, taken from the real data
# --------------------------------------------------------------------------

silent <- panel[panel$pre == 0, ]
active <- panel[panel$pre > 0, ]

target_activation <- mean(silent$post > 0)
target_active_sd <- summary(lm(log((active$post + 0.5) / (active$pre + 0.5)) ~
                                 factor(active$year)))$sigma
target_n_active <- round(nrow(active) / length(calibration_years))
seasonal_ratio <- sum(panel$post) / sum(panel$pre)

cat("Calibration targets from observed data (", window_days, "-day windows):\n", sep = "")
cat("  activation rate among silent municipalities:", round(target_activation, 4), "\n")
cat("  residual SD of log ratio among active municipalities:",
    round(target_active_sd, 3), "\n")
cat("  active municipalities per season:", target_n_active, "\n")
cat("  seasonal post/pre ratio:", round(seasonal_ratio, 3), "\n\n")

# --------------------------------------------------------------------------
# Data-generating process
# --------------------------------------------------------------------------
#
# Each municipality has a latent per-window reporting rate. It is estimated by
# averaging its observed window counts over the calibration seasons, with a
# floor so that municipalities which have never reported still have a small
# positive rate -- the empirical activation rate among never-reporting
# municipalities is 1.6% per season, not zero.

# The latent rate is each municipality's own observed pre-window count in the
# reference season, so the number of active municipalities is right by
# construction. Municipalities observed at zero get a floor, calibrated to
# reproduce the observed activation rate -- their true rate is small but not
# zero (1.6% of never-reporting municipalities activate in a season).
reference <- panel[panel$year == max(calibration_years), ]
reference <- reference[match(all_municipalities, reference$unit_name), ]

calibrate_floor <- function(tau, floor_grid = seq(0.002, 0.10, by = 0.002),
                            n_calibration = 15L, seed = 5) {
  errors <- vapply(floor_grid, function(floor_value) {
    set.seed(seed)
    rates <- replicate(n_calibration, {
      lambda <- pmax(reference$pre, floor_value)
      shock <- exp(rnorm(length(lambda), -tau^2 / 2, tau))
      pre <- rpois(length(lambda), lambda)
      post <- rpois(length(lambda), lambda * seasonal_ratio * shock)
      mean(post[pre == 0] > 0)
    })
    abs(mean(rates) - target_activation)
  }, numeric(1))
  floor_grid[which.min(errors)]
}

calibrate_tau <- function(floor_value, tau_grid = seq(0.3, 2.0, by = 0.1),
                          n_calibration = 15L, seed = 6) {
  errors <- vapply(tau_grid, function(tau) {
    set.seed(seed)
    sds <- replicate(n_calibration, {
      lambda <- pmax(reference$pre, floor_value)
      shock <- exp(rnorm(length(lambda), -tau^2 / 2, tau))
      pre <- rpois(length(lambda), lambda)
      post <- rpois(length(lambda), lambda * seasonal_ratio * shock)
      keep <- pre > 0
      if (sum(keep) < 20) return(NA_real_)
      sd(log((post[keep] + 0.5) / (pre[keep] + 0.5)))
    })
    abs(mean(sds, na.rm = TRUE) - target_active_sd)
  }, numeric(1))
  tau_grid[which.min(errors)]
}

tau <- 1.0
for (iteration in 1:3) {
  floor_value <- calibrate_floor(tau)
  tau <- calibrate_tau(floor_value)
}
lambda_base <- pmax(reference$pre, floor_value)

set.seed(99)
check <- replicate(20, {
  shock <- exp(rnorm(length(lambda_base), -tau^2 / 2, tau))
  pre <- rpois(length(lambda_base), lambda_base)
  post <- rpois(length(lambda_base), lambda_base * seasonal_ratio * shock)
  keep <- pre > 0
  c(activation = mean(post[pre == 0] > 0), n_active = sum(keep),
    active_sd = sd(log((post[keep] + 0.5) / (pre[keep] + 0.5))))
})

cat("Calibrated DGP: tau =", tau, ", latent-rate floor =", floor_value, "\n")
cat("  simulated activation rate:", round(mean(check["activation", ]), 4),
    " (target", round(target_activation, 4), ")\n")
cat("  simulated active-municipality SD:", round(mean(check["active_sd", ]), 3),
    " (target", round(target_active_sd, 3), ")\n")
cat("  simulated active municipalities:", round(mean(check["n_active", ])),
    " (target", target_n_active, ")\n\n")

# --------------------------------------------------------------------------
# Two-margin statistics
# --------------------------------------------------------------------------
#
# Both are put on a common LOG scale, so that under a common multiplicative
# effect m each estimates log(m) and the two can be combined directly:
#   extensive: log(activation rate treated / activation rate neutral).
#              For small p, P(>=1 report) is nearly proportional to the latent
#              rate, so this tracks log(m) with sensitivity ~0.98.
#   intensive: difference in mean log ratio.
#
# Mixing a relative-change statistic with a log statistic, or exponentiating a
# relative-change statistic, silently misstates the MDE -- both are avoided here.

margin_statistics <- function(pre, post, arm) {
  silent <- pre == 0
  active <- !silent

  activation <- as.numeric(post > 0)
  treated_rate <- mean(activation[silent & arm == "prevention_focus"])
  neutral_rate <- mean(activation[silent & arm == "neutral"])
  extensive <- if (treated_rate > 0 && neutral_rate > 0) {
    log(treated_rate / neutral_rate)
  } else {
    NA_real_
  }

  log_ratio <- log((post + 0.5) / (pre + 0.5))
  intensive <- mean(log_ratio[active & arm == "prevention_focus"]) -
    mean(log_ratio[active & arm == "neutral"])

  c(extensive = extensive, intensive = intensive)
}

simulate_once <- function(effect) {
  arm_effect <- c(neutral = 1, prevention_focus = effect, promotion_focus = effect)
  arm <- sample(rep(arm_levels, length.out = length(lambda_base)))
  shock <- exp(rnorm(length(lambda_base), -tau^2 / 2, tau))
  pre <- rpois(length(lambda_base), lambda_base)
  post <- rpois(length(lambda_base),
                lambda_base * seasonal_ratio * shock * arm_effect[arm])
  margin_statistics(pre, post, arm)
}

# Null run: gives the SE of each margin and hence the combination weights.
set.seed(2024)
null_draws <- replicate(n_sims, simulate_once(1))
null_se <- apply(null_draws, 1, sd, na.rm = TRUE)
weights <- (1 / null_se^2) / sum(1 / null_se^2)

combine <- function(statistics) sum(weights * statistics)
null_combined_se <- sd(apply(null_draws, 2, combine), na.rm = TRUE)

cat("Null standard errors (log scale):\n")
cat("  extensive margin:", round(null_se[["extensive"]], 4), "\n")
cat("  intensive margin:", round(null_se[["intensive"]], 4), "\n")
cat("  combination weights:", round(weights, 3), "\n")
cat("  combined SE:", round(null_combined_se, 4), "\n\n")

critical <- qnorm(1 - alpha / 2)

evaluate <- function(effect) {
  draws <- replicate(n_sims, simulate_once(effect))
  combined <- apply(draws, 2, combine)
  data.frame(
    effect_percent = 100 * (effect - 1),
    power_extensive = mean(abs(draws["extensive", ]) >
                             critical * null_se[["extensive"]], na.rm = TRUE),
    power_intensive = mean(abs(draws["intensive", ]) >
                             critical * null_se[["intensive"]], na.rm = TRUE),
    power_combined = mean(abs(combined) > critical * null_combined_se, na.rm = TRUE)
  )
}

set.seed(777)
results <- do.call(rbind, lapply(c(1.00, 1.10, 1.15, 1.20, 1.25, 1.30, 1.50),
                                 function(effect) {
  cat("effect =", effect, "\n")
  evaluate(effect)
}))

write.csv(results, file.path(output_dir, "hurdle_combined_power.csv"),
          row.names = FALSE)

cat("\n=== Power by margin, all", length(lambda_base), "Spanish municipalities ===\n")
cat("(the 0% row is the Type I error check)\n\n")
print(results, row.names = FALSE, digits = 3)

mde <- function(standard_error) {
  100 * (exp((qnorm(0.975) + qnorm(0.8)) * standard_error) - 1)
}
cat("\nMDE at 80% power:\n")
cat("  extensive margin alone:", sprintf("%+.0f%%", mde(null_se[["extensive"]])), "\n")
cat("  intensive margin alone:", sprintf("%+.0f%%", mde(null_se[["intensive"]])), "\n")
cat("  combined:              ", sprintf("%+.0f%%", mde(null_combined_se)), "\n")

cat("\nOutputs written to", output_dir, "\n")
