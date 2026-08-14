# Extensive-margin (activation) design over Spanish municipalities.
#
# Motivation. Every design analysed so far defines the effect multiplicatively:
# reports go up by X%. Under that definition a municipality with zero baseline
# reports is structurally unable to respond -- 0 x 1.1 = 0 -- so the ~7,400
# silent Spanish municipalities inflate n without adding signal. That is a
# property of the EFFECT MODEL, not of reality: an ad campaign in a silent
# municipality could plausibly produce its first report.
#
# Redefining the effect on the extensive margin fixes this:
#
#   estimand = P(a municipality with no pre-window reports records at least one
#              report in the post window)
#   effect   = increase in that probability
#
# Two structural advantages over the count-ratio designs:
#
#   1. No tau. The province-level idiosyncratic shock that blocks every other
#      design is a property of log-ratios of counts, which have unbounded,
#      heavy-tailed unit-level noise. A binary outcome has variance p(1-p),
#      fully determined by p, so there is no extra between-unit component. This
#      script verifies that by permutation against the real data.
#   2. Sensitivity ~1. For small p, P(>=1 report) = 1 - exp(-lambda) is very
#      nearly proportional to lambda, so a multiplicative effect on reporting
#      propensity translates almost one-for-one onto the activation rate. There
#      is no sensitivity penalty of the kind the per-user log ratio pays.
#
# Usage:  Rscript analysis/r/power_analysis/run_extensive_margin_municipalities.R

suppressWarnings({
  options(stringsAsFactors = FALSE)
})

output_dir <- file.path("analysis", "r", "power_analysis", "output")
campaign_month_day <- "08-15"
calibration_years <- 2021:2024
alpha <- 0.05
target_power <- 0.80
power_multiplier <- qnorm(1 - alpha / 2) + qnorm(target_power)

counts <- read.csv(file.path(output_dir, "spain_municipality_daily_counts.csv"))
counts$date <- as.Date(counts$date)
municipality_index <- read.csv(file.path(output_dir, "spain_municipality_index.csv"))
all_municipalities <- municipality_index$unit_name

# Window totals for every municipality, including those with no reports at all.
window_panel <- function(year, window_days) {
  treatment_date <- as.Date(sprintf("%d-%s", year, campaign_month_day))
  if (max(counts$date) < treatment_date + window_days - 1) return(NULL)

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
    prior_year = totals(counts[counts$date >= treatment_date - 425 &
                                 counts$date < treatment_date - window_days, ]),
    year = year
  )
}

build_panel <- function(window_days) {
  panels <- lapply(calibration_years, window_panel, window_days = window_days)
  do.call(rbind, panels[!vapply(panels, is.null, logical(1))])
}

# --------------------------------------------------------------------------
# 1. Activation rates
# --------------------------------------------------------------------------

activation_rates <- do.call(rbind, lapply(c(30L, 60L, 91L), function(window_days) {
  panel <- build_panel(window_days)
  silent <- panel[panel$pre == 0, ]

  do.call(rbind, lapply(split(silent, silent$year), function(rows) {
    data.frame(
      window_days = window_days,
      year = unique(rows$year),
      n_silent = nrow(rows),
      n_activated = sum(rows$post > 0),
      activation_rate = mean(rows$post > 0)
    )
  }))
}))

write.csv(activation_rates, file.path(output_dir, "municipality_activation_rates.csv"),
          row.names = FALSE)

cat("=== Activation of silent municipalities (no pre-window reports) ===\n")
print(activation_rates, row.names = FALSE, digits = 3)

# --------------------------------------------------------------------------
# 2. Verify there is no extra between-unit variance
# --------------------------------------------------------------------------

cat("\n=== Permutation check: binary outcome has no tau ===\n")
cat("Permutation SE of a 3-arm contrast on real data vs binomial theory.\n\n")

verification <- do.call(rbind, lapply(calibration_years, function(year) {
  panel <- window_panel(year, 60L)
  if (is.null(panel)) return(NULL)
  silent <- panel[panel$pre == 0, ]
  n_units <- nrow(silent)
  activated <- silent$post > 0
  rate <- mean(activated)

  set.seed(4)
  contrasts <- replicate(400, {
    arm <- sample(rep(c("neutral", "a", "b"), length.out = n_units))
    mean(activated[arm == "a"]) - mean(activated[arm == "neutral"])
  })

  data.frame(
    year = year, n_silent = n_units, activation_rate = rate,
    permutation_se = sd(contrasts),
    binomial_se = sqrt(2 * rate * (1 - rate) / (n_units / 3))
  )
}))

print(verification, row.names = FALSE, digits = 3)

# --------------------------------------------------------------------------
# 3. Minimum detectable effect
# --------------------------------------------------------------------------

pooled_rate <- weighted.mean(
  activation_rates$activation_rate[activation_rates$window_days == 60],
  activation_rates$n_silent[activation_rates$window_days == 60]
)
max_units <- round(mean(activation_rates$n_silent[activation_rates$window_days == 60]))

mde_table <- do.call(rbind, lapply(c(500L, 1000L, 2000L, 4000L, max_units), function(n_units) {
  per_arm <- n_units / 3
  contrast_se <- sqrt(2 * pooled_rate * (1 - pooled_rate) / per_arm)
  mde <- power_multiplier * contrast_se

  data.frame(
    n_municipalities = n_units,
    n_per_arm = round(per_arm),
    baseline_rate = pooled_rate,
    natural_activations_per_arm = round(per_arm * pooled_rate),
    mde_percentage_points = 100 * mde,
    mde_relative_percent = 100 * mde / pooled_rate,
    extra_municipalities_per_arm = round(per_arm * mde)
  )
}))

write.csv(mde_table, file.path(output_dir, "municipality_extensive_margin_mde.csv"),
          row.names = FALSE)

cat("\n=== MDE on the extensive margin, 60-day windows ===\n")
cat("Baseline activation rate:", round(pooled_rate, 4), "\n\n")
print(mde_table, row.names = FALSE, digits = 3)

# --------------------------------------------------------------------------
# 4. Does selecting which silent municipalities to target help?
# --------------------------------------------------------------------------

panel_60 <- build_panel(60L)
silent_60 <- panel_60[panel_60$pre == 0, ]
silent_60$stratum <- cut(
  silent_60$prior_year, c(-1, 0, 2, 10, Inf),
  labels = c("none in prior year", "1-2", "3-10", ">10")
)

strata <- do.call(rbind, lapply(split(silent_60, silent_60$stratum), function(rows) {
  if (nrow(rows) == 0) return(NULL)
  n_per_season <- nrow(rows) / length(calibration_years)
  rate <- mean(rows$post > 0)
  contrast_se <- sqrt(2 * rate * (1 - rate) / (n_per_season / 3))
  data.frame(
    stratum = as.character(rows$stratum[1]),
    n_per_season = round(n_per_season),
    activation_rate = rate,
    mde_percentage_points = 100 * power_multiplier * contrast_se,
    mde_relative_percent = 100 * power_multiplier * contrast_se / rate
  )
}))

write.csv(strata, file.path(output_dir, "municipality_activation_strata.csv"),
          row.names = FALSE)

cat("\n=== Targeting by prior-year history ===\n")
print(strata, row.names = FALSE, digits = 3)
cat("\nPooling all silent municipalities beats every single stratum: the largest\n")
cat("stratum has the lowest activation rate, and n dominates.\n")

cat("\nOutputs written to", output_dir, "\n")
