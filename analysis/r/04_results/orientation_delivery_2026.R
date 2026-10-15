# =============================================================================
# Item 6: prevention- versus promotion-focused creative within the framed arm.
#
# Declared exploratory in the pre-registration: Google's optimiser, not
# randomization, decides how impressions are split between the six framed ad
# groups (2 orientations x 3 themes), so this is observational even within the
# experiment, and App campaigns do not report delivery by ad group AND
# municipality. What can be reported is the delivery each orientation and
# theme received: impressions, installs, cost and cost per install, per
# campaign and in total. Descriptive only; no test.
#
# Input: Google Ads web-interface Ad groups report, 17 Aug - 14 Oct 2026, all
# MA2026 campaigns, with Impr., Clicks, Conversions and Cost columns.
#
# Usage: Rscript analysis/r/04_results/orientation_delivery_2026.R [report.csv]
# Writes analysis/r/output/orientation_delivery_2026.csv
# =============================================================================
args <- commandArgs(trailingOnly = TRUE)
path <- if (length(args) >= 1) args[[1]] else
  file.path("data", "google_ads", "adgroup_performance_2026-08-17_to_2026-10-14.csv")
source(file.path("analysis", "r", "04_results", "delivery_utils.R"))

g <- read_ads_report(path)
g <- g[grepl("^MA2026_", g$Campaign), ]
name_col <- intersect(c("Ad group", "Ad group name"), names(g))[1]
g$ad_group <- trimws(g[[name_col]])
g$arm <- ifelse(grepl("framed", g$Campaign), "framed", "neutral")
g$orientation <- ifelse(grepl("^Prevention", g$ad_group), "prevention",
                 ifelse(grepl("^Promotion", g$ad_group), "promotion", "neutral"))
g$theme <- trimws(sub("^(Prevention|Promotion)\\s*-\\s*", "", g$ad_group))
g$theme[g$arm == "neutral"] <- "neutral"
for (c in c("Impr.", "Clicks", "Conversions", "Cost")) g[[c]] <- ads_number(g[[c]])

agg <- function(by) {
  a <- aggregate(cbind(impressions = g[["Impr."]], clicks = g$Clicks, installs = g$Conversions, cost = g$Cost), by, sum)
  a$cost_per_install <- ifelse(a$installs > 0, a$cost / a$installs, NA)
  a
}
tot <- agg(list(arm = g$arm, orientation = g$orientation))
fr <- tot[tot$arm == "framed", ]
tot$share_of_arm_impressions <- tot$impressions / ave(tot$impressions, tot$arm, FUN = sum)
tot$share_of_arm_installs <- tot$installs / ave(tot$installs, tot$arm, FUN = sum)
cat("=== Delivery by orientation (totals over the flight) ===\n"); print(tot, row.names = FALSE, digits = 3)

by_theme <- agg(list(arm = g$arm, orientation = g$orientation, theme = g$theme))
cat("\n=== Delivery by orientation x theme ===\n"); print(by_theme, row.names = FALSE, digits = 3)

per_camp <- agg(list(campaign = g$Campaign, orientation = g$orientation))
pc <- per_camp[per_camp$orientation != "neutral", ]
pc$share_impr <- pc$impressions / ave(pc$impressions, pc$campaign, FUN = sum)
cat("\n=== Prevention share of impressions, by framed campaign (how consistently the optimiser split) ===\n")
print(pc[pc$orientation == "prevention", c("campaign", "share_impr", "installs", "cost_per_install")], row.names = FALSE, digits = 3)

out <- rbind(cbind(level = "arm x orientation", tot[, c("arm", "orientation", "impressions", "clicks", "installs", "cost", "cost_per_install")], theme = NA),
             cbind(level = "arm x orientation x theme", by_theme[, c("arm", "orientation", "impressions", "clicks", "installs", "cost", "cost_per_install")], theme = by_theme$theme))
write.csv(out, file.path("analysis", "r", "output", "orientation_delivery_2026.csv"), row.names = FALSE)
cat("\nWritten to analysis/r/output/orientation_delivery_2026.csv\n")
