# Regulatory-Focus Framing in Geo-Targeted Ads for Citizen Science

**IDAlert Task 5.4 — a randomized experiment across 949 Spanish municipalities,
August–October 2026.**

Does the *content* of a recruitment message change how well geographically
targeted advertising recruits citizen scientists — and does such advertising
recruit at all, including in places with no existing participation?

Every Spanish municipality that Google Ads can target by name, and whose
existing [Mosquito Alert](https://www.mosquitoalert.com) activity is below a
pre-specified cap, is randomly assigned to one of three arms:

| Arm | Units | Treatment |
|---|---|---|
| Framed | 420 | Android app-install ads using regulatory-focus framing |
| Neutral | 420 | Identical ads with neutral framing |
| No advertising | 109 | Nothing |

Ads run from 17 August 2026 (EUR 5,000 total, 20 campaigns of 42 municipalities
at EUR 250 each). The primary outcome is the number of distinct people whose
modal sampling municipality is the unit and who emit Mosquito Alert background location
tracks during the 60-day post window (16 Aug – 14 Oct); people submitting
mosquito reports are the secondary outcome. 571 of the municipalities have no
recent activity at all, so the ads-versus-nothing contrast is in part an
**activation** experiment.

## The three documents that matter

| Document | What it is |
|---|---|
| [docs/preregistration/preregistration-osf.md](docs/preregistration/preregistration-osf.md) | **The registration of record** — hypotheses, design, analysis plan, power, limitations, structured against the OSF Preregistration form |
| [REPRODUCE.md](REPRODUCE.md) | How to regenerate the assignment bit-for-bit and rerun every power figure |
| [analysis/r/output/manifest_2026_final.txt](analysis/r/output/manifest_2026_final.txt) | The frozen assignment's seed, eligibility rule, checksums, and verification results |

## Design in brief

- **Randomization**: units ordered by baseline participation (median over
  2021–2025, modal-attributed), cut into blocks of 9, each full block randomly
  permuted 4 framed / 4 neutral / 1 no-ad; a trailing partial block goes to
  the no-ad hold-out. Frozen seed, pinned RNG, bit-reproducible.
- **Analysis** (pre-registered): linear model on post-window counts with block
  fixed effects, the pre-window count and the historical median as covariates.
  Randomization inference — labels permuted within blocks — is the primary
  test; HC3 is the parametric companion; confidence intervals invert the
  permutation test exactly.
- **Power**: 0.92 at a 15% framing advantage (moderate delivery spread), ~1.00
  at 20%; the ads-versus-nothing contrast detects roughly +110% over the
  no-ad arm's 1.1 participants.
- **Verification is built in**: the assignment script checks Type I error on
  the realized draw, verifies outcome attribution from the data (municipality
  sums against province totals), and hard-stops on duplicate Google Ads
  Criteria IDs. The analysis script has a `--calibrate` mode that measures the
  committed code's own error rates, and
  `verify_campaign_locations.R` gates launch on the configured Google Ads
  locations matching the frozen assignment ID-for-ID.

## Repository map

```text
.
├── README.md                  this file
├── REPRODUCE.md               regenerate everything
├── analysis/r/
│   ├── 01_data_prep/          Google Ads crosswalk, grid geometry, reporter counts
│   ├── 02_power/              power for the final design (primary + reports outcome)
│   ├── 03_randomization/      THE assignment script, THE analysis script, launch gate
│   ├── archive/               the exploration that led here (+ its outputs, local)
│   └── output/                generated files; the committed subset is the public record
├── data/raw/                  inputs (participant-derived extracts not committed)
└── docs/
    ├── preregistration/       the registration document of record
    ├── operations/            live operational notes (measurement, Google Ads setup)
    └── archive/               superseded design memos, kept as history
```

Campaign build files (Google Ads upload CSVs, canonical-name lists, budgets)
are in
[analysis/r/output/campaign_criteria_ids/](analysis/r/output/campaign_criteria_ids/).

## Data availability

The aggregate inputs are published openly at
**[10.5281/zenodo.21940738](https://doi.org/10.5281/zenodo.21940738)** (CC-BY-4.0): modal-attributed participant counts by
municipality and by province, and municipality-level reporter counts. Because
the deposited participants file is byte-identical to the one checksummed in
`manifest_2026_final.txt`, anyone can download it, confirm the md5, rerun
`assign_treatment_2026.R`, and check that the assignment reproduces.

Larger or participant-level inputs are not distributed here. Public reference inputs are fetchable from
their sources (Google Ads geotargets from Google, GADM boundaries from GADM);
the participant window counts and raw report export must be obtained as
described under *Data availability* in the pre-registration. Every committed output lists its input checksums in the manifest,
so a supplied data file can be verified against the exact bytes the assignment
was generated from.

## Ethics

UPF's Institutional Committee for Ethical Review of Projects (CIREP) approved
this research as a modification to protocol 270 (originally approved on 21 July
2022; modification approved 30 July 2026). Individuals exposed to
advertisements are not enrolled as research subjects; the analysis uses
municipality-level aggregate counts only.

## History

The design went through provinces, radius-targeted circles, postal codes,
hurdle models and repeated waves before landing here.
[analysis/r/archive/README.md](analysis/r/archive/README.md) documents that
arc — including the corrections — and [docs/archive/](docs/archive/) holds the
superseded memos. The git history is the timestamped record that every design
decision preceded the campaign launch.

## Funding

This research is part of [IDAlert](https://idalertproject.eu), which has received funding from the European Union's Horizon Europe programme under Grant Agreement 101057554.
