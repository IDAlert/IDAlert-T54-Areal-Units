# Archive: the exploration that led to the final design

Nothing in this folder is needed to reproduce the final study — see
`REPRODUCE.md` at the repository root. It is kept because the design went
through many hands-on iterations, several of which were set aside for reasons
worth remembering, and because the timestamped record of that arc is part of
the study's credibility.

> **Provenance note (2026-08-15).** During a git-history cleanup, a
> `git filter-repo` run reset the working tree and deleted files that were
> staged but uncommitted. Live-pipeline files were reconstructed and verified
> (the assignment script regenerates the frozen assignment bit-for-bit, md5
> `cd9c8672…`; the reporter-counts builder regenerates its output identically,
> md5 `7b6dbf85…`). This README was rewritten afterwards. Two archive-only
> scripts could not be recovered: `run_named_municipality_power.R` (hurdle
> power over nameable municipalities) and the 2025-era `assign_treatment.R`
> (population strata, prevention/promotion arms). Their generated outputs
> survive in `output/`, and `README_power_exploration.md` documents the
> methods of that era.

## The arc, in brief

1. **Provinces** (50 units): no version could detect less than roughly a
   doubling; the binding constraint was a large year-specific idiosyncratic
   component in post/pre ratios. `power_single_wave_spain.R`,
   `run_final_design_spain.R`, `run_wave_comparison_spain.R`.
2. **Report-based outcomes, alternative countries, cohorts**: bites and
   albopictus subsets, Greece, participant-level cohorts, repeated waves —
   none rescued a 10% target. `build_*`, `run_power_scenarios.R`,
   `run_user_level_comparison.R`, `run_outcome_comparison.R`.
3. **Free circles, postal codes, radius targeting**: better on paper, set
   aside for operational complexity and spillover control.
   `run_free_circle_placement.R`, `run_postal_code_design.R`,
   `run_buffer_design_tradeoff.R`, `measure_spillover_scale.R`.
4. **Municipalities + hurdle analysis** (the 2025 adopted design): two-margin
   analysis over nameable municipalities. Superseded when the outcome moved to
   background-track participants and the model to a linear count regression
   with block fixed effects. `run_hurdle_combined_design.R`,
   `run_extensive_margin_municipalities.R`, `run_named_municipality_power.R`
   (lost, see note), `run_municipality_coverage_sensitivity.R`,
   `run_hybrid_unit_scenarios.R`.
5. **Parallel power approaches on the way to the final design**:
   `run_person_level_power.R` (each adult reports with some probability;
   binomial draws; negative-binomial DiD) and `run_impression_budget_power.R`
   (power as a function of purchased impressions through the
   impressions→clicks→installs funnel) — both superseded by
   `02_power/run_final_2026_power.R`, which simulates on the realized
   assignment. `build_municipality_window_counts.R` built the report-based
   municipality-day counts these designs used.

Corrections worth remembering when reading old outputs here: an early
log-ratio estimator reported power ≈ 0.85 for a 10% effect with a Type I error
near 0.90 (see `README_power_exploration.md`); several files predate the
switch from presence-attributed to home-assigned participant counts and are no
longer regenerable from current data.

## `output/`

Generated files from the exploration era (~320 MB, mostly untracked):
superseded assignments and manifests (tracked, as the record of earlier
candidate designs), power grids, simulation draws, and intermediate panels.
Several are not regenerable — they were computed from the presence-attributed
data that the final home-assigned delivery replaced.

Superseded design memos live in `docs/archive/`.
