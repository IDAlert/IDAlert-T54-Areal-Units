# Compare candidate outcome measures and country sets for the single-wave
# 15 August 2026 design.
#
# Answers three questions:
#   (a) does restricting to a report type (bite only, albopictus only) help?
#   (b) does a sampling-effort / participation measure help?
#   (c) does adding Greece back help?
#
# The decisive quantity in every case is the number of *informative* areal units
# times the residual SD of their log(post/pre). Restricting to a narrower report
# type lowers the SD only by turning units into structural zeros, which look
# stable but cannot respond to treatment. Those units are excluded here.
#
# Usage:  Rscript analysis/r/power_analysis/run_outcome_comparison.R [n_sims]

suppressWarnings({
  options(stringsAsFactors = FALSE)
})

suppressPackageStartupMessages({
  library(sandwich)
  library(lmtest)
})

output_dir <- file.path("analysis", "r", "power_analysis", "output")
args <- commandArgs(trailingOnly = TRUE)
n_sims <- if (length(args) >= 1) as.integer(args[[1]]) else 1000L

campaign_month_day <- "08-15"
window_days <- 91L
calibration_years <- 2021:2025
reference_year <- 2025L
# A unit is "informative" if its typical pre-window baseline is big enough that
# a multiplicative treatment effect could actually show up in it. Units at or
# near zero have a log-ratio pinned at 0 under both the null and the
# alternative: they add to n without adding signal, and including them makes a
# narrow outcome look deceptively stable.
#
# The threshold is per outcome because SE / SE_expected are on a probability
# scale, not a count scale, and a shared count threshold would wrongly discard
# most provinces for those measures.
informative_threshold <- c(
  n_participants = 5,
  SE_expected = 1,
  SE = 1,
  n_reports_albopictus = 5,
  n_reporters_albopictus = 5,
  n_reports_bite = 5,
  n_reporters_bite = 5
)
default_informative_threshold <- 5

# The offset added inside log((post + c) / (pre + c)) must be on the same scale
# as the outcome. Using the count offset of 0.5 on SE / SE_expected, whose
# province-window values run from about 0.3 to 60, shrinks the log ratio for
# small units and understates the variance -- the same class of artifact as
# counting structural zeros as informative units.
log_offset <- c(
  n_participants = 0.5,
  SE_expected = 0.05,
  SE = 0.05,
  n_reports_albopictus = 0.5,
  n_reporters_albopictus = 0.5,
  n_reports_bite = 0.5,
  n_reporters_bite = 0.5
)
default_log_offset <- 0.5

# The method-of-moments split of variance into Poisson counting noise and
# unit-level heterogeneity only makes sense for integer counts.
count_outcomes <- c(
  "n_participants", "n_reports_albopictus", "n_reporters_albopictus",
  "n_reports_bite", "n_reporters_bite"
)

candidate_outcomes <- c(
  "n_participants",
  "SE_expected",
  "n_reports_albopictus",
  "n_reporters_albopictus",
  "n_reports_bite",
  "n_reporters_bite"
)

# --------------------------------------------------------------------------
# Window panel
# --------------------------------------------------------------------------

build_window_panel <- function(panel_csv, country_label) {
  panel <- read.csv(panel_csv)
  panel$date <- as.Date(panel$date)
  present <- intersect(candidate_outcomes, names(panel))

  rows <- lapply(calibration_years, function(year) {
    treatment_date <- as.Date(sprintf("%d-%s", year, campaign_month_day))
    if (max(panel$date) < treatment_date + window_days - 1) return(NULL)

    pre <- panel[panel$date >= treatment_date - window_days & panel$date < treatment_date, ]
    post <- panel[panel$date >= treatment_date & panel$date < treatment_date + window_days, ]

    pre_totals <- aggregate(pre[present], list(unit_name = pre$unit_name), sum)
    post_totals <- aggregate(post[present], list(unit_name = post$unit_name), sum)
    merged <- merge(pre_totals, post_totals, by = "unit_name",
                    suffixes = c(".pre", ".post"))
    merged$year <- year
    merged$country <- country_label
    merged
  })

  do.call(rbind, rows[!vapply(rows, is.null, logical(1))])
}

