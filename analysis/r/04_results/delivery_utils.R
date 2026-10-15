# Shared helpers for reading Google Ads web-interface report exports and
# joining the matched-location report to the assignment.
#
# Report format: line 1 report name, line 2 date range, line 3 header, then
# data; numbers may carry thousands separators, percentages and "--".

read_ads_report <- function(path) {
  lines <- readLines(path, encoding = "UTF-8", warn = FALSE)
  header <- grep("Impr\\.|Conversions|Cost", lines)[1]   # first line that looks like a column header
  if (is.na(header)) stop("No recognised header line in ", path)
  read.csv(text = paste(lines[header:length(lines)], collapse = "\n"),
           check.names = FALSE, stringsAsFactors = FALSE)
}

ads_number <- function(x) {
  x <- gsub("[,%]", "", trimws(as.character(x)))
  x[x %in% c("", "--")] <- "0"
  as.numeric(x)
}

# Google's canonical location name as it appears in reports ("Girona,
# Catalonia, Spain") versus the crosswalk ("Municipality of Seville,Andalusia,
# Spain"; "Girona,Girona,Catalonia,Spain" for provincial capitals): normalise
# separators, drop the "Municipality of " prefix, collapse a repeated segment.
normalise_location <- function(x) {
  vapply(x, function(s) {
    parts <- trimws(strsplit(s, ",")[[1]])
    parts[1] <- sub("^Municipality of ", "", parts[1])
    keep <- c(TRUE, parts[-1] != parts[-length(parts)])
    paste(parts[keep], collapse = ",")
  }, character(1), USE.NAMES = FALSE)
}

# One row per targeted municipality with impressions, installs, clicks, cost.
read_delivery_by_location <- function(path, assignment) {
  d <- read_ads_report(path)
  d <- d[grepl("^MA2026_", d$Campaign), ]
  d$key <- normalise_location(d$Location)
  a_key <- normalise_location(assignment$google_canonical_name)
  idx <- match(d$key, a_key)
  if (any(is.na(idx))) stop("Unjoined report locations: ",
                            paste(head(d$Location[is.na(idx)]), collapse = "; "))
  if (any(duplicated(idx))) stop("A municipality appears more than once in the report")
  out <- data.frame(
    unit_name = assignment$unit_name[idx],
    campaign_reported = sub("^MA2026_", "", d$Campaign),
    impressions = ads_number(d[["Impr."]]),
    clicks = ads_number(d[["Interactions"]]),
    installs = ads_number(d[["Conversions"]]),
    cost = ads_number(d[["Cost"]]),
    stringsAsFactors = FALSE)
  mismatch <- out$campaign_reported != assignment$campaign[idx]
  if (any(mismatch)) stop(sum(mismatch), " municipalities reported under a campaign other than their assigned one")
  out
}
