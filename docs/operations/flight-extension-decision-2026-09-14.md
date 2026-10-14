# Flight extension decision — 14 September 2026

Pre-registered clause (*Starting and stopping rules*): "If a campaign's
budget is materially unspent on 15 September, its end date may be extended
toward 14 October. This is a delivery decision, taken from spend data only,
applied to all affected campaigns by the same rule, and made without
reference to any outcome."

## Rule adopted

> Every campaign whose cumulative spend is below EUR 250 has its end date
> extended to 14 October 2026, with daily budget (EUR 8.33) and target CPA
> (EUR 0.39) unchanged. Each campaign is paused on the day its cumulative
> spend first reaches EUR 250. No other setting is changed.

The threshold is a bright line rather than a judgment of "materially": every
campaign below EUR 250 is treated identically, so the rule cannot select
campaigns by arm. Budgets and bids are not touched, because changing them
would reset the optimiser's learning and break the identical-settings
symmetry across the twenty campaigns.

## Data at the decision (spend only; no outcome data consulted)

Source: `data/google_ads/campaign_performance_2026-08-17_to_2026-09-14.csv`
(flight day 29 of 30). All twenty campaigns are below EUR 250; none can reach
it by 15 September (the two closest, framed_01 and neutral_01, stand at
EUR 236–237 and spend about EUR 8/day). The rule's outcome on 15 September
was therefore already determined, and the extension was applied on
14 September to avoid a serving gap at the scheduled end date.

| campaign | spend EUR | remaining | EUR/day (29-day avg) | days to cap at pace |
|---|---|---|---|---|
| framed_01 | 236.00 | 14.00 | 8.14 | 1.7 |
| framed_02 | 231.21 | 18.79 | 7.97 | 2.4 |
| framed_03 | 189.56 | 60.44 | 6.54 | 9.2 |
| framed_04 | 171.45 | 78.55 | 5.91 | 13.3 |
| framed_05 | 117.69 | 132.31 | 4.06 | 32.6 |
| framed_06 | 71.82 | 178.18 | 2.48 | 71.9 |
| framed_07 | 100.60 | 149.40 | 3.47 | 43.1 |
| framed_08 | 81.68 | 168.32 | 2.82 | 59.8 |
| framed_09 | 60.54 | 189.46 | 2.09 | 90.8 |
| framed_10 | 65.99 | 184.01 | 2.28 | 80.9 |
| neutral_01 | 236.84 | 13.16 | 8.17 | 1.6 |
| neutral_02 | 235.48 | 14.52 | 8.12 | 1.8 |
| neutral_03 | 206.21 | 43.79 | 7.11 | 6.2 |
| neutral_04 | 183.96 | 66.04 | 6.34 | 10.4 |
| neutral_05 | 109.66 | 140.34 | 3.78 | 37.1 |
| neutral_06 | 49.06 | 200.94 | 1.69 | 118.8 |
| neutral_07 | 110.36 | 139.64 | 3.81 | 36.7 |
| neutral_08 | 90.97 | 159.03 | 3.14 | 50.7 |
| neutral_09 | 127.02 | 122.98 | 4.38 | 28.1 |
| neutral_10 | 62.61 | 187.39 | 2.16 | 86.8 |

Arm spend at the decision: framed EUR 1,326.54, neutral EUR 1,412.17
(total EUR 2,738.71 of 5,000).

Expected consequence: bands 01–04 (eight campaigns, four per arm) reach
EUR 250 within the extension and are paused; bands 05–10 (twelve campaigns,
six per arm) run to 14 October without reaching it. Extension adds no cost
beyond the registered EUR 5,000.

## Enforcement of the EUR 250 cap

Google Ads offers no per-campaign total budget for App campaigns (daily
budgets only), so the cap is enforced by pausing:

1. Primary: an automated rule ("pause campaigns when Cost over all time is
   at or above EUR 250"), run once daily at a fixed hour, so that all
   twenty campaigns are evaluated at the same moment and both arms are
   treated identically.
2. Backup: a manual daily check of cumulative spend against the same
   threshold, at least until the rule has been seen to fire correctly on
   the first campaigns to reach the cap.

Because pausing happens at most once a day and Google may deliver up to
twice a daily budget on any single day, realized totals can exceed EUR 250
by up to one day's spend (roughly EUR 8–16 for the fastest campaigns).
This overshoot is symmetric across band-matched pairs (framed_k and
neutral_k spend at nearly the same daily rate) and immaterial to the design.
Realized totals and the date each campaign was paused will be reported with
the delivery diagnostics.

## Record

- Extension applied: 14 September 2026, all twenty campaigns, end date
  2026-09-15 → 2026-10-14. A campaign-settings export taken after the
  change is kept in `data/google_ads/` per the creatives provenance rules.
- Pause log: see below.

## Pause log

Source: `data/google_ads/campaign_performance_by_day_2026-08-17_to_2026-10-14.csv`
(day-level spend, downloaded 14 October 2026 before the day closed). "Crossed"
is the first day cumulative spend reached EUR 250; "last spend" is the last day
with any cost recorded.

| campaign | spend at 15 Sep | spend at 14 Oct | vs EUR 250 | crossed | last spend | outcome |
|---|---|---|---|---|---|---|
| framed_01 | 255.50 | 256.07 | +6.07 | 15 Sep | 16 Sep | paused |
| neutral_01 | 255.94 | 256.66 | +6.66 | 15 Sep | 16 Sep | paused |
| framed_02 | 239.48 | 260.58 | +10.58 | 16 Sep | 18 Sep | paused |
| neutral_02 | 244.94 | 255.66 | +5.66 | 16 Sep | 18 Sep | paused |
| framed_03 | 194.56 | 278.24 | +28.24 | 30 Sep | 14 Oct | **paused late, 14 Oct** |
| neutral_03 | 209.45 | 283.27 | +33.27 | 1 Oct | 14 Oct | **paused late, 14 Oct** |
| neutral_04 | 188.82 | 271.67 | +21.67 | 7 Oct | 14 Oct | **paused late, 14 Oct** |
| framed_04 | 174.87 | 239.65 | −10.35 | — | 14 Oct | ran to end |

The remaining twelve campaigns (bands 05–10, both arms) ended between
EUR 74.61 and EUR 179.83 and never approached the cap.

The four band-01 and band-02 campaigns were paused manually within one to two
days of reaching the cap. Two of the four campaigns ended 15 September already
over EUR 250 on the day's spend, which is consistent with the one-day
overshoot anticipated when the rule was adopted.

## Deviation: three campaigns not paused at the cap until the last day

The rule required each campaign to be paused on the day it reached EUR 250.
After 18 September the daily check lapsed, and three campaigns that crossed
the cap later were not paused when they reached it: framed_03 (crossed 30
September), neutral_03 (1 October) and neutral_04 (7 October). They kept
serving until they were paused on the evening of 14 October, a few hours
before the scheduled end, once the lapse was detected,
overspending the cap by EUR 28.24, 33.27 and 21.67. framed_04, neutral_04's
band partner, never reached the cap.

The lapse was operational, not a decision, and was detected on 14 October
from spend data alone, before any outcome data had been extracted.

Assessment:

- **Size.** Total overrun beyond the cap is EUR 44.89 in the framed arm and
  EUR 67.26 in the neutral arm; the difference attributable to the lapse is
  EUR 22.37, or 0.6% of total spend.
- **Direction.** The extra spend went disproportionately to the neutral arm.
  For H1 (framed versus neutral) this is conservative: additional neutral
  delivery reduces any framed advantage rather than creating one.
- **Context.** The larger part of the arm spend difference (framed
  EUR 1,713.91, neutral EUR 1,837.97 at 14 October) comes from ordinary
  differences in delivery rate among campaigns that never reached the cap,
  which the design anticipates.
- **Handling.** This is reported as a deviation from the registered delivery
  protocol. The pre-registered equal-exposure estimate (*Other planned
  analysis*, item 4) and the delivery distributions by arm (item 5) are the
  analyses that address unequal realized spend; no change to the primary
  analysis is made or warranted.

## Policy limitation during the flight

Between 3 and 14 September Google began reporting **"most ads limited by
policy"** for all twenty campaigns. It is absent from the 3 September
snapshot and present in all twenty in the 14 and 20 September snapshots and
at 14 October. All 70 ads were *Approved* in the 3 September creatives export.

Because the limitation appeared in every campaign of both arms within the
same window, it is not the arm-differential policy filtering that the *Ad
review contingency* treats as confounded with the treatment. The neutral arm
carries no risk or protection language, so the cause is most likely an
element the arms share: one of the 17 common image assets, or the app listing
itself. Per rule 3 of the contingency, the limitation, its timing, and its
equal incidence across arms are reported with the results. The closing
creatives export (14 October) confirms this at the level of individual ads:
all 70 ads, in both arms, changed from *Approved* to *Approved limited*, with
no change to any text or image.

The policy named by Google is **Misleading Ad Design**. A screenshot of the
campaign status on 14 October (`data/google_ads/policy_status_misleading_ad_design_2026-10-14_2245.png`,
kept locally with the other account exports) shows: "1 out of 1 ad group is
limited by policy. Some of your ads can only serve in certain countries or on
certain devices due to the nature of the content", with the policy listed as
Misleading Ad Design. This policy concerns the visual design of ads, such as
images resembling interface elements or buttons, not the claims in the copy.
The most likely trigger is therefore one or more of the app-interface
screenshots in the shared image set, which run in all seven ad groups of both
arms. That is consistent with the equal incidence across arms, and it places
the limitation outside the framing manipulation, which lives in the text and
in the three arm-specific mosquito photographs.

The day-level delivery data are consistent with this. In the sixteen
campaigns that ran throughout (bands 03–10), daily impressions in both arms
fell in parallel during the onset window, roughly halving over 8–10 September,
with the two arms moving almost in step (9 September: 18,402 framed against
19,643 neutral; 10 September: 15,044 against 15,118). Weekend effects and the
general decline in delivery over the flight mean the onset cannot be dated
more precisely than that.

## Snapshots

The campaign-settings export that should have been taken when the extension
was applied on 14 September was missed. The one taken on 20 September
(`data/google_ads/campaign_settings_export_2026-09-20.zip`) records the same
state: all twenty campaigns ending 2026-10-14, four paused, daily budget
EUR 8.33 and target CPA EUR 0.39, every other setting unchanged since
3 September. The closing export on 14 October
(`campaign_settings_export_2026-10-14.zip`) shows the same settings with the
seven capped campaigns paused. The date the extension was applied is recorded
above. Nothing is lost from the missed performance snapshot
either: Google Ads retains day-level history, so a day-segmented spend report
run at any time reconstructs cumulative spend on 15 September and the exact
date each campaign was paused.
