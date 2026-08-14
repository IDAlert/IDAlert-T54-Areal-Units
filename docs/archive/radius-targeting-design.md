# Radius Targeting, Spillover and Unit Design

Assessment of named-location versus radius targeting, whether to re-add Greece,
and how to define the areal units for a single-wave campaign on 15 August 2026.

## Summary of recommendations

1. **Do not add Greece.** At municipality level Greece contributes 42 active and
   283 silent units against Spain's 847 and 7,393. The combined MDE improves
   from +23.4% to +22.7% — under one percentage point, for a second ad account,
   language, and ethics jurisdiction.
2. **Use radius targeting**, but not primarily to increase *n*. Use it because it
   reaches the ~7,270 municipalities Google does not name, and because it makes
   the buffer between arms explicit and controllable.
3. **Separate unit centres by 5-8 km.** For municipality-centred units 5 km is
   optimal under every leakage assumption tested. For freely placed 2 km
   circles the choice is genuinely unresolved: 5 km separation (1 km edge gap)
   wins if leakage is mild, 8 km (4 km gap) if it is severe. Default to **8 km**
   until leakage is measured — it costs ~3 points of central-case MDE and
   protects against a much worse downside.
4. **Place circles freely, not on municipality centroids.** Candidates are the
   locations with a recorded app audience; select ~4,000-5,000 by historical
   activity. This gives 862 active units against 678 for municipality-centring,
   and a 7.7% activation rate among silent units against 2.8%. Do not build
   population-based units. Allocate *budget* by audience instead.
5. **Postal codes are the best unit but the worst target.** All 11,150 Spanish
   postal codes would give MDE +19%, better than anything else considered — but
   Google names only 1,221 of them (10%, covering 44% of reports), which drops
   the design to +39% un-thinned and +62% thinned. Verify whether the UI resolves
   postal codes beyond the published table; if it does, revisit this.
6. **Keep three arms but pool for the primary test.** Prevention + promotion
   against neutral uses 2N/3 units against N/3, capturing most of the gain from
   dropping to two arms (+33% against +31% for postal codes) while keeping the
   framing comparison estimable and a null result interpretable.
7. **Run a leakage pilot before August.** The weakest number in this whole
   analysis is how much treatment leaks between neighbouring units, and it is
   cheaply measurable. It also decides the named-versus-radius question.

## What the literature says

**Jones RB, Goldsmith L, Williams CJ, Kamel Boulos MN. Accuracy of
Geographically Targeted Internet Advertisements on Google Adwords for
Recruitment in a Randomized Trial. J Med Internet Res 2012;14(3):e84.**
This is the closest published precedent — a pilot cluster RCT recruiting to a
depression resource across 16 of 121 British postcode areas in four arms.

Findings that bear directly on our design:

- **Targeting accuracy was poor.** By participants' self-reported postcodes, only
  **21%** of website visitors were in the targeted intervention areas, though
  Google Analytics claimed 70%. In a subsample comparing IP location to stated
  postcode, AdWords "targeted correctly in just half the cases". Roughly 25% of
  ads reached exactly on-target areas and 25% leaked to nearby zones.
- **But control contamination was minimal — 1%** (22/2,236 visitors). The reason
  is that intervention and control areas were deliberately far apart: 35 miles
  at the closest, 110–160 miles for several pairs.
- **Leakage is local.** Most of the ~78% that landed outside the study went to
  *nearby or adjacent* areas, not randomly across the country.
- Their recommendations: use radius targeting rather than polygons (Google
  withdrew polygons), use the smallest radius (1 km) in urban areas, run a
  separate campaign per area so performance can be monitored, prioritise
  geographic separation over covariate matching, and prefer two arms with more
  clusters over four arms with fewer.

The other relevant literature is Google's own geo-experiment methodology —
Vaver & Koehler, *Measuring Ad Effectiveness Using Geo Experiments* (Google,
2011), and the time-based regression extension (Kerman, Wang & Vaver, 2017),
with an open-source implementation at `google/GeoexperimentsResearch`. Their
design rule is the same one Jones et al. arrived at empirically: geos must be
targetable by the channel *and* "large enough so as to be reasonably isolated
from other geos" to limit spillover from travel across boundaries.

