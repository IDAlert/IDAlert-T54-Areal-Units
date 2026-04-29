# Areal-Unit Power Analysis

This directory contains first-pass R code for power analysis of the areal-unit messaging experiment.

## Current design assumptions

1. Countries included: Spain and Greece.
2. Unit of randomization: provinces in Spain and regional units in Greece.
3. Unit counts used here: 50 provinces in Spain and 74 regional units in Greece.
4. Messaging arms: `neutral`, `prevention_focus`, and `promotion_focus`.
5. Treatments are assigned every 14 days from 1 June through 1 November, re-randomizing at each treatment date.
6. Outcomes are 7-day report counts before treatment and 7-day report counts after treatment.
7. Initial baseline counts are assumed to average roughly 5 to 10 reports per 7-day period.
8. The default simulated effect size is a 10% increase for both non-neutral messaging arms relative to neutral.

## Current modeling approach

The script simulates repeated pre/post counts for each areal unit and treatment wave, then fits a Poisson difference-in-differences style model:

```r
count ~ unit + wave + post * arm
```

This yields:

1. Per-arm power for detecting `prevention_focus` versus `neutral`.
2. Per-arm power for detecting `promotion_focus` versus `neutral`.
3. Joint power for detecting any post-treatment arm effect.

## Files

1. `power_simulation.R`: core simulation functions and a runnable default analysis.
2. `build_empirical_weekly_counts.R`: builds empirical weekly counts and unit baselines from raw report data.
3. `run_power_scenarios.R`: compares alternative cadence and window scenarios when the richer empirical simulation API is available.
4. `run_municipality_coverage_sensitivity.R`: explores how municipality-only power changes as targetable municipality coverage changes.
5. `run_hybrid_unit_scenarios.R`: explores mixed designs that combine Spain provinces and Greece regional-unit proxies with top-reporting municipalities.

## Run

From the repository root:

```bash
Rscript analysis/r/power_analysis/power_simulation.R
```

The script writes a summary CSV to `analysis/r/power_analysis/output/power_summary.csv`.

## Updating with observed counts later

When real 7-day counts are available, the easiest next step will be to replace the synthetic unit-level baseline means with observed province and regional-unit means. The script already includes a helper for reading those values from a CSV.

In practice, this repository now already includes empirical baseline builders and saved outputs derived from the historical Mosquito Alert counts, including 2023-2025 restricted files in `analysis/r/power_analysis/output/`.

