# =============================================================================
# How many ad impressions per municipality do we need?
#
# This frames the design the way the campaign is actually bought. The chain is:
#
#     X impressions in a municipality
#       -> click_rate * X clicks
#       -> conversion * X people who install and generate a report
#
# where "report" is read loosely: background tracks are emitted by anyone who
# installs, so essentially every install shows up as activity in that
# municipality.
#
# The three arms all buy the SAME X impressions. What differs between them is
# the conversion rate: a regulatory-focus frame converts (1 + delta) times as
# well as the neutral frame. So the detectable signal per municipality is
#
#     conversion * delta * X
#
# which is a fixed expected COUNT increment, independent of population. That is
# a materially different model from adding a fixed probability increment to
# every adult, because it hands the same absolute boost to a village and a town.
#
# The question this answers: for a given frame advantage delta, what X gives
# 80% power, and what does that cost?
#
# IMPORTANT -- the analysis model dominates the answer. 69% of municipalities
# record ZERO reporters in the pre-window. Differencing against a baseline that
# is mostly zero destroys precision: at X = 100,000 and delta = 0.5 a
# difference-in-differences has power 0.21 while a simple comparison of
# post-period counts has 0.94. Since the arms are randomized, the pre-period is
# not needed for unbiasedness -- only as a precision covariate, and entered that
# way (log1p) it helps slightly rather than hurting. The primary analysis here
# is therefore the post-period comparison; the DiD is reported alongside for
# comparison because it is the specification one reaches for by habit.
#
# Usage:
#   Rscript analysis/r/02_power/run_impression_budget_power.R [n_sims]
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
n_sims <- if (length(args) >= 1) as.integer(args[[1]]) else 400L

ADULT_SHARE <- 0.83
ALPHA <- 0.05
ARMS <- c("neutral", "prevention_focus", "promotion_focus")

# Funnel. CONVERSION is impressions -> new reporting participants.
CONVERSION <- 1e-5          # 1 per 100,000 impressions
VCPM <- 6                   # EUR per 1,000 viewable impressions

# Frame advantage: a framed ad converts (1 + delta) times as well as neutral.
DELTA_GRID <- c(0, 0.10, 0.20, 0.30, 0.50)
# Practical ceiling on deliverable frequency over a 60-day window.
MAX_IMPRESSIONS_PER_ADULT <- 15

# Impressions per municipality.
X_GRID <- c(10e3, 25e3, 50e3, 75e3, 100e3, 150e3, 250e3)

# --- inputs ------------------------------------------------------------------

assignment <- read.csv(file.path(output_dir, "assignment_3arm_pop3k40k.csv"))
reporters <- read.csv(file.path(output_dir, "municipality_reporter_counts.csv"))

panel <- merge(assignment[, c("unit_name", "arm", "population")],
               reporters[, c("unit_name", "year", "pre_reporters", "post_reporters")],
               by = "unit_name")
panel <- panel[!is.na(panel$population), ]
panel$adults <- round(panel$population * ADULT_SHARE)
panel$p_pre <- panel$pre_reporters / panel$adults
panel$p_post <- panel$post_reporters / panel$adults

unit_order <- sort(unique(panel$unit_name))
seasons <- sort(unique(panel$year))
p_pre_matrix <- matrix(panel$p_pre[order(panel$unit_name, panel$year)],
                       nrow = length(unit_order), byrow = TRUE)
p_post_matrix <- matrix(panel$p_post[order(panel$unit_name, panel$year)],
                        nrow = length(unit_order), byrow = TRUE)
adults <- panel$adults[match(unit_order, panel$unit_name)]
arm <- factor(assignment$arm[match(unit_order, assignment$unit_name)], levels = ARMS)

cat("=== setup ===\n")
cat(sprintf("municipalities: %d | adults: %.2f M | median adults per municipality: %s\n",
            length(unit_order), sum(adults) / 1e6, format(round(median(adults)), big.mark = ",")))
cat(sprintf("baseline post-window reporters: %.1f per 100,000 adults\n",
            1e5 * mean(panel$p_post)))
cat(sprintf("assumed conversion: %.0e (1 reporter per %s impressions)\n",
            CONVERSION, format(1 / CONVERSION, big.mark = ",", scientific = FALSE)))
cat(sprintf("assumed price: EUR %.0f per 1,000 viewable impressions\n\n", VCPM))

# --- simulation --------------------------------------------------------------
#
# `allocation` controls how X is spread. "uniform" buys the same X everywhere,
# which is what the funnel arithmetic above assumes. "per_capita" buys X in
# proportion to adult population, holding impressions per head constant. The two
# differ a lot for power, because the analysis weights municipalities roughly
# equally rather than by size.

simulate_once <- function(impressions, delta, allocation = "uniform") {
  season <- sample(seq_along(seasons), length(unit_order), replace = TRUE)
  index <- cbind(seq_along(unit_order), season)
  p_pre <- p_pre_matrix[index]
  p_post <- p_post_matrix[index]

  # Uniform X everywhere, but capped at what a municipality can actually absorb.
  impressions_i <- pmin(rep(impressions, length(unit_order)),
                        adults * MAX_IMPRESSIONS_PER_ADULT)

  # Every arm runs ads; only the conversion rate differs between them.
  rate <- ifelse(arm == "neutral", CONVERSION, CONVERSION * (1 + delta))
  added <- rpois(length(unit_order), impressions_i * rate)

  data.frame(
    arm = arm, adults = adults, impressions = impressions_i,
    pre_count = rbinom(length(unit_order), adults, p_pre),
    post_count = rbinom(length(unit_order), adults, p_post) + added)
}

