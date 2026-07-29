# IDAlert T5.4 Areal-Unit-Based Motivation Study

## Overview

This repository supports a mixed research and implementation workflow for an areal-unit-based motivation study using geographically targeted digital ads for Mosquito Alert. The design is to randomize ad messaging across subnational geographic units and estimate whether different motivational frames increase citizen science reporting activity.

The study compares messages derived from regulatory focus framing alongside a neutral comparison condition. Outcomes are evaluated using aggregate reporting counts by areal unit and time period, with a difference-in-differences style analysis as the primary approach.

## Current design

1. Country: Spain only.
2. Areal units: **2 km radius circles**, placed freely on locations with a recorded app audience rather than on administrative boundaries, thinned to a minimum 5-8 km separation (~5,000 units), delivered by Google Ads radius targeting.
3. Randomization: a single point in time, 15 August 2026, with no re-randomization.
4. Arms: prevention-focused, promotion-focused, and neutral messaging.
5. Outcome comparison: report counts in the 30 or 60 days before versus after 15 August 2026, analysed as a two-margin (hurdle) model — a log ratio for units with baseline reports, and a first-report activation probability for units without.

Provinces were the working unit until the power analysis showed 50 units could not detect anything below roughly a doubling; municipalities were an intermediate step, superseded because free circle placement gives more active units and a far higher activation rate among silent ones. Greece and Bangladesh were considered in earlier iterations; Greece was re-examined at municipality level and contributes under one percentage point of MDE, so it remains out of scope.

## Status: power analysis

The power analysis for this design is complete, and its conclusion is negative. Calibrated to observed 2021-2024 Spanish province reporting, the design has **no meaningful power to detect a 10% effect** (simulated power ≈ 0.05, i.e. the false-positive rate). The minimum detectable effect at 80% power is an increase of roughly **95% to 170%** per arm.

The binding constraint is that province-level post/pre report ratios carry a large year-specific idiosyncratic component (SD ≈ 0.6-0.95 on the log scale) that does not shrink with longer windows or higher report volume. With 50 provinces split across 3 arms, that swamps a 10% effect.

Alternative outcomes were tested and none rescues it. Restricting to albopictus reports cuts usable provinces from 50 to 18 and makes things much worse; restricting to bite reports roughly breaks even. A participation/sampling-effort outcome is the best aggregate measure, and re-including Greece adds about 10%, giving an MDE of about +104%.

Two reformulations do substantially better. Moving to **participant (user) level** — a closed cohort of pre-window reporters, analysed via the province mean of the per-user log ratio — gives an MDE of about **+57%**, but introduces user-level linkage that would change the ethics framing. Moving to **municipalities with a two-margin (hurdle) analysis** is the best single-wave design found, at about **+24%** — roughly the ~850 municipalities with pre-period reports (+27% on their own) combined with the ~7,400 silent ones analysed on the extensive margin (+53% on their own).

None of these reaches a 10% target, but +24% is within range of a plausible advertising effect and would combine with repeated waves. At province level the hurdle approach buys nothing, since essentially no Spanish province is silent.

Earlier results in this repository reporting power ≈ 0.85 for a 10% effect are **superseded and should not be used**: the estimator behind them has a Type I error rate near 0.90. See `analysis/r/power_analysis/README.md` and `docs/operations/power-analysis-spain-provinces-2026.md` for the full account and for what would change the answer.

## Key research question

Do geographically targeted ads using different motivational frames produce measurable differences in Mosquito Alert reporting volume across areal units, relative to neutral messaging and pre-campaign baselines?

## Project workstreams

1. Literature review on motivational framing, digital engagement, and ethics of low-risk field interventions.
2. Study planning and implementation design.
3. Ethics preparation, as an amendment to the approved broad IDAlert protocol (Component 4), based on institutional templates in `templates/cirep_forms/en/`.
4. Reproducible code for implementation support, data processing, and statistical analysis in R and Python.

## Repository structure

