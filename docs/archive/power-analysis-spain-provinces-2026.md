# Power Analysis: Spain, Provinces, Single Campaign on 15 August 2026

Status: final. Supersedes `hurdle-power-analysis-spain-greece.md`.

## The design analysed

1. Country: Spain only.
2. Areal units: the 50 GADM province-level units (`TYPE_2 == "Provincia"`).
3. Randomization: once, on 15 August 2026. Provinces are assigned to arms a
   single time; there is no re-randomization.
4. Arms: `neutral`, `prevention_focus`, `promotion_focus`, balanced 17/17/16.
5. Outcome: province report counts in the 91 days before 15 August 2026 versus
   the 91 days after.
6. Target effect: a 10% increase in reporting in each treated arm relative to
   neutral.

## Bottom line

The design cannot detect a 10% effect. It cannot detect anything below roughly a
doubling.

| Effect on reporting | Simulated power |
|---|---|
| +5% | 0.05 |
| +10% | 0.05 |
| +20% | 0.06 |
| +30% | 0.11 |
| +50% | 0.20 |
| +75% | 0.31 |
| +100% | 0.45 |

Randomization-inference test, 2000 simulations, one arm versus neutral, at the
pooled 2021-2024 calibration. Minimum detectable effect at 80% power:

| Assumed tau | MDE, unweighted | MDE, precision-weighted |
|---|---|---|
| 0.40 | +67% | +65% |
| 0.60 | +102% | +94% |
| 0.95 (pooled 2021-2024) | +171% | +159% |

The realistic range is the last two rows: **an increase of roughly 95% to 170%**
is what this design is powered to detect.

## Why: the constraint is `tau`, not the model

Write each province's outcome as the log ratio of post-window to pre-window
counts. Two things move it:

1. Poisson counting noise, which shrinks as a province's report volume grows.
2. A province-specific, year-specific shock to the seasonal trajectory. Provinces
   do not all decline at the same rate after mid-August, and which ones run hot
   or cold changes from year to year.

`tau` is the SD of (2) on the log scale. Splitting the observed variance by
method of moments across the 2021-2024 seasons:

| Window | 2021 | 2022 | 2023 | 2024 |
|---|---|---|---|---|
| 30 days | 0.00 | 0.00 | 0.62 | 0.85 |
| 45 days | 0.24 | 0.66 | 0.61 | 0.89 |
| 60 days | 0.49 | 0.68 | 0.63 | 0.89 |
| 91 days | 0.99 | 1.18 | 0.69 | 0.87 |

(The 2021-2022 zeros at short windows are an artifact of truncating the
estimator at zero when volumes are too low; 2023-2024 are the reliable years.)

Three properties make this decisive:

1. **`tau` does not shrink with window length.** Changing from 3-month to 1-month
   windows does not help. The 3-month choice is not the problem.
2. **`tau` does not shrink with report volume.** Restricting to provinces with
   100+ reports leaves `tau` at 0.62-1.71. Barcelona is no less idiosyncratic
   than Soria, it is just measured more precisely.
3. **`tau` is not predictable from a province's own history.** Cross-year
   correlations of province log-ratios are 0.03-0.63 and inconsistent in sign;
   adding province fixed effects moves the residual SD from 1.156 to 1.121.
   Covariate adjustment on prior-year behaviour will not rescue the design.

With 50 provinces in 3 arms, the SE of an arm-versus-neutral contrast is about
`tau * sqrt(2/16.7)` = 0.21 to 0.33 on the log scale. A 10% effect is 0.095. No
choice of estimator changes that arithmetic.

Power at a 10% effect as a function of `tau` shows how sharp the dependence is:

| tau | Power (randomization inference, weighted) |
|---|---|
| 0.0 | 0.51 |
| 0.2 | 0.12 |
| 0.4 | 0.08 |
| 0.6 | 0.08 |
| 0.95 | 0.05 |

At `tau = 0` the design would be roughly half-powered. The empirical value is
0.6-0.95.

## Correction to the earlier analysis

`hurdle-power-analysis-spain-greece.md` reported per-arm power of 0.85-0.89 and
joint power of 0.98 for a 10% effect. Those figures should not be used or cited.

**The estimator was invalid under realistic data.** The fixed-effects Poisson
GLM (`count ~ unit + wave + post * arm`) treats counting noise as the only
residual variation, which is the assumption `tau = 0`. Simulating from a DGP
with the empirically estimated `tau` and testing with that model gives:

