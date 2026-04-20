# IDAlert T5.4 Areal-Unit-Based Motivation Study

## Overview

This repository supports a mixed research and implementation workflow for an areal-unit-based motivation study using geographically targeted digital ads for Mosquito Alert. The working design is to randomize ad messaging across subnational geographic units and estimate whether different motivational frames increase citizen science reporting activity.

The study will compare messages derived from regulatory focus framing alongside a neutral comparison condition. Outcomes will be evaluated using aggregate reporting counts by areal unit and time period, with a difference-in-differences style analysis as the primary approach.

## Current project scope

The project includes four linked workstreams:

1. Literature review on motivational framing, digital engagement, and ethics of low-risk field interventions.
2. Study planning for implementation in Spain, Greece, and Bangladesh.
3. Ethics preparation for expedited review, based on institutional templates in `templates/cirep_forms/en/`.
4. Reproducible code for implementation support, data processing, and statistical analysis in R and Python.

## Key research question

Do geographically targeted ads using different motivational frames produce measurable differences in Mosquito Alert reporting volume across areal units, relative to neutral messaging and pre-campaign baselines?

## Working study concept

1. Select a feasible administrative level in each country that is targetable by the chosen ad platform and compatible with Mosquito Alert outcome aggregation.
2. Assign each eligible areal unit to one of several messaging conditions.
3. Run synchronized ad campaigns using standardized creative formats.
4. Compare aggregate outcomes before and after campaign exposure across treatment conditions.

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

## Core documents added

1. `docs/study_plan/study-plan-draft.md` contains the initial study design and implementation planning draft.
2. `docs/ethics/ethics-protocol-draft.md` contains a first-pass ethics protocol draft for adaptation into the institutional template.
3. `docs/ethics/ethics-protocol-form-draft.md` reorganizes the ethics text to match the UPF protocol form headings.
4. `docs/ethics/ethics-checklist-draft.md` provides a checklist-aligned ethics preparation draft.
5. `docs/literature_review/review-matrix.md` provides a starter structure for the literature review.
6. `docs/operations/platform-targeting-assessment.md` provides a preliminary platform and geography feasibility assessment.

## Recommended workflow

### 1. Literature review

Build a review matrix focused on:

1. Regulatory focus and motivational framing.
2. Digital advertising for public-interest behavior change.
3. Ethics of low-risk digital field experiments.
4. Aggregate geographic outcome analysis.

### 2. Implementation planning

Confirm, for Spain, Greece, and Bangladesh:

1. Smallest targetable administrative unit by platform.
2. Whether Google AdMob is appropriate for this design.
3. Whether alternative platforms offer cleaner geographic randomization.
4. Whether Mosquito Alert outcomes can be exported at the same geographic level.

### 3. Ethics preparation

Use the templates in `templates/cirep_forms/en/` to prepare:

1. Checklist.
2. Protocol form.
3. DPIA, if required.

The current ethics draft assumes a minimal-risk study using aggregate outcomes only, but this assumption still needs validation against actual platform and backend data flows.

### 4. Code and analysis

Planned code tasks include:

1. Scripts to clean and harmonize areal-unit-level input data.
2. Campaign configuration and QA support scripts where feasible.
3. Reproducible analysis pipelines in R and Python.
4. Output generation for tables, figures, and reports.

## Immediate priorities

1. Confirm the ad platform strategy and targetable geographic levels in all three countries.
2. Expand the literature review with ethics-relevant sources.
3. Translate the draft ethics protocol into the formal institutional template.
4. Define the minimal analysis dataset and data access boundaries.
5. Draft and refine ad copy for each message condition.

## Notes on data governance

This repository is organized around the principle that raw extracts and operational outputs should not be committed to version control. The `.gitignore` is configured to keep raw, interim, processed, and generated output files local unless they are explicitly curated for sharing.

## Next suggested documents

1. Platform targeting memo for Spain, Greece, and Bangladesh.
2. Messaging matrix with draft ads by language and condition.
3. Ethics checklist draft keyed to the institutional form.
4. Data flow and data management note.