# Units whose typical pre-window baseline is large enough to carry information.
informative_units <- function(window_panel, outcome) {
  threshold <- if (outcome %in% names(informative_threshold)) {
    informative_threshold[[outcome]]
  } else {
    default_informative_threshold
  }

  baseline <- window_panel[[paste0(outcome, ".pre")]]
  by_unit <- aggregate(list(median_baseline = baseline),
                       list(unit_name = window_panel$unit_name), median)
  by_unit$unit_name[by_unit$median_baseline >= threshold]
}

# Residual SD of the log ratio after removing year and country effects, plus a
# method-of-moments split into counting noise and unit-level heterogeneity.
summarize_outcome <- function(window_panel, outcome) {
  keep <- informative_units(window_panel, outcome)
  subset_panel <- window_panel[window_panel$unit_name %in% keep, ]
  n_eff <- length(keep)

  if (n_eff < 6) {
    return(data.frame(
      n_units = length(unique(window_panel$unit_name)), n_informative = n_eff,
      residual_sd = NA_real_, tau = NA_real_, mde_percent_approx = NA_real_
    ))
  }

  offset <- if (outcome %in% names(log_offset)) {
    log_offset[[outcome]]
  } else {
    default_log_offset
  }

  pre <- subset_panel[[paste0(outcome, ".pre")]]
  post <- subset_panel[[paste0(outcome, ".post")]]
  log_ratio <- log((post + offset) / (pre + offset))

  model <- if (length(unique(subset_panel$country)) > 1) {
    lm(log_ratio ~ factor(subset_panel$year) + subset_panel$country)
  } else {
    lm(log_ratio ~ factor(subset_panel$year))
  }
  residual_sd <- summary(model)$sigma

  tau <- if (outcome %in% count_outcomes) {
    sampling_var <- mean(1 / (pre + offset) + 1 / (post + offset))
    sqrt(max(0, residual_sd^2 - sampling_var))
  } else {
    NA_real_
  }

  contrast_se <- residual_sd * sqrt(2 / (n_eff / 3))

  data.frame(
    n_units = length(unique(window_panel$unit_name)),
    n_informative = n_eff,
    residual_sd = residual_sd,
    tau = tau,
    mde_percent_approx = 100 * (exp((qnorm(0.975) + qnorm(0.8)) * contrast_se) - 1)
  )
}

# --------------------------------------------------------------------------
# Simulation check for a chosen configuration
# --------------------------------------------------------------------------