| Estimator | Type I error, prevention | joint |
|---|---|---|
| Randomization inference, weighted | 0.041 | 0.047 |
| Randomization inference, unweighted | 0.040 | 0.046 |
| Log-ratio OLS with HC3 | 0.040 | 0.046 |
| **Poisson DiD (earlier model)** | **0.895** | **0.990** |
| Quasi-Poisson DiD | 0.412 | 0.596 |

At a nominal 0.05. The earlier "power" of 0.85 is essentially that model's
false-positive rate: it rejects at ~0.90 whether or not there is an effect,
because it interprets province-level seasonal heterogeneity as treatment signal.
Quasi-Poisson mitigates but does not fix this.

**The simulated effect was also larger than stated.** The hurdle DGP applied the
arm multiplier to both the activation probability and the conditional count, so
the nominal 10% scenario was closer to a 21% increase in expected counts. This
was flagged in the earlier memo as a "dual-margin" sensitivity, but it means the
headline number was not a 10% effect.

## What would change the answer

Province shocks are essentially **uncorrelated across waves within a season** —
the mean cross-wave correlation of province log-ratios is -0.075 in 2023 and
-0.091 in 2024. So re-randomizing repeatedly does add close to a full set of
independent observations each time. Simulated at 14-day cadence with 14-day
windows (`tau` = 0.69):

| Waves | Unit-waves | Power at +10% | Power at +30% | MDE (80%) |
|---|---|---|---|---|
| 1 | 50 | 0.06 | 0.11 | >+100% |
| 6 | 300 | 0.09 | 0.44 | +55% |
| 11 (June-November) | 550 | 0.14 | 0.64 | +38% |

Repeated waves help substantially, but **even the full-season 11-wave design
reaches only 0.14 power at a 10% effect**. The earlier multi-wave design was
underpowered for 10% too; that was masked by the same invalid estimator.

Two alternatives that do not work:

1. **Municipalities, or provinces plus high-reporting municipalities.** This was
   the natural response to low power at the province level, but municipality
   `tau` is *higher*, not lower: 0.85-1.46 across 2023-2024 at every volume
   threshold tested. Only ~600 Spanish municipalities record 10 or more reports
   in a 3-month window, and the remaining ~7,600 contribute noise rather than
   information. The extra units are more than offset by their extra idiosyncrasy.
   *This conclusion holds only for a multiplicatively-defined effect.* Redefining
   the effect on the extensive margin makes those same silent municipalities the
   informative ones — see "Redefining the effect so that zero-baseline units
   count" below.
2. **Adding Greece back.** Greek regional units average 0.33 reports per week
   against 12.7 for Spanish provinces. They add units that carry almost no
   information.

For reference, the number of areal units that a 10% effect would require at 80%
power, using the large-count approximation `SE = tau * sqrt(2/n_per_arm)` — which
ignores counting noise and is therefore an optimistic floor:

| tau | Units needed (3 arms) |
|---|---|
| 0.60 | ~1,900 |
| 0.95 | ~4,700 |

## Alternative outcome measures and country sets

Three follow-up questions were tested: whether restricting the report type
helps, whether a sampling-effort or participation measure helps, and whether
adding Greece back helps. **None of them changes the conclusion**, though the
best combination improves the MDE by roughly a third.

These use the Mosquito Alert sampling-effort dataset (Zenodo record 21466159,
version v2026.07.21), which carries much more than sampling effort: per
0.05-degree cell per day it has participant counts, two effort estimates,
Entolab-validated species-level report counts, and unique-reporter counts. It
also runs to **2026-07-20**, giving five complete seasons (2021-2025) rather
than the four available from the raw report extract.

### The counting rule that matters

A unit only contributes information if a multiplicative treatment effect could
show up in it. A province with no albopictus has a log-ratio pinned at exactly 0
under both the null and the alternative: it adds to *n* without adding signal,
and it makes a narrow outcome look deceptively stable. Every result below counts
only **informative units** — those whose typical pre-window baseline is above a
per-outcome threshold.

