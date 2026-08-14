# =============================================================================
# Person-level power simulation.
#
# Deliberately simple and readable. Runs alongside run_named_municipality_power.R
# rather than replacing it; the two answer the same question by different routes,
# which is useful precisely because they can be compared.
#
# The model, in words:
#
#   1. Every adult resident of a municipality has some probability of sending a
#      report during a 60-day window. Each person sends at most one report, so a
#      municipality's count IS its number of reporters, and the count is a
#      Binomial draw from the adult population.
#   2. That probability is estimated from history: reporters / adult population,
#      separately for the pre and post window of each past season.
#   3. For 2026, each municipality inherits one historical season drawn at
#      random. This carries the real year-to-year variation in how a
#      municipality's reporting changes from the pre to the post window, which
#      is the noise the design has to beat. Fixing the probabilities at their
#      averages instead would erase that variation and overstate power badly.
#   4. Treatment adds X percentage points to the post-window probability of
#      every adult in a treated municipality.
#   5. A negative binomial regression tests the difference in differences.
#
# Usage:
#   Rscript analysis/r/02_power/run_person_level_power.R [n_sims]
# =============================================================================

suppressWarnings({
  options(stringsAsFactors = FALSE)
})

suppressPackageStartupMessages({
  library(MASS)
  library(sandwich)
  library(lmtest)
})

output_dir <- file.path("analysis", "r", "output")
args <- commandArgs(trailingOnly = TRUE)
n_sims <- if (length(args) >= 1 && !is.na(suppressWarnings(as.integer(args[[1]])))) {
  as.integer(args[[1]])
} else {
  500L
}
run_multiplicative <- any(args == "--multiplicative")

# Share of the population aged 18+. Spain-wide figure applied uniformly; INE
# publishes this by municipality and it varies (roughly 78-88%), so this is an
# approximation, not a measured input.
ADULT_SHARE <- 0.83

ALPHA <- 0.05
ARMS <- c("neutral", "prevention_focus", "promotion_focus")

# Two ways of specifying the treatment, run side by side because they are not
# the same intervention and the difference matters:
#
#   additive       adds X percentage points to every adult's probability. The
#                  same absolute increment everywhere, so in RELATIVE terms it
#                  is enormous where baseline reporting is near zero and small
#                  where it is high. This is the natural model if a fixed
#                  fraction of people who see an ad go on to report.
#
#   multiplicative multiplies each municipality's post-window probability by
#                  (1 + X). Directly comparable to the minimum detectable
#                  effects from the report-based analysis, which are all
#                  multiplicative.
#
# Baseline probabilities are of order 0.005%, so the additive grid runs in
# hundredths of a percentage point.
# The additive specification is the primary one. Grid is fine around the region
# where power crosses 80%.
ADDITIVE_GRID <- c(0, 0.001, 0.002, 0.003, 0.004, 0.005, 0.006, 0.008, 0.010)

# Multiplicative is run only with --multiplicative, for comparison against the
# report-based analysis whose MDEs are all multiplicative.
MULTIPLICATIVE_GRID <- c(0, 0.30, 0.50, 0.75, 1.00, 1.50)

# --- inputs ------------------------------------------------------------------

assignment <- read.csv(file.path(output_dir, "assignment_3arm_pop3k40k.csv"))
reporters <- read.csv(file.path(output_dir, "municipality_reporter_counts.csv"))

panel <- merge(
  assignment[, c("unit_name", "arm", "population")],
  reporters[, c("unit_name", "year", "pre_reporters", "post_reporters")],
  by = "unit_name")
panel <- panel[!is.na(panel$population), ]
panel$adults <- round(panel$population * ADULT_SHARE)

# Observed per-person probabilities, one pair per municipality-season.
panel$p_pre <- panel$pre_reporters / panel$adults
panel$p_post <- panel$post_reporters / panel$adults

units <- unique(panel$unit_name)
seasons <- sort(unique(panel$year))

cat("=== calibration ===\n")
cat(sprintf("municipalities: %d | seasons: %s | adult share assumed %.2f\n",
            length(units), paste(range(seasons), collapse = "-"), ADULT_SHARE))
cat(sprintf("total adults: %.2f M\n", sum(panel$adults[panel$year == seasons[1]]) / 1e6))
cat(sprintf("mean probability of reporting, pre window:  %.5f%%  (%.1f per 100,000 adults)\n",
            100 * mean(panel$p_pre), 1e5 * mean(panel$p_pre)))
cat(sprintf("mean probability of reporting, post window: %.5f%%  (%.1f per 100,000 adults)\n",
            100 * mean(panel$p_post), 1e5 * mean(panel$p_post)))
cat(sprintf("municipality-seasons with zero post reporters: %.0f%%\n\n",
            100 * mean(panel$post_reporters == 0)))

# Lookup tables for fast resampling: rows are municipalities, columns seasons.
p_pre_matrix <- matrix(panel$p_pre[order(panel$unit_name, panel$year)],
                       nrow = length(units), byrow = TRUE)
p_post_matrix <- matrix(panel$p_post[order(panel$unit_name, panel$year)],
                        nrow = length(units), byrow = TRUE)
unit_order <- sort(units)
adults <- panel$adults[match(unit_order, panel$unit_name)]
arm <- factor(assignment$arm[match(unit_order, assignment$unit_name)], levels = ARMS)

# --- one simulated experiment ------------------------------------------------