# PRIMARY: negative binomial on post-period counts, with the pre-period count as
# a covariate. Randomization makes this unbiased without differencing.
fit_post <- function(wide, pooled = TRUE) {
  group <- if (pooled) {
    factor(ifelse(wide$arm == "neutral", "neutral", "framed"),
           levels = c("neutral", "framed"))
  } else {
    relevel(wide$arm, ref = "neutral")
  }
  model <- tryCatch(
    MASS::glm.nb(wide$post_count ~ group + log1p(wide$pre_count)),
    error = function(e) NULL, warning = function(w) NULL)
  if (is.null(model)) return(NA_real_)
  term <- if (pooled) "groupframed" else "groupprevention_focus"
  coefficients <- summary(model)$coefficients
  if (!term %in% rownames(coefficients)) return(NA_real_)
  coefficients[term, 4]
}

# COMPARISON: the difference-in-differences specification.
fit_did <- function(wide, pooled = TRUE) {
  group <- if (pooled) {
    factor(ifelse(wide$arm == "neutral", "neutral", "framed"),
           levels = c("neutral", "framed"))
  } else {
    relevel(wide$arm, ref = "neutral")
  }
  long <- data.frame(
    unit = rep(seq_len(nrow(wide)), 2), group = rep(group, 2),
    post = rep(c(0L, 1L), each = nrow(wide)),
    count = c(wide$pre_count, wide$post_count))
  model <- tryCatch(MASS::glm.nb(count ~ post * group, data = long),
                    error = function(e) NULL, warning = function(w) NULL)
  if (is.null(model)) return(NA_real_)
  robust <- tryCatch(
    lmtest::coeftest(model, vcov. = sandwich::vcovCL(model, cluster = long$unit)),
    error = function(e) NULL)
  if (is.null(robust)) return(NA_real_)
  term <- if (pooled) "post:groupframed" else "post:groupprevention_focus"
  if (!term %in% rownames(robust)) return(NA_real_)
  robust[term, 4]
}

# --- run ---------------------------------------------------------------------

set.seed(20260815)
results <- do.call(rbind, lapply(DELTA_GRID, function(delta) {
  do.call(rbind, lapply(X_GRID, function(impressions) {
    cat(sprintf("  delta %+3.0f%%  X = %9s impressions/municipality\n",
                100 * delta, format(impressions, big.mark = ",", scientific = FALSE)))
    draws <- replicate(n_sims, {
      sim <- simulate_once(impressions, delta)
      c(post = fit_post(sim, TRUE), post_single = fit_post(sim, FALSE),
        did = fit_did(sim, TRUE))
    })
    delivered <- pmin(rep(impressions, length(unit_order)),
                      adults * MAX_IMPRESSIONS_PER_ADULT)
    data.frame(
      delta = delta,
      impressions_per_municipality = impressions,
      impressions_per_adult = impressions / median(adults),
      total_impressions = sum(delivered),
      cost_eur = sum(delivered) / 1000 * VCPM,
      power_post_pooled = mean(draws["post", ] < ALPHA, na.rm = TRUE),
      power_post_single = mean(draws["post_single", ] < ALPHA, na.rm = TRUE),
      power_did_pooled = mean(draws["did", ] < ALPHA, na.rm = TRUE))
  }))
}))

write.csv(results, file.path(output_dir, "impression_budget_power.csv"), row.names = FALSE)

cat("\n=== power, pooled framed arms vs neutral ===\n")
cat("delta = how much better a framed ad converts than the neutral ad.\n")
cat("delta = 0 rows are the Type I error check.\n\n")
cat(sprintf("%6s %12s %9s %14s %11s %9s %9s %8s\n",
            "delta", "impr/muni", "per adult", "total impr", "cost EUR",
            "post", "post 1arm", "DiD"))
for (i in seq_len(nrow(results))) {
  r <- results[i, ]
  cat(sprintf("%5.0f%% %12s %9.1f %14s %11s %9.3f %9.3f %8.3f\n",
              100 * r$delta,
              format(r$impressions_per_municipality, big.mark = ",", scientific = FALSE),
              r$impressions_per_adult,
              format(round(r$total_impressions), big.mark = "", scientific = FALSE),
              format(round(r$cost_eur, -2), big.mark = ","),
              r$power_post_pooled, r$power_post_single, r$power_did_pooled))
}

cat("\n=== impressions and budget for 80% power (post-period analysis, pooled) ===\n")
for (d in setdiff(DELTA_GRID, 0)) {
  rows <- results[results$delta == d, ]
  rows <- rows[order(rows$impressions_per_municipality), ]
  y <- rows$power_post_pooled
  if (all(y < 0.8)) {
    cat(sprintf("  delta %+3.0f%%: not reached below %s impressions per municipality\n",
                100 * d, format(max(rows$impressions_per_municipality), big.mark = ",", scientific = FALSE)))
    next
  }
  k <- which(y >= 0.8)[1]
  needed <- if (k == 1) rows$impressions_per_municipality[1] else {
    x <- rows$impressions_per_municipality[(k - 1):k]
    x[1] + (0.8 - y[k - 1]) * diff(x) / diff(y[(k - 1):k])
  }
  cost <- approx(rows$impressions_per_municipality, rows$cost_eur, needed)$y
  cat(sprintf("  delta %+3.0f%%: %s impressions per municipality -> EUR %s\n",
              100 * d, format(round(needed, -3), big.mark = ",", scientific = FALSE),
              format(round(cost, -2), big.mark = ",")))
}
cat("\nWritten to", file.path(output_dir, "impression_budget_power.csv"), "\n")
