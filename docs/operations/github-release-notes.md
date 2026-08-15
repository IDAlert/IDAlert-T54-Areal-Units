# GitHub release notes — paste-ready

Tag: `v1.0-preregistration` · Title: **Pre-registration and launch state (2026-08)**

GitHub renders Markdown in release notes (unlike Zenodo, which needs HTML), so
paste the block below as-is.

---

The state of this repository at pre-registration, immediately before the
advertising campaign launches. **No outcome data exists at this commit** — the
post-treatment measurement window opens on 16 August 2026 — so everything here
was fixed in advance of the results it will be used to analyse.

## What is frozen here

| | |
|---|---|
| Study units | 949 Spanish municipalities (every one Google Ads can target by name with a median pre-window participant count ≤ 25; no floor, so 571 have zero baseline) |
| Arms | framed 420 / neutral 420 / no advertising 109 |
| Randomization | blocks of 9, seed `20260815`, RNG kind pinned |
| Assignment | `analysis/r/output/assignment_2026_final.csv`, md5 `cd9c86726fd7f9aa5c8e488d0b5361b2` |
| Campaigns | 20 × exactly 42 municipalities, EUR 250 each (EUR 5,000 total), Android, launch 17 August 2026 |
| Primary outcome | distinct participants emitting masked background tracks, 16 Aug – 14 Oct 2026, modal attribution |
| Power | 0.92 at a 15% framing effect (σ_c = 0.4); ~1.00 at 20% |

## Verification included in this release

- **The assignment regenerates bit-for-bit.** `assign_treatment_2026.R` on the
  deposited inputs reproduces the committed CSV, md5 above, recorded with input
  checksums in `analysis/r/output/manifest_2026_final.txt`.
- **Type I error checked on the realised draw**, not just in expectation:
  H1 0.030, H2 0.019 at the design stage; the committed analysis code's own
  `--calibrate` mode reads H1 0.052, H2 0.067 over 600 null datasets.
- **Google Ads configuration verified ID-for-ID.**
  `verify_campaign_locations.R` confirms all 840 configured location Criteria
  IDs match the assignment exactly, with no no-advertising municipality
  targeted: `ALL CLEAR: 0 of 20 campaigns failed`
  (`analysis/r/output/campaign_criteria_ids/VERIFIED.md`).

## Reproducing it

```bash
# fetch the aggregate inputs from the data deposit into data/raw/
Rscript analysis/r/01_data_prep/build_google_ads_crosswalk.R data/raw/google_ads_geotargets-2026-07-16.csv
Rscript analysis/r/01_data_prep/build_municipality_grid_geometry.R
Rscript analysis/r/03_randomization/assign_treatment_2026.R
md5 analysis/r/output/assignment_2026_final.csv   # expect cd9c8672...
```

Full path in `REPRODUCE.md`.

## Related records

- **Data:** aggregate participation and reporter counts —
  https://doi.org/10.5281/zenodo.21940738 (CC-BY-4.0). The deposited
  `participants_spain_municipality_aug_windows.csv` is byte-identical to the
  input checksummed in the manifest.
- **Pre-registration:** OSF registration — *[add DOI once public]*
- **Ethics:** approved by CIREP (Universitat Pompeu Fabra) as a modification to
  protocol 270 (originally approved 21 July 2022; modification approved
  30 July 2026).

Part of IDAlert, EU Horizon Europe grant agreement 101057554.

---

## Sequence (order matters)

1. **If you want a DOI for the code**, connect the repository to Zenodo *first*
   — Zenodo only archives releases created **after** the integration is
   switched on. Recommended: this repository's code defines the randomization,
   and GitHub is not an archive.
2. Tag and push:
   ```bash
   git tag -a v1.0-preregistration -m "Pre-registration and launch state: design frozen, no outcome data"
   git push origin v1.0-preregistration
   ```
3. Create the GitHub release from that tag, pasting the notes above.
4. Publish the Zenodo **data** record (it already cites this tag).
5. Register on OSF, citing the data DOI and the release URL.
6. Return to Zenodo and add the OSF DOI to the data record — description *and*
   Related identifiers ("is documented by"), since only the latter is
   machine-readable. Do the same on the code record if you created one.

After October, tag the analysis state as `v2.0-outcomes` so the pre-registration
state and the analysed state stay distinguishable.
