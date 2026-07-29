# Hurdle-Style Power Analysis for Spain and Greece: Final Design Options

> **SUPERSEDED — do not cite the power figures in this document.**
>
> Replaced by `power-analysis-spain-provinces-2026.md`. Two problems invalidate
> the results below:
>
> 1. **The analysis model is not valid for these data.** The fixed-effects
>    Poisson model used to evaluate power assumes that, beyond unit and wave
>    effects, the only residual variation is Poisson counting noise. Spanish
>    province data violate this: the province-level log-scale shock to the
>    post/pre report ratio has SD of roughly 0.6-0.95 after counting noise is
>    removed. Simulating with that heterogeneity and testing with this model
>    produces a Type I error rate of about **0.90** for the per-arm tests and
>    **0.99** for the omnibus test, at a nominal 0.05. The per-arm "power" of
>    0.85-0.89 reported here is therefore approximately the model's
>    false-positive rate, not power.
>
> 2. **The simulated effect is larger than stated.** As noted in the
>    "Hurdle-Style Simulation Specification" section below, the arm multiplier is
>    applied to both the activation probability and the conditional count, so the
>    nominal 10% scenario corresponds to roughly a 21% increase in expected
>    counts.
>
> Corrected result: under the finalized Spain-only province design, power to
> detect a 10% effect is approximately 0.05, and the minimum detectable effect at
> 80% power is an increase of roughly 95% to 170%. Even an 11-wave season-long
> design reaches only about 0.14 power at a 10% effect.
>
> The design description and the empirical data summaries below remain accurate
> and are still useful as a record of the earlier design options.

## Purpose

This note documents the final two retained study-design options for the Spain and Greece areal-unit messaging experiment, using empirical Mosquito Alert reporting data restricted to 2023-2025.

Both options are evaluated under the same hurdle-style data-generating process. In that setup, each intervention arm is assumed to increase both:

1. the probability that an areal unit records at least one report during the campaign window, and
2. the number of reports conditional on reporting occurring.

This was motivated by the fact that the empirical reporting data are highly zero-heavy, especially in Greece, which makes a single-process Poisson count model potentially too restrictive if treatment could activate otherwise silent unit-periods.

## Final Design Options

The retained options are now framed as campaigns that span the full post period itself, rather than as single-day interventions with a separate post-measurement window. This wording matches the simulation setup as long as the listed date is interpreted as the campaign start date.

### Option 1: Six 15-Day Campaign Waves

1. Countries: Spain and Greece only.
2. Areal units: 50 Spanish provinces and 52 Greek proxy regional units.
3. Number of campaign waves: 6.
4. Campaign cadence: every 30 days starting on 15 June 2026.
5. Campaign length: 15 days.
6. Pre-period length: 15 days immediately before each campaign starts.
7. Campaign start dates:
   1. 2026-06-15
   2. 2026-07-15
   3. 2026-08-14
   4. 2026-09-13
   5. 2026-10-13
   6. 2026-11-12
8. Interpretation: each campaign runs over its full 15-day post window.

Because the pre and post windows are both 15 days and the campaigns recur every 30 days, the design has no cross-wave overlap.

### Option 2: Single 30-Day Campaign

1. Countries: Spain and Greece only.
2. Areal units: 50 Spanish provinces and 52 Greek proxy regional units.
3. Number of campaign waves: 1.
4. Campaign start date: 2026-08-15.
5. Campaign length: 30 days.
6. Pre-period length: 30 days immediately before the campaign starts.
7. Interpretation: the campaign occupies the full 30-day post window.

In the simulation code, this is represented as a one-wave design with a 30-day pre window and a 30-day post window.

## Areal Units Used

### Spain

Spain was represented using the 50 GADM provinces. These are the same province-level units used in the earlier province-based power analysis.

Terminology note: Spanish provinces are the province-level units that correspond most closely to NUTS3. By contrast, the autonomous communities are the NUTS2-equivalent layer.

### Greece

Greece was represented using 52 GISCO NUTS3 units as proxies for Greek regional units. This is not an exact 74-unit administrative layer; it is the same proxy layer used in the earlier empirical analysis because a cleaner exact layer was not available in the current workflow.

## Empirical Data Used

The raw source file was:

1. `data/raw/mosquito_alert_raw_reports.Rds`

### Inclusion Rules

The empirical weekly counts were built from all geolocated non-mission reports that passed the following filters:

1. longitude and latitude not missing,
2. report type not equal to `mission`,
3. creation date not missing,
4. creation date not later than the analysis date,
5. Android reports only from 2014-06-14 onward,
6. iOS-family reports only from 2014-06-24 onward,
7. report date restricted to the window from 2023-01-01 through 2025-12-31.

No validation or expert-review filter was applied. The counts therefore include all eligible non-mission reports, not only validated reports.

### Time Coverage

After filtering, the empirical data covered:

1. earliest included date: 2023-01-01
2. latest included date: 2025-08-14
3. calendar years represented: 2023 through 2025
4. total filtered reports: 171,381

### Report Types Included

After filtering, the empirical data included:

1. `adult`: 82,852 reports
2. `bite`: 75,238 reports
3. `site`: 13,291 reports

## Empirical Reporting Distribution

### Unit-Level Baseline Means

Source file:

1. `analysis/r/power_analysis/output/empirical_unit_baselines_20230101_to_20251231.csv`

Spain:

1. units: 50
2. mean of unit weekly means: 12.654
3. SD of unit weekly means: 22.055
4. minimum: 0.196
5. 25th percentile: 1.243
6. median: 4.370
7. 75th percentile: 14.402
8. 90th percentile: 31.910
9. 95th percentile: 39.519
10. maximum: 135.551
11. zero-mean units: 0