**The implication for us is uncomfortable.** Our power gain came from using
thousands of small, adjacent municipalities. That is precisely the configuration
both sources warn against. Every unit would border differently-armed units, so
leakage would flow directly between arms rather than into neutral ground.

## Measured spillover from participant movement

Ad-delivery error cannot be measured from our data. Participant movement can,
and it puts a floor under the separation needed. From 9,857 Spanish
user-seasons with two or more reports in a 60-day window around 15 August:

| Distance from a reporter's own median location | Share of their reports |
|---|---|
| within 1 km | 83.6% |
| within 2 km | 85.9% |
| within 5 km | 88.8% |
| within 10 km | 90.6% |
| within 20 km | 92.4% |
| within 50 km | 94.8% |

The distribution has a sharp core and a long tail: most reporting is essentially
at a fixed point, but about 5% of reports are more than 50 km from the
reporter's own centre — holiday and travel reporting, which no buffer can fix.

At municipality level, **21.4% of user-seasons report from more than one
municipality, and 10.2% of reports fall outside their reporter's modal
municipality.** That 10% is an irreducible attenuation of any
municipality-level contrast, independent of how well the ads are targeted.

## The separation-versus-power tradeoff

Thinning the municipality set so that no two retained centres are within
`D` km, preferring high-activity municipalities, gives:

| Separation | Units | Active | Silent | Reports retained | MDE (no leakage) |
|---|---|---|---|---|---|
| 0 km | 8,240 | 847 | 7,393 | 100% | +23% |
| 2 km | 8,035 | 834 | 7,200 | 99% | +24% |
| 5 km | 5,529 | 678 | 4,851 | 87% | +27% |
| 10 km | 2,354 | 417 | 1,937 | 70% | +36% |
| 20 km | 765 | 216 | 549 | 49% | +56% |
| 30 km | 382 | 134 | 248 | 41% | +77% |
| 50 km | 156 | 72 | 84 | 33% | +125% |

Separation is nearly free up to about 5 km — Spanish municipality centres are
mostly more than 2 km apart already, and at 5 km you keep 87% of the reports.
Beyond 10 km it becomes expensive fast.

Charging each design the leakage it plausibly suffers (leakage being the share
of the treatment contrast lost to differently-armed neighbours, which falls as
separation rises) produces an interior optimum:

| Separation | Units | Optimistic | Central | Pessimistic |
|---|---|---|---|---|
| 0 km | 8,240 | 33% | 47% | 77% |
| 2 km | 8,035 | 31% | 39% | 52% |
| **5 km** | **5,529** | **32%** | **37%** | **44%** |
| 10 km | 2,354 | 40% | 43% | 47% |
| 20 km | 765 | 60% | 64% | 68% |
| 50 km | 156 | 131% | 135% | 139% |

**For municipality-centred units, 5 km is the right answer.** It is optimal or
within one point of optimal under all three leakage assumptions, and it has much
the narrowest spread across them (32–44%, against 33–77% with no separation).
Choosing it does not require knowing the leakage rate, which is exactly the
property you want from a design decision made before the leakage rate is
measurable. For freely placed circles the equivalent question is less
clear-cut — see the free-placement section below.

Note that the leakage column is judgement anchored on Jones et al., not
estimated from our data. It is the weakest input to this analysis.

## (a) Should there be a buffer, and how large?

Yes. For freely placed 2 km circles, default to **8 km between centres** (a 4 km
edge gap) until leakage is measured; 5 km is better if leakage turns out mild.
With circles of radius `r`, the physical gap between adjacent units is `D − 2r`,
so:

- radius 2 km, separation 5 km → 1 km gap
- radius 2 km, separation 10 km → 6 km gap

The 5 km figure is driven by the shape of the tradeoff curve, not by the
displacement data. The displacement data say something slightly different and
worth noting: 84% of reports fall within 1 km of the reporter's own centre, so
*participant movement* is mostly very local and a small buffer handles most of
it. The residual 10% cross-municipality leakage comes from a minority of mobile
reporters and a 5 km buffer will not remove it. Budget for roughly 10%
attenuation from movement regardless of what buffer you choose.

What the buffer really protects against is **ad delivery error**, which Jones et
al. suggest is the dominant channel. A buffer converts leaked exposure from
"contaminating a control unit" into "wasted on nobody", which costs money but
preserves the contrast.

## (b) How should the units be defined?