This matters a lot. Scored naively, albopictus reporters look like the best
outcome in Spain (SD 0.679 across all 50 provinces) and adding Greece looks like
it cuts the MDE from +93% to +53%. Both are artifacts: albopictus is established
in only 18 Spanish provinces and essentially absent from Greece (59 validated
reports across 52 units and 5 seasons), so those apparent gains come entirely
from structural zeros. The same class of artifact — a zero-heavy outcome making
a model look precise — is what produced the original 0.85 power figure.

### Results

Single wave, 15 August, 91-day windows, 2021-2025 calibration:

| Outcome | Country set | Informative units | Residual SD | MDE (80%) |
|---|---|---|---|---|
| Unique bite reporters | Spain | 42 | 0.882 | +154% |
| Unique bite reporters | Spain+Greece | 46 | 0.890 | +146% |
| Participants | Spain | 50 | 0.795 | +116% |
| **Participants** | **Spain+Greece** | **71** | **0.873** | **+104%** |
| SE_expected | Spain | 47 | 0.845 | +133% |
| SE_expected | Spain+Greece | 50 | 0.847 | +127% |
| Bite reports | Spain+Greece | 47 | 0.956 | +160% |
| Albopictus reports | Spain | 18 | 0.825 | +280% |
| Albopictus reporters | Spain | 18 | 0.775 | +250% |

Simulated power (the MDE column above uses the pooled historical SD; simulation
calibrates counting noise to 2025 volumes and is slightly more favourable):

| Outcome / set | Units | +10% | +25% | +50% | +100% | +150% |
|---|---|---|---|---|---|---|
| Participants, Spain | 50 | 0.05 | 0.12 | 0.29 | 0.69 | 0.91 |
| Participants, Spain+Greece | 71 | 0.07 | 0.14 | 0.34 | 0.78 | 0.93 |
| Bite reporters, Spain | 42 | 0.05 | 0.14 | 0.37 | 0.84 | 0.97 |
| Albopictus reporters, Spain | 18 | 0.04 | 0.06 | 0.18 | 0.38 | 0.58 |

### Answers

**(a) Report type: no.** Restricting to albopictus is much worse — it cuts the
usable province count from 50 to 18 and pushes the MDE to +250%. Restricting to
bite reports gives the lowest per-unit heterogeneity of any count outcome
(tau = 0.467 against 0.724 for participants), but costs 8 provinces, so the two
effects roughly cancel: simulated MDE ≈ +90%, about the same as participants.
Narrowing the outcome trades units for precision at close to an even rate.

Note that albopictus and species-level counts are *not* available in
`data/raw/mosquito_alert_raw_reports.Rds`, which has no species or validation
field. They come only from the Zenodo dataset.

**(b) Sampling effort: marginally, if used as the outcome — not as a
denominator.** Participant counts are the single best all-province outcome
(all 50 informative, SD 0.795, MDE +116%, against roughly +130% to +160% for
raw report counts). The modelled effort measures `SE` and `SE_expected` are
noisier than the raw participant count they are built from. Dividing reports by
effort is actively harmful — it adds the denominator's noise (bite reports per
unit effort: MDE +130%, against +105% for the same reports unnormalised) — and
it would also difference away any treatment effect that operates through
participation, which is the mechanism the ads are meant to work through.

**(c) Greece: yes, but only slightly, and only for participation.** Greece adds
21 informative units out of 52 for participant counts, with higher noise
(SD 0.99 against 0.795), improving the MDE from +116% to +104%. For every other
outcome Greece contributes 0 to 4 usable units and nothing to power. Greece is
worth re-including only if the outcome is participation, and it buys about 10%.

**Best available combination: participant counts, Spain plus Greece, MDE ≈
+104%.** Against roughly +130% to +160% for the original design — a real
improvement of about a third, and still an order of magnitude short of 10%.

## Participant (user) level analysis

This is the largest single improvement found: it roughly halves the MDE relative
to the best aggregate design. It does not close the gap to 10%.

### The design

Take all reports in the window before and after 15 August, extract user UUIDs,
and form a closed cohort of everyone who reported in the pre-window. Assign each
user to their modal pre-window province, which fixes their treatment arm.
Analyse per-user reporting change as a function of that arm.

The multi-province problem is small in practice. In a 30-day pre-window only
**3.4%** of cohort users report from more than one province, and **0.3%** of
reports fall outside the user's modal province (4.6% and 1.5% at 91 days).
Modal-province assignment is sufficient; dropping multi-province users entirely
would be a cheap robustness check.

