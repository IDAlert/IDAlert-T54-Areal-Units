# =============================================================================
# Power for the design as actually assigned, read from assignment_2026_final.csv.
#
# Model: each municipality's 2026 pre/post participant counts are drawn by
# resampling one of its observed historical seasons, so the real year-to-year
# variation is carried rather than averaged away. The campaign adds installs
# drawn with unit-level delivery noise. Analysis is a linear model on
# post-window participant counts -- chosen because it is structurally immune to
# the concentration artefact that inflates Type I error on the log scale when
# delivery spread differs between arms.
#
# Four things this script reports that the earlier version did not:
#
#   1. Type I error CONDITIONAL on the realised draw, not averaged over fresh
#      randomisations. The two came apart badly once (0.216 against 0.064 for
#      H2) and only the conditional number describes the experiment being run.
#   2. H2 as a minimum detectable effect in percent, not as "power 1.00". The
#      assumed effect is roughly +1300% over the no-ad arm, so of course power
#      saturates; the honest quantity is the smallest effect H2 could catch.
#   3. Sensitivity to LEAKAGE -- ad-induced participants recorded outside the
#      municipality that was targeted, whether because people move or because
#      the 0.025 degree masking grid blurs boundaries.
#   4. Power on the pre-specified core subset (least grid contamination).
#
# Grid-masking measurement NOISE needs no modelling here: the historical counts
# were built with the same masking, so it is already inside the observed
# unit-level variation being resampled. Only leakage of the treatment SIGNAL is
# a separate phenomenon, and that is what LAMBDA_GRID covers.
#
# Usage: Rscript analysis/r/02_power/run_final_2026_power.R [n_sims]
# =============================================================================

suppressWarnings({
  options(stringsAsFactors = FALSE)
})

suppressPackageStartupMessages({
  library(sandwich)
  library(lmtest)
})

# HC3 rather than the ordinary t-test: on skewed counts with unequal arms the
# t approximation has been anti-conservative (0.098 on one earlier draw). The
# pre-registered PRIMARY test is randomisation inference, exact by construction
# over the randomisation distribution; HC3 is what the simulation uses because
# it is cheap enough to run tens of thousands of times.
#
# Guard: HC3 divides by (1 - h_i)^2 and returns NaN when a unit's hat value is
# 1 -- which happens whenever a block dummy isolates a single unit, e.g. in the
# core-subset analysis. Fall back to HC1 for those fits.
hc3_p <- function(fit, row = 2) {
  h <- stats::hatvalues(fit)
  type <- if (any(h > 0.999)) "HC1" else "HC3"
  lmtest::coeftest(fit, vcov. = sandwich::vcovHC(fit, type = type))[row, 4]
}

output_dir <- file.path("analysis", "r", "output")
args <- commandArgs(trailingOnly = TRUE)
n_sims <- if (length(args) >= 1) as.integer(args[[1]]) else 1000L

BUDGET <- 5000
CPI <- 0.39
ALPHA <- 0.05
CALIBRATION_YEARS <- 2021:2025

DELTA_GRID <- c(0, 0.05, 0.10, 0.15, 0.20, 0.30)
SIGMA_GRID <- c(0.3, 0.4, 0.6)
LAMBDA_GRID <- c(0, 0.15, 0.30)     # share of induced participants misplaced
LEAK_DECAY_KM <- 3                  # exponential decay of leakage with distance
LEAK_MAX_KM <- 10

assignment <- read.csv(file.path(output_dir, "assignment_2026_final.csv"))
participants <- read.csv(file.path("data", "raw",
                                   "participants_spain_municipality_aug_windows.csv"))

outcome_column <- "n_participants"   # attribution verified by the assignment script
participants$outcome <- participants[[outcome_column]]
participants <- participants[participants$window_complete %in% c(TRUE, "TRUE"), ]
participants$unit_name <- paste(participants$NAME_4, participants$NAME_2, sep = ", ")
participants <- participants[participants$year %in% CALIBRATION_YEARS, ]

before <- participants[participants$period == "before",
                       c("unit_name", "year", "outcome")]
after <- participants[participants$period == "after",
                      c("unit_name", "year", "outcome")]
panel <- merge(before, after, by = c("unit_name", "year"),
               suffixes = c(".pre", ".post"))
panel <- panel[panel$unit_name %in% assignment$unit_name, ]

units <- assignment$unit_name
arm <- factor(assignment$arm, levels = c("framed", "neutral", "no_ad"))
history <- assignment$median_post_participants
block <- factor(assignment$block)
core <- assignment$core_subset %in% c(TRUE, "TRUE")
n_units <- length(units)
n_ad_units <- sum(arm != "no_ad")
installs_per_unit <- BUDGET / CPI / n_ad_units
seasons <- sort(unique(panel$year))
panel_key <- paste(panel$unit_name, panel$year)

# Level of the no-ad arm: the denominator for expressing H2 as a percentage.
control_level <- mean(panel$outcome.post)

