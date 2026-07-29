# Does moving to participant (user) level help?
#
# Treatment is assigned at province level, so the effective sample size for
# inference is the number of provinces, not the number of users. User-level data
# can only help if it lowers the between-province variance of the province-level
# summary, per unit of sensitivity to the treatment.
#
# That last clause matters. Summaries differ in how much they move for a given
# multiplicative effect on reporting:
#
#   log(sum(post)/sum(pre))          shifts by exactly log(m)   -> sensitivity 1
#   log(mean post per cohort member) shifts by exactly log(m)   -> sensitivity 1
#   mean_i log((post_i+.5)/(pre_i+.5))                          -> sensitivity ~0.5
#   log(share of cohort still reporting)                        -> sensitivity ~0.55
#
# A summary with a small SD and a small sensitivity is no better than one with a
# large SD and a large sensitivity. Everything below is reported as a
# sensitivity-corrected minimum detectable effect so the comparison is fair.
#
# Usage:  Rscript analysis/r/power_analysis/run_user_level_comparison.R [n_sims]

suppressWarnings({
  options(stringsAsFactors = FALSE)
})

output_dir <- file.path("analysis", "r", "power_analysis", "output")
args <- commandArgs(trailingOnly = TRUE)
n_sims <- if (length(args) >= 1) as.integer(args[[1]]) else 2000L

campaign_month_day <- "08-15"
calibration_years <- 2021:2024
reference_year <- 2024L

reports <- read.csv(file.path(output_dir, "spain_user_province_reports.csv"))
reports$date <- as.Date(reports$date)

# --------------------------------------------------------------------------
# Cohort construction
# --------------------------------------------------------------------------

build_cohort <- function(year, window_days) {
  treatment_date <- as.Date(sprintf("%d-%s", year, campaign_month_day))
  if (max(reports$date) < treatment_date + window_days - 1) return(NULL)

  pre <- reports[reports$date >= treatment_date - window_days &
                   reports$date < treatment_date, ]
  post <- reports[reports$date >= treatment_date &
                    reports$date < treatment_date + window_days, ]
  if (nrow(pre) == 0) return(NULL)

  pre_table <- table(pre$user, pre$unit_name)
  cohort <- data.frame(
    user = rownames(pre_table),
    unit_name = colnames(pre_table)[max.col(pre_table, ties.method = "first")],
    pre = as.integer(rowSums(pre_table)),
    stringsAsFactors = FALSE
  )

  post_counts <- as.data.frame(table(post$user), stringsAsFactors = FALSE)
  names(post_counts) <- c("user", "post")
  cohort <- merge(cohort, post_counts, by = "user", all.x = TRUE)
  cohort$post[is.na(cohort$post)] <- 0L
  cohort$year <- year
  cohort
}

aggregate_counts <- function(year, window_days) {
  treatment_date <- as.Date(sprintf("%d-%s", year, campaign_month_day))
  if (max(reports$date) < treatment_date + window_days - 1) return(NULL)

  pre <- as.data.frame(table(
    reports$unit_name[reports$date >= treatment_date - window_days &
                        reports$date < treatment_date]))
  post <- as.data.frame(table(
    reports$unit_name[reports$date >= treatment_date &
                        reports$date < treatment_date + window_days]))
  names(pre) <- c("unit_name", "agg_pre")
  names(post) <- c("unit_name", "agg_post")

  merged <- merge(pre, post, by = "unit_name", all = TRUE)
  merged[is.na(merged)] <- 0
  merged$year <- year
  merged
}

province_summaries <- function(cohort) {
  do.call(rbind, lapply(
    split(cohort, list(cohort$unit_name, cohort$year), drop = TRUE),
    function(rows) data.frame(
      unit_name = rows$unit_name[1],
      year = rows$year[1],
      cohort_size = nrow(rows),
      mean_user_log_ratio = mean(log((rows$post + 0.5) / (rows$pre + 0.5))),
      log_retention = log(max(mean(rows$post > 0), 0.01)),
      log_cohort_ratio = log(max(sum(rows$post) / max(sum(rows$pre), 1), 0.02)),
      stringsAsFactors = FALSE
    )))
}

# --------------------------------------------------------------------------
# Sensitivity: how far does each summary move per unit of log(effect)?
# --------------------------------------------------------------------------

estimate_sensitivity <- function(cohort, n_draws = 40L, probe_effect = 1.5, seed = 8) {
  set.seed(seed)
  seasonal_ratio <- sum(cohort$post) / max(sum(cohort$pre), 1)

  summarize_draw <- function(effect) {
    draws <- replicate(n_draws, {
      simulated_post <- rpois(nrow(cohort), cohort$pre * seasonal_ratio * effect)
      c(
        mean_user_log_ratio = mean(log((simulated_post + 0.5) / (cohort$pre + 0.5))),
        log_retention = log(max(mean(simulated_post > 0), 0.01)),
        log_cohort_ratio = log(max(sum(simulated_post) / max(sum(cohort$pre), 1), 0.02))
      )
    })
    rowMeans(draws)
  }

  (summarize_draw(probe_effect) - summarize_draw(1)) / log(probe_effect)
}

# --------------------------------------------------------------------------
# Like-for-like comparison on a common province set
# --------------------------------------------------------------------------

