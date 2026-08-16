# =============================================================================
# Sensitivity of H1 power to the delivery-noise model: independent vs zero-sum
#
# run_final_2026_power.R draws each municipality's delivered installs with
# independent lognormal noise. In reality each of the 20 campaigns has a fixed
# budget, so delivery is zero-sum WITHIN a campaign: an over-delivering
# municipality takes installs from its 41 campaign-mates. This script re-runs
# the H1 simulation under that constraint -- lognormal weights renormalised so
# every campaign delivers exactly its planned total -- and reports Type I error
# and power alongside the independent-noise model, on the committed assignment
# and the same historical resampling.
#
# Usage: Rscript analysis/r/02_power/run_zerosum_sensitivity.R [n_sims]
# Writes analysis/r/output/zerosum_sensitivity.csv
# =============================================================================
suppressPackageStartupMessages({ library(sandwich); library(lmtest) })
args <- commandArgs(trailingOnly = TRUE)
n_sims <- if (length(args) >= 1) as.integer(args[[1]]) else 1000L
ALPHA <- 0.05; BUDGET <- 5000; CPI <- 0.39; CALIBRATION_YEARS <- 2021:2025
output_dir <- file.path("analysis", "r", "output")

assignment <- read.csv(file.path(output_dir, "assignment_2026_final.csv"))
participants <- read.csv(file.path("data", "raw",
                                   "participants_spain_municipality_aug_windows.csv"))
participants$outcome <- participants[["n_participants"]]
participants <- participants[participants$window_complete %in% c(TRUE, "TRUE") &
                               participants$year %in% CALIBRATION_YEARS, ]
participants$unit_name <- paste(participants$NAME_4, participants$NAME_2, sep = ", ")
before <- participants[participants$period == "before", c("unit_name", "year", "outcome")]
after <- participants[participants$period == "after", c("unit_name", "year", "outcome")]
panel <- merge(before, after, by = c("unit_name", "year"), suffixes = c(".pre", ".post"))
panel <- panel[panel$unit_name %in% assignment$unit_name, ]

units <- assignment$unit_name
arm <- factor(assignment$arm, levels = c("framed", "neutral", "no_ad"))
history <- assignment$median_post_participants
block <- factor(assignment$block)
campaign <- assignment$campaign
n_units <- length(units)
installs_per_unit <- BUDGET / CPI / sum(arm != "no_ad")
seasons <- sort(unique(panel$year)); panel_key <- paste(panel$unit_name, panel$year)
ad <- arm != "no_ad"

hc3_p <- function(fit) {
  if (any(stats::hatvalues(fit) > 0.999)) stop("HC3 undefined")
  lmtest::coeftest(fit, vcov. = sandwich::vcovHC(fit, type = "HC3"))[2, 4]
}

simulate_h1 <- function(delta, sigma_c, zerosum) {
  season <- sample(seasons, n_units, replace = TRUE)
  index <- match(paste(units, season), panel_key)
  base_post <- panel$outcome.post[index]; base_pre <- panel$outcome.pre[index]
  noise <- exp(rnorm(n_units, -sigma_c^2 / 2, sigma_c))
  if (zerosum) {
    # renormalise within campaign so each campaign delivers exactly its plan
    scale <- ave(noise * ad, campaign, FUN = function(w) if (sum(w) > 0) sum(w > 0) / sum(w) else 0)
    noise <- noise * scale
  }
  generated <- ifelse(ad, installs_per_unit * noise * ifelse(arm == "framed", 1 + delta, 1), 0)
  post <- rpois(n_units, pmax(base_post + generated, 1e-8))
  hc3_p(lm(post[ad] ~ factor(arm[ad], levels = c("neutral", "framed")) +
             factor(block[ad]) + base_pre[ad] + history[ad]))
}

set.seed(20260815)
grid <- expand.grid(model = c("independent", "zerosum"), sigma_c = c(0.4, 0.6),
                    delta = c(0, 0.15, 0.20), stringsAsFactors = FALSE)
grid$power <- NA_real_
cat("=== H1: independent vs zero-sum (fixed campaign total) delivery ===\n")
for (i in seq_len(nrow(grid))) {
  p <- replicate(n_sims, simulate_h1(grid$delta[i], grid$sigma_c[i], grid$model[i] == "zerosum"))
  if (anyNA(p)) stop("undefined p-value")
  grid$power[i] <- mean(p < ALPHA)
  cat(sprintf("  %-12s sigma_c %.1f  delta %3.0f%%  %s %.3f\n", grid$model[i], grid$sigma_c[i],
              100 * grid$delta[i], if (grid$delta[i] == 0) "Type I" else "power ", grid$power[i]))
}
write.csv(grid, file.path(output_dir, "zerosum_sensitivity.csv"), row.names = FALSE)
cat("Written to analysis/r/output/zerosum_sensitivity.csv\n")
