# =============================================================================
# Pre-specified secondary and exploratory analyses (pre-registration, "Other
# planned analysis"), run on the 2026 outcomes AFTER the primary analysis.
# Committed before outcome extraction (docs/operations/analysis-log-2026.md).
#
#   1. presence-attributed outcome   H1, H2   randomization inference
#   2. core subset (interior >= .25) H1, H2   randomization inference
#   4. equal-exposure estimate       H1       HC3 only (post-treatment covariate)
#   5. delivery distributions by arm            descriptive
#   7. minimum-delivery subset       H1, H2   HC3 only (post-treatment subset)
#   8. activation subgroup           H2       randomization inference
#
# Items 3 (realized multi-municipality ratio) and 6 (orientation delivery)
# are produced by prepare_outcomes_2026.R and orientation_delivery_2026.R.
#
# Randomization-inference items reuse ri_test() from the frozen primary script
# verbatim (sourced, not copied), with the same seed and permutation count, so
# the subset tests are the registered test applied to a subset.
#
# Usage:
#   Rscript analysis/r/04_results/secondary_analyses_2026.R
#     [--outcomes=path] [--delivery=path] [--subset=path] [--perms=N] [--out=path]
# =============================================================================
args <- commandArgs(trailingOnly = TRUE)
get_arg <- function(name, default) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit)) sub(paste0("^--", name, "="), "", hit[[1]]) else default
}
output_dir <- file.path("analysis", "r", "output")
outcomes_path <- get_arg("outcomes", file.path(output_dir, "outcomes_2026.csv"))
delivery_path <- get_arg("delivery", file.path("data", "google_ads",
                                                "delivery_by_location_2026-08-17_to_2026-10-14.csv"))
subset_path <- get_arg("subset", file.path(output_dir, "min_delivery_subset_2026.csv"))
results_path <- get_arg("out", file.path(output_dir, "secondary_results_2026.csv"))

# -- the registered test, sourced from the frozen script ----------------------
primary <- readLines(file.path("analysis", "r", "03_randomization", "analyse_assignment.R"))
eval(parse(text = primary[1:(grep("^# --- hypothesis wrappers", primary) - 1)]))
N_PERMUTATIONS <- as.integer(get_arg("perms", N_PERMUTATIONS))
source(file.path("analysis", "r", "04_results", "delivery_utils.R"))

assignment <- read.csv(assignment_path)
assignment <- assignment[order(assignment$block, assignment$unit_name), ]
outcomes <- read.csv(outcomes_path)
o <- outcomes[match(assignment$unit_name, outcomes$unit_name), ]
if (any(is.na(o$post_participants))) stop("outcomes file does not cover every assignment unit")
arm <- factor(assignment$arm, levels = c("framed", "neutral", "no_ad"))
block <- assignment$block
hist <- assignment$median_post_participants
post <- o$post_participants; pre <- o$pre_participants
n <- nrow(assignment)

covariates_for <- function(keep, pre_v, hist_v) {
  cbind(model.matrix(~ factor(block[keep]))[, -1, drop = FALSE],
        pre = pre_v[keep], hist = hist_v[keep])
}

# HC3 regression estimate for post-treatment analyses (no randomization test):
# singleton-block units dropped exactly as ri_test() does.
hc3_fit <- function(y, treat, covariates, blk) {
  single <- ave(seq_along(blk), blk, FUN = length) == 1
  y <- y[!single]; treat <- treat[!single]; covariates <- covariates[!single, , drop = FALSE]
  covariates <- covariates[, colSums(abs(covariates)) > 0, drop = FALSE]
  X <- cbind(treat = treat, covariates)
  fit <- lm(y ~ X)
  if (any(stats::hatvalues(fit) > 0.999)) stop("HC3 undefined after singleton removal")
  ct <- lmtest::coeftest(fit, vcov. = sandwich::vcovHC(fit, type = "HC3"))
  est <- ct["Xtreat", 1]; se <- ct["Xtreat", 2]
  data.frame(estimate = est, p_ri = NA, p_hc3 = ct["Xtreat", 4],
             ci_low = est - qnorm(0.975) * se, ci_high = est + qnorm(0.975) * se,
             n_permutations = NA, n_units = length(y), n_singleton_dropped = sum(single))
}

results <- list()
record <- function(analysis, hypothesis, r, method, control_mean) {
  r$analysis <- analysis; r$hypothesis <- hypothesis; r$method <- method
  r$control_mean <- control_mean
  r$pct_vs_control <- 100 * r$estimate / control_mean
  results[[length(results) + 1]] <<- r
  cat(sprintf("  %-4s n=%4d  est %7.3f (%+5.0f%% vs control)  p_RI %s  p_HC3 %.4f  CI [%.2f, %.2f]%s\n",
              hypothesis, r$n_units, r$estimate, r$pct_vs_control,
              if (is.na(r$p_ri)) "   --  " else sprintf("%.4f", r$p_ri), r$p_hc3, r$ci_low, r$ci_high,
              if (r$n_singleton_dropped > 0) sprintf("  [%d singleton-block units dropped]", r$n_singleton_dropped) else ""))
}
run_h1 <- function(keep, y, pre_v, hist_v, label, method = "RI") {
  k <- keep & arm != "no_ad"
  f <- if (method == "RI") ri_test(y[k], as.numeric(arm[k] == "framed"), covariates_for(k, pre_v, hist_v), block[k]) else
    hc3_fit(y[k], as.numeric(arm[k] == "framed"), covariates_for(k, pre_v, hist_v), block[k])
  record(label, "H1", f, method, mean(y[k & arm == "neutral"]))
}
run_h2 <- function(keep, y, pre_v, hist_v, label, method = "RI") {
  k <- keep
  f <- if (method == "RI") ri_test(y[k], as.numeric(arm[k] != "no_ad"), covariates_for(k, pre_v, hist_v), block[k]) else
    hc3_fit(y[k], as.numeric(arm[k] != "no_ad"), covariates_for(k, pre_v, hist_v), block[k])
  record(label, "H2", f, method, mean(y[k & arm == "no_ad"]))
}
all_units <- rep(TRUE, n)