Three options were on the table. The recommendation is the third.

**Uniform radius everywhere, control for population in the analysis.** Rejected
as the primary frame. It is not wrong, but it solves a problem the design
already handles: both outcomes are baseline-normalised — the intensive margin is
a log ratio and the extensive margin is a conditional activation probability —
so unit population is largely absorbed already. Adding a population covariate to
a randomized comparison buys little.

**Population-based areal units (equal-population cells).** Rejected. It breaks
the correspondence with administrative geography, which matters for three
practical reasons: the 970 named Google targets are municipalities, the ethics
framing and reporting are in terms of official units, and Mosquito Alert's own
reporting to public health agencies is municipality-based. It also gains
nothing statistically, because equalising population does not equalise the
quantity that actually drives precision, which is baseline reporting activity.

**Free circle placement — recommended.** See the section below; this supersedes
the municipality-centred recommendation that originally stood here.

**Municipalities as the frame, uniform circles as the unit — superseded.**
Concretely:

1. Take the municipality centroids already computed in
   `targeting_plan_spain_municipalities.csv` (point-on-surface, so they fall
   inside the polygon even for concave shapes).
2. Thin greedily to 5 km minimum separation, preferring high-activity
   municipalities. This yields ~5,500 units retaining 87% of reports.
3. Target each with a **uniform radius** — 2 km is a reasonable default, and
   Jones et al. recommend the smallest available (1 km) in urban areas.
4. **Define the analysis unit as the circle, not the municipality.** Aggregate
   reports by whether they fall inside the circle. This makes exposure geography
   and outcome geography identical, which is the single most important property
   for clean identification. Reports in the buffer zone are simply excluded —
   that is what the buffer is for.
5. Where a municipality *does* have a named Google geo target and its boundary
   is a reasonable match, you may prefer the named target: it follows the real
   administrative boundary and is likely better served by Google's own location
   inference. This is a per-unit choice, and the crosswalk marks which are
   available.

**Uniform radius, non-uniform budget.** The one place population genuinely
matters is dose. A fixed budget per circle buys very different per-capita
exposure in Madrid than in a village, and the estimand is a per-unit
multiplicative effect. Allocate spend proportional to the population inside each
circle — or better, to the baseline participant count from the Zenodo
sampling-effort surface (`province_outcome_daily_*.csv` is built from cell-level
`n_participants`), which measures the reachable app-relevant audience rather
than raw population. That keeps the treatment dose comparable across units,
which is what the constant-effect assumption in the analysis requires.

## Free circle placement beats municipality-centring

If the units are radius-targeted circles anyway, nothing forces their centres
onto municipality centroids. The three reasons originally given for
municipality-centring do not survive scrutiny:

1. *Correspondence with the 970 named Google targets* — irrelevant once we are
   radius-targeting.
2. *Ethics framing* — the protocol specified provinces, so a modification is
   needed regardless; municipalities and circles are the same size of change.
3. *Mosquito Alert reports by municipality* — that is a convenient aggregation
   choice, not a constraint. Reports are points and can be aggregated to any
   geometry.

Tested directly. Candidate centres are the 0.025-degree sampling-effort cells
that have ever recorded a participant (33,760 in Spain), which restricts
placement to somewhere with an app-relevant audience. Greedy selection at 5 km
minimum separation, ordered by historical activity then audience:

| Circles used | Active | Silent | Activation rate | MDE |
|---|---|---|---|---|
| 500 | 296 | 204 | 25.2% | +53% |
| 1,000 | 474 | 526 | 18.5% | +38% |
| 2,000 | 705 | 1,295 | 13.4% | +28% |
| **4,000** | **862** | **3,138** | **7.7%** | **+22%** |
| 6,000 | 862 | 5,138 | 4.7% | +22% |
| 9,220 (all) | 862 | 8,358 | 2.9% | +22% |

Against municipality-centring at the same 5 km separation (5,529 units, 678
active, 4,851 silent, MDE +27%), free placement gives **862 active units instead
of 678** and a **7.7% activation rate instead of 2.8%**.

Two things drive the gain:

- **Dense areas get subdivided.** Barcelona is one municipality carrying ~8,000
  reports; free placement splits that footprint into several units, each with
  ample counts. Municipality-centring wastes its one unit per municipality
  wherever activity is concentrated, and wastes units on rural centroids that
  sit in empty fields.
