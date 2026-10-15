# =============================================================================
# Build the 2026 outcomes file read by the frozen analysis script
# (analyse_assignment.R --outcomes=...), from the October extracts.
#
# Inputs (data/raw/ unless noted). The October extracts are NEW files with a
# _2026-10 suffix: the deposited August files are inputs to the registered
# assignment, checksummed in the manifest, and must never be overwritten.
#   participants_spain_municipality_aug_windows_2026-10.csv
#                                                     modal attribution, with the
#                                                     2026 post window complete and
#                                                     the 2026 pre window re-extracted
#   participants_spain_province_aug_windows_2026-10.csv
#                                                     province totals, same extract
#   participants_spain_municipality_aug_windows_presence_2026-10.csv
#                                                     presence attribution (tertiary
#                                                     outcome); optional
#   analysis/r/output/municipality_reporter_counts.csv  rebuilt by the committed
#                                                     builder with 2026 rows
#
# Refuses to run if the 2026 windows are not complete (placeholder rows), and
# re-verifies attribution from the data: municipality sums against province
# totals (1.000 = modal partition). Reports the realized 2026 multi-municipality
# ratio from the presence extract (pre-registration, item 3).
#
# Prints NO arm-level quantity: this script runs before anyone looks at the
# outcome, and keeps it that way.
#
# Usage: Rscript analysis/r/04_results/prepare_outcomes_2026.R
# Writes analysis/r/output/outcomes_2026.csv and outcomes_2026_checks.txt
# =============================================================================
output_dir <- file.path("analysis", "r", "output")
raw <- function(f) file.path("data", "raw", f)
assignment <- read.csv(file.path(output_dir, "assignment_2026_final.csv"))

load_windows <- function(path, label) {
  p <- read.csv(path)
  p$unit_name <- paste(p$NAME_4, p$NAME_2, sep = ", ")
  y <- p[p$year == 2026, ]
  for (per in c("before", "after")) {
    w <- y[y$period == per, ]
    if (nrow(w) == 0) stop(label, ": no 2026 ", per, " rows")
    if (!all(w$window_complete %in% c(TRUE, "TRUE")) || !all(w$days_observed == 60))
      stop(label, ": 2026 ", per, " window is not complete in every row -- ",
           "these look like placeholder rows, not an outcome extraction")
  }
  p
}
pick <- function(p, per) {
  w <- p[p$year == 2026 & p$period == per, ]
  v <- w$n_participants[match(assignment$unit_name, w$unit_name)]
  if (any(is.na(v))) stop(sum(is.na(v)), " assignment units missing from the ", per, " extract")
  v
}

checks <- c(sprintf("prepared: %s", format(Sys.time(), "%Y-%m-%d %H:%M")))
modal <- load_windows(raw("participants_spain_municipality_aug_windows_2026-10.csv"), "modal municipality file")
province <- read.csv(raw("participants_spain_province_aug_windows_2026-10.csv"))

# The October extract must reproduce the deposited calibration data exactly for
# the seasons the registered analysis was calibrated on: same tracks, same rule.
# Any difference would mean the outcome and the calibration data were built
# differently, and must be understood before going further.
deposited <- read.csv(raw("participants_spain_municipality_aug_windows.csv"))
deposited$unit_name <- paste(deposited$NAME_4, deposited$NAME_2, sep = ", ")
key <- function(d) paste(d$unit_name, d$year, d$period)
hist_new <- modal[modal$year %in% 2021:2025, ]
hist_old <- deposited[deposited$year %in% 2021:2025, ]
hist_new <- hist_new[order(key(hist_new)), ]; hist_old <- hist_old[order(key(hist_old)), ]
if (!identical(key(hist_new), key(hist_old)))
  stop("2021-2025 rows of the October extract do not line up with the deposited file")
n_diff <- sum(hist_new$n_participants != hist_old$n_participants)
checks <- c(checks, sprintf("2021-2025 municipality counts vs deposited file: %s",
                            if (n_diff == 0) "IDENTICAL" else sprintf("%d of %d rows differ (max abs diff %d)", n_diff, nrow(hist_new),
                                                                        max(abs(hist_new$n_participants - hist_old$n_participants)))))