# -- 1. presence-attributed outcome -------------------------------------------
if (!is.null(o$post_participants_presence)) {
  cat("\n=== 1. Presence-attributed outcome (tertiary) ===\n")
  hp <- if (!is.null(o$hist_participants_presence)) o$hist_participants_presence else hist
  cat(if (is.null(o$hist_participants_presence)) "  (historical median: modal, presence history not supplied)\n" else "  (historical median: presence)\n")
  run_h1(all_units, o$post_participants_presence, o$pre_participants_presence, hp, "1 presence attribution")
  run_h2(all_units, o$post_participants_presence, o$pre_participants_presence, hp, "1 presence attribution")
} else cat("\n=== 1. Presence-attributed outcome: not supplied, skipped ===\n")

# -- 2. core subset -------------------------------------------------------------
core <- assignment$core_subset %in% c(TRUE, "TRUE")
cat(sprintf("\n=== 2. Core subset: %d units with interior cell fraction >= 0.25 ===\n", sum(core)))
run_h1(core, post, pre, hist, "2 core subset")
run_h2(core, post, pre, hist, "2 core subset")

# -- delivery data (items 4, 5, 7) ----------------------------------------------
delivery <- read_delivery_by_location(delivery_path, assignment)
di <- match(assignment$unit_name, delivery$unit_name)
impressions <- delivery$impressions[di]; installs <- delivery$installs[di]; cost <- delivery$cost[di]
impressions[arm == "no_ad"] <- 0; installs[arm == "no_ad"] <- 0; cost[arm == "no_ad"] <- 0
if (any(is.na(impressions))) stop("delivery report does not cover every advertising municipality")

# -- 4. equal-exposure estimate ---------------------------------------------------
cat("\n=== 4. Equal-exposure estimate: H1 additionally adjusted for realized impressions (HC3 only) ===\n")
k <- arm != "no_ad"
cov4 <- cbind(covariates_for(k, pre, hist), impressions = impressions[k] / 1000)
record("4 equal exposure (impressions covariate)", "H1",
       hc3_fit(post[k], as.numeric(arm[k] == "framed"), cov4, block[k]), "HC3", mean(post[k & arm == "neutral"]))

# -- 5. delivery distributions by arm --------------------------------------------
cat("\n=== 5. Delivery by arm (advertising municipalities) ===\n")
q <- function(x) sprintf("mean %6.1f  median %5.0f  p10 %4.0f  p90 %6.0f  zero %3d  sd log(x>0) %.2f",
                         mean(x), median(x), quantile(x, .1), quantile(x, .9), sum(x == 0),
                         if (any(x > 0)) sd(log(x[x > 0])) else NA)
deliv <- data.frame()
for (a in c("framed", "neutral")) {
  s <- arm == a
  cat(sprintf("  %-7s impressions: %s\n", a, q(impressions[s])))
  cat(sprintf("  %-7s installs:    %s\n", a, q(installs[s])))
  cat(sprintf("  %-7s cost EUR:    total %8.2f  %s\n", a, sum(cost[s]), q(cost[s])))
  deliv <- rbind(deliv, data.frame(arm = a, n = sum(s), impressions = sum(impressions[s]), installs = sum(installs[s]),
                                   cost = sum(cost[s]), mean_installs = mean(installs[s]), median_installs = median(installs[s]),
                                   zero_install_units = sum(installs[s] == 0), sd_log_installs = sd(log(installs[s][installs[s] > 0]))))
}
write.csv(deliv, sub("\\.csv$", "_delivery_by_arm.csv", results_path), row.names = FALSE)

# -- 7. minimum-delivery subset ----------------------------------------------------
sub <- read.csv(subset_path)
inmin <- sub$in_subset[match(assignment$unit_name, sub$unit_name)] %in% c(TRUE, "TRUE")
cat(sprintf("\n=== 7. Minimum-delivery subset: %d advertising units (rule fixed before outcomes; HC3 only, no RI) ===\n", sum(inmin)))
run_h1(inmin, post, pre, hist, "7 minimum-delivery subset", method = "HC3")
cat("  (H2 on this subset compares delivered units with the no-ad arm, which has no delivery by definition;\n   reported for completeness, not as a test of H2)\n")
run_h2(inmin | arm == "no_ad", post, pre, hist, "7 minimum-delivery subset (+ no-ad arm)", method = "HC3")

# -- 8. activation subgroup ---------------------------------------------------------
zero <- assignment$median_pre_participants == 0
cat(sprintf("\n=== 8. Activation subgroup: H2 among the %d zero-baseline municipalities ===\n", sum(zero)))
run_h2(zero, post, pre, hist, "8 activation subgroup")
run_h1(zero, post, pre, hist, "8 activation subgroup (H1 for completeness)")

res <- do.call(rbind, results)
res <- res[, c("analysis", "hypothesis", "method", "n_units", "n_singleton_dropped", "estimate",
               "control_mean", "pct_vs_control", "p_ri", "p_hc3", "ci_low", "ci_high", "n_permutations")]
write.csv(res, results_path, row.names = FALSE)
cat("\nWritten to", results_path, "\n")
