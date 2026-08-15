# Pre-registration: Regulatory-Focus Framing in Geographically Targeted Advertisements for Citizen Science

**IDAlert Task 5.4 — a randomized experiment across 949 Spanish
municipalities, August–October 2026.**

This document is the pre-registration of record for the study. Its sections
follow the fields of the standard OSF Preregistration form, in form order.
Supporting technical memos ca be found in `docs/operations/` of the study repository,
and the code that produces every number reported here is listed under *Context
and additional information*.

---

# Metadata

## Title

Regulatory-Focus Framing in Geographically Targeted Advertisements for Citizen
Science: A Randomized Experiment Across Spanish Municipalities

## Description

This is a three-arm randomized experiment testing whether advertising using
regulatory-focus framing increases participation in public-health-related
citizen science more than neutrally framed advertising, and whether
geographically targeted advertising increases participation at all. The
experiment relies on Mosquito Alert (https://www.mosquitoalert.com), an
expert-validated citizen science system that enables anyone to
participate in the surveillance of vector mosquitoes. The units of analysis are
949 Spanish municipalities — every municipality Google Ads can target by name
whose baseline activity falls below a pre-specified cap, including 571 with no
recent Mosquito Alert activity at all. The units are randomly assigned to a
regulatory-focus framed campaign, a neutral campaign, or no campaign. Outcomes
are measured in a fixed 60-day post-campaign window (16 August – 14 October
2026); data from the 60-day pre-campaign window are used as statistical
controls. The primary outcome is the number of distinct Mosquito Alert
participants who are active in each municipality during the measurement window
and whose sampling effort is concentrated there. The secondary outcome is the
number of participants submitting mosquito reports in that window.

## Contributors

John R.B. Palmer, Universitat Pompeu Fabra

Berj Dekramanjian, Universitat Pompeu Fabra

## License

CC-By Attribution 4.0 International

## Subject

Social and Behavioral Sciences; Public Health; Environmental Public Health

## Tags

citizen science; regulatory focus; field experiment; digital advertising;
mosquito surveillance; vector mosquitoes; mosquito-borne disease; Mosquito Alert; randomized controlled trial

---

# Overview

## Research questions or hypotheses

**H1 (primary).** Municipalities assigned to the regulatory-focus framed
advertising campaign will record more distinct Mosquito Alert participants in
the post-campaign window than municipalities assigned to the neutrally framed
campaign.

**H2 (secondary).** Municipalities assigned to either advertising campaign will
record more distinct participants than municipalities assigned to no campaign.

Both hypotheses are two-sided.

"Regulatory focus" refers to Higgins' distinction between **prevention focus**
(motivation framed around avoiding a negative outcome) and **promotion focus** (motivation framed around
attaining a positive outcome). The framed arm includes messaging oriented to both of these foci; the neutral
arm uses neither. See *Manipulated variables*.

H1 is the primary test and asks whether the content of a recruitment message
changes how much participation it generates, holding budget, targeting and
platform constant.

Both hypotheses are evaluated on the primary outcome (sampling effort) and, separately and secondarily, on the reporting outcome
(people submitting mosquito reports). See *Measured variables*.

H2 serves two purposes. It is a substantive result — whether geographically
targeted digital advertising raises citizen science participation at all is not
established — and it is a manipulation check. If H2 is not supported, the
campaign did not deliver, and H1 is uninterpretable rather than null.

## Foreknowledge of data or evidence

**Selected option:** *Authors have observed the data, but have not performed the
proposed analyses.* At least some of the data that will be used for this
analysis plan has been accessed and observed by the authors. The authors have
sufficiently observed relevant evidence to influence their analysis decisions or
conclusions. However, the authors have not yet performed any of the proposed
analyses in this plan and will not do so until after this plan is registered.

## Explanation of foreknowledge and managing unintended influences

All data observed to date are **pre-treatment**. They comprise Mosquito Alert
background-track participant counts for the 2018–2025 seasons, and the 2026
pre-campaign window (16 June – 14 August 2026), which enters the analysis as a
covariate.

These data materially influenced the design and analysis plan, and we record
that plainly rather than claim otherwise. Specifically, observation of
historical data determined:

1. the choice of sampling effort over submitted reports as the outcome
   (unit-level residual SD ≈ 0.43 on the log scale against 0.87–0.95 for
   report counts);
2. the eligibility rule, including the upper baseline cap (see *Data inclusion
   and exclusion*);
3. the decision to model counts rather than log counts;
4. the decision to enter the pre-period as a covariate rather than difference
   it;
5. the 4:4:1 arm allocation;
6. the choice of modal attribution over presence attribution for the primary
   outcome (the two are defined under *Indices*);
7. the use of seasons 2021–2025 for calibration, because earlier seasons
   reflect a different tracking regime (see *Indices*);
8. the decision to include municipalities with no baseline activity, after
   simulation on pre-treatment data showed that they raise rather than lower
   power (see *Data collection procedures*).

Each is justified in the relevant section below.

**What has not been observed.** The outcome — participant counts for the 60-day
post window, 16 August to 14 October 2026 — does not exist at the time of
registration. The advertising campaign has not launched. No comparison of any outcome between arms
has been computed on real data at any point.

**Managing unintended influence.** The treatment assignment was generated by a
script with a frozen seed and pinned RNG, and both the assignment and md5
checksums of its inputs and outputs are committed to the repository and
timestamped before launch. Every analysis decision is specified below in
sufficient detail to be executed mechanically. Analysis code has been written
and exercised on *simulated* outcomes only.

---

# Research Design

## Study type

**Randomized experiment.** Municipalities are randomly assigned to treatment
arms by the investigators.

## Intention for causal interpretation

**Direct causal inference.** Random assignment of municipalities to arms
supports a causal interpretation of the arm contrasts, for the population
defined in *Data collection procedures*.

## Blinding of experimental treatments

- **Subjects are blinded.** Individuals exposed to advertisements see an
  ordinary advertisement and are not informed of, and have no way to detect,
  assignment to a study arm. No individual-level data are collected for the
  purpose of this experiment beyond the aggregate counts described below.
- **Data analysts are not blinded.** The assignment file is public in the
  repository. This is mitigated by full pre-specification of the analysis and by
  the use of randomization inference, which is mechanical given the assignment.

## Additional blinding during research or analysis

Analysis code was written and validated against simulated outcomes before any
2026 outcome data existed, and is committed to the repository prior to launch.
No interim comparison between arms will be computed at any point during the
campaign (see *Starting and stopping rules*).

## Study design

Three-arm, parallel-group, cluster-randomized field experiment with a single
treatment wave. The cluster — and the unit of both randomization and analysis —
is the municipality.

| | |
|---|---|
| Units | 949 Spanish municipalities |
| Arms | framed (420), neutral (420), no advertising (109) |
| Allocation | 4:4:1 |
| Campaign launch | **17 August 2026** |
| Planned flight | 30 days, 17 August – 15 September (EUR 8.33/day per campaign) |
| Measurement anchor | **15 August 2026** |
| Measurement windows | 60 days before (16 Jun – 14 Aug) and 60 days after (16 Aug – 14 Oct); the anchor day itself is excluded, matching every historical season |
| Platform | Android only |
| Budget | EUR 5,000 total: EUR 250 per campaign, every campaign holding exactly 42 municipalities, so every municipality carries the same expected budget (EUR 5.95) |

**Arms.** The *framed* arm runs advertisements using regulatory-focus framing.
The *neutral* arm runs advertisements identical in placement, budget, targeting
and call to action but with neutral framing. The *no advertising* arm receives
no campaign.

**Launch date versus measurement anchor.** The measurement windows are anchored
on 15 August, matching the anchor used for every historical season, so that
2026 is exactly comparable to 2021–2025. The campaign launches on Monday 17
August: 15 August 2026 is a Saturday and a Spanish national holiday, and
launching across an unmonitored holiday weekend risks the first 48 hours of
delivery. Because the post window begins 16 August (the anchor day is excluded
by the data pipeline's convention, in every season), a 17 August launch leaves
exactly **one untreated day** — 1.7% of the window — which attenuates the
estimate negligibly. This is accepted in exchange for exact historical
comparability. Were the launch to slip more than five days, the measurement
anchor would be moved and all historical windows re-derived to match.

**Timing rationale.** A mid-August launch places part of the Spanish summer
holiday period in the pre-window and part in the post-window, so that seasonal
mobility is represented on both sides of the comparison rather than only one.

**Campaign structure.** Each advertising arm is divided into 10 campaigns of
**exactly 42 municipalities**, formed as **contiguous baseline bands**:
campaign k in the framed arm and campaign k in the neutral arm hold the same
band, the same unit count, and the same budget, so the arms are symmetric
campaign by campaign and Google's optimiser faces an identical allocation
problem in both. Each campaign holds units of similar size so the optimiser can
only reallocate spend among like units.
(A cross-sectional "serpentine" grouping was considered and rejected: it makes
campaigns comparable to each other but internally heterogeneous, which with 571
zero-baseline units would mix villages and active towns in one campaign and
invite concentration on the towns.) 20 campaigns in total; the no-ad arm
requires none. Municipalities are targeted by Google Ads Criteria ID, never by
pasted place name, because Spanish municipality names repeat across regions.

Homogeneous campaigns limit how far Google's optimiser can concentrate spend
within an arm, which is the principal identified threat to H1.

**Campaign budgets are EUR 250 each** — the general rule is budgets
proportional to municipality counts, which with all campaigns at exactly 42
units reduces to equal budgets, EUR 5.95 per municipality everywhere. The
budget table is emitted by the assignment script (`campaign_budgets.csv`) so
the allocation is part of the reproducible record.

**Android only.** Roughly 70% of Spanish Mosquito Alert participants use
Android; the EUR 0.39 cost-per-install estimate comes from an Android test
campaign; and splitting a fixed budget across two platforms would halve the
units per campaign without a corresponding gain.

## Randomization

**Method.** Block randomization. Municipalities are ordered by median
pre-window participant count (2021–2025), with all ties broken explicitly and
deterministically, and cut into consecutive blocks of 9. Each block receives a
uniformly random permutation of the arm vector (4 framed, 4 neutral, 1 no-ad),
so every block is balanced by construction and the arms are matched on the
covariate that most predicts the outcome. A trailing partial block — with 949
units, the four smallest-baseline municipalities — is assigned entirely to the
**no-advertising arm**, deterministically and stated in advance. Under the
block-fixed-effects analysis a single-arm block contributes no identifying
variation to either contrast, so as advertising units these four would be spend
without information; assigning them to no-ad keeps every eligible unit in the
frame at zero cost, and makes the advertising arms exactly equal (420 / 420).
That equality is what allows every campaign to hold exactly 42 municipalities
with identical budgets, so Google's within-campaign optimiser faces the same
problem in both arms.

**Level.** Municipality. There is no individual-level randomization.

**Reproducibility.** Implemented in
`analysis/r/03_randomization/assign_treatment_2026.R` with seed `20260815` and
the RNG kind pinned (`Mersenne-Twister` / `Inversion` / `Rejection`), because R
changed the default `sample()` algorithm at version 3.6.0 and a bare
`set.seed()` is not portable. The seed is an arbitrary frozen constant, not a
date reference. The script writes a manifest recording the seed, RNG kinds, R
version, eligibility rule, outcome column used, and md5 checksums of both inputs
and the resulting assignment.

**Pre-launch verification.** The assignment script simulates Type I error
**conditional on the realized draw** and warns hard if either hypothesis is
anti-conservative (above 0.09); below 0.02 it notes the conservatism without
warning, since HC3 over-corrects in the presence of block dummies and a small
no-ad arm, and the primary randomization test is exact regardless. This check
is deliberately not the design-level rate averaged over fresh randomizations:
an earlier candidate design had a design-level rate of 0.064 for H2 while the
particular draw in hand had a rate of 0.216. Only the conditional quantity
describes the experiment actually being run. On the final 949-unit assignment
the check reads **H1 0.030, H2 0.019 — both nominal to mildly conservative**.
The 109-unit no-advertising arm resolved the small-arm pathologies seen on
earlier, smaller candidate pools.

**Attribution verification.** Because a column of counts does not by itself
reveal which attribution produced it, the script verifies the attribution from
the data: under modal attribution each participant is counted exactly once, so
municipality sums equal province totals (ratio 1.000), whereas presence
attribution gives ratios of 1.17–1.28. The verdict is recorded in the
manifest; the data used here verify as `modal-attributed partition
(ratio 1.000)`.

---

# Sampling

## Data collection procedures

**Population.** Spanish municipalities that can be targeted directly by name in
Google Ads, excluding only the three whose existing Mosquito Alert activity is
extreme (see the cap below). This includes 571 municipalities with no recent
activity at all, so the study speaks both to amplifying participation where it
exists and to **activating** it where it does not.

**Sampling frame and eligibility.** Beginning from all 8,244 Spanish
municipalities, with participant counts under modal attribution:

| Step | Remaining |
|---|---|
| All municipalities | 8,244 |
| Targetable by name in Google Ads (name and autonomous community both match) | 952 |
| Median pre-window participants 2021–2025 ≤ 25 | **949** |

**All 949 eligible municipalities enter the study.** There is no further
sampling: N is determined by the eligibility rule applied to pre-treatment data,
not chosen as a target. Every unit's Google Ads Criteria ID was verified
individually: 949 distinct numeric IDs, each matched on both municipality name
and autonomous community.

**There is no minimum-activity requirement.** Requiring some baseline
participation before a municipality could enter was considered and rejected:
under the registered model a municipality with zero baseline activity is fully
informative — its no-advertising outcome is near zero with little variance,
and its treated outcome is essentially the advertising-driven installs. In
simulation on pre-treatment data, including the 571 zero-baseline nameable
municipalities raises H1 power from 0.71 to 0.93 at a 15% framing effect, and
it turns H2 partly into an activation experiment. This decision was made
before the randomization was frozen, on pre-treatment data only.

**Outcome data.** Two extracts, both aggregated to municipality by season and
window:

1. **Sampling effort** measured from optional, masked background locations emitted passively by the application (and used by the Mosquito Alert system to reduce sampling bias).
   Locations are masked to a 0.025° × 0.025° grid before aggregation.
2. **Submitted mosquito reports**, geolocated and assigned to municipality by
   point-in-polygon on the report location.

The two extracts use different approaches to geographic attribution: The primary track outcome is attributed to the user's
modal sampling municipality; reports are attributed to the location of the report
itself, for three reasons. First, reporting identifiers are deliberately not
linkable to background-tracking identifiers — a privacy-by-design separation —
so a modal sampling municipality, which is defined on the tracking stream, cannot be
computed for reporters at all. Second, most reporters submit exactly one
report, so a modal-location rule would collapse to the report location anyway.
Third, every historical season in the reports calibration is report-location
attributed, so keeping that attribution for 2026 preserves comparability. The
residual multi-municipality inflation this leaves in the reports outcome is
small (single-report users dominate) and symmetric across arms, so it cannot
bias H1.

**Recruitment.** No recruitment of individuals is performed by the
investigators. The intervention is the purchase of advertising inventory;
individuals are exposed through ordinary Google advertising delivery as part of Mosquito Alert's ongoing recruitment operations.

## Sample size

**949 municipalities**: 420 framed, 420 neutral, 109 no advertising.

Approximately 15 app installs per advertising municipality, from EUR 5,000 at an
estimated EUR 0.39 per install across 840 advertising municipalities. The total
budget is fixed at EUR 5,000; when the eligible pool changes, the
per-municipality dose adjusts, not the budget.

## Sample size rationale

N is fixed by the eligibility rule rather than chosen, so this section reports
the power that the resulting design achieves. All figures come from simulation
on the realized assignment, resampling each municipality's observed 2021–2025
pre/post pair so that real year-to-year variation is carried rather than
averaged away (`analysis/r/02_power/run_final_2026_power.R`).

**H1 — framing contrast.** `delta` is the conversion advantage of the framed
creative. Because both arms' counts contain the baseline and the installs, the
resulting percentage difference in observed participants is smaller than
`delta`. `sigma_c` is the unit-to-unit spread in realized installs.

| delta | Observed difference | sigma_c = 0.3 | sigma_c = 0.4 | sigma_c = 0.6 |
|---|---|---|---|---|
| 0% (Type I) | — | 0.029 | 0.033 | 0.030 |
| 5% | +5% | 0.29 | 0.18 | 0.09 |
| 10% | +9% | 0.75 | 0.65 | 0.42 |
| **15%** | **+14%** | **0.98** | **0.92** | 0.70 |
| **20%** | **+19%** | **1.00** | **1.00** | 0.89 |
| 30% | +28% | 1.00 | 1.00 | 1.00 |

**The study has power 0.92 at a 15% framing effect and essentially 1.00 at 20%
at moderate delivery spread (sigma_c = 0.4), and meaningful though not adequate
power at 10% (0.65). Below 10% it is not powered.** Including the zero-baseline
municipalities is what buys this: in design-stage simulations the full 949-unit
pool at ~15 installs per municipality outperformed a 378-unit pool restricted
to municipalities with baseline activity (which would have received ~38
installs each) under every scenario tested, because power here is driven by
unit count far more than by dose.

**H2 — advertising versus none.** The assumed campaign effect is about 15
installs against a no-advertising level of 1.14 participants, an increase of
over 1300%, so reporting "power ≈ 1" would be uninformative. The minimum
detectable effect is the meaningful quantity:

| Extra participants per municipality | % over no-ad arm | Power (HC3) |
|---|---|---|
| 0.5 | +44% | 0.35 |
| 1.0 | +87% | 0.70 |
| **1.2** | **+108%** | **0.80** |
| 1.5 | +131% | 0.92 |
| 2.0 | +175% | 1.00 |

Randomization inference — the primary inference method — agrees (≈0.70 at
+87%), placing the **MDE at roughly 1.2 extra participants, about +110%** over
the no-advertising arm. **H2 therefore fails to reject only if the
campaign delivers under roughly 8% of plan**, at which point H1 is
uninterpretable regardless, which is what a manipulation check should do.

**The H1 and H2 percentages are not comparable and should not be compared.**
H1's percentage is measured against a municipality that already carries
advertising (1.14 baseline plus ~15 installs ≈ 16 participants); H2's against an
untreated municipality at 1.14. In absolute terms H2 detects a difference of
~1.2 participants and H1 one of ~2.3; the percentages differ mainly because the
denominators do.

**Power for the secondary reporting outcome.** The reporting outcome has a
no-advertising level of 1.20 reporters per municipality against 1.14 track
participants, with 65% of municipality-seasons recording zero reporters. Its
power depends on what share of advertising-driven installs go on to submit at
least one report — the *report rate* — which is not known in advance. The
historical aggregate ratio of reporter counts to track-participant counts is
about 1.0 (1.20 / 1.14), but this is a ratio of municipality totals under two
different attributions (reports by report location, tracks by modal sampling municipality), not a
per-user rate, and newly recruited users are expected to report at a lower rate
than the established base. The plausible range is therefore treated as wide and
low.

H1 power on the reporting outcome, by report rate
(`analysis/r/02_power/run_report_outcome_power.R`):

| Report rate | New reporters per municipality | delta = 0 | delta = 15% | delta = 20% | delta = 30% |
|---|---|---|---|---|---|
| 70% | 10.7 | 0.033 | 0.94 | 1.00 | 1.00 |
| 40% | 6.1 | 0.031 | 0.79 | 0.97 | 1.00 |
| 20% | 3.1 | 0.032 | 0.43 | 0.69 | 0.97 |
| 10% | 1.5 | 0.035 | 0.11 | 0.25 | 0.57 |

H2 minimum detectable effect on the reporting outcome:

| Extra reporters per municipality | % over no-ad arm | Power |
|---|---|---|
| 0.5 | +42% | 0.39 |
| **0.95** | **+79%** | **0.80** |
| 1.0 | +84% | 0.83 |
| 1.5 | +125% | 0.96 |
| 2.0 | +167% | 1.00 |

**The reporting outcome has power 0.79 for a 15% framing effect if roughly 40%
of installs report, 0.97 at a 20% effect, and is underpowered when the report
rate is 20% or below.** Type I error is nominal to conservative throughout. This
contingency is stated in advance precisely so that a null result on the
reporting outcome cannot be read as informative without reference to the
realized report rate, which will be reported.

**Why this allocation.** The no-advertising arm consumes no budget, so its
units are nearly free. In design-stage simulations, H1 power at a 15% effect
was 0.87 for a design with every unit advertising against 0.88 for the 4:4:1
split — the units surrendered to the no-advertising arm are offset by the
larger dose to those remaining. A randomized H2 therefore costs essentially
nothing.

**Why the whole eligible pool.** Power is driven by unit count far more than
by dose, because delivery noise scales with the install count. In design-stage
simulations, two advertising arms of 224 municipalities receiving 28.6 installs
each gave H1 power 0.87, while arms of 100 municipalities receiving 64 installs
each gave 0.58.

**Principal threat — uneven delivery.** At `sigma_c` = 0.6, power at a 15%
effect falls to 0.72 (0.93 at 20%). The banded campaign structure described in
*Study design* is the mitigation, and realized delivery spread will be reported
whatever it shows.

**Sensitivity to track emission.** If only a fraction of advertising-driven
installs ever emit a background track (equivalently, if the realized cost per
install is higher than estimated — both scale the effective dose):

| Track rate | H1 power at 15% | H2 |
|---|---|---|
| 100% | 0.94 | 1.00 |
| 50% | 0.75 | 1.00 |
| 30% | 0.58 | 1.00 |
| 15% | 0.31 | 1.00 |

H2 is unaffected because even a 15% track rate leaves roughly 2.3 extra
participants per municipality, above its ~1.2 MDE.

**Sensitivity to leakage.** `lambda` is the share of advertising-induced
participants recorded outside the municipality that was targeted, whether
because people move or because the masking grid blurs boundaries.

| lambda | H1 power at 15% | Type I (HC3) |
|---|---|---|
| 0 | 0.93 | 0.039 |
| 0.15 | 0.86 | 0.021 |
| 0.30 | 0.77 | 0.029 |

Leakage has two opposing effects — it attenuates the arm contrast, and it
smooths unit-level delivery noise — and which dominates depends on the realized
pool's spatial density: with 949 study units covering 11.5% of Spain's
municipalities, about 68% of leaked activity lands inside the study, so
attenuation dominates (confirmed by a common-random-numbers simulation:
paired power difference −0.15 at lambda = 0.30). **Under the plausible central
case (lambda ≈ 0.15, in line with the ~1.20 multi-municipality ratio measured
under presence attribution), power at a 15% framing effect is roughly 0.86;
heavy leakage (lambda = 0.30) leaves 0.77.** Type I error is unaffected. Modal
attribution already removes the recorded double counting; residual lambda
reflects ad recruits whose sampling is concentrated outside the targeted
municipality (e.g. commuters), which the realized multi-municipality diagnostic cannot directly
measure — a reason the attenuation caveat in *Inference criteria* matters.

Two alternative designs intended to reduce leakage were tested at design
stage and rejected. Requiring at least 5 km of separation between study
municipalities cut the design-stage pool from 448 to 198 units and dropped H1
power to 0.59 — separation loses more to sample size than leakage takes.
Randomizing clusters of adjacent municipalities as single units was worse
still (power 0.46 at lambda = 0.30) and inflated Type I error to 0.098,
because clusters of touching municipalities do not contain spillover operating
at a 3 km scale.

## Starting and stopping rules

**Start.** The campaign launches on 17 August 2026 with a planned 30-day
flight (to 15 September), EUR 8.33 per campaign per day. Thirty days rather
than sixty because the optimiser's learning is driven by conversion volume,
which the fixed budget fixes — a longer flight delivers the same data at half
the daily rate, spending a larger share of budget inside the learning phase and
serving erratically at very thin daily amounts — and because recruits arriving
earlier have more of the measurement window in which to appear in the outcome.
Reports in the second half of the post window run at about three-quarters the
volume of the first half (0.60–0.91 across 2021–2025), a mild further argument
for concentrating delivery early.

**If a campaign's budget is materially unspent on 15 September, its end date
may be extended toward 14 October.** This is a delivery decision, taken from
spend data only, applied to all affected campaigns by the same rule, and made
without reference to any outcome.

**Data collection end.** The post-treatment window closes 14 October 2026, 60
days after the measurement anchor. Outcome data are extracted after that date.

**Stopping rule.** The campaign may be halted early on **cost or delivery
grounds only** — realized cost per install substantially above estimate, or
delivery materially below plan. **No comparison between arms will be computed
before the post window closes.** Any halt, its date and its reason will be
reported.

**Regeneration against final data.** The assignment and every figure above
were regenerated on 14 August 2026 against the completed 2026 pre-window data
(the pre-window closed that day and enters the analysis as a covariate). The
eligibility rule, arm ratio, blocking variable, seed and analysis plan were
fixed before that regeneration and did not change. The 2026 pre-window
covariate will be re-extracted together with the October outcome pull, so that
any late-arriving tracks are included; the outcome extraction and the covariate
re-extraction are a single operation.

**The 2026 season is atypically quiet.** The 2026 pre-window total is 304
participants Spain-wide, against roughly 1,000–1,300 in comparable seasons —
a genuine drop reflecting reduced dissemination this year and apparently lower
mosquito populations in much of Spain, not a data artefact. Consequences:
the 2026 pre-window covariate is weaker but valid; post-window baselines will
likely run below the historical levels the power simulation resamples, which
shrinks baseline noise while the install dose is unchanged, so the stated power
is conservative for H2 and approximately unchanged for H1, where delivery noise
dominates; and H2 gains substantive interest, since it measures whether paid
advertising can sustain participation in precisely the conditions where organic
participation is falling.

---

# Variables

## Manipulated variables

**Advertising condition**, assigned at municipality level, three levels:

1. **Regulatory-focus framed** — advertisements whose copy is framed around
   either avoiding a negative outcome (prevention focus: mosquito bites, disease
   risk) or attaining a positive one (promotion focus: contributing to science,
   protecting the community), or both.
2. **Neutral** — advertisements matched on placement, budget, targeting, call to
   action and platform, differing only in message framing. Copy describes the
   application without invoking either regulatory-focus orientation.
3. **No advertising** — no campaign runs in these municipalities.

Budget is held equal across advertising campaigns. Targeting is by Google Ads
Criteria ID. All campaigns are Android app-install campaigns.

**Verbatim advertisement copy for all arms will be deposited in the repository
and linked from this registration before launch.** The regulatory-focus label is
a claim about the stimulus, so the stimulus is recorded rather than merely
described. Whether the framed arm runs one creative or both orientations will be
decided before launch and recorded with the deposited copy; if both, the
prevention-versus-promotion contrast is exploratory and underpowered (see
*Other planned analysis*).

## Measured variables

**Primary outcome — track participants.** The number of distinct Mosquito Alert
participants whose **modal sampling municipality** is the unit in question —
the municipality in which their sampling effort is concentrated (see
*Indices*) — and who emitted at least one background location track during the
post window, 16 August to 14 October 2026.

**Secondary outcome — reporters.** The number of distinct users who submitted at
least one geolocated non-mission report (adult mosquito, bite, or breeding
site) attributed to the municipality during the same window.

These measure different things and the distinction is substantive. Track
participants capture anyone running the application; reporters capture people
who actually contribute surveillance data. Reporting is the outcome that matters
for the platform's purpose, and is reported as such — but it is noisier
(unit-level residual SD 0.87–0.95 on the log scale against 0.43 for track
participants, with 65% of study municipality-seasons recording zero reporters),
which is why the design is powered on track participants. Power for the reporting
outcome is stated explicitly in *Sample size rationale* rather than left
implicit.

**A divergence between the two outcomes is interpretable, not a problem.**
Advertising that raises track participants but not reporters would indicate
recruitment of app-runners who do not contribute data — itself a finding about
what advertising can and cannot buy.

**Tertiary outcome — presence attribution.** The primary outcome recomputed
under **presence** attribution, in which a participant is counted in every
municipality where they emitted a track. This is the attribution used in all
data deliveries through 2025; the presence-attributed 2026 extract will be
produced together with the October outcome extraction.

**Covariates.** For each outcome, its own:

- The equivalent count for the pre window, 16 June to 14 August 2026 (same attribution
  and same measure as the outcome).
- The municipality's median post-window count for that measure across seasons
  2021–2025.

**Delivery measures (post-treatment, reported but not used in the primary
analysis).** Realized impressions, clicks, installs and spend per municipality,
from Google Ads reporting.

## Indices

**Modal sampling municipality assignment.** Each user is assigned to exactly one
municipality: the one in which they were observed on the greatest number of
distinct days, computed over the user's **full track history** rather than the
study window alone. Ties are broken by number of distinct grid cells, then by
GADM `GID_4`, so the rule is deterministic. **No minimum-activity threshold is
applied**, because requiring a minimum number of tracked days would
preferentially remove the marginal, low-activity users that the campaign is
intended to create.

Modal attribution is used for the primary outcome rather than presence
attribution because presence attribution counts a participant in every
municipality visited, so
municipality counts sum to approximately 1.20 times the true number of people
(stable across 2021–2025; the ratio was 1.6–2.0 before 2021, a different
tracking regime, which is why calibration begins at 2021). Modal attribution makes
the counts an exact partition of people, makes units statistically independent,
and removes transient passers-by.

The natural objection — that Google targets by *presence* while modal
attribution measures a participant's habitual location, which would diverge
during the Spanish holiday season — is not supported: the multi-municipality ratio is 1.233 in coastal provinces
against 1.202 in interior provinces (p = 0.56). The phenomenon is ordinary local
mobility, not tourism.

**Modal attribution is nonetheless measured post-treatment**, because an
advertising-induced user's entire track history begins after launch. If
advertising caused users to run the app more while physically inside the
targeted municipality, borderline users would be classified there and the
estimate would inflate. Background tracks are emitted passively, so this is
expected to be small. Note that **H1 is immune** — both arms are advertised, so
any such bias cancels — while **H2 is not**. This is recorded as a limitation.

**Interior cell fraction.** For each municipality, the share of its assigned
0.025° grid cells that lie entirely within its boundary. Cells are approximately
6 km² at Spanish latitudes and are assigned whole to the municipality containing
their centroid; the median study municipality has an interior fraction of only
0.24, so most of its cells straddle its boundary. Municipalities spanning
several GADM polygons are unioned before measurement. This index is computed
from GADM boundaries before launch, stored in the assignment file, and defines
the pre-specified core robustness subset (448 units at ≥ 0.25).

---

# Analysis Plan

## Statistical models

**Primary specification.** A linear model on post-window participant counts, one
observation per municipality:

```
post_participants ~ arm + block + pre_participants + historical_median
```

where `block` enters as fixed effects for the 106 randomization blocks and
`historical_median` is the municipality's median post-window count across
2021–2025.

**The block fixed effects are not optional.** The design blocked on baseline;
a model without the blocks lets the curvature of the count outcome in baseline —
which blocking absorbed by design — re-enter the specification. In simulation on
an earlier realized draw this put H2's conditional Type I error at 0.10, against
0.06 with the blocks included, while power was unchanged for H1 and slightly
improved for H2. Analyze as you randomize.

**H1** tests the `arm` coefficient among advertising municipalities only
(framed versus neutral, n = 840).

**H2** tests advertising municipalities pooled against no-advertising
municipalities in the same specification (n = 949).

**The same specification is applied to the secondary reporting outcome**, with
report-based covariates substituted throughout (pre-window reporters, and the
median post-window reporter count across 2021–2025). Nothing else changes.
Results on the reporting outcome are reported alongside the primary outcome
whatever they show, and are labelled secondary.

**Why counts rather than logs.** If Google's optimiser concentrates spend more
in one arm than the other, a model on the log scale reports a spurious effect
even when the arms receive identical total impressions, because the log of a
concentrated allocation has a lower mean than that of an even one. In simulation
this inflated Type I error from 0.05 to as high as 0.99 with no true effect. A
linear model on counts is structurally immune and costs essentially no power.

**Why a covariate rather than a difference.** The pre-window count enters as a
covariate rather than being subtracted. Difference-in-differences implicitly
constrains its coefficient to 1; the estimated optimum in these data is
0.58–0.93, so differencing imports baseline noise without removing a
corresponding amount.

**Estimand.** Intention-to-treat with respect to the **assigned municipality**.

## Transformations

**None.** The outcome enters untransformed, for the reason given above.
Covariates enter untransformed and linearly. No standardization, binning, or
winsorization is applied.

The single derived variable is the modal sampling municipality assignment described under
*Indices*, which is applied identically to pre- and post-window counts and to
all historical seasons.

## Inference criteria

**Alpha 0.05, two-sided**, throughout.

**There is exactly one primary test: H1 on the primary outcome (modal-attributed
track participants).** Every other test in this plan is secondary or tertiary
and is labelled as such wherever reported:

| Test | Status |
|---|---|
| H1, track participants | **Primary** |
| H2, track participants | Secondary |
| H1, reporters | Secondary |
| H2, reporters | Secondary |
| H1 and H2, presence attribution | Tertiary |

**No multiplicity correction is applied**, because these are not a family from
which a single claim is selected. Each addresses a distinct question and all are
reported together with their own alpha, whatever they show. The protection
against selective reporting is that the full set is enumerated here in advance
and will be reported in full.

**A secondary result cannot rescue a null primary.** If H1 on track participants
is not supported, a supported H1 on the reporting outcome is reported as what it
is — a secondary finding requiring replication — and not as support for H1.

**Primary test: randomization inference** (implemented in
`analysis/r/03_randomization/analyse_assignment.R`). The test statistic is the
`arm` **coefficient from the primary model itself**, re-estimated under
permutations of the treatment labels **within the realized blocks** — the
design's own randomization distribution — with the covariates retained at their
observed values. 10,000 permutations; two-sided p-value
(1 + #{|T_perm| ≥ |T_obs|}) / (1 + N).

Permutation scheme, per hypothesis: for H1, the no-advertising units are set
aside and framed/neutral labels are permuted within blocks among the advertising
units — the randomization distribution conditional on the no-ad positions, which
are themselves a function of the assignment. For H2, the pooled
advertising/no-advertising indicator is permuted within blocks across all units.

This is exact over the randomization distribution by construction, **and its
exactness does not depend on independence between municipalities**: under the
sharp null the outcomes are fixed, so spatial correlation — including any
induced by leakage of ad-driven participants between neighbouring
municipalities — cannot invalidate it. Parametric alternatives carry no such
guarantee: on an earlier candidate assignment, HC3's Type I error drifted from
0.055 to 0.073 as simulated leakage rose, precisely because leakage correlates
neighbouring outcomes. On the final assignment no such drift appears, but the
immunity of randomization inference is structural rather than an empirical
observation about one draw.

Randomization inference with the block-fixed-effects model is the primary
method because the obvious alternatives failed at design stage: on an earlier
realized draw with a covariates-only model, the ordinary t-test rejected a true
H2 null **0.098** of the time (49 no-ad against 399 advertising units,
right-skewed counts), and even randomization inference on the blockless model
reached 0.10 conditional on the draw. The block terms remove the source of
both. Randomization inference was verified exact over the randomization
distribution (rejection rate 0.046 at alpha 0.05, median p-value 0.502, under
simulation in which only the assignment varies), and the analysis script's
`--calibrate` mode re-runs an end-to-end verification on the committed code.
On the final assignment, over 600 simulated null datasets, it reads
**H1 0.052, H2 0.067**. These are the stricter draw-conditional check —
outcomes redrawn with the assignment held fixed — which RI does not formally
control (its guarantee is over the randomization distribution, where it is
exact). H1 is essentially exact on this check and H2 sits within about 1.5
standard errors of 0.05; both were far worse on earlier, smaller candidate
pools (H2 reached 0.22 without the cap and 0.10 without block terms), and the
large no-advertising arm of this design is what tamed them. HC3 sits mildly
below nominal (0.02–0.03). A result whose significance depends on the gap between the two
tests — one just under alpha, the other just over — will be reported as
equivocal rather than resolved by picking the favourable one.

**Secondary test: HC3 heteroskedasticity-consistent standard errors**, reported
alongside. With block dummies and a no-advertising arm holding one unit in nine,
HC3 over-corrects and runs mildly conservative on the realized draw (H1 0.030,
H2 0.019). Where a block dummy isolates a single unit — possible in subset
analyses — HC3 is undefined and HC1 is substituted; the analysis code does this
automatically.

**Effect sizes reported.** For H1, the estimated difference in participants
between framed and neutral municipalities, both in absolute terms and as a
percentage of the neutral arm's mean. For H2, the estimated difference between
advertising and no-advertising municipalities, in absolute terms and as a
percentage of the no-advertising arm's mean. Both with 95% confidence intervals;
for the randomization-inference results, the interval is obtained by inverting
the permutation test **under a constant additive per-municipality effect**. The
statistic is linear in the hypothesised shift, so the inversion is exact rather
than a grid approximation.

**Attenuation.** Advertising-induced participants recorded outside the
municipality that was targeted attenuate the estimate toward zero. A supported
H1 is therefore conservative. A null H1 is **not** evidence of no effect and
will not be reported as such.

## Data inclusion and exclusion

**Inclusion.** All 949 municipalities meeting the eligibility rule in *Data
collection procedures* are included. Eligibility uses only pre-treatment
information and is applied before randomization, so it cannot bias the treatment
contrast; it defines the population to which results generalize.

**The upper baseline cap, and why it exists.** Municipalities with a median
pre-window count above 25 are excluded — on the final modal-attributed data these
are Barcelona (93), Madrid (48) and Valencia (40), which
sit one to two orders of magnitude above the pool median of 2. They are not
merely large — they destabilize inference. At design stage, with them included,
the realized assignment had a Type I error for H2 of **0.216 conditional on
that draw**, against a design-level 0.064 averaged over fresh randomizations,
because the extreme right tail landed disproportionately in the advertising
arms and the covariates could not absorb it. They are also the municipalities
in which EUR 5,000 buys the least exposure per head. The cap is a fixed rule
applied to the data, not a list of named cities: across design iterations on
successive pre-treatment datasets, other large municipalities moved in and out
of eligibility as their medians crossed the threshold, and the three excluded
here are simply those above it in the final data.

**Post-assignment exclusion.** No municipality will be excluded after assignment
except where Google Ads refuses to serve the location at all. Any such exclusion
will be reported by arm, with the analysis repeated both including and excluding
the affected units.

**Outliers.** No outlier rule is applied to the outcome. The eligibility cap
above is a pre-treatment criterion applied before randomization, not an outcome
based exclusion.

## Missing data

**Municipalities with no tracked participants are zeros, not missing.** The
sampling frame is the complete list of municipalities, so a municipality with no
activity in a window contributes a count of 0. This is the substantively correct
treatment and the reason the frame is built from the full municipality index
rather than from observed activity.

**Historical seasons.** Calibration uses the median across seasons 2021–2025 and
requires the window to be complete (`window_complete`); incomplete windows are
dropped from calibration only, and never from the 2026 outcome.

**Anticipated missingness in 2026.** None for the outcome: the extraction covers
all municipalities. If Google Ads reporting is incomplete for a campaign, the
delivery diagnostics for the affected municipalities will be reported as missing
and the primary analysis, which does not use them, is unaffected.

## Other planned analysis

All of the following are pre-specified and secondary. None affects the status of
H1 or H2.

1. **Presence-attributed outcome** substituted for modal attribution (the tertiary
   outcome). If the two disagree, that is a finding about mobility rather than a
   defect.
2. **Core subset**: the 448 municipalities with interior cell fraction ≥ 0.25,
   i.e. least affected by grid masking, fixed in the assignment file before
   unblinding. This subset has half the units and materially less power
   (0.49 against 0.92 at a 15% effect; 0.72 against 0.99 at 20%). It is a check
   on whether the full-sample estimate is driven by grid blurring, **not** a
   cleaner version of the primary analysis, and a null result there is expected
   under plausible effect sizes.
3. **Realized multi-municipality ratio** for 2026, as a direct leakage
   diagnostic, compared against the 1.17–1.28 range observed since 2021.
4. **Equal-exposure estimate**: a model additionally adjusted for realized
   impressions per municipality. Realized impressions are post-treatment, so
   this is secondary and reported as such.
5. **Delivery distributions by arm**: impressions, clicks, installs and spend per
   municipality, reported whatever the result. If these differ materially between
   arms, H1 must be read with that caveat foregrounded.
6. **Prevention-focused versus promotion-focused creative**, if the framed arm
   runs both. **Declared exploratory and underpowered.**
7. **Minimum-delivery subset**: analysis restricted to municipalities receiving
   at least a threshold level of delivery. The threshold will be fixed and
   recorded before outcome data are examined.
8. **Activation subgroup**: H2 restricted to the 571 municipalities with zero
   baseline participants — does advertising create participation where none
   exists? The subgroup is defined by pre-treatment data and fixed in the
   assignment file. Reported with its own power, whatever it shows.

---

# Other

## Context and additional information

**Project context.** This experiment is Task 5.4 of IDAlert (Infectious Disease
Decision-support Tools and Alert Systems), an EU Horizon Europe project.
Mosquito Alert (https://www.mosquitoalert.com) is an expert-validated citizen
science system that enables ordinary people to participate in the surveillance
of vector mosquitoes, established in Spain since 2014.

**Ethics.** UPF's Institutional Committee for Ethical Review of Projects
(CIREP) approved this research as a modification to protocol 270 (originally
approved on 21 July 2022; modification approved 30 July 2026). Individuals exposed to advertisements are
not enrolled as research subjects and no individual-level data are collected for
the purpose of this experiment; the analysis uses municipality-level aggregate
counts only.

**Why background tracks are the primary outcome and reports secondary.**
Background tracks are emitted by anyone running the application, so they capture
participation more broadly than report submission, and they are substantially
less noisy: the unit-level residual SD is roughly 0.43 on the log scale for
track participants against 0.87–0.95 for report counts, with 65% of study
municipality-seasons recording zero reporters. The design is therefore powered
on tracks. Reporting is nonetheless the outcome that matters for the platform's
purpose — it is the actual contribution of surveillance data — so it is analysed
and reported in full as a secondary outcome, with its power stated in advance.

**Known limitations, stated in advance.**

1. The measured outcome attenuates the true effect, because participants induced
   in one municipality may be recorded in another. A null H1 is uninformative
   about the absence of an effect.
2. Modal attribution is computed partly from post-treatment data. H1 is immune to
   any resulting bias; H2 is not.
3. The study has power 0.92 at a 15% framing effect and essentially 1.00 at
   20% on the primary outcome (at moderate delivery spread), 0.65 at 10%, and
   is not powered below that. Leakage of ad recruits whose sampling is concentrated
   outside the targeted municipality reduces H1 power moderately (to roughly 0.86 at a
   plausible lambda of 0.15). On the secondary reporting outcome, power at a
   15% effect is 0.79 if roughly 40% of advertising-driven installs go on to
   report, and lower below that.
4. Results generalize to the Spanish municipalities Google Ads can target by
   name, from those with no prior Mosquito Alert activity up to moderate
   activity — but not to the three largest-activity cities (Barcelona, Madrid,
   Valencia), which the eligibility cap excludes, nor to municipalities Google
   Ads cannot address directly.
5. The cost-per-install figure of EUR 0.39 is a Google estimate from a test
   campaign, not a realized cost. If the realized cost is materially higher,
   installs per municipality fall and power falls with them; realized cost will
   be reported.

**What would falsify what.**

- *H1 supported*: the framed arm exceeds the neutral arm, with comparable
  delivery distributions across arms.
- *H1 not supported*: no detectable difference. Given the power above, this
  rules out framing effects above roughly 15%, is partially informative at 10%
  (power 0.65), uninformative below, and — because of attenuation — is not
  evidence of no effect.
- *H2 not supported*: the campaign did not deliver. H1 becomes uninterpretable
  and will be reported as such rather than as a null result.

**Materials and code.** All code, the assignment, and the checksummed manifest
are in the project repository,
`https://github.com/IDAlert/IDAlert-T54-Areal-Units`, at the release tag
**`v1.0-preregistration`** — the repository state at registration, before any
outcome existed. The assignment can be verified against the manifest md5 at
that tag.

**Data availability.** The aggregate inputs — municipality-level
modal-attributed participation counts and municipality-level reporter counts,
both containing no identifiers, coordinates, or per-person records — are
deposited openly at **[10.5281/zenodo.21940738](https://doi.org/10.5281/zenodo.21940738)** (CC-BY-4.0) so that the manifest checksums are verifiable rather than
merely asserted, and so the assignment can be independently regenerated. The
pre-treatment inputs are deposited **before any outcome exists**, which
timestamps exactly the bytes the randomization consumed; the 2026 outcome
extracts follow after the post window closes on 14 October 2026. Deposit scope and the measured disclosure profile — including the comparison
with Mosquito Alert's existing finer-grained public releases — are set out in
`docs/operations/data-deposit-plan.md`. The participant-level raw report export
is not published; it is the input to the aggregate reporter counts, not a
publishable product.

| Item | Location |
|---|---|
| Assignment | `analysis/r/output/assignment_2026_final.csv` |
| Assignment code | `analysis/r/03_randomization/assign_treatment_2026.R` |
| Manifest with checksums, attribution check | `analysis/r/output/manifest_2026_final.txt` |
| Power analysis, primary outcome | `analysis/r/02_power/run_final_2026_power.R` |
| Power analysis, reporting outcome | `analysis/r/02_power/run_report_outcome_power.R` |
| Analysis code (RI, HC3, CI inversion, calibration) | `analysis/r/03_randomization/analyse_assignment.R` |
| Grid geometry per municipality | `analysis/r/output/municipality_grid_geometry.csv` |
| Measurement memo (grid, modal attribution) | `docs/operations/measurement-grid-and-modal-attribution.md` |
| Campaign target lists | `analysis/r/output/campaign_criteria_ids/` |
| Reproduction path | `REPRODUCE.md` |
