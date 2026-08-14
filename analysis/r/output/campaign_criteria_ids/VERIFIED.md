# Campaign location verification — ALL CLEAR

- **Date:** 2026-08-14 (re-confirmed 2026-08-15)
- **Command:**
  `Rscript analysis/r/03_randomization/verify_campaign_locations.R data/google_ads/campaign_locations_2026-08-14.csv`
- **Result:** ALL CLEAR — 0 of 20 campaigns failed; 840 configured Criteria IDs
  match the frozen assignment exactly (420 framed + 420 neutral across 20
  campaigns); no no-ad municipality targeted anywhere.
- **Export verified:** Google Ads Editor locations view, account 289-473-3923,
  saved as `data/google_ads/campaign_locations_2026-08-14.csv`,
  md5 `f3f25a0e11b5419c355aa27d4fd80481` (kept locally, not committed —
  `data/google_ads/` is gitignored as an operational account export).
- **Assignment verified against:** `assignment_2026_final.csv`,
  md5 `cd9c86726fd7f9aa5c8e488d0b5361b2`.

History: a first name-based configuration pass mis-resolved 20 locations in 4
campaigns (including five whole provinces); all were corrected by Criteria ID
and re-verified before launch. Re-run the verifier on a fresh export after ANY
change to campaign targeting.