simulate_configuration <- function(window_panel, outcome, effect_grid,
                                   n_sims = 1000L, alpha = 0.05, seed = 606) {
  keep <- informative_units(window_panel, outcome)
  subset_panel <- window_panel[window_panel$unit_name %in% keep, ]
  reference <- subset_panel[subset_panel$year == reference_year, ]
  if (nrow(reference) < 6) return(NULL)

  summary_stats <- summarize_outcome(window_panel, outcome)
  tau <- summary_stats$tau

  units <- data.frame(
    unit_name = reference$unit_name,
    country = reference$country,
    lambda_pre = pmax(reference[[paste0(outcome, ".pre")]], 0.5)
  )

  # Country-specific seasonal ratio, so between-country differences are not
  # charged to the province shock.
  ratio_by_country <- tapply(
    seq_len(nrow(reference)),
    reference$country,
    function(index) {
      sum(reference[[paste0(outcome, ".post")]][index]) /
        max(sum(reference[[paste0(outcome, ".pre")]][index]), 1)
    }
  )
  units$ratio <- as.numeric(ratio_by_country[units$country])

  arm_levels <- c("neutral", "prevention_focus", "promotion_focus")
  n_units <- nrow(units)

  # Blocked within country by baseline volume.
  assign_arms <- function() {
    assignment <- character(n_units)
    for (country_name in unique(units$country)) {
      index <- which(units$country == country_name)
      ordered_index <- index[order(units$lambda_pre[index], decreasing = TRUE)]
      for (block_start in seq(1, length(ordered_index), by = 3)) {
        block <- ordered_index[block_start:min(block_start + 2, length(ordered_index))]
        assignment[block] <- sample(arm_levels, length(block), replace = FALSE)
      }
    }
    assignment
  }

  set.seed(seed)
  do.call(rbind, lapply(effect_grid, function(effect) {
    arm_effects <- c(neutral = 1, prevention_focus = effect, promotion_focus = effect)
    p_values <- numeric(n_sims)

    for (sim_index in seq_len(n_sims)) {
      arm_assignment <- assign_arms()
      shock <- exp(rnorm(n_units, mean = -tau^2 / 2, sd = tau))
      pre_count <- rpois(n_units, lambda = units$lambda_pre)
      post_count <- rpois(
        n_units,
        lambda = pmax(units$lambda_pre * units$ratio * shock *
                        arm_effects[arm_assignment], 1e-8)
      )

      frame <- data.frame(
        log_ratio = log((post_count + 0.5) / (pre_count + 0.5)),
        arm = relevel(factor(arm_assignment, levels = arm_levels), ref = "neutral"),
        country = units$country
      )
      model <- if (length(unique(frame$country)) > 1) {
        lm(log_ratio ~ country + arm, data = frame)
      } else {
        lm(log_ratio ~ arm, data = frame)
      }
      test <- lmtest::coeftest(model, vcov. = sandwich::vcovHC(model, type = "HC3"),
                               df = df.residual(model))
      p_values[sim_index] <- test["armprevention_focus", 4]
    }

    data.frame(
      outcome = outcome,
      n_informative = n_units,
      tau = tau,
      effect_percent = 100 * (effect - 1),
      power = mean(p_values < alpha, na.rm = TRUE)
    )
  }))
}

# --------------------------------------------------------------------------
# Run
# --------------------------------------------------------------------------

spain <- build_window_panel(
  file.path(output_dir, "province_outcome_daily_spain.csv"), "Spain")
greece <- build_window_panel(
  file.path(output_dir, "province_outcome_daily_greece.csv"), "Greece")

country_sets <- list(
  Spain = spain,
  Greece = greece,
  `Spain+Greece` = rbind(spain, greece)
)

comparison <- do.call(rbind, lapply(names(country_sets), function(set_name) {
  do.call(rbind, lapply(candidate_outcomes, function(outcome) {
    if (!paste0(outcome, ".pre") %in% names(country_sets[[set_name]])) return(NULL)
    row <- summarize_outcome(country_sets[[set_name]], outcome)
    cbind(data.frame(country_set = set_name, outcome = outcome), row)
  }))
}))

write.csv(comparison, file.path(output_dir, "outcome_comparison.csv"), row.names = FALSE)

cat("=== Candidate outcomes, single wave 15 August, 91-day windows ===\n")
cat("(informative unit = median pre-window baseline above a per-outcome threshold)\n\n")
print(comparison, row.names = FALSE, digits = 3)

# Simulation check on the configurations that looked best
cat("\n=== Simulation check ===\n")
effect_grid <- c(1.10, 1.25, 1.50, 1.75, 2.00, 2.50)

simulated <- rbind(
  simulate_configuration(country_sets[["Spain"]], "n_participants",
                         effect_grid, n_sims = n_sims, seed = 101),
  simulate_configuration(country_sets[["Spain+Greece"]], "n_participants",
                         effect_grid, n_sims = n_sims, seed = 202),
  simulate_configuration(country_sets[["Spain"]], "n_reporters_bite",
                         effect_grid, n_sims = n_sims, seed = 303),
  simulate_configuration(country_sets[["Spain"]], "n_reporters_albopictus",
                         effect_grid, n_sims = n_sims, seed = 404)
)

write.csv(simulated, file.path(output_dir, "outcome_comparison_power.csv"),
          row.names = FALSE)
print(simulated, row.names = FALSE, digits = 3)

cat("\nOutputs written to", output_dir, "\n")
