# Campaign location verification — ALL CLEAR

- **Date:** 2026-08-14 (re-confirmed 2026-08-15; re-verified 2026-08-16 on a
  fresh export taken after the final creative edits and ad review, and again
  2026-08-18 on a live post-launch export — see below)
- **Command:**
  `Rscript analysis/r/03_randomization/verify_campaign_locations.R data/google_ads/campaign_locations_2026-08-16.csv`
- **Result:** ALL CLEAR — 0 of 20 campaigns failed; 840 configured Criteria IDs
  match the frozen assignment exactly (420 framed + 420 neutral across 20
  campaigns); no no-ad municipality targeted anywhere.
- **Export verified:** Google Ads Editor locations view, account 289-473-3923,
  saved as `data/google_ads/campaign_locations_2026-08-14.csv`,
  md5 `f3f25a0e11b5419c355aa27d4fd80481` (kept locally, not committed —
  `data/google_ads/` is gitignored as an operational account export).
  The 2026-08-16 re-verification export,
  `data/google_ads/campaign_locations_2026-08-16.csv`, is **byte-identical**
  to it (same md5): the location configuration did not change between the
  original verification and the launch-eve gate, despite intervening creative
  edits and ad review.
  A further export on 2026-08-18 (`campaign_locations_2026-08-18.csv`, taken
  after launch) again passes ALL CLEAR: the (campaign, Criteria ID) set is
  identical to the 16 Aug export and the only column that differs is
  `Campaign Status` (Pending → Enabled). A direct census of `Location type`
  finds 530 Municipality + 310 City entries and no province, region or other
  entity type. This check was prompted by a colleague seeing provinces in
  `MA2026_neutral_01` in Google Ads Editor; that proved to be an un-refreshed
  local Editor copy still holding the pre-correction configuration, and the
  provinces disappeared on refresh.
- **2026-09-03 (flight day 18 of 30):** `campaign_locations_2026-09-03.csv`
  passes ALL CLEAR and is byte-identical to the 18 Aug export (md5
  `625ce384a41941f4b1d4a4dc659bd843`). A campaign-settings export the same
  day (local, `data/google_ads/campaign_settings_export_2026-09-03.zip`)
  shows every one of the 20 campaigns identical on all 24 settings fields:
  App installs, EUR 8.33 daily, Target CPA EUR 0.39, 2026-08-17 to
  2026-09-15, location-of-presence targeting, same install conversion
  action, languages ca/en/es, no ad schedule. Statuses: 12 Eligible, 4
  "Eligible (Limited) — limited by budget" (bands 01–02, both arms) and 4
  "bidding strategy constrained" (framed_05, neutral_05/07/09); neither
  reason is a policy or serving restriction.
- **2026-10-14, closing verification (last day of the flight):**
  `campaign_locations_2026-10-14.csv` passes ALL CLEAR — 840 locations across
  all 20 campaigns. The 840 (campaign, Criteria ID) pairs are identical to every
  earlier export; the only changed column is `Campaign Status` (*Enabled* →
  *Paused*) on the 294 rows of the seven campaigns paused at the EUR 250 cap.
  The location configuration was therefore unchanged from first verification
  on 14 August to the end of the flight. A settings export the same evening
  shows all 20 campaigns ending 2026-10-14 with every other setting unchanged
  since 3 September.
- **Assignment verified against:** `assignment_2026_final.csv`,
  md5 `cd9c86726fd7f9aa5c8e488d0b5361b2`.

History: a first name-based configuration pass mis-resolved 20 locations in 4
campaigns (including five whole provinces); all were corrected by Criteria ID
and re-verified before launch. Re-run the verifier on a fresh export after ANY
change to campaign targeting.