simulate_once <- function(effect, type = c("additive", "multiplicative")) {
  type <- match.arg(type)
  # Each municipality inherits one historical season, so the pre/post pair keeps
  # its real joint behaviour rather than an averaged-away version.
  season <- sample(seq_along(seasons), length(unit_order), replace = TRUE)
  index <- cbind(seq_along(unit_order), season)

  p_pre <- p_pre_matrix[index]
  p_post <- p_post_matrix[index]

  treated <- arm != "neutral"
  p_post_treated <- p_post
  if (type == "additive") {
    p_post_treated[treated] <- p_post[treated] + effect / 100
  } else {
    p_post_treated[treated] <- p_post[treated] * (1 + effect)
  }
  p_post_treated <- pmin(pmax(p_post_treated, 0), 1)

  data.frame(
    unit_name = rep(unit_order, 2),
    arm = rep(arm, 2),
    adults = rep(adults, 2),
    post = rep(c(0L, 1L), each = length(unit_order)),
    count = c(rbinom(length(unit_order), adults, p_pre),
              rbinom(length(unit_order), adults, p_post_treated)))
}

# --- the test ----------------------------------------------------------------
#
# Negative binomial difference in differences. The offset makes the outcome a
# rate per adult. Standard errors are clustered on municipality because each
# municipality contributes a pre and a post row.

fit_did <- function(simulated) {
  simulated$arm <- relevel(simulated$arm, ref = "neutral")
  model <- tryCatch(
    MASS::glm.nb(count ~ post * arm + offset(log(adults)), data = simulated),
    error = function(e) NULL, warning = function(w) NULL)
  if (is.null(model)) return(setNames(rep(NA_real_, 2), paste0("post:arm", ARMS[-1])))

  robust <- tryCatch(
    lmtest::coeftest(model, vcov. = sandwich::vcovCL(model, cluster = simulated$unit_name)),
    error = function(e) NULL)
  if (is.null(robust)) return(setNames(rep(NA_real_, 2), paste0("post:arm", ARMS[-1])))

  terms <- paste0("post:arm", ARMS[-1])
  setNames(vapply(terms, function(term) {
    if (term %in% rownames(robust)) robust[term, 4] else NA_real_
  }, numeric(1)), terms)
}

# --- run ---------------------------------------------------------------------

adults_per_arm <- sum(adults) / length(ARMS)

run_grid <- function(grid, type) {
  baseline <- mean(panel$p_post)
  do.call(rbind, lapply(grid, function(effect) {
    cat(sprintf("  %s effect = %s\n", type,
                if (type == "additive") paste(effect, "pp") else sprintf("%+.0f%%", 100 * effect)))
    p_values <- replicate(n_sims, fit_did(simulate_once(effect, type)))
    data.frame(
      type = type,
      effect = effect,
      extra_reporters_per_100k = if (type == "additive") 1000 * effect
                                 else 1e5 * baseline * effect,
      relative_increase = if (type == "additive") effect / 100 / baseline else effect,
      extra_reporters_per_arm = round(effect / 100 * adults_per_arm),
      power_prevention = mean(p_values[1, ] < ALPHA, na.rm = TRUE),
      power_promotion = mean(p_values[2, ] < ALPHA, na.rm = TRUE),
      converged = mean(!is.na(p_values[1, ])))
  }))
}

set.seed(20260815)
results <- run_grid(ADDITIVE_GRID, "additive")
if (run_multiplicative) {
  results <- rbind(results, run_grid(MULTIPLICATIVE_GRID, "multiplicative"))
}

write.csv(results, file.path(output_dir, "person_level_power.csv"), row.names = FALSE)

cat("\n=== power: negative binomial difference in differences, one arm vs neutral ===\n")
cat("Treatment adds a flat probability increment to every adult in a treated arm.\n")
cat("The effect = 0 row is the Type I error check; it should land near 0.05.\n\n")

add <- results[results$type == "additive", ]
cat(sprintf("%10s %12s %14s %12s %11s %11s\n",
            "effect pp", "per 100k", "extra people", "vs baseline", "prevention", "promotion"))
for (i in seq_len(nrow(add))) {
  cat(sprintf("%10.3f %12.1f %14s %11.0f%% %11.3f %11.3f\n",
              add$effect[i], add$extra_reporters_per_100k[i],
              format(add$extra_reporters_per_arm[i], big.mark = ","),
              100 * add$relative_increase[i],
              add$power_prevention[i], add$power_promotion[i]))
}

crossing <- function(x, y, target = 0.80) {
  if (all(y < target)) return(NA_real_)
  k <- which(y >= target)[1]
  if (k == 1) return(x[1])
  x[k - 1] + (target - y[k - 1]) * diff(x[(k - 1):k]) / diff(y[(k - 1):k])
}
mde_prev <- crossing(add$effect, add$power_prevention)
cat(sprintf("\n80%% power at about %.4f percentage points", mde_prev))
cat(sprintf(" = %.1f extra reporters per 100,000 adults", 1000 * mde_prev))
cat(sprintf("\n   = about %s additional people reporting across a treated arm",
            format(round(mde_prev / 100 * adults_per_arm), big.mark = ",")))
cat(sprintf("\n   = %.0f%% above the observed post-window baseline\n",
            100 * mde_prev / 100 / mean(panel$p_post)))

if (run_multiplicative) {
  cat("\n--- multiplicative, for comparison with the report-based analysis ---\n")
  print(results[results$type == "multiplicative",
                c("effect", "extra_reporters_per_100k", "power_prevention", "power_promotion")],
        row.names = FALSE, digits = 3)
}
cat("\nWritten to", file.path(output_dir, "person_level_power.csv"), "\n")