cat("=== design as assigned ===\n")
cat(sprintf("  outcome column: %s\n", outcome_column))
cat(sprintf("  units %d | framed %d, neutral %d, no-ad %d\n", n_units,
            sum(arm == "framed"), sum(arm == "neutral"), sum(arm == "no_ad")))
cat(sprintf("  budget EUR %s at EUR %.2f per install -> %.1f installs per ad unit\n",
            format(BUDGET, big.mark = ","), CPI, installs_per_unit))
cat(sprintf("  median baseline post-window participants: %.1f (mean %.2f)\n",
            median(assignment$median_post_participants), control_level))
cat(sprintf("  core subset (low grid contamination): %d units\n\n", sum(core)))

# --- leakage kernel ----------------------------------------------------------
#
# Row i distributes its leaked participants over nearby units with weight
# exp(-d/LEAK_DECAY_KM). Study municipalities cover a meaningful share of Spain,
# so much of the leakage lands back INSIDE the study; retained_share captures
# how much stays inside it.

neighbour_path <- file.path(output_dir, "municipality_neighbour_distances.csv")
kernel <- matrix(0, n_units, n_units)
retained_share <- rep(0, n_units)
if (file.exists(neighbour_path)) {
  nb <- read.csv(neighbour_path)
  nb <- nb[nb$unit_name %in% units & nb$neighbour_name %in% units &
             nb$distance_km <= LEAK_MAX_KM, ]
  i <- match(nb$unit_name, units)
  j <- match(nb$neighbour_name, units)
  kernel[cbind(i, j)] <- exp(-nb$distance_km / LEAK_DECAY_KM)
  gross <- rowSums(kernel)
  retained_share <- gross / (1 + gross)
  kernel <- kernel / pmax(gross, 1e-9)
} else {
  warning("Neighbour distances not found; leakage rows will show no contamination.")
}

# --- simulation --------------------------------------------------------------

simulate <- function(delta, sigma_c, track_rate = 1, lambda = 0, subset = NULL) {
  season <- sample(seasons, n_units, replace = TRUE)
  index <- match(paste(units, season), panel_key)
  base_post <- panel$outcome.post[index]
  base_pre <- panel$outcome.pre[index]

  generated <- installs_per_unit * track_rate *
    exp(rnorm(n_units, -sigma_c^2 / 2, sigma_c))
  generated <- ifelse(arm == "no_ad", 0,
                      generated * ifelse(arm == "framed", 1 + delta, 1))

  kept <- generated * (1 - lambda)
  moved <- as.vector(t(kernel) %*% (generated * lambda * retained_share))
  post <- rpois(n_units, pmax(base_post + kept + moved, 1e-8))

  keep <- if (is.null(subset)) rep(TRUE, n_units) else subset
  ad <- keep & arm != "no_ad"
  fit_framing <- lm(post[ad] ~ factor(arm[ad], levels = c("neutral", "framed")) +
                      factor(block[ad]) + base_pre[ad] + history[ad])
  group <- factor(ifelse(arm[keep] == "no_ad", "no_ad", "ads"),
                  levels = c("no_ad", "ads"))
  fit_ads <- lm(post[keep] ~ group + factor(block[keep]) + base_pre[keep] +
                  history[keep])
  c(framing = hc3_p(fit_framing), ads = hc3_p(fit_ads))
}

run <- function(delta, sigma_c, track_rate = 1, lambda = 0, subset = NULL,
                sims = n_sims) {
  draws <- replicate(sims, simulate(delta, sigma_c, track_rate, lambda, subset))
  c(framing = mean(draws["framing", ] < ALPHA, na.rm = TRUE),
    ads = mean(draws["ads", ] < ALPHA, na.rm = TRUE))
}

# H2's effect is an absolute number of extra participants per municipality, not
# a multiple of the framing effect, so it needs its own simulator.
simulate_h2 <- function(extra, sigma_c) {
  season <- sample(seasons, n_units, replace = TRUE)
  index <- match(paste(units, season), panel_key)
  base_post <- panel$outcome.post[index]
  base_pre <- panel$outcome.pre[index]
  added <- ifelse(arm == "no_ad", 0,
                  extra * exp(rnorm(n_units, -sigma_c^2 / 2, sigma_c)))
  post <- rpois(n_units, pmax(base_post + added, 1e-8))
  group <- factor(ifelse(arm == "no_ad", "no_ad", "ads"), levels = c("no_ad", "ads"))
  hc3_p(lm(post ~ group + block + base_pre + history))
}

set.seed(20260815)

# --- 1. Type I error on the realised draw ------------------------------------

cat("=== Type I error, conditional on the realised assignment ===\n")
cat("   this is the rate for THIS draw, not averaged over fresh randomisations\n")
cat("   H1 null: both ad arms get installs, framing advantage zero\n")
cat("   H2 null: NO arm gets installs -- delivering them and then testing ads\n")
cat("            against no-ad is H2's alternative, and returns 1.000\n\n")
for (sc in SIGMA_GRID) {
  h1_null <- run(0, sc)["framing"]
  h2_null <- mean(replicate(n_sims, simulate_h2(0, sc)) < ALPHA, na.rm = TRUE)
  cat(sprintf("  sigma_c %.1f:  H1 %.3f   H2 %.3f\n", sc, h1_null, h2_null))
}