Greece:

1. units: 52
2. mean of unit weekly means: 0.325
3. SD of unit weekly means: 1.025
4. minimum: 0.000
5. 25th percentile: 0.0272
6. median: 0.0906
7. 75th percentile: 0.214
8. 90th percentile: 0.566
9. 95th percentile: 1.038
10. maximum: 7.225
11. zero-mean units: 4

### Unit-Week Distribution

Source file:

1. `analysis/r/power_analysis/output/empirical_weekly_counts_20230101_to_20251231.csv`

Spain:

1. total unit-weeks: 6,900
2. zero-share across unit-weeks: 0.437
3. mean weekly count: 12.654
4. median weekly count: 1
5. 90th percentile: 26
6. 95th percentile: 59
7. maximum weekly count: 1,202

Greece:

1. total unit-weeks: 7,176
2. zero-share across unit-weeks: 0.918
3. mean weekly count: 0.325
4. median weekly count: 0
5. 90th percentile: 0
6. 95th percentile: 1
7. maximum weekly count: 74

## Hurdle-Style Simulation Specification

This analysis did not fit a packaged regression-based hurdle model and then simulate from the fitted coefficient vector. Instead, it used a semi-parametric empirical hurdle data-generating process built directly from the historical weekly counts.

For each areal unit, the simulation estimated:

1. the historical probability that a unit-week was active, and
2. the empirical pool of positive weekly counts for that unit.

Within each pre or post campaign window, the simulation then generated counts by:

1. drawing whether each subwindow was active,
2. sampling from the unit's empirical positive-count pool when active, and
3. applying the intervention multiplier to both the activation margin and the conditional count margin during the post window.

Under the 10% scenario, each intervention arm is assigned a multiplier of $1.10$ on both margins relative to the neutral arm.

This should be interpreted as a dual-margin sensitivity analysis rather than as a simple 10% increase in overall expected counts.

## Analysis Model Used for Power Evaluation

After simulated pre and post counts were generated, the analysis fit a fixed-effects Poisson comparison model.

For the six-wave design, the model was:

$$
\text{count} \sim \text{unit\_id} + \text{wave} + \text{post} * \text{arm}
$$

For the single-wave design, the one-wave simplification was used:

$$
\text{count} \sim \text{unit\_id} + \text{post} + \text{post} * \text{arm}
$$

Power is reported as:

1. `prevention_focus_power`: the share of simulations where the prevention-focused post-by-arm interaction is significant,
2. `promotion_focus_power`: the share of simulations where the promotion-focused post-by-arm interaction is significant,
3. `joint_power`: the share of simulations where the omnibus likelihood-ratio test comparing the reduced and full models is significant.

Because the simulation does not encode any substantive difference between the prevention and promotion arms, small differences between the two arm-specific power estimates should be interpreted as simulation noise rather than as meaningful design asymmetry.

## Results for the Two Final Options

All results below use:

1. the 2023-2025 restricted empirical baseline,
2. the hurdle-style data-generating process,
3. 500 Monte Carlo repetitions,
4. a 10% dual-margin effect for each intervention arm relative to neutral.

### Option 1: Six 15-Day Campaign Waves

Results:

1. prevention-focused arm power: 0.890
2. promotion-focused arm power: 0.854
3. joint power: 0.980

Interpretation:

1. per-arm power is in the mid-to-high 80% range,
2. joint power is about 98%,
3. the small difference between the two arm-specific estimates should not be interpreted substantively.

Saved outputs:

1. `analysis/r/power_analysis/output/power_summary_30d_15pre_15post_hurdle_10pct_spain_greece_20230101_to_20251231.csv`
2. `analysis/r/power_analysis/output/simulation_p_values_30d_15pre_15post_hurdle_10pct_spain_greece_20230101_to_20251231.csv`

### Option 2: Single 30-Day Campaign Starting 15 August 2026

Results:

1. prevention-focused arm power: 0.850
2. promotion-focused arm power: 0.856
3. joint power: 0.980

Interpretation:

1. per-arm power is again in the mid-80% range,
2. joint power is again about 98%,
3. relative to the six-wave design, the single-wave design appears slightly lower on the individual contrasts but very similar on the omnibus comparison.

Saved outputs:

1. `analysis/r/power_analysis/output/power_summary_single_wave_20260815_30pre_30post_hurdle_10pct_spain_greece_20230101_to_20251231.csv`
2. `analysis/r/power_analysis/output/simulation_p_values_single_wave_20260815_30pre_30post_hurdle_10pct_spain_greece_20230101_to_20251231.csv`

### Compact Comparison Output

The two retained options are also summarized together in:

1. `analysis/r/power_analysis/output/final_design_options_hurdle_10pct_spain_greece_20230101_to_20251231.csv`

## Bottom Line

Under the retained 10% dual-margin hurdle scenario calibrated to observed Spain and Greece Mosquito Alert reporting in 2023-2025, both final design options appear to have per-arm power in the mid-to-high 80% range and joint power of about 98%.

On that basis:

1. the six-wave 15-day-campaign design looks slightly stronger on the individual arm-versus-neutral contrasts,
2. the single 30-day-campaign design produces very similar joint power,
3. both designs look viable under this optimistic dual-margin sensitivity analysis.

## Files and Code

The relevant code paths are:

1. `analysis/r/power_analysis/build_empirical_weekly_counts.R`
2. `analysis/r/power_analysis/power_simulation.R`

The hurdle-style option was implemented in `power_simulation.R` via a separate empirical data-generating process using unit-specific activation probabilities and positive-count pools derived from the historical weekly counts.