```text
.
├── README.md
├── .gitignore
├── admin/
├── analysis/
│   ├── notebooks/
│   ├── python/
│   └── r/
├── data/
│   ├── interim/
│   ├── processed/
│   └── raw/
├── docs/
│   ├── ethics/
│   ├── literature_review/
│   ├── operations/
│   └── study_plan/
├── outputs/
│   ├── figures/
│   ├── reports/
│   └── tables/
└── templates/
	└── cirep_forms/
		└── en/
```

## Core documents

1. `docs/operations/power-analysis-spain-provinces-2026.md` — the finalized power analysis for the current design, and the correction to the earlier results.
2. `docs/operations/google-ads-municipality-targeting.md` — how many Spanish municipalities Google Ads can target, how to set the campaign up by Criteria ID, and the power cost of the coverage limit.
3. `docs/operations/radius-targeting-design.md` — radius vs named targeting, spillover and buffer sizing, unit design, and why Greece is not worth re-adding.
4. `docs/operations/hurdle-power-analysis-spain-greece.md` — superseded earlier power analysis, retained for the record with a correction notice.
5. `docs/study_plan/study-plan-draft.md` — initial study design and implementation planning draft.
6. `docs/literature_review/review-matrix.md` — starter structure for the literature review.
7. `docs/operations/platform-targeting-assessment.md` and `platform-targeting-memo.md` — platform and geography feasibility assessment.
8. `docs/operations/google-ads-account-setup.md` — Google Ads account and billing setup guidance.
9. `docs/ethics/Protocol Form-3_IDAlert_rev_2023_06_16.docx` — the approved broad IDAlert protocol this study amends (Component 4).
10. `analysis/r/power_analysis/README.md` — power-analysis code, method, and results.

## Recommended workflow

### 1. Literature review

Build a review matrix focused on:

1. Regulatory focus and motivational framing.
2. Digital advertising for public-interest behavior change.
3. Ethics of low-risk digital field experiments.
4. Aggregate geographic outcome analysis.

### 2. Implementation planning

Confirm, for Spain:

1. That provinces are cleanly targetable in Google Ads and Meta.
2. Whether Google AdMob is appropriate for this design.
3. Whether alternative platforms offer cleaner geographic randomization.
4. That Mosquito Alert outcomes can be exported at province level.

### 3. Ethics preparation

This study is Component 4 of the already-approved broad IDAlert protocol, so the route is an amendment rather than a new submission. Templates for reference are in `templates/cirep_forms/en/`.

The ethics position assumes a minimal-risk study using aggregate areal-unit counts only, with no individual recruitment, consent, or participant-level linkage. That assumption still needs validation against actual ad-platform and backend data flows.

### 4. Code and analysis

Planned code tasks include:

1. Scripts to clean and harmonize areal-unit-level input data.
2. Campaign configuration and QA support scripts where feasible.
3. Reproducible analysis pipelines in R and Python.
4. Output generation for tables, figures, and reports.

## Immediate priorities

1. **Decide how to respond to the power result.** The current design detects only very large effects. Options are set out at the end of `docs/operations/power-analysis-spain-provinces-2026.md`: run as a large-effect-only study, switch to repeated re-randomized waves across the season, change the outcome or unit of analysis, or reframe the 2026 campaign as an implementation pilot.
2. **Run a leakage pilot.** How much treatment leaks between neighbouring units is the weakest assumption in the design and decides whether the study is worth running. See `docs/operations/radius-targeting-design.md`.
3. Confirm the ad platform strategy. Google Ads names only 970 of Spain's 8,240 municipalities (78% of reports); going beyond that needs radius targeting.
3. Expand the literature review with ethics-relevant sources.
4. Prepare the Component 4 amendment to the approved IDAlert protocol.
5. Define the minimal analysis dataset and data access boundaries.
6. Draft and refine ad copy for each message condition.

## Notes on data governance

This repository is organized around the principle that raw extracts and operational outputs should not be committed to version control. The `.gitignore` is configured to keep raw, interim, processed, and generated output files local unless they are explicitly curated for sharing.

## Next suggested documents

1. Messaging matrix with draft ads by language and condition.
2. Component 4 amendment text for the approved IDAlert protocol.
3. Ethics checklist draft keyed to the institutional form.
4. Data flow and data management note.