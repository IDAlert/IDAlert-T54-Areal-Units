# Open data deposit: what to publish, where, and when

**Status:** cleared and in progress, 2026-08-15.
**DOI: [10.5281/zenodo.21940738](https://doi.org/10.5281/zenodo.21940738)**

## 1. Why this matters more than it looks

`manifest_2026_final.txt` records md5 checksums of the files the assignment was
generated from. Today nobody outside the project can obtain those files, so the
checksums are unfalsifiable assertions rather than verifiable ones. Depositing
the inputs converts the whole reproducibility chain into something a reader can
actually execute:

```
deposited input  --md5-->  manifest  --script-->  assignment  --md5-->  committed CSV
```

The strongest version of this is to deposit the **pre-treatment inputs now,
before any outcome exists**. That timestamps exactly the bytes the randomization
consumed, so the claim "the design was fixed before outcomes were observed" is
independently checkable rather than a matter of trust. Post hoc deposit, after
the October outcome pull, cannot establish the same thing.

## 2. What to deposit

| File | Size | Content | When |
|---|---|---|---|
| `participants_spain_municipality_aug_windows.csv` | 20.6 MB | Modal-attributed background-track participant counts, 8,244 municipalities × 2018–2026 × pre/post 60-day windows. **md5 `ee47f0e8…` — the exact bytes in the manifest.** | now |
| `participants_spain_province_aug_windows.csv` | 0.1 MB | Same, aggregated to province. Used only for the attribution check. | now |
| `municipality_reporter_counts.csv` | 1.6 MB | Distinct reporters and reports per municipality × season × window, 2021–2025. Secondary outcome calibration. The report export ends one day before the 2026 pre-window closes, so 2026 is absent; it arrives with the outcome version. | now |
| 2026 outcome extracts (same schemas) | — | The post-window counts | after 14 Oct 2026 |

**Deposit byte-identical copies.** Do not tidy, re-sort, or drop rows before
uploading: the verification argument depends on the deposited file hashing to
the value already published in the manifest. In particular the 2026 `after`
rows are present with `window_complete = FALSE`, `days_observed = 0` and counts
of 0 — they are placeholders, not outcomes, and must be explained in the data
dictionary rather than removed.

**Do not deposit** `mosquito_alert_raw_reports.Rds` (participant-level, with
identifiers and precise coordinates) — it is the input to the reporter counts,
not a publishable product.

## 3. Zenodo, not the git repository

The repository is the right home for code, the assignment, and the manifest;
it is the wrong home for data. Zenodo gives a DOI, immutable versioning, and a
citation, and it is where Mosquito Alert already publishes aggregate data
products. 20 MB in git would also be an odd precedent for a repo whose stated
policy is that participant-derived extracts stay out of version control.

Suggested deposit metadata:

- **Title:** Aggregate Mosquito Alert participation counts by Spanish
  municipality, 2018–2026 (IDAlert T5.4)
- **License:** CC-BY-4.0
- **Related identifiers:** *is supplement to* the OSF registration
  (10.17605/OSF.IO/XQWB3); *is supplement to* the code archive
  (10.5281/zenodo.21969063, release `v1.0-preregistration`)
- Cite the deposit DOI back in the pre-registration and `REPRODUCE.md`, and
  add the DOI to the repository README, so the link works in both directions.

## 4. Disclosure profile, against what is already public

Both files are counts of people aggregated to municipality × 60-day window.
Neither contains identifiers, coordinates, dates finer than a 60-day window,
device information, or any per-person record.

| | participants | reporters |
|---|---|---|
| Rows | 148,392 | 41,200 |
| Cells equal to 0 | 92.8% | 92.8% |
| Cells equal to 1 | 4.4% | 4.3% |
| Cells 2–4 | 2.0% | — |
| Maximum cell | 822 | — |

**The relevant comparison is with Mosquito Alert's existing public releases.**
The platform already publishes sampling-effort data giving the number of
participants per 0.025° × 0.025° cell **per day**, and all reports are public.
Both are *finer* than what is proposed here on both axes:

| | already public | proposed deposit |
|---|---|---|
| Spatial unit | 0.025° cell (~6 km²) | municipality (median ~35 km²) |
| Temporal unit | day | 60-day window |

So the presence signal in this deposit is a strict coarsening of data already
open. The only element not derivable from the public releases is the **per-user
modal assignment** — because the public cell-day file contains counts, not
per-user records, one cannot reconstruct which municipality any individual
sampled in most. What the deposit adds is therefore the aggregate statement
"N participants concentrate their sampling here", at coarser resolution than
the daily presence data already published.

The residual consideration is the **small-count cells**: roughly 6,500
municipality-windows contain exactly one person. In a small municipality a
reader with local knowledge could infer that a specific individual used the app
in that window — but the already-public daily cell data supports the same
inference at finer resolution, so the marginal disclosure from this deposit is
slight.

Conventional small-count suppression (drop cells < 5) is **not** an option
here: the design is built on zeros and ones, so suppression would destroy the
very reproducibility the deposit exists to provide, while leaving the published
analysis unverifiable. The honest choice is to publish in full or not at all —
and publishing in full is consistent with what the platform already does.

## 5. Deposit record

Cleared for publication. Deposited at **[10.5281/zenodo.21940738](https://doi.org/10.5281/zenodo.21940738)**, CC-BY-4.0.

| File | md5 |
|---|---|
| `participants_spain_municipality_aug_windows.csv` | `ee47f0e841790fcba139aaecf892bb9d` |
| `participants_spain_province_aug_windows.csv` | `ebd07219d817355eb60bd590af37e329` |
| `municipality_reporter_counts.csv` | `7b6dbf8559d40899a57052992de3ecfd` |

The first of these is the byte-identical file recorded as an input in
`manifest_2026_final.txt`, which is what closes the verification chain in §1.

## 6. Cross-referencing, both directions

Done: the DOI now appears in `README.md`, `REPRODUCE.md`, the
pre-registration's *Data availability* section, and — via `DEPOSIT_DOI` in
`assign_treatment_2026.R` — in `manifest_2026_final.txt` itself, so the
manifest names the archive its inputs came from and the archive names the
manifest. `docs/operations/zenodo-description.html` is the paste-ready deposit
description carrying the same checksums.

## Data dictionary

**`participants_spain_municipality_aug_windows.csv`** — one row per
municipality × season × window.

| Column | Meaning |
|---|---|
| `year` | Season (2018–2026) |
| `period` | `before` or `after` the anchor |
| `anchor_date` | 15 August of that season |
| `window_start`, `window_end` | Window bounds. Pre = 16 Jun–14 Aug; post = 16 Aug–14 Oct. The anchor day belongs to neither window. |
| `window_complete` | `FALSE` where the data do not yet cover the whole window — **2026 `after` rows are placeholders with `days_observed = 0` and counts of 0, not outcomes** |
| `days_observed` | Days of data actually covered |
| `GID_0`…`NAME_4` | GADM identifiers and names (country, autonomous community, province, municipality) |
| `n_gadm_units` | GADM polygons merged into this municipality |
| `n_grid_cells` | 0.025° masking-grid cells attributed to this municipality (centroid rule) |
| `n_participants` | **Distinct people whose modal sampling municipality is this unit and who emitted ≥1 background location track in the window.** Modal sampling municipality = the municipality with the most distinct days observed over the user's full history — where that participant's sampling effort is concentrated. This is **not** a residence claim. Despite the legacy column name, this is modal attribution, not presence; verify with the municipality/province sum ratio (1.00 = partition). |

**`participants_spain_province_aug_windows.csv`** — same, aggregated to
province; `n_participants` is deduplicated within province.

**`municipality_reporter_counts.csv`** — one row per municipality × season
(2021–2025).

| Column | Meaning |
|---|---|
| `unit_name` | `NAME_4, NAME_2` |
| `year` | Season |
| `pre_reporters`, `post_reporters` | Distinct users submitting ≥1 geolocated non-mission report (adult mosquito, bite, breeding site) in the window |
| `pre_reports`, `post_reports` | Report counts for the same windows |

Reports are attributed by **report location** (point-in-polygon), not by modal
sampling municipality:
reporting identifiers are deliberately not linkable to tracking identifiers.