### Sensitivity has to be accounted for

Treatment is assigned at province level, so the effective sample size stays at
the number of provinces. What changes is the province-level summary — and
summaries differ in how far they move for a given multiplicative effect `m` on
reporting:

| Province summary | Sensitivity (shift per unit log m) |
|---|---|
| log(sum post / sum pre), closed cohort | 1.00 |
| log(mean post per cohort member) | 1.00 |
| mean of per-user log((post+.5)/(pre+.5)) | 0.47 - 0.59 |
| log(share of cohort still reporting) | 0.55 - 0.61 |

A summary with a small SD and a small sensitivity is no better than one with a
large SD and a large sensitivity. Everything below divides by sensitivity.

### Results, same provinces, sensitivity-corrected MDE

60-day windows, provinces ranked by median cohort size:

| Provinces used | Mean user log-ratio | Closed-cohort ratio | Aggregate counts |
|---|---|---|---|
| 10 | +111% | +622% | +467% |
| 15 | +81% | +432% | +260% |
| 21 | +80% | +445% | +194% |
| **30** | **+60%** | +381% | +176% |
| 50 | +83% | +281% | +146% |

Direct simulation of the best cell (60-day windows, top 30 provinces, mean user
log-ratio), drawing from the observed province-level residual distribution:

| Effect | +10% | +25% | +50% | +75% | +100% |
|---|---|---|---|---|---|
| Power | 0.09 | 0.30 | 0.71 | 0.88 | 0.97 |

MDE ≈ **+57%**, against +104% for the best aggregate design and +146% to +160%
for the original. Power at a 10% effect rises from about 0.05 to **0.09**.

### Why it works — not the reason you might expect

The gain is *not* that a closed cohort removes cohort turnover. The
closed-cohort ratio, which is exactly the turnover-free version of the aggregate
count, is far **worse** (+281% to +622%).

The gain comes from averaging a **bounded per-user statistic**. Each user
contributes at most a few log units regardless of how many reports they send, so
a handful of heavy reporters can no longer dominate a province's summary. It is
effectively a robust estimator of the province-level shift. That is also why
restricting to the top 30 provinces helps: below that, cohorts are too small
(median 12 users at 50 provinces) for the province mean to be stable.

### Two things to weigh before adopting it

1. **It changes the estimand, and it cannot see recruitment.** A closed cohort
   of pre-period reporters measures the effect on people who were *already*
   reporting. If geographically targeted ads work mainly by recruiting new
   participants — a plausible primary mechanism — this design is blind to it,
   while the aggregate design captures it. The sensitivity of 0.54 also means
   the estimate is a shift in the distribution of per-user change, not a
   percentage change in reports; it needs to be preregistered as such.

2. **It has ethics consequences.** The Component 4 amendment currently rests on
   the study using aggregate areal-unit counts with no participant-level
   linkage, which is the main argument that it is lower risk than the
   already-approved regulatory-focus study. Extracting user UUIDs and building
   per-user pre/post behavioural profiles linked to assigned treatment removes
   exactly that argument. This does not make the design unacceptable — the
   earlier study did user-level linkage with consent and was approved — but it
   would likely change the review posture, which matters given the timeline. See
   `docs/ethics/`.

## Redefining the effect so that zero-baseline units count

Every design above defines the effect **multiplicatively**: reports rise by X%.
Under that definition a municipality with zero baseline reports cannot respond,
because 0 x 1.1 = 0. That is why the ~7,400 silent Spanish municipalities looked
like pure noise, and why the municipality design was rejected earlier.

But that is a property of the *effect model*, not of reality. An ad campaign in
a silent municipality could plausibly produce its first report. Defining the
effect on the **extensive margin** makes exactly those units the informative
ones:

> **Estimand:** the probability that a municipality with no pre-window reports
> records at least one report in the post window.
> **Effect:** the increase in that probability.

This turns out to be the best-behaved design found.

### Two structural advantages

**1. It eliminates `tau` entirely.** The province-level idiosyncratic shock that
blocks every other design is a property of *log-ratios of counts*, which have
unbounded, heavy-tailed unit-level noise. A binary outcome has variance
`p(1-p)`, fully determined by `p`, so there is no extra between-unit component
to absorb. Verified by permuting arm labels on the real data:

| Season | Silent municipalities | Activation rate | Permutation SE | Binomial SE |
|---|---|---|---|---|
| 2021 | 7,894 | 0.0236 | 0.00413 | 0.00418 |
| 2022 | 7,954 | 0.0230 | 0.00413 | 0.00412 |
| 2023 | 6,348 | 0.0361 | 0.00576 | 0.00573 |
| 2024 | 7,375 | 0.0327 | 0.00523 | 0.00507 |

The observed randomization SE matches binomial theory to three decimals. There
is no hidden variance component.

**2. Sensitivity is ~1.0.** For small `p`, `P(>=1 report) = 1 - exp(-lambda)` is
very nearly proportional to `lambda`, so a multiplicative effect on reporting
propensity carries onto the activation rate almost one-for-one (sensitivity
0.98 across the range 1.1x to 2x). Unlike the per-user log ratio, which pays a
0.54 sensitivity penalty, nothing is lost in translation.

### Results

Natural activation rate is stable at **2.3% to 3.6%** per season (60-day
windows), across roughly 7,400 silent municipalities.

| Municipalities targeted | Per arm | Natural activations | MDE (pp) | MDE (relative) |
|---|---|---|---|---|
| 500 | 167 | 5 | +5.10 | ~+200% |
| 1,000 | 333 | 9 | +3.60 | ~+145% |
| 2,000 | 667 | 19 | +2.55 | ~+100% |
| 4,000 | 1,333 | 38 | +1.80 | ~+72% |
| **7,393 (all)** | **2,464** | **70** | **+1.50** | **+53%** |

Using all silent municipalities, the design detects a **+53% relative increase**
in first-time activation — from 2.84% to about 4.35%, i.e. roughly **37 extra
first-time municipalities per arm**. Because sensitivity is ~1, that +53% is
directly comparable to the multiplicative MDEs elsewhere in this memo.

> **Correction.** An earlier version of this section reported +47%. That figure
> came from `2.802 x (null SE) / p`, which linearises an effect large enough that
> the linearisation matters and ignores the larger variance under the
> alternative. A direct simulation of the difference-in-proportions test gives
> power 0.72 at +47% and 0.92 at +64%, so the 80% MDE is about +53%. The
> percentage-point column was unaffected.

Selecting *which* silent municipalities to target does not help. Municipalities
with more prior-year history activate far more often, but there are too few of
them:

| Stratum (silent in pre-window) | Per season | Activation rate | MDE (relative) |
|---|---|---|---|
| No reports in prior year | 6,659 | 1.6% | +67% |
| 1-2 prior-year reports | 455 | 10.0% | +97% |
| 3-10 | 224 | 19.1% | +94% |
| >10 | 55 | 32.1% | +134% |

Pooling all of them (+47%) beats every individual stratum.

### Combining both margins: the hurdle design

Restricting to silent municipalities throws away the ~850 active ones. A real
analysis would use both, which is exactly what a hurdle or zero-inflated count
model does: one parameter for whether a unit reports at all, another for how
much it reports given that it does.

Both margins can be put on a common log scale, so that under a common
multiplicative effect `m` each estimates `log(m)`:

- **extensive**: `log(activation rate treated / activation rate neutral)` over
  municipalities silent in the pre-window
- **intensive**: difference in mean `log((post+0.5)/(pre+0.5))` over
  municipalities active in the pre-window

and then combined by inverse variance. `run_hurdle_combined_design.R` simulates
this end to end against a DGP calibrated to the observed activation rate, the
observed log-ratio SD among active municipalities, and the observed count of
active municipalities. Type I error checks out at 0.038-0.058.

| Margin | Weight | MDE |
|---|---|---|
| Extensive (silent, ~7,400 units) | 0.16 | ~+53% |
| Intensive (active, ~850 units) | 0.84 | **~+27%** |
| **Combined** | — | **~+24%** |

**The intensive margin dominates.** Adding all 7,400 silent municipalities to
the ~850 active ones improves the MDE only from about +27% to about +24%. The
zeros are worth having, and they cost nothing, but they are not where the
information is.

Note also that the combination assumes a *common* effect on both margins. That
is unlikely to hold exactly — activating a silent municipality and increasing
reporting in an active one are different behaviours, and the extensive effect
could well be larger. A hurdle model naturally reports both coefficients, and
the analysis should preregister which is primary rather than relying only on
the pooled estimate.

### Correction: municipalities were dismissed too early

