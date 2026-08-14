# Measuring participation: the masking grid, and home assignment

**Status** Decided 2026-08-13; **home-assigned data delivered 2026-08-14** and
verified (municipality sums equal province totals exactly, ratio 1.000, every
year and window — the signature of a partition). The delivery keeps the
historical column name `n_participants`, so the assignment script verifies
attribution from the data (municipality/province sum ratio) rather than
trusting the name, and records the result in the manifest.

Under home attribution per-unit medians fell to 0.76–0.80 of presence values,
with none rising. The final design (2026-08-14) also removed the eligibility
floor and extended calibration to 2021–2025: the pool is now all 949 nameable
municipalities with median at most 25, of which 571 have zero baseline. Only
Barcelona, Madrid and Valencia are excluded by the cap; Vigo and Sevilla, once
excluded, re-entered as the data and calibration window changed.

Also fixed 2026-08-14: municipalities spanning several GADM polygons (54 in
Spain — Murcia, Zaragoza, Málaga, ...) are now **unioned** before measuring
area, cells, interior fraction and distances. An earlier version kept only the
first polygon, which computed geometry on a fragment; Murcia's interior
fraction, for instance, was 0.00 on the fragment and is 0.72 on the union.

Implemented in `analysis/r/01_data_prep/build_municipality_grid_geometry.R` and
reflected in the assignment and power scripts.

The outcome is "distinct people emitting Mosquito Alert background location
tracks in a municipality." Two features of how that is computed affect the
design, and they pull in opposite directions.

---

## 1. Tracks are masked to a 0.025 degree grid

Before aggregation, track locations are snapped to a 0.025 x 0.025 degree grid.
At Spanish latitudes one cell is:

| Latitude | N–S | E–W | Area |
|---|---|---|---|
| 36 N | 2.78 km | 2.25 km | 6.3 km² |
| 40 N | 2.78 km | 2.13 km | 5.9 km² |
| 43 N | 2.78 km | 2.04 km | 5.7 km² |

### Cells partition cleanly

Municipality cell counts sum **exactly** to the province totals (85,767 =
85,767 for 2024), and reconstructing the assignment by "cell centroid falls
inside municipality" reproduces the recorded `n_grid_cells` for 98% of units.
So each cell belongs wholly to one municipality. No territory is double
counted, and there is no inflation from the grid itself.

### But the fit is poor at the unit level

Among the 448 eligible municipalities:

| | |
|---|---|
| Median area | 54.7 km² |
| Median cells | 9 |
| **Median share of a unit's cells lying fully inside it** | **0.22** |
| Units with no fully interior cell | 149 (33%) |
| Units smaller than one cell | 10 |

About **78% of a typical study municipality's cells straddle its boundary**, so
activity just outside can be recorded inside, and vice versa.

### Why this needs less correction than it looks

The historical 2021–2024 counts used to calibrate unit-level noise were built
with the **same** masking. Whatever extra variance the straddling cells create
is therefore already inside the observed year-to-year variation that the power
simulation resamples. Nothing needs adding for measurement noise.

What is *not* automatic is leakage of the treatment **signal** — ad-induced
participants recorded outside the municipality that was targeted. That is
modelled explicitly as `lambda` in `run_final_2026_power.R`.

### Why we did not select on geometry

Two tempting fixes both fail on arithmetic:

| Constraint | Units surviving |
|---|---|
| None | 448 |
| Interior cell fraction ≥ 0.25 | 211 |
| Interior cell fraction ≥ 0.50 | 71 |
| ≥ 5 km from any other eligible unit | 198 |
| ≥ 5 km **and** interior fraction ≥ 0.25 | 131 |

Power is driven by unit count far more than by dose (224/224 gives H1 power
0.87 at 28.6 installs each; 100/100 gives 0.58 at 64 installs each). Simulating
leakage directly:

| Design | Units | λ=0 | λ=0.15 | λ=0.30 |
|---|---|---|---|---|
| **Unit randomisation, all 448** | 448 | **0.87** | **0.85** | **0.80** |
| Cluster randomisation, all 448 | 448 | 0.88 | 0.73 | 0.46 |
| Unit randomisation, ≥5 km apart | 198 | 0.59 | 0.45 | 0.34 |

