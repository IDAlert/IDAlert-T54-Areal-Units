# =============================================================================
# Verify the locations actually configured in Google Ads against the frozen
# assignment -- run this BEFORE enabling the campaigns.
#
# Why it exists: Google's geo table holds 180 Spanish targets (provinces,
# cities, homonymous municipalities) that share a display name with a study
# municipality, and bulk name-matching in the web UI resolves ambiguously. The
# only trustworthy check is Criteria ID against Criteria ID.
#
# Input: a CSV exported from Google Ads Editor (select the 20 campaigns ->
# Keywords and targeting -> Locations -> File > Export) or any CSV that has
#   * a campaign column whose values contain MA2026_<arm>_<nn>, and
#   * a column holding the numeric location Criteria ID (any column whose
#     values are purely digits will be detected; Editor calls it "Location").
#
# It reports, per campaign: missing municipalities, unexpected extras, and --
# the alarm that matters most -- any configured location that belongs to the
# no-ad arm or to another campaign. Exits nonzero if anything fails, so it can
# gate a launch checklist.
#
# Usage:
#   Rscript analysis/r/03_randomization/verify_campaign_locations.R export.csv
# =============================================================================

suppressWarnings({
  options(stringsAsFactors = FALSE)
})

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  stop("Usage: verify_campaign_locations.R <export.csv | directory> [more files]")
}
paths <- args
if (length(paths) == 1 && dir.exists(paths[[1]])) {
  paths <- list.files(paths[[1]], pattern = "\\.csv$", full.names = TRUE)
}

assignment <- read.csv(file.path("analysis", "r", "output",
                                 "assignment_2026_final.csv"),
                       colClasses = "character")
expected <- assignment[!is.na(assignment$campaign) & assignment$campaign != "", ]
no_ad_ids <- assignment$google_criteria_id[assignment$arm == "no_ad"]

# Google exports come in several dialects: Ads Editor writes UTF-16LE,
# tab-separated, CRLF; the web UI writes UTF-8 with preamble rows. Try the
# dialects in order and keep whatever parses into a table that mentions our
# campaigns.
read_ads_export <- function(path) {
  attempts <- list(
    function() read.delim(path, fileEncoding = "UTF-16LE", sep = "\t",
                          check.names = FALSE, colClasses = "character"),
    function() read.csv(path, check.names = FALSE, colClasses = "character"),
    function() read.delim(path, sep = "\t", check.names = FALSE,
                          colClasses = "character"))
  for (attempt in attempts) {
    parsed <- tryCatch(suppressWarnings(attempt()), error = function(e) NULL)
    if (!is.null(parsed) && ncol(parsed) > 1 &&
        any(vapply(parsed, function(v) any(grepl("MA2026_", v)), logical(1)))) {
      return(parsed)
    }
  }
  NULL
}

frames <- list()
for (path in paths) {
  parsed <- read_ads_export(path)
  if (is.null(parsed)) {
    cat("  [skipped, no MA2026_ campaigns or unparseable]", basename(path), "\n")
    next
  }
  campaign_column <- names(parsed)[vapply(parsed, function(v)
    any(grepl("MA2026_", v)), logical(1))][1]
  # The Criteria ID: prefer a column literally named ID; fall back to the
  # first column whose non-empty values are purely digits (skipping Reach,
  # which comes after ID in Editor exports).
  id_column <- intersect(c("ID", "ID#Original", "Location ID", "Criteria ID"),
                         names(parsed))[1]
  if (is.na(id_column)) {
    for (column in setdiff(names(parsed), campaign_column)) {
      values <- parsed[[column]]
      values <- values[!is.na(values) & values != ""]
      if (length(values) > 0 && all(grepl("^[0-9]+$", values))) {
        id_column <- column
        break
      }
    }
  }
  if (is.na(id_column) || is.null(id_column)) {
    cat("  [skipped, no Criteria ID column]", basename(path), "\n")
    next
  }
  rows <- data.frame(
    campaign = sub(".*?(MA2026_[a-z]+_[0-9]+).*", "\\1",
                   parsed[[campaign_column]]),
    criteria_id = parsed[[id_column]],
    location = if ("Location" %in% names(parsed)) parsed[["Location"]] else "",
    location_type = if ("Location type" %in% names(parsed))
      parsed[["Location type"]] else "")
  rows <- rows[grepl("^MA2026_", rows$campaign) & rows$criteria_id != "", ]
  if (nrow(rows) > 0) frames[[length(frames) + 1]] <- rows
}
if (length(frames) == 0) stop("No usable location rows found in the export(s).")
exported <- unique(do.call(rbind, frames))

cat("=== verifying configured locations against the frozen assignment ===\n")
cat(sprintf("  export: %s rows across %d campaigns\n\n",
            nrow(exported), length(unique(exported$campaign))))

failures <- 0L
for (campaign in sort(unique(expected$campaign))) {
  want <- expected$google_criteria_id[expected$campaign == campaign]
  have <- exported$criteria_id[exported$campaign == paste0("MA2026_", campaign)]
  missing <- setdiff(want, have)
  extra <- setdiff(have, want)
  extra_no_ad <- intersect(extra, no_ad_ids)
  extra_other <- intersect(extra, setdiff(expected$google_criteria_id, want))
  status <- if (length(missing) == 0 && length(extra) == 0) "PASS" else "FAIL"
  if (status == "FAIL") failures <- failures + 1L
  cat(sprintf("  %-18s %s  (%d/%d configured)\n", paste0("MA2026_", campaign),
              status, length(intersect(want, have)), length(want)))
  if (length(missing) > 0) {
    cat("      missing: ", paste(head(assignment$unit_name[
      assignment$google_criteria_id %in% missing], 5), collapse = "; "),
      if (length(missing) > 5) sprintf(" (+%d more)", length(missing) - 5) else "",
      "\n", sep = "")
  }
  if (length(extra_no_ad) > 0) {
    cat("      *** NO-AD ARM CONTAMINATED: ", paste(assignment$unit_name[
      assignment$google_criteria_id %in% extra_no_ad], collapse = "; "),
      " ***\n", sep = "")
  }
  if (length(extra_other) > 0) {
    cat("      in the wrong campaign: ", paste(head(assignment$unit_name[
      assignment$google_criteria_id %in% extra_other], 5), collapse = "; "), "\n",
      sep = "")
  }
  unknown <- setdiff(extra, c(expected$google_criteria_id, no_ad_ids))
  if (length(unknown) > 0) {
    labels <- exported[exported$criteria_id %in% unknown &
                         exported$campaign == paste0("MA2026_", campaign), ]
    labels <- unique(labels[, c("criteria_id", "location", "location_type")])
    shown <- head(seq_len(nrow(labels)), 6)
    cat("      WRONG ENTITY (name mis-resolution):\n")
    for (i in shown) {
      cat(sprintf("        %s = %s [%s]\n", labels$criteria_id[i],
                  labels$location[i], labels$location_type[i]))
    }
    if (nrow(labels) > 6) cat(sprintf("        (+%d more)\n", nrow(labels) - 6))
  }
}

cat(sprintf("\n%s: %d of 20 campaigns failed verification\n",
            if (failures == 0) "ALL CLEAR" else "DO NOT LAUNCH",
            failures))
if (failures > 0) quit(status = 1)
