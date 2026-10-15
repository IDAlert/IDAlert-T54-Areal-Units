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

## Sequence of events

| date | step | artifact |
|---|---|---|
| 14 Oct | post window closed; flight ended; closing exports verified | `VERIFIED.md`, creatives README |
| 15 Oct | threshold rule declared; secondary-analysis code committed | this file, `04_results/` |
| 15 Oct 15:57 | delivery-by-location report for the full flight pulled (840 rows, 42 per campaign; totals reconcile with the day-level file) | `data/google_ads/delivery_by_location_2026-08-17_to_2026-10-14.csv` (local) |
| 15 Oct | minimum-delivery subset fixed from it: 447 municipalities (217 framed, 230 neutral) with >= 5 installs; committed before any outcome file was opened | `min_delivery_subset_2026.csv` |
| | outcome extraction (analysis of record) | (to be filled in) |
| | primary analysis run | (to be filled in) |
