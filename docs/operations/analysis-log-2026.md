# Outcome extraction and analysis log, 2026

Dated record of every step from the close of the post window (14 October
2026) to the reported results, in the order it happened. Written so that the
sequence required by the pre-registration — delivery-based decisions fixed
before outcome data are examined; one analysis of record — is auditable from
the git history of this file and of the artifacts it names.

## 15 October — declarations made before any outcome data were examined

**1. Minimum-delivery threshold (pre-registration, *Other planned analysis*,
item 7).** Rule: a municipality is in the minimum-delivery subset if Google
Ads reports **at least 5 installs** (conversions) for it over the full flight,
17 August – 14 October 2026, in the delivery-by-location report pulled on
15 October 2026. Five is about one third of the 15.3 installs per municipality
the campaign planned. The resulting list is written by
`analysis/r/04_results/fix_min_delivery_subset.R` to
`analysis/r/output/min_delivery_subset_2026.csv` and committed before outcome
extraction. Later re-pulls of the delivery report (conversion counts settle
for some days after the flight) feed the delivery diagnostics only; the
subset is not re-derived.

**2. Analysis of record.** The outcome extraction performed on or about
15 October 2026 — modal-attributed participant counts for the post window
16 August – 14 October, the re-extracted 2026 pre-window covariate, the
presence-attributed 2026 extract, and the 2026 reporter counts built by the
committed builder — is the **analysis of record** for every pre-registered
test. The pre-registration anticipates late-arriving background tracks; to
measure them without creating a second look at the outcome, **one**
re-extraction will be performed on or after 21 October 2026 and analysed with
the same frozen code as a declared *late-upload sensitivity check*, reported
alongside the analysis of record whatever either shows. The analysis of
record is not replaced by it.

**2a. Erratum to the registered description of modal attribution — found
and recorded before any outcome data were examined.** While locating the code
that generates the participant counts for the outcome extraction, the rule
actually implemented was found to differ from the registered description. The
generator is `scripts/z1_participants_areal_units_weekly.R` in the
`mosquito_model_data_prep` repository (commit `539a22ae8`, 14 August 2026,
"counting only in home municipality"), which runs nightly on the cluster and
produced the deposited August data. It assigns each participant, **within each
60-day window separately**, to the municipality in which they were tracked on
the most distinct days *in that window*, ties broken by participant-cell-days
and then by unit identifier. The pre-registration (*Indices*) describes the
modal municipality as "computed over the participant's full sampling effort
history rather than the study window alone", with ties "broken by number of
distinct grid cells, then by GADM `GID_4`", and says this "makes the assignment
effectively pre-treatment for existing participants". No version of the
generator ever implemented the full-history rule; the description was written
from the data specification sent to the pipeline, not from the code.

Resolution: the **rule is not changed**. The deposited calibration data
(2021–2025), the pre-window covariate and the outcome are all produced by the
same within-window rule, so they remain exactly comparable, and the
municipality/province partition property the assignment script verifies holds
under it. The **description is corrected** (errata section appended to the
repository copy of the pre-registration; the OSF registration is unchanged).
Consequences for inference: H1 is unaffected — the rule is identical in both
advertising arms. For H2, the registered limitation that modal attribution is
"computed partly from post-treatment data" understates the case: for the post
window it is computed entirely from post-window tracks, so the mechanism the
registration describes (advertising-induced activity inside the targeted
municipality pulling borderline participants into it) applies in full. The
presence-attributed tertiary outcome (item 1), registered as the robustness
comparison for exactly this, therefore carries more weight for H2 than
anticipated, and the H2 result will be reported with this caveat foregrounded.

**2b. Extraction source.** The outcome files are the nightly cluster
pipeline's `data/proc/participants_spain_{municipality,province}_aug_windows.csv`
from the first run whose data reach 14 October 2026 (expected 16 October), with
`mosquito_alert_raw_reports.Rds` from the same run. The analysis-of-record
declaration in item 2 refers to that run; the late-upload sensitivity check is
the same files from the run of 21 October or later. The presence-attributed
extract is produced by the companion script
`scripts/z1b_participants_spain_windows_presence.R` (added 15 October) from the
same tracks file.

**3. Code.** The primary analysis is `analyse_assignment.R` (frozen at tag
`v1.0-preregistration`, with the HC3/singleton fix of 16 August). The
pre-specified secondary and exploratory analyses are implemented in
`analysis/r/04_results/` and committed before outcome extraction:

