# Reproducing the Treatment Assignment

Everything needed to regenerate the exact set of municipalities used in the
study and their assignment to messaging arms — and, optionally, every
committed intermediate from its public source. All commands run from the
repository root.

## Requirements

R 4.4 or later, with:

```r
install.packages(c("sf", "terra", "sandwich", "lmtest", "dplyr", "geodata"))
```

## Data setup

The repository does not ship `data/raw/` — you create and populate it. Two
levels of reproduction are possible.

### Quick path — verify the assignment (about 2 minutes)

This needs only the deposited aggregate data: every other input to the
assignment (the Google Ads crosswalk and the grid geometry) is already
committed in `analysis/r/output/`. Download the three deposited files from
[10.5281/zenodo.21940738](https://doi.org/10.5281/zenodo.21940738) (CC-BY-4.0):

```bash
mkdir -p data/raw
base=https://zenodo.org/records/21940738/files
curl -L -o data/raw/participants_spain_municipality_aug_windows.csv \
  "$base/participants_spain_municipality_aug_windows.csv?download=1"
curl -L -o data/raw/participants_spain_province_aug_windows.csv \
  "$base/participants_spain_province_aug_windows.csv?download=1"
curl -L -o analysis/r/output/municipality_reporter_counts.csv \
  "$base/municipality_reporter_counts.csv?download=1"
md5sum data/raw/participants_*.csv analysis/r/output/municipality_reporter_counts.csv
# (macOS: use `md5` instead of `md5sum`)
```

Expected checksums (also listed in the deposit and in
`docs/operations/data-deposit-plan.md`):

| File | md5 |
|---|---|
| `participants_spain_municipality_aug_windows.csv` | `ee47f0e841790fcba139aaecf892bb9d` |
| `participants_spain_province_aug_windows.csv` | `ebd07219d817355eb60bd590af37e329` |
| `municipality_reporter_counts.csv` | `7b6dbf8559d40899a57052992de3ecfd` |

Then run **step 3** (and, for the power figures, step 4). The participants
file is byte-identical to the input checksummed in `manifest_2026_final.txt`,
so a successful step 3 reproduces `assignment_2026_final.csv` md5-for-md5.

### Full path — also rebuild the committed intermediates (about 25 minutes)

To regenerate the crosswalk and geometry rather than trust the committed
copies, additionally fetch the two public reference inputs and run steps 1–2
first:

- **Google Ads geo targets — the dated 2026-07-16 snapshot, specifically.**
  From https://developers.google.com/google-ads/api/data/geotargets download
  `geotargets-2026-07-16.csv` (~23 MB) and save it as
  `data/raw/google_ads_geotargets-2026-07-16.csv`. **The date matters:**
  Google revises this table continually, and Criteria IDs, names and entity
  types drift between snapshots, so only this version reproduces the
  committed crosswalk. It is not committed here (third-party data); if the
  dated snapshot is no longer offered, the committed crosswalk output remains
  the verifiable record.
- **GADM 4.1 boundaries, Spain level 4** (~50 MB; free for academic use, see
  https://gadm.org). Step 1 downloads this automatically via the `geodata`
  package into `data/raw/gadm/gadm41_ESP_4_pk.rds`, which step 2 then reads.
  To fetch it manually (e.g. to run step 2 without step 1):

  ```r
  geodata::gadm(country = "ESP", level = 4, path = "data/raw")
  ```

### Not available: the raw report export

`data/raw/mosquito_alert_raw_reports.Rds` is Mosquito Alert's internal
participant-level report data and is not distributed. Reproduction does not need
it: its only role is producing `municipality_reporter_counts.csv`, which is
deposited with its checksum, and
`build_municipality_reporter_counts.R` is committed so the derivation is
fully documented.

### Inputs at a glance

| File | Role | Where to get it |
|---|---|---|
| `data/raw/participants_spain_municipality_aug_windows.csv` | sampling effort participants, municipality × season × window (primary input) | Zenodo [10.5281/zenodo.21940738](https://doi.org/10.5281/zenodo.21940738) |
| `data/raw/participants_spain_province_aug_windows.csv` | province totals, for attribution verification | Zenodo (same record) |
| `analysis/r/output/municipality_reporter_counts.csv` | secondary (reporting) outcome counts | Zenodo (same record) |
| `data/raw/google_ads_geotargets-2026-07-16.csv` | full path only, step 1 | Google, dated snapshot (see above) |
| `data/raw/gadm/gadm41_ESP_4_pk.rds` | full path only, step 2 | `geodata::gadm()` (see above) |
| `data/raw/mosquito_alert_raw_reports.Rds` | authors only — builds the reporter counts | not distributed |

### Outcome attribution

Two attributions exist for participant counts:

| Attribution | Meaning |
|---|---|
| **Presence** | A participant is counted in every municipality where they emitted at least one background location track. Municipality counts sum to ~1.20x the true number of people. How the counts were produced through 2025. |
| **Modal** | Each participant is counted only in the municipality where they were observed on the most distinct days — where their sampling effort is concentrated. An exact partition. The attribution of the final deposited dataset. |

The
assignment script **verifies attribution from the data** — municipality sums
against province totals (1.000 = partition, 1.17–1.28 = presence) — and records
the verdict in the manifest rather than trusting the column name. See
`docs/operations/measurement-grid-and-modal-attribution.md`.

The secondary reporting outcome is attributed by **report location**:
reporting identifiers are deliberately not linkable to tracking identifiers, so
modal attribution cannot be computed for reporters.

## Steps

### 1. Google Ads crosswalk (full path only — the output is committed)

```bash
Rscript analysis/r/01_data_prep/build_google_ads_crosswalk.R \
  data/raw/google_ads_geotargets-2026-07-16.csv
```

Matches municipalities to Google Ads geo targets, requiring agreement on both
municipality name and autonomous community. Yields **952 targetable
municipalities** of the 8,240 GADM level-4 municipalities. (The deposited
participation data cover 8,244 level-4 units: these 8,240 plus the four
*plazas de soberanía*, which are not municipalities and not targetable —
hence the pre-registration's frame of 8,244.) Writes
`analysis/r/output/google_ads_spain_municipality_crosswalk.csv`.

The script stops if any Criteria ID resolves to two municipalities. It has to:
Spain repeats municipality names across regions, and a laxer match sent
"Cieza, Cantabria" to Google's Cieza in Murcia — putting one Google target into
two arms.

### 2. Grid-masking geometry (full path only — the outputs are committed)

```bash
Rscript analysis/r/01_data_prep/build_municipality_grid_geometry.R
```

Sampling effort locations are masked to a 0.025° grid before leaving the
participant's device — about 6 km² at Spanish latitudes —
and cells are assigned whole to the municipality holding their centroid. This
step measures, per municipality, how much of it the grid actually resolves —
area, cells, and the fraction of its cells lying entirely inside it — plus
distances to nearby municipalities. Municipalities spanning several GADM
polygons are unioned before measurement.

Writes `municipality_grid_geometry.csv` and
`municipality_neighbour_distances.csv`. The first fixes the pre-specified core
robustness subset before unblinding; the second drives the leakage model in the
power analysis.

Takes roughly 20 minutes.

### 3. Assignment

```bash
Rscript analysis/r/03_randomization/assign_treatment_2026.R
```

Selects every municipality that is targetable by name with a median pre-window
participant count of **at most 25** across 2021–2025 — **949 units** on the
final modal-attributed data, including 571 with zero baseline — and assigns them
in blocks of 9 (4 framed, 4 neutral, 1 no-ad), giving **420 / 420 / 109** (a
trailing partial block is assigned entirely to the no-ad arm — under block
fixed effects a single-arm block carries no identifying variation, and this
makes the ad arms exactly equal, every campaign exactly 42 municipalities, and
every budget exactly EUR 250).

There is no eligibility floor, and N follows from the eligibility rule rather than being
chosen. The upper cap excludes municipalities that would otherwise enter a pool
whose median is far below theirs, raising Type I
errors.
On the final data the cap excludes Barcelona, Madrid and Valencia.

The script simulates **Type I error on the realised draw** and warns if
either hypothesis is anti-conservative (above 0.09); below 0.02 it notes the
conservatism (HC3 over-corrects with block dummies and a small no-ad arm) but
does not warn, since randomization inference is the primary test. This is the
rate for the realised draw, not the design average over fresh randomisations.

Writes to `analysis/r/output/`:

- `assignment_2026_final.csv` — the full record, including `interior_frac` and
  `core_subset`
- `campaign_criteria_ids/` — per-campaign build files (CSV with full detail,
  canonical-name lists for the web UI, bare Criteria IDs), a single
  `google_ads_upload_all.csv`, an Editor import sheet
  (`editor_locations_import.csv`, Campaign + numeric Criteria ID — the only
  bulk path that cannot mis-resolve names), `campaign_budgets.csv`, and
  `NO_AD_do_not_target.txt`
- `manifest_2026_final.txt` — seed, RNG kinds, R version, outcome column,
  verified attribution, eligibility rule, realised Type I error, and md5
  checksums

To confirm you have reproduced the published assignment, compare the md5 in your
manifest against the one in this repository's committed manifest.

After building campaigns in Google Ads, verify what was actually configured:

```bash
Rscript analysis/r/03_randomization/verify_campaign_locations.R \
  data/google_ads/campaign_locations_2026-08-14.csv
```

This diffs every configured Criteria ID against the frozen assignment (Google's
geo table holds 180 Spanish provinces, cities and homonymous entities sharing a
display name with a study municipality, so name-based entry mis-resolves) and
refuses launch until it prints ALL CLEAR.

### 4. Power

```bash
Rscript analysis/r/02_power/run_final_2026_power.R          # primary outcome
Rscript analysis/r/02_power/run_report_outcome_power.R      # secondary (reports)
```

(A third script, `build_municipality_reporter_counts.R`, produces the reporter
counts the second command reads — but it requires the non-distributed raw
report export, so external reproducers download its deposited, checksummed output
instead; see *Data setup*.)

The main script reads the assignment and simulates power on it, resampling each
municipality's observed 2021–2025 pre/post pair so real year-to-year variation
is carried. Reports Type I error conditional on the realised draw, H1 power by
framing effect and delivery spread, H2 as a minimum detectable percentage,
sensitivity to leakage and to the share of installs that ever emit sampling
effort, and power on the core subset. The reports script does the same for the
secondary reporting outcome across a grid of report rates.

All power fits use the same model as the analysis: **block fixed effects** plus
the pre-window count and historical median.

### 5. Analysis (after the campaign)

```bash
Rscript analysis/r/03_randomization/analyse_assignment.R --outcomes=<2026_counts.csv>
Rscript analysis/r/03_randomization/analyse_assignment.R --outcomes=<...> --outcome=reports
Rscript analysis/r/03_randomization/analyse_assignment.R --demo        # simulated
Rscript analysis/r/03_randomization/analyse_assignment.R --calibrate   # Type I check
```

The pre-registered test: the arm coefficient from
`lm(post ~ arm + block + pre + historical_median)`, with randomization
inference — labels permuted **within blocks**, the design's own randomization
distribution — as the primary p-value, HC3 alongside, and confidence intervals
by exact inversion of the permutation test under a constant additive shift.
`--calibrate` verifies the committed code's Type I error end-to-end.

## Design summary

- **Units:** 949 Spanish municipalities targetable by name in Google Ads with a
  median pre-window modal-attributed participant count of at most 25 (no floor;
  571 units have zero baseline).
- **Arms:** framed (420) / neutral (420) / no-ad (109), Android only,
  EUR 5,000 across 20 campaigns of exactly 42 municipalities at EUR 250 each
  (~15 installs and EUR 5.95 per advertising municipality; contiguous baseline
  bands; `campaign_budgets.csv`).
- **Randomization:** block randomization, blocks of 9 formed by ordering on
  baseline participants, one random permutation of (4 framed, 4 neutral,
  1 no-ad) per full block; the trailing partial block goes to no-ad.
- **Timing:** single wave. Measurement anchor 15 August 2026 (pre window
  16 Jun – 14 Aug, post window 16 Aug – 14 Oct — the anchor day itself is
  excluded, matching every historical season); campaign launch 17 August,
  planned 30-day flight.
- **Analysis:** linear model on post-window counts with **block fixed effects**,
  the pre-window count and the historical median as covariates; randomization
  inference for the p-value.

Design rationale — why this allocation, this pool, this outcome — is in the
pre-registration (`docs/preregistration/preregistration-osf.md`); this file
covers only how to reproduce what was done.

## Reproducibility guarantees

1. Deterministic ordering, every tie broken explicitly, ending on a unique key.
   Without this the assignment would depend on input row order, because
   `sample()` assigns by position.
2. RNG kind pinned. R changed the default `sample()` algorithm in 3.6.0, so a
   bare `set.seed()` is not portable across versions.
3. Seed frozen at `20260815`. Do not change after preregistration.
4. Short final blocks are assigned entirely to the no-ad arm — deterministic
   and stated in advance. Under block fixed effects a single-arm block carries
   no identifying variation to either contrast, so as advertising units they
   would spend budget without adding information; as no-ad units they keep the frame complete at
   zero cost and make the ad arms exactly equal (420/420).
5. Manifest with input and output checksums, recording which outcome column was
   used and the verified attribution.

## What is not in the reproduction path

`analysis/r/archive/` holds the exploratory work that led here — provinces,
municipalities with radius targeting, freely placed circles, postal codes,
participant-level cohorts, Greece, repeated waves, and several corrections to
earlier analyses — together with its generated outputs. None of it is needed to
reproduce the final study. See `analysis/r/archive/README.md` for what each
script was for and why it was set aside. Superseded design memos are in
`docs/archive/`.