Plain unit randomisation on the full pool is the most robust. It survives
because leaked participants land in neighbours that are ~45% framed and ~44%
neutral, so contamination largely cancels, and because study units are only
5.4% of Spain's municipalities, most leakage exits the study rather than
landing in the opposite arm. Cluster randomisation is worse on both counts:
touching-clusters do not contain 3 km spillover, and its Type I error reaches
0.098 under leakage.

**Retained instead:** `interior_frac` is carried in the assignment file, and
the 211 units at ≥ 0.25 form a pre-specified robustness subset fixed before
unblinding.

---

## 2. Participants are counted by presence, not residence

A user is currently counted in **every** municipality where they emitted a
track. Summing over municipalities therefore exceeds the number of people:

| Year | before | after |
|---|---|---|
| 2018–2020 | 1.62–1.99 | 1.71–1.88 |
| 2021 | 1.257 | 1.281 |
| 2022 | 1.191 | 1.267 |
| 2023 | 1.185 | 1.229 |
| 2024 | 1.179 | 1.223 |
| 2025 | 1.174 | — |

**~20% of participant–municipality records are a second sighting of someone
already counted elsewhere**, stable since 2021. The 1.6–2.0 era before 2021 is
a different tracking regime — one of the reasons calibration is restricted to
2021 onward.

It is **not** a holiday or tourism effect, which is what a mid-August campaign
in Spain would lead you to expect:

| | Mean ratio (2024 after-window) |
|---|---|
| Coastal provinces (n=17) | 1.233 |
| Interior provinces (n=13) | 1.202 |
| | p = 0.56 |

So it is ordinary local mobility — commuting, the next town over. That matters,
because the main objection to home assignment was that Google targets by
*presence* while home assignment measures *residence*, and in August those
would diverge badly. They do not. Google's "presence or regularly in" targeting
is approximately "residents plus regular commuters", close to what a modal
municipality rule recovers.

### Decision: move to home assignment

Each UUID is assigned to the municipality where it was seen on the most
distinct days, and counted only there.

**What it buys**

1. An exact partition — municipality counts sum to the true participant total.
2. Genuinely independent units, removing the positive correlation between
   neighbours that complicates leakage modelling.
3. Less noise. Someone passing through once currently contributes a full unit
   of count; ad-induced installs are almost certainly residents.

**Three cautions, carried into the pre-registration**

- **Home is measured post-treatment.** For an ad-induced user every track used
  to classify them is collected after the campaign begins. If ads made people
  use the app more while inside the targeted municipality, borderline users
  would be classified there and the estimate would inflate. Background tracks
  are passive, so this should be small — and note **H1 is immune** (both arms
  are treated, so any such bias cancels) while **H2 is not**.
- **No minimum-activity threshold.** Requiring, say, ≥5 days of tracks before
  assigning a home would remove exactly the marginal, low-activity users the
  campaign creates. Assign a home to everyone; break ties deterministically.
- **Everything recalibrates.** Home assignment cuts counts ~17%, moving
  baselines, eligibility, and τ. Expected direction is that τ falls and power
  improves, since transients are erratic year to year — but that is a
  prediction to check, not a result.

### Data specification

Requested alongside the existing columns, same file, same windows, 2021 onward:

- For each UUID and season, distinct days present per municipality.
- `home` = municipality with the most distinct days; ties broken by most cells,
  then by `GID_4`, so the rule is deterministic.
- Home computed from the UUID's **full track history**, not just the study
  window — this makes home effectively pre-treatment for existing users and
  stabilises it for new ones.
- Emitted as `n_participants_home` beside the existing `n_participants`.

`assign_treatment_2026.R` and `run_final_2026_power.R` both detect
`n_participants_home` automatically and fall back to `n_participants` with a
note when it is absent, so the switch needs no code change.

**Home-assigned counts become the primary outcome; presence-based counts remain
a pre-specified robustness comparison.** If the two disagree that is a finding
about mobility, not a problem with the experiment.
