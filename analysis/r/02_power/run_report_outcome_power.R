# =============================================================================
# Power for the SECONDARY reporting outcome, on the design as assigned.
#
# The design is powered on background-track participants; the reporting outcome
# -- distinct people submitting at least one mosquito report -- is noisier
# (log-scale residual SD 0.87-0.95 against 0.43, and 65% of municipality-seasons
# record zero reporters) but is the outcome that matters for the platform's
# purpose, so its power is stated in the pre-registration rather than left
# implicit.
#
# The extra unknown relative to the track outcome is the REPORT RATE: the share
# of ad-driven installs that go on to submit at least one report. The historical
# aggregate ratio of reporter counts to track-participant counts is about 0.68
# (2.05 / 3.00 across study municipalities) -- an aggregate ratio, not a
# per-user rate, and newly recruited users are expected to report at a lower
# rate than the established base. Power is therefore reported across a grid.
#
# Usage: Rscript analysis/r/02_power/run_report_outcome_power.R [n_sims]
# =============================================================================

suppressWarnings({
  options(stringsAsFactors = FALSE)
})

suppressPackageStartupMessages({
  library(sandwich)
  library(lmtest)
})

hc3_p <- function(fit, row = 2) {
  lmtest::coeftest(fit, vcov. = sandwich::vcovHC(fit, type = "HC3"))[row, 4]
}

output_dir <- file.path("analysis", "r", "output")
args <- commandArgs(trailingOnly = TRUE)
n_sims <- if (length(args) >= 1) as.integer(args[[1]]) else 1000L

BUDGET <- 5000
CPI <- 0.39
ALPHA <- 0.05
# Matches the tracks calibration. Seasons whose windows the report export does
# not fully cover are simply absent from the counts file, so this degrades
# gracefully with an older export.
CALIBRATION_YEARS <- 2021:2025
REPORT_RATE_GRID <- c(0.70, 0.40, 0.20, 0.10)
DELTA_GRID <- c(0, 0.15, 0.20, 0.30)

assignment <- read.csv(file.path(output_dir, "assignment_2026_final.csv"))
reporters <- read.csv(file.path(output_dir, "municipality_reporter_counts.csv"))
reporters <- reporters[reporters$unit_name %in% assignment$unit_name &
                         reporters$year %in% CALIBRATION_YEARS, ]

units <- assignment$unit_name
arm <- factor(assignment$arm, levels = c("framed", "neutral", "no_ad"))
block <- factor(assignment$block)
n_units <- length(units)
installs <- BUDGET / CPI / sum(arm != "no_ad")

historical <- aggregate(post_reporters ~ unit_name, reporters, median)
history <- historical$post_reporters[match(units, historical$unit_name)]
seasons <- sort(unique(reporters$year))
panel_key <- paste(reporters$unit_name, reporters$year)
control_level <- mean(reporters$post_reporters)

cat("=== secondary reporting outcome, design as assigned ===\n")
cat(sprintf("  mean post-window reporters per municipality: %.2f\n", control_level))
cat(sprintf("  zero-reporter municipality-seasons: %.0f%%\n",
            100 * mean(reporters$post_reporters == 0)))
cat(sprintf("  installs per ad municipality: %.1f\n\n", installs))

simulate <- function(delta, report_rate, extra = NULL) {
  season <- sample(seasons, n_units, replace = TRUE)
  index <- match(paste(units, season), panel_key)
  base_post <- reporters$post_reporters[index]
  base_pre <- reporters$pre_reporters[index]

  effect <- if (is.null(extra)) installs * report_rate else extra
  added <- ifelse(arm == "no_ad", 0,
                  effect * exp(rnorm(n_units, -0.08, 0.4)) *
                    ifelse(arm == "framed", 1 + delta, 1))
  post <- rpois(n_units, pmax(base_post + added, 1e-8))

  if (is.null(extra)) {
    ad <- arm != "no_ad"
    hc3_p(lm(post[ad] ~ factor(arm[ad], levels = c("neutral", "framed")) +
               factor(block[ad]) + base_pre[ad] + history[ad]))
  } else {
    group <- factor(ifelse(arm == "no_ad", "no_ad", "ads"),
                    levels = c("no_ad", "ads"))
    hc3_p(lm(post ~ group + block + base_pre + history))
  }
}

run <- function(delta, report_rate, extra = NULL) {
  mean(replicate(n_sims, simulate(delta, report_rate, extra)) < ALPHA,
       na.rm = TRUE)
}

set.seed(20260815)

cat("=== H1 (framed vs neutral) by report rate ===\n")
cat("   delta = 0 is the Type I error check\n\n")
cat(sprintf("%12s %12s", "report rate", "new reporters"))
for (d in DELTA_GRID) cat(sprintf(" %9s", sprintf("d=%.0f%%", 100 * d)))
cat("\n")
h1 <- list()
for (rate in REPORT_RATE_GRID) {
  cat(sprintf("%11.0f%% %12.1f", 100 * rate, installs * rate))
  for (d in DELTA_GRID) {
    power <- run(d, rate)
    cat(sprintf(" %9.3f", power))
    h1[[length(h1) + 1]] <- data.frame(report_rate = rate, delta = d, power = power)
  }
  cat("\n")
}

cat("\n=== H2 (ads vs none) minimum detectable effect ===\n\n")
cat(sprintf("%18s %16s %10s\n", "extra reporters", "% over no-ad", "power"))
h2 <- list()
for (extra in c(0, 0.5, 1.0, 1.5, 2.0, 3.0)) {
  power <- run(0, NA, extra = extra)
  cat(sprintf("%18.1f %15.0f%% %10.3f\n", extra, 100 * extra / control_level, power))
  h2[[length(h2) + 1]] <- data.frame(extra = extra,
                                     pct_over_noad = extra / control_level,
                                     power = power)
}

write.csv(do.call(rbind, h1),
          file.path(output_dir, "report_outcome_power_h1.csv"), row.names = FALSE)
write.csv(do.call(rbind, h2),
          file.path(output_dir, "report_outcome_power_h2.csv"), row.names = FALSE)
cat("\nWritten to", file.path(output_dir, "report_outcome_power_h1.csv"),
    "and _h2.csv\n")
