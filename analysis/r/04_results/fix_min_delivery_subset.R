# =============================================================================
# Minimum-delivery subset (pre-registration, Other planned analysis, item 7)
#
# Rule, declared 15 October 2026 before any outcome data were examined (see
# docs/operations/analysis-log-2026.md): a municipality is in the subset if
# Google Ads reports at least MIN_INSTALLS installs (conversions) for it over
# the full flight, 17 Aug - 14 Oct 2026, in the delivery-by-location report
# pulled on 15 October 2026. No-advertising municipalities are never in it.
#
# Usage: Rscript analysis/r/04_results/fix_min_delivery_subset.R [delivery.csv]
# Writes analysis/r/output/min_delivery_subset_2026.csv
# =============================================================================
MIN_INSTALLS <- 5
args <- commandArgs(trailingOnly = TRUE)
delivery_path <- if (length(args) >= 1) args[[1]] else
  file.path("data", "google_ads", "delivery_by_location_2026-08-17_to_2026-10-14.csv")
output_dir <- file.path("analysis", "r", "output")

source(file.path("analysis", "r", "04_results", "delivery_utils.R"))

assignment <- read.csv(file.path(output_dir, "assignment_2026_final.csv"))
delivery <- read_delivery_by_location(delivery_path, assignment)   # one row per targeted municipality

subset <- data.frame(
  unit_name = assignment$unit_name,
  arm = assignment$arm,
  installs = delivery$installs[match(assignment$unit_name, delivery$unit_name)],
  stringsAsFactors = FALSE)
subset$installs[assignment$arm == "no_ad"] <- NA
subset$in_subset <- !is.na(subset$installs) & subset$installs >= MIN_INSTALLS

cat(sprintf("Rule: installs >= %d over the full flight (delivery report: %s)\n",
            MIN_INSTALLS, basename(delivery_path)))
cat(sprintf("Advertising municipalities joined to the report: %d of %d\n",
            sum(!is.na(subset$installs)), sum(assignment$arm != "no_ad")))
print(table(arm = subset$arm, in_subset = subset$in_subset))

write.csv(subset, file.path(output_dir, "min_delivery_subset_2026.csv"), row.names = FALSE)
cat("Written to analysis/r/output/min_delivery_subset_2026.csv\n")