- `prepare_outcomes_2026.R` — derives the outcomes file the frozen script
  reads from the raw extracts; re-verifies modal attribution on the 2026
  windows (municipality/province ratio); computes the realized 2026
  multi-municipality ratio from the presence-attributed extract (item 3).
- `fix_min_delivery_subset.R` — item 7's list (above).
- `secondary_analyses_2026.R` — items 1 (presence attribution), 2 (core
  subset), 4 (equal-exposure estimate), 5 (delivery distributions by arm),
  7 (minimum-delivery subset, descriptive), 8 (activation subgroup).
- `orientation_delivery_2026.R` — item 6 (prevention vs promotion
  delivery within the framed arm, descriptive).

**4. Provenance of the extractions.** The data-prep pipeline commits its
run logs automatically after each nightly cluster run
(`Mosquito-Alert/mosquito_model_data_prep`, commits "log files from cluster
run (automated)"). The `z1_participants_areal_units_weekly.out` log in each
commit records the data range the run used:

| run | commit | log line | role |
|---|---|---|---|
| 15 Oct 2026 (committed 05:45 +0200) | `84c6d3d89` | counts written for 2018-01-01 **to 2026-10-14** | analysis-of-record extraction (modal participants, province totals, reports) |
| 16 Oct 2026 (committed 05:43 +0200) | `a8613978e` | counts written for 2018-01-01 **to 2026-10-15** | presence extract (`z1b`, run ~11:45 on 16 Oct against this run's tracks) |

## Sequence of events

| date | step | artifact |
|---|---|---|
| 14 Oct | post window closed; flight ended; closing exports verified | `VERIFIED.md`, creatives README |
| 15 Oct | threshold rule declared; secondary-analysis code committed | this file, `04_results/` |
| 15 Oct 15:57 | delivery-by-location report for the full flight pulled (840 rows, 42 per campaign; totals reconcile with the day-level file) | `data/google_ads/delivery_by_location_2026-08-17_to_2026-10-14.csv` (local) |
| 15 Oct | minimum-delivery subset fixed from it: 447 municipalities (217 framed, 230 neutral) with >= 5 installs; committed before any outcome file was opened | `min_delivery_subset_2026.csv` |
| 15 Oct | generator of the participant counts located in `mosquito_model_data_prep`; within-window modal rule found; erratum recorded (item 2a) | this file; prereg errata section |
| 15 Oct 02:30 | nightly cluster run whose data reach 14 Oct: the analysis-of-record extraction (both 2026 windows complete; reports through 14 Oct). Files copied 15 Oct 18:02 | `data/raw/*_2026-10.csv`, `mosquito_alert_raw_reports.Rds` (local) |
| 15 Oct 18:03 | reporter counts rebuilt; 2021–2025 rows identical to the deposit | `municipality_reporter_counts.csv` (local; v2 deposit) |
| 15 Oct 18:06 | outcomes file built; checks passed (2021–2025 identical; ratio 1.000; pre-window 309 vs 304) | `outcomes_2026.csv`, `outcomes_2026_checks.txt` |
| 15 Oct 18:08 | **primary analysis run**: H2 supported (p 0.003), H1 not supported (p 0.305) | `primary_results_2026_tracks.log` |
| 15 Oct 18:12 | reports outcome: H2 p 0.0003 (HC3 0.058), H1 p 0.895 | `primary_results_2026_reports.log` |
| 15 Oct 18:20 | secondary analyses (items 2, 4, 5, 7, 8) and orientation table (item 6) | `secondary_results_2026.*`, `orientation_delivery_2026.*` |
| 16 Oct ~11:45 | presence extract produced on the cluster by `z1b` from the 16 Oct run's tracks (one day later than the record extraction; noted); copied 11:49 | `data/raw/*_presence_2026-10.csv` (local) |
| 16 Oct 12:05 | item 1 (presence outcome: H2 +59% p 0.003; H1 +11% p 0.19) and item 3 (within-province ratio 1.67 / 1.56 vs 1.17–1.28) added; all other items reproduce exactly | `outcomes_2026.csv` (presence columns added; record columns unchanged), `secondary_results_2026.*` |
| ≥ 21 Oct | late-upload sensitivity check: same files from a later cluster run | |

Results: `docs/results/results-2026.md`.
