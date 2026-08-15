# Regulatory-Focus Framing in Geo-Targeted Ads for Citizen Science

**IDAlert Task 5.4 — a randomized experiment across 949 Spanish municipalities,
August–October 2026.**

Does the content of a recruitment message change how much participation
geographically targeted advertising generates for citizen science — and does
such advertising generate participation at all, including in places with none?

The experiment is built on [Mosquito Alert](https://www.mosquitoalert.com), an
expert-validated citizen science system through which anyone can
participate in the surveillance of vector mosquitoes. Every Spanish
municipality that Google Ads can target by name, and whose existing Mosquito
Alert activity falls below a pre-specified cap, is randomly assigned to one of
three arms:

| Arm | Municipalities | Treatment |
|---|---|---|
| Framed | 420 | Android app-install ads using regulatory-focus framing |
| Neutral | 420 | Identical ads with neutral framing |
| No advertising | 109 | Nothing |

Ads run from 17 August 2026. The primary outcome is the number of distinct
participants who are active in each municipality during the 60-day
post-campaign window (16 August – 14 October) and whose sampling effort is
concentrated there — each participant is counted in exactly one municipality,
the one where they were observed on the most days. The secondary outcome is
the number of participants submitting mosquito reports in that window. 571 of
the municipalities have no recent Mosquito Alert activity at all, so the
ads-versus-nothing contrast is in part an **activation** experiment: can
advertising create participation where none exists?

## Where to start

| Document | Contents |
|---|---|
| [docs/preregistration/preregistration-osf.md](docs/preregistration/preregistration-osf.md) | **The pre-registration of record** — hypotheses, design, analysis plan, power, and limitations, structured against the OSF Preregistration form |
| [REPRODUCE.md](REPRODUCE.md) | Step-by-step instructions to regenerate the treatment assignment exactly and rerun every power figure |
| [analysis/r/output/manifest_2026_final.txt](analysis/r/output/manifest_2026_final.txt) | The assignment's seed, eligibility rule, input and output checksums, and verification results |

## Design in brief

- **Randomization.** Municipalities are ordered by baseline participation
  (median over the 2021–2025 seasons) and cut into blocks of 9; each full
  block is randomly permuted 4 framed / 4 neutral / 1 no-advertising, and a
  trailing partial block joins the no-advertising arm. The random seed is
  fixed and the random-number generator pinned, so the assignment regenerates
  bit-for-bit from the same inputs.
- **Analysis** (pre-registered). A linear model on post-window counts with
  block fixed effects, the pre-window count, and the historical median as
  covariates. The primary test is randomization inference — treatment labels
  permuted within blocks, reproducing the design's own randomization
  distribution — with a heteroskedasticity-robust regression test (HC3)
  reported alongside and confidence intervals obtained by exact inversion of
  the permutation test.
- **Power.** 0.92 to detect a 15% framing advantage at moderate delivery
  spread, and essentially 1.00 at 20%. The advertising-versus-nothing contrast
  detects an increase of roughly +110% over the no-advertising arm's expected
  level of about 1.1 participants per municipality.
- **Built-in verification.** The assignment script checks the Type I error of
  the realized assignment (not just the design in expectation), verifies from
  the data which attribution the participant counts carry, and stops if any
  Google Ads location identifier would reach two municipalities. The analysis
  script includes a calibration mode that measures the error rates of the
  exact code in this repository, and a separate script verifies that the
  locations configured in Google Ads match the assignment identifier by
  identifier before the campaigns launch.

## Repository map

```text
.
├── README.md                  this file
├── REPRODUCE.md               how to reproduce the assignment and analyses
├── analysis/r/
│   ├── 01_data_prep/          Google Ads crosswalk, grid geometry, reporter counts
│   ├── 02_power/              power analyses (primary and reporting outcomes)
│   ├── 03_randomization/      treatment assignment, pre-registered analysis,
│   │                          and the campaign-verification script
│   ├── archive/               earlier design explorations, superseded
│   └── output/                generated files; the committed subset is the
│                              public record of the experiment
├── data/raw/                  inputs (not committed; see Data availability)
└── docs/
    ├── preregistration/       the pre-registration of record
    ├── operations/            operational notes (measurement definitions,
    │                          Google Ads setup, data deposit)
    └── archive/               superseded design memos, kept as history
```

Campaign build files (Google Ads upload sheets, location identifier lists,
budgets) are in
[analysis/r/output/campaign_criteria_ids/](analysis/r/output/campaign_criteria_ids/).

## Data availability

The aggregate input data are available at [10.5281/zenodo.21940738](https://doi.org/10.5281/zenodo.21940738): participant counts by municipality and by province, and reporter
counts by municipality, all as counts per 60-day window with no identifiers,
coordinates, or per-person records. The deposited participants file is
byte-identical to the input recorded in
[the manifest](analysis/r/output/manifest_2026_final.txt), so anyone can
download it, confirm the checksum, run the assignment script, and verify that
the published assignment reproduces exactly.

Two public reference inputs are fetched from their sources rather than
committed: the Google Ads geographic targets table (from Google) and GADM
municipality boundaries. The only withheld input is the raw Mosquito Alert data from which the deposited aggregate reporter counts are built.

## Ethics

UPF's Institutional Committee for Ethical Review of Projects (CIREP) approved
this research as a modification to protocol 270 (originally approved on 21
July 2022; modification approved 30 July 2026). Mosquito Alert participants are citizen scientists, not research subjects;
the analysis uses municipality-level aggregate counts only, and no
individual-level or otherwise personally identifiable data are used.

## History

The design went through several earlier forms — provinces as units, freely
placed radius-targeted circles, postal codes, hurdle models, repeated
campaign waves — before reaching the registered design.
[analysis/r/archive/README.md](analysis/r/archive/README.md) and the git history document that
progression, including analyses that were corrected or superseded along the
way, and [docs/archive/](docs/archive/) holds the superseded design memos.

## Funding

This research is part of [IDAlert](https://idalertproject.eu), which has
received funding from the European Union's Horizon Europe programme under
Grant Agreement 101057554.