- **Candidates are audience-defined, so the structural-zero problem is avoided
  by construction.** Restricting centres to cells with recorded participants
  means silent circles are places with people but no reports yet — genuinely
  activatable — rather than empty countryside. This is the same "count only
  informative units" principle, applied at the design stage instead of post hoc.

Note the optimum at about **4,000 circles**. Beyond that, added circles sit in
low-audience places whose activation probability approaches zero: they add *n*
without adding information, and the MDE flattens at +22%.

Coverage is better than the small footprints suggest. 2 km circles cover a tiny
fraction of Spain's land area but capture **72%** of all Spanish reports in the
2021-2024 windows (39,276 of 54,231), because reporting is concentrated exactly
where the circles are. The remaining 28% falls in the buffer and is excluded by
design.

### Separation, with leakage charged

| Separation | Edge gap | Circles | Optimistic | Central | Pessimistic |
|---|---|---|---|---|---|
| 5 km | 1 km | 9,220 | 29% | **37%** | 53% |
| 8 km | 4 km | 5,246 | 34% | **40%** | 49% |
| 10 km | 6 km | 3,786 | 38% | **42%** | 50% |
| 15 km | 11 km | 2,145 | 46% | 50% | 55% |
| 20 km | 16 km | 1,375 | 56% | 59% | 63% |

Free placement's nominal advantage (+22% against +27%) is real but smaller than
the spread induced by the leakage assumption, and after charging leakage the two
approaches converge near +37%. The choice between 5 km and 8-10 km separation is
**not resolved by the data**: optimistic leakage favours the tighter packing,
pessimistic favours the wider gap, and the ranking flips between them.

Given Jones et al.'s pessimism about targeting accuracy, 8 km separation
(4 km edge gap, ~5,200 circles) is the more defensible default — it gives up
about 3 points of central-case MDE for a much smaller downside if leakage turns
out to be bad.

### One methodological point for reviewers

Circle centres are selected using historical reporting activity, which overlaps
the outcome variable. This is safe because selection uses 2021-2024 data only,
happens entirely before randomization, and is therefore identical across arms:
it can bias the *level* of the outcome (units selected on high past activity
will regress toward the mean) but not the arm *contrast*. The selection rule
must be frozen and preregistered before the 2026 pre-window opens.

## Would named units leak less than circles? And should we use postal codes?

**The mechanism is plausible.** Google's inferred user location is frequently
only place-level: an IP resolves to a city or postal-code centroid, not a
coordinate. Matching a place-level estimate against a *named place* target is
exact — no geometry step, no error introduced. Forcing that same coarse estimate
through a fine geometric test, which is what radius targeting does, can only add
error: whether the ad serves then depends on where the inferred centroid happens
to fall relative to our circle, which is close to arbitrary. For the share of
impressions where location is known only at place level, named targeting should
be strictly more accurate.

