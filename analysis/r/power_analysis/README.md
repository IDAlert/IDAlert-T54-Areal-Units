# Areal-Unit Power Analysis

This directory contains the R code used for empirical power analysis of the areal-unit messaging experiment.

## Final retained design options

The current documentation and saved outputs focus on two retained design options under the 2023-2025 Spain and Greece empirical baseline and the hurdle-style 10% dual-margin sensitivity analysis.

### Option 1: Six 15-Day Campaign Waves

1. Countries included: Spain and Greece.
2. Unit of randomization: provinces in Spain and proxy regional units in Greece.
3. Unit counts used here: 50 provinces in Spain and 52 proxy units in Greece.
4. Messaging arms: `neutral`, `prevention_focus`, and `promotion_focus`.
5. Campaigns recur every 30 days starting on 15 June 2026.
6. Each campaign lasts 15 days.
7. The pre-period is the 15 days immediately before each campaign starts.
8. The post-period is the 15-day campaign itself.

### Option 2: Single 30-Day Campaign

1. Countries included: Spain and Greece.
2. Unit of randomization: provinces in Spain and proxy regional units in Greece.
3. Unit counts used here: 50 provinces in Spain and 52 proxy units in Greece.
4. Messaging arms: `neutral`, `prevention_focus`, and `promotion_focus`.
5. The campaign starts on 15 August 2026.
6. The campaign lasts 30 days.
7. The pre-period is the 30 days immediately before the campaign starts.
8. The post-period is the 30-day campaign itself.

In both retained options, the intervention wording should be read as a campaign spanning the full post window rather than as a one-day treatment followed by a separate post-measurement window.

## Boundary note

Spain is currently aggregated exactly at the province level.

Greece is currently aggregated using a GISCO NUTS3 proxy source in the empirical builder because the tested general-purpose administrative boundary sources did not expose the 74 regional units cleanly. This makes the Greece side more realistic than a synthetic baseline, but it is still a proxy and should be replaced with an exact 74-unit boundary file if available.

## Modeling approach

The simulation code generates repeated pre/post counts for each areal unit and treatment wave, then fits a Poisson difference-in-differences style model:

```r
count ~ unit + wave + post * arm
```

This yields:

1. Per-arm power for detecting `prevention_focus` versus `neutral`.
2. Per-arm power for detecting `promotion_focus` versus `neutral`.
3. Joint power for detecting any post-treatment arm effect.

When there is only one wave, the code uses the corresponding one-wave simplification.

## Files

1. `power_simulation.R`: simulation functions and a runnable default analysis.
2. `build_empirical_weekly_counts.R`: derives weekly counts by Spain province and Greece regional unit from the raw report file.
3. `run_power_scenarios.R`: compares alternative treatment intervals and pre/post outcome windows.
4. `output/final_design_options_hurdle_10pct_spain_greece_20230101_to_20251231.csv`: compact summary of the two retained design options.

## Core empirical inputs

1. `analysis/r/power_analysis/output/empirical_weekly_counts_20230101_to_20251231.csv`
2. `analysis/r/power_analysis/output/empirical_unit_baselines_20230101_to_20251231.csv`

## Final retained outputs

### Six-wave 15-day campaign design

1. `analysis/r/power_analysis/output/power_summary_30d_15pre_15post_hurdle_10pct_spain_greece_20230101_to_20251231.csv`
2. `analysis/r/power_analysis/output/simulation_p_values_30d_15pre_15post_hurdle_10pct_spain_greece_20230101_to_20251231.csv`

### Single-wave 30-day campaign design

1. `analysis/r/power_analysis/output/power_summary_single_wave_20260815_30pre_30post_hurdle_10pct_spain_greece_20230101_to_20251231.csv`
2. `analysis/r/power_analysis/output/simulation_p_values_single_wave_20260815_30pre_30post_hurdle_10pct_spain_greece_20230101_to_20251231.csv`

### Combined comparison

1. `analysis/r/power_analysis/output/final_design_options_hurdle_10pct_spain_greece_20230101_to_20251231.csv`

## Run

From the repository root:

```bash
Rscript analysis/r/power_analysis/build_empirical_weekly_counts.R
Rscript analysis/r/power_analysis/power_simulation.R
Rscript analysis/r/power_analysis/run_power_scenarios.R
```

The retained final-design outputs listed above were generated from ad hoc `simulate_power(...)` runs using the 2023-2025 restricted empirical baseline.

## Empirical baseline note

The current workflow already uses empirical weekly counts from the raw Mosquito Alert reports file in `data/raw/mosquito_alert_raw_reports.Rds`. For the final retained outputs, the relevant baseline is the restricted 2023-2025 file rather than the older full-history baseline.
