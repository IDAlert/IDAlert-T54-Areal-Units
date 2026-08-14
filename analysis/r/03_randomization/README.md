# Treatment Assignment and Analysis

The scripts that define the experiment: the frozen randomization, the
pre-registered analysis that matches it, and the launch gate that checks what
was actually configured in Google Ads.

## Current scripts

```bash
# from the repository root

# THE assignment (frozen seed 20260815; regenerates bit-identically)
Rscript analysis/r/03_randomization/assign_treatment_2026.R

# the pre-registered analysis
Rscript analysis/r/03_randomization/analyse_assignment.R --outcomes=<2026_counts.csv>
Rscript analysis/r/03_randomization/analyse_assignment.R --outcomes=<...> --outcome=reports
Rscript analysis/r/03_randomization/analyse_assignment.R --demo        # simulated run
Rscript analysis/r/03_randomization/analyse_assignment.R --calibrate   # Type I check

# the launch gate: configured Google Ads locations vs the frozen assignment
Rscript analysis/r/03_randomization/verify_campaign_locations.R \
  data/google_ads/campaign_locations_2026-08-14.csv
```

The superseded 2025 assignment script (population strata, hurdle margins,
prevention/promotion arms) lived here as `assign_treatment.R`; see
`analysis/r/archive/README.md`.

## Design, as implemented

- **Eligibility, not sampling.** Every municipality that Google Ads can target
  by name and whose median pre-window participant count (2021–2025, home
  attribution) is at most 25 enters. No floor. N follows from the rule.
- **Block randomization.** Units ordered by baseline, ties broken explicitly,
  cut into consecutive blocks of 9; each full block gets a random permutation
  of (4 framed, 4 neutral, 1 no-ad). A trailing partial block is assigned to
  the no-ad arm, which makes the advertising arms exactly equal.
- **Verification on the realized draw.** The assignment script simulates the
  Type I error of the realized assignment (not the design average — the two
  came apart once, 0.216 vs 0.064) and warns hard if anti-conservative.
- **Attribution self-check.** Municipality sums are compared with province
  totals; ratio 1.00 = home-assigned partition. Recorded in the manifest, so
  the outcome definition is verified from the data rather than assumed from a
  column name.
- **Launch gate.** Google's geo table holds 180 Spanish provinces, cities and
  homonymous entities sharing a display name with a study municipality, so
  name-based entry mis-resolves; `verify_campaign_locations.R` diffs the
  configured Criteria IDs against the assignment and refuses launch until
  ALL CLEAR.

## Analysis, as pre-registered

Linear model on post-window counts with **block fixed effects**, the pre-window
count and the historical median as covariates. The blocks are not optional
furniture: without them the count outcome's curvature in baseline — which
blocking absorbed by design — re-enters the model, and H2's conditional Type I
error was 0.10 against 0.06 with them.

Inference is **randomization inference**: the arm coefficient re-estimated
under permutations of labels within the realized blocks. Exact under the sharp
null regardless of outcome distribution or spatial dependence. The ordinary
t-test is anti-conservative for H2 (small no-ad arm, skewed counts);
HC3 is reported alongside as the parametric check. Confidence intervals invert
the permutation test under a constant additive shift — the statistic is linear
in the shift, so the inversion is exact.

`--calibrate` re-runs the Type I verification end-to-end on the committed code.