**There is no direct evidence either way.** Jones et al. compared radius circles
against hand-drawn polygons, not against named administrative targets, and their
reference standard (participants' self-reported postcodes) conflates ad-delivery
error with participant mobility. So this remains a mechanism argument.

**But postal codes do not deliver, for a reason unrelated to leakage.** Google
lists only **1,221 of Spain's ~11,150 postal codes** — about 10%.

| Design | Units | Active | Silent | Activation | Reports covered | MDE |
|---|---|---|---|---|---|---|
| All 11,150 Spanish postal codes | 11,150 | 1,231 | 9,919 | 3.3% | 100% | **+19%** |
| Google-targetable postal codes | 1,219 | 399 | 820 | 11.0% | 44% | +39% |
| Targetable, thinned to 8 km | 566 | 195 | 371 | 10.5% | 27% | +62% |
| Free circles, 8 km separation | 5,246 | 584 | 4,662 | 3.4% | — | **+28%** |

Targetable postal codes are also unevenly spaced — median distance to nearest
neighbour 4.0 km, but 1.8 km at the 25th percentile and 0.19 km at the 10th — so
using them un-thinned means many differently-armed units directly abutting.

**How large would the leakage advantage have to be to overturn this?** Comparing
the thinned designs at 8 km separation, postal codes would need essentially zero
leakage while circles suffered ~40% before the two draw level. Comparing
un-thinned postal codes (1,219 units, +39%) against 8 km circles (5,246 units,
+28%), the crossover is around a 25 percentage-point leakage advantage for named
targeting. That is a large differential to assume without evidence.

### What the postal-code design would actually detect

The +39% is a single common multiplicative effect on underlying reporting
propensity. It shows up on two margins at once, and the test combines them by
inverse variance:

| Margin | Units per arm | MDE alone | Weight in the combined test |
|---|---|---|---|
| Intensive — more reports where reports already happen | 133 | +46% | 0.76 |
| Extensive — a first report where there were none | 273 | +98% | 0.24 |
| **Combined** | 406 | **+39%** | — |

The intensive margin carries three quarters of the weight despite having half as
many units, because a count carries far more information per unit than a
yes/no.

In tangible terms, per arm, for the single 2026 season:

**Silent postal codes (273 per arm, no reports in the pre-window).** About
**30** of them would record a first report in the post window anyway. At the
+39% detectable effect that becomes **42** — twelve extra postal codes lighting
up for the first time. At +20% it would be 36, six extra.

**Active postal codes (133 per arm).** These are thin: the median has **3**
reports in a 60-day pre-window (mean 5.9), and the Spain-wide post/pre ratio in
them is 0.86, i.e. reporting is already declining after mid-August. One arm's
active postal codes would produce roughly **765** reports in the post window. At
+39% that becomes about **1,063** — some 300 extra reports. At +20%, about 150
extra.

So the whole study turns on detecting something like *twelve additional
first-reporting postal codes and three hundred additional reports, per arm*.

Power across effect sizes:

| Effect | +10% | +20% | +25% | +30% | +39% | +50% |
|---|---|---|---|---|---|---|
| Power | 0.13 | 0.34 | 0.47 | 0.60 | 0.79 | 0.93 |

Two caveats. The combined test assumes a *common* effect on both margins; if
activating a silent area and boosting an active one respond differently — which
is likely — the pooled estimate is a weighted average of two different things,
and both coefficients should be reported separately. And the median active unit
having only 3 pre-window reports is why the intensive-margin residual SD is
1.105: these are very small counts, and that is the fundamental reason 1,219
postal codes cannot do better than +39%.

**The genuinely interesting number is the first row.** All 11,150 postal codes
would give **+19%** — better than any design considered anywhere in this project,
because postal codes are small, exhaustive, non-overlapping, and their boundaries
follow settlement patterns. Postal codes are an excellent *unit* and a poor
*target*: the constraint is entirely Google's 10% coverage.

That makes one cheap check worth doing before settling the design: **type a few
Spanish postal codes that are absent from the published table into the Google Ads
location search and see whether they resolve.** The published geo target table is
the canonical list of geo target constants and the API will only accept IDs from
it, so 1,221 is probably a hard limit — but if the UI or bulk upload resolves
postal codes beyond it, postal codes become the best available design by a
wide margin and this section should be rewritten.

## Two arms versus three

Dropping an arm puts 50% more units in each of the remaining ones. Both margins'
standard errors scale as `sqrt(2 / n_per_arm)`, so the whole combined SE scales
by `sqrt((N/3)/(N/2))` = 0.816.

| Design | 3 arms, pairwise | 3 arms, pooled | 2 arms |
|---|---|---|---|
| Postal codes (1,219) | +39% | **+33%** | +31% |
| Free circles, 8 km (5,246) | +28% | **+24%** | +23% |
| Free circles, 5 km (9,220) | +23% | **+19%** | +18% |
| Municipalities, 5 km (5,529) | +27% | **+23%** | +21% |

The "pooled" column is the option worth noticing: **keep all three arms, but make
the primary test prevention + promotion combined against neutral.** That contrast
uses 2N/3 units against N/3, giving a relative SE of 0.866 — it captures most of
the two-arm gain while keeping the framing comparison available as a secondary
analysis. For postal codes it is +33% against +31% for a true two-arm design.

There is a further, less obvious point in favour of two arms or pooling. A
three-arm design testing both prevention-vs-neutral and promotion-vs-neutral is
running two contrasts; if those are adjusted for multiplicity the three-arm
pairwise MDE worsens from +39% to +44% for postal codes. A single preregistered
primary contrast avoids that entirely.

### But which arm would you drop?

This is the part that matters more than the power arithmetic.

**Dropping neutral** (prevention vs promotion) buys the best power and aims it
at the *smallest* of the three available contrasts. Regulatory-focus theory
predicts a fit effect — the framing that works depends on the recipient's own
chronic orientation — so averaged over a general population the two framings
plausibly have similar mean effects. Worse, without a neutral arm a null result
is uninterpretable: "both framings worked equally" and "neither framing did
anything" produce identical data.

**Dropping one framing** (say prevention vs neutral) targets the larger expected
effect and yields an interpretable result either way, but abandons the
regulatory-focus comparison that is the study's theoretical contribution.

**Pooling within a three-arm design** avoids the choice. The primary test asks
whether framed messaging moves reporting at all, at +33% rather than +39%; the
prevention-versus-promotion contrast remains estimable, underpowered but
reportable as exploratory. Given that no configuration reaches a 10% effect
anyway, preserving interpretability costs little.

Note that Jones et al. recommended two-arm designs with more clusters over
four-arm designs with fewer — but their concern was cluster count per arm in a
16-cluster study, not a 1,000+ unit design, and they retained a control.

## Named locations versus radius targeting

| | Named geo targets | Radius targeting |
|---|---|---|
| Units available (Spain) | 970 | unlimited |
| Boundary fidelity | exact administrative boundary | circle, ignores boundaries |
| Buffer control | none — units are adjacent by construction | explicit and tunable |
| Setup | Criteria IDs, well supported in Editor/API | lat/lng + radius, equally supported |
| Google's location inference | tuned to these entities | generic |
| MDE (Spain, hurdle) | +40% | +23% nominal, ~+37% after leakage |

Radius targeting wins, but for the buffer control rather than the unit count.
Note that once a 5 km buffer is imposed, the nominal advantage of radius
targeting shrinks: 5,529 buffered radius units give +27% nominal against +40%
for the 970 named units, and the named units cannot be buffered at all.

A hybrid is defensible and probably best: use named geo targets where they
exist and the municipality is retained after thinning, radius elsewhere.

## The pilot worth running

Everything above hinges on a leakage rate nobody has measured for this platform,
country and unit size. Jones et al.'s contribution was precisely to measure it,
and they found the platform's own reporting (Analytics: 70% on-target)
overstated accuracy by more than threefold against self-reported location (21%).

Before committing the August budget, run a small campaign in a handful of
well-separated units and check where the resulting app installs and reports
actually come from. Even a crude estimate would replace the weakest assumption
in this design, and it would distinguish the 32% and 77% ends of the table
above — a difference that decides whether the study is worth running.

## Files

1. `analysis/r/power_analysis/run_free_circle_placement.R` — free placement,
   the separation curve, and the circle centre list
2. `analysis/r/power_analysis/measure_spillover_scale.R` — participant
   displacement and cross-municipality leakage
3. `analysis/r/power_analysis/run_buffer_design_tradeoff.R` — the same curve for
   municipality-centred units
4. `analysis/r/power_analysis/run_postal_code_design.R` — postal codes as units
   (needs GeoNames https://download.geonames.org/export/zip/ES.zip)
5. `output/free_circle_centres.csv` — selected circle centres, ready to target
6. `output/free_circle_placement.csv`, `output/free_circle_separation_curve.csv`
7. `output/postal_code_design.csv`
8. `output/spillover_scale.csv`, `output/buffer_design_tradeoff.csv`

## Sources

- Jones RB, Goldsmith L, Williams CJ, Kamel Boulos MN. Accuracy of
  Geographically Targeted Internet Advertisements on Google Adwords for
  Recruitment in a Randomized Trial. J Med Internet Res 2012;14(3):e84.
  https://www.jmir.org/2012/3/e84/ (open access via PMC3414907)
- Vaver J, Koehler J. Measuring Ad Effectiveness Using Geo Experiments. Google,
  2011. https://research.google/pubs/measuring-ad-effectiveness-using-geo-experiments/
- Kerman J, Wang P, Vaver J. Estimating Ad Effectiveness using Geo Experiments
  in a Time-Based Regression Framework. Google, 2017.
  https://research.google/pubs/estimating-ad-effectiveness-using-geo-experiments-in-a-time-based-regression-framework/
- Google geo target reference table:
  https://developers.google.com/google-ads/api/data/geotargets
