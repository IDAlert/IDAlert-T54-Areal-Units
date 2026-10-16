# Results of the pre-registered analysis — analysis of record (15 October 2026)

Pre-registration: https://doi.org/10.17605/OSF.IO/XQWB3. Analysis code frozen
at tag `v1.0-preregistration` (`analyse_assignment.R`, with the 16 August
HC3/singleton fix). Sequence and declarations: `docs/operations/analysis-log-2026.md`.

## Data

Outcome files are the nightly cluster pipeline's outputs from the run of
15 October 2026, 02:30 — the first run whose data reach 14 October, the last
day of the post window (both 2026 windows complete, 60 of 60 days). Checks
performed by `prepare_outcomes_2026.R` before any arm-level quantity was
computed:

- the October extract's 2021–2025 municipality counts are **identical** to the
  deposited calibration data (10.5281/zenodo.21940738);
- modal attribution verifies as a partition on both 2026 windows
  (municipality sum / province sum = 1.000);
- the re-extracted 2026 pre-window covariate is 309 participants Spain-wide
  against 304 in the August extract (late uploads; 7 municipalities changed);
- the 2026 reporter counts were rebuilt by the committed builder from a
  reports export running through 14 October; its 2021–2025 rows are
  identical to the deposited file.

The minimum-delivery subset was fixed and committed (`be88f63`) before any
outcome file was opened. An erratum to the registered description of modal
attribution was recorded and committed (`5c70418`) before extraction; see the
pre-registration's errata section.

## Primary and secondary hypothesis tests (frozen code)

Linear model on post-window counts with block fixed effects, the pre-window
count and the historical median; randomization inference within blocks
(10,000 permutations) as the primary p-value, HC3 alongside, 95% interval by
exact inversion of the permutation test.

| outcome | hypothesis | estimate (participants / municipality) | vs control | p (RI) | p (HC3) | 95% CI (RI) | n |
|---|---|---|---|---|---|---|---|
| sampling effort (primary) | **H1** framed vs neutral | +0.12 | +11% | 0.305 | 0.338 | −0.11 to +0.35 | 840 |
| sampling effort (primary) | **H2** ads vs none | +0.50 | +97% | **0.003** | <0.001 | +0.19 to +0.82 | 949 |
| reporters (secondary) | H1 framed vs neutral | +0.03 | +1% | 0.895 | 0.898 | −0.33 to +0.39 | 840 |
| reporters (secondary) | H2 ads vs none | +1.20 | +79% | **0.0003** | 0.058 | +0.59 to +1.81 | 949 |

Control means: sampling effort, neutral 1.04 and no-ad 0.52; reporters,
neutral 2.37 and no-ad 1.51.

**H2 is supported** on the primary outcome, with both tests in agreement:
geographically targeted advertising roughly doubled the number of distinct
sampling-effort participants relative to municipalities with no campaign. On
the reporting outcome the primary test also supports H2; the HC3 companion
agrees in direction but sits at 0.058. Under the registered rule this
disagreement is reported, not resolved by picking: the randomization test is
the primary test and is far from the boundary, while HC3's leverage penalty
on a heavily skewed count is the likely source of the gap.

**H1 is not supported** on either outcome. The primary estimate is positive
(+11%) with an interval from −11% to +34%. As registered, a null H1 is not
evidence of no effect: the manipulation check passed (H2), so H1 is
interpretable, but the study was powered on a planned 15 installs per
municipality each becoming a tracked participant, and the realized dose in
those terms was far smaller (next section). The interval is the informative
quantity.

## Realized delivery (pre-registered diagnostics, items 5 and 6)

| | framed | neutral |
|---|---|---|
| spend (EUR) | 1,715.53 | 1,839.06 |
| impressions | 1,819,680 | 1,982,753 |
| installs | 5,350 | 5,567 |
| installs per municipality: mean / median | 12.7 / 5 | 13.3 / 6 |
| municipalities with zero installs | 96 | 90 |
| sd of log installs (installs > 0) | 1.25 | 1.23 |

Delivery was closely matched between arms, so the caveat the pre-registration
attaches to H1 in the event of unequal delivery does not apply. Installs per
municipality ran at about 85% of plan, but the H2 estimate implies that only
on the order of 4 of every 100 installs became a distinct participant emitting
sampling effort in the window (0.50 extra participants from about 13
installs) — far below the 15% track-emission rate at which the registered
sensitivity table already put H1 power at 0.30. The 2026 season was also
atypically quiet: the no-advertising level, 0.52 participants per
municipality, is less than half the 1.14 the power simulations assumed.