Turn-2 of this analysis rejected municipalities on the grounds that municipality
`tau` is higher than province `tau` (0.85-1.46 against 0.6-0.95). That compared
`tau` values without computing the MDE, and it was wrong. `tau` is about 1.4x
larger, but there are 847 usable municipalities against 50 provinces — and
`sqrt(847/50) = 4.1x` beats `1.4x` comfortably:

| Threshold on pre-window count | Municipalities per season | Residual SD | MDE |
|---|---|---|---|
| >= 1 | 847 | 1.00 | **+27%** |
| >= 3 | 427 | 1.11 | +44% |
| >= 5 | 284 | 1.14 | +59% |
| >= 10 | 159 | 1.09 | +81% |
| >= 30 | 54 | 1.00 | +153% |

Lower thresholds are monotonically better: take every municipality with at
least one pre-window report. The municipality intensive margin alone (+27%) is
the strongest single-wave design in this memo, and it does not depend on the
extensive-margin reformulation at all.

### Where this sits

| Design | MDE |
|---|---|
| Original: aggregate province counts, 50 provinces | +146% to +170% |
| Best aggregate: participants, Spain + Greece | +104% |
| Participant-level closed cohort, top 30 provinces | +57% |
| Municipality activation only (extensive margin) | ~+53% |
| Province design with 11 re-randomized waves | +38% |
| Municipality intensive margin, pre >= 1 | ~+27% |
| **Municipality hurdle, both margins, all 8,240** | **~+24%** |

### At province level this buys nothing

All 50 Spanish provinces record reports in the relevant seasons, so there is no
extensive margin to exploit:

| Window | 2021 | 2022 | 2023 | 2024 |
|---|---|---|---|---|
| 30 days | 15 | 17 | 0 | 3 |
| 60 days | 9 | 6 | 0 | 1 |
| 91 days | 4 | 3 | 0 | 1 |

(Provinces with zero pre-window reports. The 2021-2022 counts reflect much lower
app usage in those years; 2023-2024 are the relevant calibration.)

With zero or one silent province, the hurdle design degenerates to its intensive
margin, which is exactly the original design. The extensive-margin idea works
only because municipalities are numerous *and* mostly silent — it is a property
of the unit level, not of the estimand.

### The budget caveat

This assumes each municipality gets a campaign capable of producing the effect.
If total spend `B` is fixed and the effect per municipality scales with spend
per municipality (`B/n`), then the z-statistic goes as `B/sqrt(n)` — meaning
**concentrating spend on fewer municipalities beats spreading it thin**, the
opposite of what the MDE table alone suggests. Relative detectability against
the n = 7,400 case is 1.4x at n = 4,000, 1.9x at n = 2,000, 3.9x at n = 500.

The two forces pull in opposite directions and the optimum depends on the cost
per activation, which is unknown. That parameter is precisely what a
feasibility pilot could estimate, and it would then pin down the design.

Two further practical checks before adopting this:

1. **Targetability — now resolved.** Google Ads names only **970** of Spain's
   8,240 municipalities (covering 78% of reports). Restricting to those raises
   the combined MDE from +23% to **+40%**; reaching the full set requires
   proximity (radius) targeting. Full detail, including the campaign-ready
   Criteria ID list, is in `google-ads-municipality-targeting.md`.
2. **Spillover.** Silent municipalities are small and often adjacent. Ads
   delivered by radius or city targeting will reach neighbouring units,
   contaminating control municipalities and biasing the estimate toward zero.
   Randomizing in spatially separated blocks would mitigate this.

## Options

1. **Move to municipalities with a hurdle analysis.** This is the best
   single-wave design found: MDE ~+24% across all 8,240 Spanish municipalities,
   against ~+104% to +170% for anything at province level. Most of that comes
   from the ~850 active municipalities (intensive margin, ~+27% alone); the
   ~7,400 silent ones add the extensive margin and improve it to ~+24%. Still
   above a 10% target, but within range of a plausible advertising effect, and
   it would combine with repeated waves. Requires validating municipality-level
   ad targetability and handling spillover.
2. **Switch to repeated re-randomized waves across the season.** The best
   available version of this design: MDE ≈ +38%. Still well above 10%, and it
   changes the intervention from a single campaign to a season-long one.