# --- 2. H1 power -------------------------------------------------------------

cat("\n=== H1: framing effect, by delivery spread ===\n")
cat("   delta is the conversion advantage of the framed creative;\n")
cat("   'obs diff' is the resulting percentage difference in participants\n\n")
cat(sprintf("%8s %10s %12s %12s\n", "delta", "obs diff", "sigma_c", "power"))
h1_results <- list()
for (sc in SIGMA_GRID) {
  for (d in DELTA_GRID) {
    r <- run(d, sc)
    observed <- installs_per_unit * d / (control_level + installs_per_unit)
    cat(sprintf("%7.0f%% %9.0f%% %12.1f %12.3f\n", 100 * d, 100 * observed, sc,
                r["framing"]))
    h1_results[[length(h1_results) + 1]] <- data.frame(
      delta = d, sigma_c = sc, observed_diff = observed, power = r["framing"])
  }
  cat("\n")
}

# --- 3. H2 minimum detectable effect -----------------------------------------

cat("=== H2: advertising vs no advertising, as a percentage ===\n")
cat(sprintf("   expressed against the no-ad arm level of %.2f participants\n", control_level))
cat("   NOTE the denominators differ from H1: H1's percentage is measured\n")
cat("   against a municipality that already has ads. Do not compare directly.\n\n")
cat(sprintf("%16s %18s %10s\n", "extra per muni", "% over no-ad", "power"))
extra_grid <- c(0, 0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 5.0, installs_per_unit)
h2_results <- list()
for (extra in extra_grid) {
  power <- mean(replicate(n_sims, simulate_h2(extra, 0.4)) < ALPHA, na.rm = TRUE)
  cat(sprintf("%16.1f %17.0f%% %10.3f\n", extra, 100 * extra / control_level, power))
  h2_results[[length(h2_results) + 1]] <- data.frame(
    extra = extra, pct = extra / control_level, power = power)
}
h2 <- do.call(rbind, h2_results)
h2 <- h2[order(h2$extra), ]
if (any(h2$power >= 0.80)) {
  k <- which(h2$power >= 0.80)[1]
  mde <- if (k == 1) h2$extra[1] else {
    x <- h2$extra[(k - 1):k]
    x[1] + (0.80 - h2$power[k - 1]) * diff(x) / diff(h2$power[(k - 1):k])
  }
  cat(sprintf("\n  H2 minimum detectable effect at 80%% power: %.1f extra participants",
              mde))
  cat(sprintf(" = +%.0f%% over the no-ad arm\n", 100 * mde / control_level))
}

# --- 4. Leakage sensitivity --------------------------------------------------

cat("\n=== sensitivity to leakage ===\n")
cat("   lambda = share of ad-induced participants recorded outside the\n")
cat("   municipality that was targeted, from mobility or grid blurring.\n")
cat(sprintf("   Measured multi-municipality ratio since 2021 is about 1.20.\n\n"))
cat(sprintf("%10s %14s %14s\n", "lambda", "H1 at 15%", "Type I"))
for (lam in LAMBDA_GRID) {
  r <- run(0.15, 0.4, lambda = lam)
  r0 <- run(0, 0.4, lambda = lam)
  cat(sprintf("%9.2f %14.3f %14.3f\n", lam, r["framing"], r0["framing"]))
}

# --- 5. Core subset ----------------------------------------------------------

if (sum(core) > 20) {
  cat("\n=== pre-specified core subset (least grid contamination) ===\n")
  cat(sprintf("   %d of %d units, interior cell fraction >= 0.25\n\n", sum(core), n_units))
  cat(sprintf("%8s %14s %14s\n", "delta", "full sample", "core subset"))
  for (d in c(0, 0.15, 0.20)) {
    full <- run(d, 0.4)
    sub <- run(d, 0.4, subset = core)
    cat(sprintf("%7.0f%% %14.3f %14.3f\n", 100 * d, full["framing"], sub["framing"]))
  }
}

# --- 6. Track emission -------------------------------------------------------

cat("\n=== if only a fraction of installs ever emit a background track ===\n")
cat(sprintf("%14s %14s %14s\n", "track rate", "H1 at 15%", "H2"))
for (tr in c(1, 0.5, 0.3, 0.15)) {
  r <- run(0.15, 0.4, track_rate = tr)
  cat(sprintf("%13.0f%% %14.3f %14.3f\n", 100 * tr, r["framing"], r["ads"]))
}

results <- do.call(rbind, h1_results)
write.csv(results, file.path(output_dir, "final_2026_power.csv"), row.names = FALSE)
write.csv(h2, file.path(output_dir, "final_2026_power_h2.csv"), row.names = FALSE)
cat("\nWritten to", file.path(output_dir, "final_2026_power.csv"), "\n")