if (n_diff > 0) stop("October extract differs from the deposited calibration data on 2021-2025 rows; see checks")
pre_old <- deposited[deposited$year == 2026 & deposited$period == "before", ]
pre_new <- modal[modal$year == 2026 & modal$period == "before", ]
checks <- c(checks, sprintf("2026 pre-window re-extraction: national total %d (deposited August extract: %d); %d municipalities changed",
                            sum(pre_new$n_participants), sum(pre_old$n_participants),
                            sum(pre_new$n_participants[match(pre_old$unit_name, pre_new$unit_name)] != pre_old$n_participants)))
out <- data.frame(unit_name = assignment$unit_name,
                  post_participants = pick(modal, "after"),
                  pre_participants = pick(modal, "before"),
                  stringsAsFactors = FALSE)

ratio <- function(muni, per, label) {
  m <- sum(muni$n_participants[muni$year == 2026 & muni$period == per])
  pv <- sum(province$n_participants[province$year == 2026 & province$period == per])
  r <- m / pv
  checks <<- c(checks, sprintf("%s, 2026 %s: municipality sum %d / province sum %d = %.3f", label, per, m, pv, r))
  r
}
for (per in c("before", "after")) {
  r <- ratio(modal, per, "modal attribution")
  if (abs(r - 1) > 0.02) stop("modal file does not verify as a partition (ratio ", round(r, 3), ")")
}

presence_path <- raw("participants_spain_municipality_aug_windows_presence_2026-10.csv")
if (file.exists(presence_path)) {
  presence <- load_windows(presence_path, "presence municipality file")
  out$post_participants_presence <- pick(presence, "after")
  out$pre_participants_presence <- pick(presence, "before")
  for (per in c("before", "after")) ratio(presence, per, "presence municipality sum / home province sum")
  pp_path <- raw("participants_spain_province_aug_windows_presence_2026-10.csv")
  if (file.exists(pp_path)) {
    pp <- read.csv(pp_path)
    for (per in c("before", "after")) {
      m <- sum(presence$n_participants[presence$year == 2026 & presence$period == per])
      pv <- sum(pp$n_participants[pp$year == 2026 & pp$period == per])
      checks <- c(checks, sprintf("realized within-province multi-municipality ratio, 2026 %s: %d / %d = %.3f (2021-2025 reference 1.17-1.28)", per, m, pv, m / pv))
    }
  }
  hist <- presence[presence$year %in% 2021:2025 & presence$period == "after" &
                     presence$window_complete %in% c(TRUE, "TRUE"), ]
  if (nrow(hist) > 0) {
    med <- aggregate(n_participants ~ unit_name, hist, median)
    out$hist_participants_presence <- med$n_participants[match(assignment$unit_name, med$unit_name)]
    checks <- c(checks, "presence historical median (2021-2025) available for the presence-attributed analysis")
  } else checks <- c(checks, "presence file carries 2026 only; presence analysis will use the modal historical median")
} else checks <- c(checks, "no presence-attributed extract found; item 1 (presence outcome) and item 3 (ratio) skipped")

rep_path <- file.path(output_dir, "municipality_reporter_counts.csv")
reporters <- read.csv(rep_path)
r26 <- reporters[reporters$year == 2026, ]
if (nrow(r26) == 0 || any(is.na(r26$post_reporters))) {
  checks <- c(checks, "reporter counts carry no complete 2026 rows; reports outcome not prepared")
} else {
  i <- match(assignment$unit_name, r26$unit_name)
  out$post_reporters <- r26$post_reporters[i]
  out$pre_reporters <- r26$pre_reporters[i]
  out$post_reporters[is.na(out$post_reporters)] <- 0   # frame is the full municipality index; absent = zero
  out$pre_reporters[is.na(out$pre_reporters)] <- 0
}

checks <- c(checks, sprintf("units: %d; columns: %s", nrow(out), paste(names(out), collapse = ", ")),
            sprintf("national 2026 totals (modal): pre %d, post %d",
                    sum(modal$n_participants[modal$year == 2026 & modal$period == "before"]),
                    sum(modal$n_participants[modal$year == 2026 & modal$period == "after"])))
write.csv(out, file.path(output_dir, "outcomes_2026.csv"), row.names = FALSE)
writeLines(checks, file.path(output_dir, "outcomes_2026_checks.txt"))
cat(checks, sep = "\n"); cat("Written to analysis/r/output/outcomes_2026.csv\n")