3. **Change the outcome or the unit of analysis** so that the treatment is
   measured on something less dominated by province-level seasonal
   idiosyncrasy — for example ad-platform click-through or app-install
   attribution, or an individual-level design of the kind CIREP approved for the
   regulatory-focus study, where the noise structure is entirely different.
4. **Treat the 2026 campaign as a feasibility and implementation pilot**, sized
   to validate geographic targeting, creative delivery and outcome linkage,
   with the powered comparison deferred.

Option 3 or 4 is the recommendation if a 10% effect is genuinely the target.

## Method

Implemented in `analysis/r/power_analysis/power_single_wave_spain.R`.

**Calibration.** Province pre/post window totals are built from
`output/spain_province_daily_counts.csv` for the 2021-2024 seasons. A province's
expected pre-window count is its observed 2024 level; its expected post-window
count is that level times a single Spain-wide seasonal ratio (0.807 for 2024 at
91 days). Using the province's *own* observed post count would double-count the
heterogeneity, since that observation already contains one realization of the
province shock.

**Data-generating process.** For province `i`:

```
pre_i  ~ Poisson(lambda_pre_i)
post_i ~ Poisson(lambda_pre_i * seasonal_ratio * exp(u_i) * effect_arm(i))
u_i    ~ Normal(-tau^2 / 2, tau^2)
```

**Randomization.** Blocked by baseline volume: provinces are ordered by volume,
grouped into consecutive blocks of 3, and one arm is assigned per block. Simple
randomization was also tested; the difference is negligible because `tau` rather
than volume imbalance is the binding constraint.

**Inference.** Randomization inference is the primary test, with the reference
distribution generated by re-running the actual assignment mechanism, so the
test is valid by construction. Precision-weighted and unweighted contrasts are
both reported; weighting buys little, again because `tau` dominates.

## Reproducing

```bash
Rscript analysis/r/power_analysis/build_spain_province_daily_counts.R
Rscript analysis/r/power_analysis/run_final_design_spain.R 2000
Rscript analysis/r/power_analysis/run_wave_comparison_spain.R 1000
```

For the alternative outcomes, first download the sampling-effort archive from
https://zenodo.org/records/21466159, unzip it, and gunzip
`sampling_effort_daily_cellres_05.csv.gz`. Then:

```bash
Rscript analysis/r/power_analysis/build_province_outcome_panel.R <csv> Spain
Rscript analysis/r/power_analysis/build_province_outcome_panel.R <csv> Greece
Rscript analysis/r/power_analysis/run_outcome_comparison.R 1000
```

For the participant-level design:

```bash
Rscript analysis/r/power_analysis/build_user_province_reports.R
Rscript analysis/r/power_analysis/run_user_level_comparison.R 2000
```

For the extensive-margin municipality design:

```bash
Rscript analysis/r/power_analysis/build_municipality_window_counts.R
Rscript analysis/r/power_analysis/run_extensive_margin_municipalities.R
Rscript analysis/r/power_analysis/run_hurdle_combined_design.R 1000
```

Result tables are written to `analysis/r/power_analysis/output/`:

1. `final_spain_tau_calibration.csv`, `final_spain_tau_by_window.csv`
2. `final_spain_type1_error.csv`
3. `final_spain_power_by_effect.csv`, `final_spain_power_by_tau.csv`
4. `final_spain_mde.csv`, `final_spain_units_required.csv`
5. `final_spain_wave_comparison.csv`, `final_spain_wave_mde.csv`
6. `outcome_comparison.csv`, `outcome_comparison_power.csv`
7. `user_level_comparison.csv`, `user_level_power.csv`
8. `municipality_activation_rates.csv`,
   `municipality_extensive_margin_mde.csv`,
   `municipality_activation_strata.csv`
9. `hurdle_combined_power.csv`

## Data note

`data/raw/mosquito_alert_raw_reports.Rds` ends on **2025-08-14**, although some
existing output filenames carry a `_to_20251231` suffix. Only the 2021-2024
seasons have a complete 3-month post-15-August window; 2025 contributes a
pre-window only. The 2023 season also contains an unusual June spike (22,160
reports against 2,623 in June 2024) that inflates that season's pre-window.

Counts include all geolocated non-mission reports with no validation filter, and
are assigned to provinces by point-in-polygon against GADM level 2. Of 122,999
Spanish-bounding-box reports from 2019 onward, 115,983 fall inside a province
polygon.
