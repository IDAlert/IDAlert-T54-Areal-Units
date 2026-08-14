# Store Listing Alignment Across Arms

> **Reconstructed 2026-08-15.** The original memo was lost in a git-history
> cleanup incident (it had never been committed). This version restates its
> operative conclusions; treat pre-incident details not repeated here as
> unrecorded.

> **Note (2026-08-14):** campaign structure has since moved to 20 campaigns
> (10 per arm, contiguous baseline bands); see the pre-registration. The store
> listing alignment and A/B-testing guidance below still applies.

## The issue

Both arms' ads drive users to the same app store listing. If the listing's
copy leans toward one motivational frame, it dilutes the framed-vs-neutral
contrast at the final step of the funnel; and if the store runs its own
listing experiments, users in the two arms can be shown different listings at
random, adding uncontrolled variation.

## Operative decisions

1. **Google Play custom store listings** can route ad traffic to
   frame-matched listings via the `&listing=` URL parameter, and **Apple
   custom product pages** via `?ppid=`. However, Android **App campaigns do
   not allow custom final URLs**, so listing-level frame matching is not
   available for this study's campaign type; the default listing serves all
   arms.
2. Therefore the default Play listing must be **frame-neutral** for the
   duration of the flight: it describes the app without invoking prevention-
   or promotion-focus language, so the only framed exposure is the ad itself.
3. **Both stores' built-in listing A/B testing must be OFF** during the
   experiment (Play's "store listing experiments"), so every recruit sees the
   same listing.
4. The study is Android-only, so Apple settings are moot for delivery, but
   the same freeze applies if iOS is ever added.

The verbatim ad copy for all arms is deposited with the pre-registration; the
listing text in force during the flight should be archived alongside it.
