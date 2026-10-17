# =============================================================================
# Derived delivery tables from the local Google Ads exports (which stay out of
# version control). Both are aggregates with no personal data, so they are the
# committed, depositable record of what the campaigns delivered, and the only
# delivery inputs the figure script needs:
#
#   analysis/r/output/delivery_by_municipality_2026.csv
#       one row per study municipality (no-ad rows carry NA: no campaign)
#   analysis/r/output/delivery_by_campaign_day_2026.csv
#       one row per campaign and day of the flight
#
# Inputs (local): data/google_ads/delivery_by_location_2026-08-17_to_2026-10-14.csv
#                 data/google_ads/campaign_performance_by_day_2026-08-17_to_2026-10-14.csv
# Usage: Rscript analysis/r/04_results/export_delivery_tables_2026.R
# =============================================================================
source(file.path("analysis", "r", "04_results", "delivery_utils.R"))
out <- file.path("analysis", "r", "output")
ads <- file.path("data", "google_ads")

a <- read.csv(file.path(out, "assignment_2026_final.csv"))
d <- read_delivery_by_location(file.path(ads, "delivery_by_location_2026-08-17_to_2026-10-14.csv"), a)
i <- match(a$unit_name, d$unit_name)
stopifnot(sum(!is.na(i)) == 840, all(is.na(i) == (a$arm == "no_ad")))
muni <- data.frame(unit_name = a$unit_name, province = a$province, block = a$block, arm = a$arm, campaign = a$campaign,
                   impressions = d$impressions[i], clicks = d$clicks[i], installs = d$installs[i], cost = d$cost[i])
write.csv(muni, file.path(out, "delivery_by_municipality_2026.csv"), row.names = FALSE)

day <- read.csv(file.path(ads, "campaign_performance_by_day_2026-08-17_to_2026-10-14.csv"), check.names = FALSE)
day <- day[grepl("^MA2026_", day$Campaign), ]
cd <- data.frame(date = as.Date(day$Day), campaign = sub("^MA2026_", "", day$Campaign))
cd$arm <- sub("_.*", "", cd$campaign)
cd$impressions <- ads_number(day[["Impr."]]); cd$clicks <- ads_number(day$Clicks)
cd$installs <- ads_number(day$Conversions); cd$cost <- ads_number(day$Cost)
stopifnot(all(cd$arm %in% c("framed", "neutral")), !anyDuplicated(cd[c("date", "campaign")]),
          setequal(unique(cd$campaign), unique(a$campaign[a$arm != "no_ad"])))
cd <- cd[order(cd$campaign, cd$date), ]
write.csv(cd, file.path(out, "delivery_by_campaign_day_2026.csv"), row.names = FALSE)

cat(sprintf("delivery_by_municipality_2026.csv: %d rows (%d with campaigns)\n", nrow(muni), sum(!is.na(muni$installs))))
cat(sprintf("delivery_by_campaign_day_2026.csv: %d rows, %s to %s, %d campaigns\n", nrow(cd), min(cd$date), max(cd$date), length(unique(cd$campaign))))
cat(sprintf("totals by arm (location report | daily report): framed EUR %.2f | %.2f, neutral EUR %.2f | %.2f\n",
            sum(muni$cost[muni$arm == "framed"]), sum(cd$cost[cd$arm == "framed"]),
            sum(muni$cost[muni$arm == "neutral"]), sum(cd$cost[cd$arm == "neutral"])))