compare_on_province_set <- function(window_days, province_counts = c(10, 15, 21, 30, 50)) {
  cohorts <- lapply(calibration_years, build_cohort, window_days = window_days)
  cohorts <- cohorts[!vapply(cohorts, is.null, logical(1))]
  cohort <- do.call(rbind, cohorts)

  panel <- province_summaries(cohort)
  panel <- merge(panel, do.call(rbind, lapply(
    calibration_years, aggregate_counts, window_days = window_days)),
    by = c("unit_name", "year"))
  panel$aggregate_log_ratio <- log((panel$agg_post + 0.5) / (panel$agg_pre + 0.5))

  sensitivity <- estimate_sensitivity(cohort)
  sensitivity[["aggregate_log_ratio"]] <- 1

  ranked <- aggregate(cohort_size ~ unit_name, panel, median)
  ranked <- ranked[order(-ranked$cohort_size), ]

  measures <- c("mean_user_log_ratio", "log_retention", "log_cohort_ratio",
                "aggregate_log_ratio")

  do.call(rbind, lapply(province_counts, function(target_n) {
    keep <- head(ranked$unit_name, target_n)
    subset_panel <- panel[panel$unit_name %in% keep, ]
    n_units <- length(unique(subset_panel$unit_name))
    if (n_units < 6) return(NULL)

    do.call(rbind, lapply(measures, function(measure) {
      residual_sd <- summary(lm(subset_panel[[measure]] ~
                                  factor(subset_panel$year)))$sigma
      contrast_se <- residual_sd * sqrt(2 / (n_units / 3))
      mde_log <- (qnorm(0.975) + qnorm(0.8)) * contrast_se / sensitivity[[measure]]

      data.frame(
        window_days = window_days,
        n_units = n_units,
        median_cohort_size = median(subset_panel$cohort_size),
        measure = measure,
        sensitivity = sensitivity[[measure]],
        residual_sd = residual_sd,
        mde_percent = 100 * (exp(mde_log) - 1)
      )
    }))
  }))
}

# --------------------------------------------------------------------------
# Direct simulation of the best configuration
# --------------------------------------------------------------------------
#
# Uses the observed province-level summaries as the noise distribution, rather
# than assuming normality, and applies the treatment as a shift of
# sensitivity * log(effect).

simulate_user_level_power <- function(window_days, target_n, measure,
                                      effect_grid, n_sims = 2000L,
                                      alpha = 0.05, seed = 31337) {
  cohorts <- lapply(calibration_years, build_cohort, window_days = window_days)
  cohort <- do.call(rbind, cohorts[!vapply(cohorts, is.null, logical(1))])
  panel <- province_summaries(cohort)
  sensitivity <- estimate_sensitivity(cohort)[[measure]]

  ranked <- aggregate(cohort_size ~ unit_name, panel, median)
  ranked <- ranked[order(-ranked$cohort_size), ]
  keep <- head(ranked$unit_name, target_n)

  subset_panel <- panel[panel$unit_name %in% keep, ]
  residuals <- residuals(lm(subset_panel[[measure]] ~ factor(subset_panel$year)))
  reference <- subset_panel[subset_panel$year == reference_year, ]
  n_units <- nrow(reference)
  arm_levels <- c("neutral", "prevention_focus", "promotion_focus")

  set.seed(seed)
  do.call(rbind, lapply(effect_grid, function(effect) {
    shift <- sensitivity * log(effect)
    p_values <- numeric(n_sims)

    for (sim_index in seq_len(n_sims)) {
      arm <- sample(rep(arm_levels, length.out = n_units), n_units)
      outcome <- sample(residuals, n_units, replace = TRUE) +
        shift * (arm != "neutral")
      frame <- data.frame(outcome = outcome,
                          arm = relevel(factor(arm, levels = arm_levels),
                                        ref = "neutral"))
      model <- lm(outcome ~ arm, data = frame)
      test <- summary(model)$coefficients
      p_values[sim_index] <- if ("armprevention_focus" %in% rownames(test)) {
        test["armprevention_focus", 4]
      } else {
        NA_real_
      }
    }

    data.frame(window_days = window_days, n_units = n_units, measure = measure,
               sensitivity = sensitivity, effect_percent = 100 * (effect - 1),
               power = mean(p_values < alpha, na.rm = TRUE))
  }))
}

# --------------------------------------------------------------------------
# Run
# --------------------------------------------------------------------------

comparison <- do.call(rbind, lapply(c(30L, 60L, 91L), compare_on_province_set))
write.csv(comparison, file.path(output_dir, "user_level_comparison.csv"),
          row.names = FALSE)

cat("=== User-level vs aggregate, same provinces, sensitivity-corrected ===\n")
cat("Cohort = users reporting in the pre-window; province = modal pre-window province.\n\n")
print(comparison[order(comparison$window_days, comparison$n_units), ],
      row.names = FALSE, digits = 3)

cat("\n=== Direct simulation, best configuration ===\n")
simulated <- simulate_user_level_power(
  window_days = 60L, target_n = 30L, measure = "mean_user_log_ratio",
  effect_grid = c(1.10, 1.25, 1.50, 1.75, 2.00), n_sims = n_sims)
write.csv(simulated, file.path(output_dir, "user_level_power.csv"), row.names = FALSE)
print(simulated, row.names = FALSE, digits = 3)

cat("\nOutputs written to", output_dir, "\n")