Within the framed arm, Google's optimizer allocated **80% of impressions and
83% of installs to the prevention-focused ad groups** (prevention 1.45 M
impressions, 4,414 installs, EUR 0.31 per install; promotion 0.37 M, 936,
EUR 0.36), consistently across campaigns (prevention share 53–90%). The
framed-versus-neutral contrast as implemented is therefore predominantly a
prevention-framing contrast. As registered, no inference is drawn from the
orientation split.

## Pre-specified secondary and exploratory analyses

| item | analysis | hypothesis | estimate | vs control | p (RI) | p (HC3) | 95% CI | n |
|---|---|---|---|---|---|---|---|---|
| 1 | presence-attributed outcome (tertiary) | H1 | +0.20 | +11% | 0.190 | 0.219 | −0.10 to +0.49 | 840 |
| 1 | presence-attributed outcome | H2 | +0.65 | +59% | **0.003** | <0.001 | +0.23 to +1.08 | 949 |
| 2 | core subset (interior ≥ 0.25) | H1 | +0.38 | +32% | 0.054 | 0.124 | −0.01 to +0.78 | 404 |
| 2 | core subset | H2 | +0.61 | +169% | 0.016 | 0.007 | +0.11 to +1.12 | 446 |
| 4 | equal-exposure (impressions covariate; HC3) | H1 | +0.14 | +14% | — | 0.237 | −0.09 to +0.38 | 840 |
| 7 | minimum-delivery subset (≥ 5 installs; HC3, descriptive) | H1 | +0.11 | +7% | — | 0.652 | −0.38 to +0.61 | 442 |
| 8 | activation subgroup (571 zero-baseline) | H2 | +0.37 | +306% | **0.017** | <0.001 | +0.09 to +0.64 | 571 |
| 8 | activation subgroup | H1 | +0.15 | +39% | 0.117 | 0.131 | −0.03 to +0.33 | 504 |

Singleton-block units dropped before fitting, as the code specifies: 2 (core
H2), 5 and 1 (item 7).

The **presence-attributed outcome** (item 1) matters more than its tertiary
status suggests, because of the erratum on modal attribution: it counts a
participant in every municipality where they emitted sampling effort, so it
does not depend on where their days concentrated, and it reproduces both
conclusions — H2 supported, H1 null at the same +11%. (Its control levels are
higher — no-ad 1.10, neutral 1.77 — because visitors are counted too.) The
presence extract was produced from the cluster run of 16 October, one day
later than the analysis-of-record modal extraction; the difference is at most
one further day of late uploads.

**Realized leakage (item 3).** The within-province multi-municipality ratio
for 2026 — presence municipality sum over presence province sum — is 1.67 in
the pre window and **1.56 in the post window**, against 1.17–1.28 in
2021–2025. Participants in 2026 were recorded in markedly more municipalities
than in the calibration years, so leakage of advertising-induced
participation across municipality lines was heavier than the registered
central case (lambda ≈ 0.15); the registered "heavy leakage" row (lambda =
0.30, H1 power 0.77 at the planned dose) is the closer description. Leakage
attenuates the arm contrast, so this reinforces, rather than qualifies, the
registered reading of the null H1.

The **activation result** is the clearest secondary finding: among
municipalities with no recent Mosquito Alert activity at all, advertising
created sampling-effort participation where there was none (no-ad level 0.12
per municipality). Every H1 estimate across the primary, secondary and subset
analyses is positive, and the core-subset H1 is borderline (RI p = 0.054), but
under the registered rule a secondary result cannot rescue a null primary;
these are reported as suggestive and consistent in direction, nothing more.

Pending: the declared late-upload sensitivity check, from the cluster run of
21 October or later (modal, reports and presence from the same run).

## Caveats carried from the flight record

- **Erratum:** modal attribution is computed within each window, not over the
  participant's full history (pre-registration errata, 15 October). H1 is
  unaffected; the H2 limitation is stronger than registered, and the
  presence-attributed outcome is the relevant robustness comparison.
- **Policy limitation:** from early September all 70 ads in both arms were
  "Approved limited" under Google's Misleading Ad Design policy; equal across
  arms, so not the arm-differential filtering the contingency guards against.
- **Cap enforcement lapse:** three campaigns overran the EUR 250 cap before
  being paused on 14 October; the lapse-attributable spend difference favours
  the neutral arm (EUR 22), conservative for H1.
- **Season:** 2026 participation was far below the calibration years, which
  the registration flagged in advance.

## Files

`analysis/r/output/`: `outcomes_2026.csv`, `outcomes_2026_checks.txt`,
`primary_results_2026_tracks.log`, `primary_results_2026_reports.log`,
`secondary_results_2026.csv` (+ `.log`, `_delivery_by_arm.csv`),
`orientation_delivery_2026.csv` (+ `.log`), `min_delivery_subset_2026.csv`.
