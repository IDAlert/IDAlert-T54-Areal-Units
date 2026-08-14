# =============================================================================
# FINAL treatment assignment: IDAlert T5.4 areal-unit messaging experiment, 2026
#
# Design (final, 2026-08-14, on the home-assigned data)
#   Units    every Spanish municipality that Google Ads can target by name AND
#            whose median pre-window participant count (2021-2025) is at most
#            25. No floor: 571 of the 949 eligible units have zero baseline.
#            N is fixed by the ELIGIBILITY RULE, not chosen.
#   Arms     framed 420 / neutral 420 / no-ad 109. Full blocks of 9 are
#            randomized 4:4:1; the trailing partial block goes to no-ad, which
#            is what makes the ad arms exactly equal.
#   Method   block randomization in blocks of 9, blocks formed by ordering on
#            baseline participants.
#   Campaigns each ad arm is cut into 10 contiguous baseline bands of exactly
#            42 municipalities at exactly EUR 250 each, so framed_k and
#            neutral_k give Google's optimiser the same problem. 20 campaigns;
#            the no-ad arm needs none. Android only.
#
# Design history that this file enforces in code, so it cannot regress:
#
#   The upper baseline cap. Without it Madrid and Barcelona (presence-era
#   medians 113 and 136) enter a pool whose median is ~2. The linear covariates
#   cannot absorb them: that draw had a CONDITIONAL Type I error of 0.216 for
#   H2 while the design-level rate, averaged over fresh randomisations, was a
#   respectable 0.064. The design was never wrong; that particular draw was.
#   The cap (25) removes the extreme tail -- on the final data it excludes only
#   Barcelona, Madrid and Valencia.
#
#   No eligibility floor. See the note at MIN_MEDIAN_PARTICIPANTS.
#
#   Checking Type I error on the REALISED draw, not just in expectation. That
#   is what caught the cap problem, so it runs on every draw rather than when
#   someone thinks to look. See check_realised_type_i() below.
#
#   Attribution verified from the data (municipality/province sum ratio), not
#   assumed from a column name. See the note at OUTCOME_COLUMN.
#
# Reproducibility: deterministic ordering with explicit tie-breaks, pinned RNG
# kind, frozen seed, and a manifest recording input and output checksums. The
# same inputs regenerate the assignment bit-for-bit.
#
# Usage:
#   Rscript analysis/r/03_randomization/assign_treatment_2026.R [n_check_sims]
# =============================================================================

suppressWarnings({
  options(stringsAsFactors = FALSE)
})

suppressPackageStartupMessages({
  library(sandwich)
  library(lmtest)
})

# --- frozen configuration ----------------------------------------------------

SEED <- 20260815L        # FROZEN at preregistration. Do not change.
RNG_KIND <- "Mersenne-Twister"
RNG_NORMAL <- "Inversion"
RNG_SAMPLE <- "Rejection"

# 4:4:1. The no-ad arm consumes no budget, so its units are close to free:
# when this ratio was fixed, the H1 power difference between a pure two-arm
# design and the 4:4:1 split at the same EUR 5,000 was 0.87 against 0.88 --
# nothing. A no-ad arm of ~1/9 buys a randomised H2 (and the activation
# analysis in the zero-baseline municipalities) at no cost to the primary
# framing contrast.
BLOCK <- c(rep("framed", 4), rep("neutral", 4), "no_ad")
CAMPAIGNS_PER_ARM <- 10L

# No eligibility floor. The old floor (median >= 1) was a fossil of the
# abandoned hurdle/log-ratio analysis, which needed nonzero baselines; under
# the linear count model with block fixed effects a zero-baseline municipality
# is a fully informative unit -- its no-ad outcome is ~0 with tiny variance and
# its treated outcome is essentially delivered installs. Admitting the 571
# zero-baseline nameable municipalities raises H1 power from 0.71 to 0.93 at a
# 15% framing effect (robust at half dose: 0.74), and makes H2 partly an
# ACTIVATION experiment. Decided 2026-08-14.
MIN_MEDIAN_PARTICIPANTS <- 0
MAX_MEDIAN_PARTICIPANTS <- 25    # eligibility cap: see the note above

# The five most recent complete seasons. 2023 was an exceptional year (roughly
# 10x normal participation) but the MEDIAN is robust to it, so it is kept in
# rather than dropped -- one rule, one statistic, nothing hand-picked.
# Seasons before 2021 are excluded on purpose: the multi-municipality ratio was
# 1.6-2.0 then against 1.17-1.28 since, so tracking behaviour changed regime.
# 2025 entered on 2026-08-14 when its post window became available in the data.
CALIBRATION_YEARS <- 2021:2025

# Pre-specified robustness subset: units whose cells are least contaminated by
# the 0.025 degree masking grid. Fixed HERE, before unblinding.
CORE_INTERIOR_FRAC <- 0.25

args <- commandArgs(trailingOnly = TRUE)
n_check_sims <- if (length(args) >= 1) as.integer(args[[1]]) else 500L

output_dir <- file.path("analysis", "r", "output")
participants_path <- file.path("data", "raw",
                               "participants_spain_municipality_aug_windows.csv")
crosswalk_path <- file.path(output_dir,
                            "google_ads_spain_municipality_crosswalk.csv")
geometry_path <- file.path(output_dir, "municipality_grid_geometry.csv")

# --- outcome column ----------------------------------------------------------
#
# Participants are counted per municipality in one of two ways:
#
#   n_participants       PRESENCE. A user is counted in every municipality where
#                        they emitted a track. Summing over municipalities
#                        therefore exceeds the true number of people -- by a
#                        factor of about 1.20 within province since 2021.
#   n_participants_home  RESIDENCE. Each user is assigned to the municipality
#                        where they were seen on the most distinct days, and
#                        counted only there. An exact partition of people.
#
# The final (2026-08-14) data delivery is home-assigned but kept the historical
# column name, which is why the check below verifies attribution from the data
# itself instead of trusting the name. Home assignment removes the double
# counting, makes units genuinely independent, and strips out transient
# passers-by, who are noise rather than signal.

participants <- read.csv(participants_path)

OUTCOME_COLUMN <- if ("n_participants_home" %in% names(participants)) {
  "n_participants_home"
} else {
  "n_participants"
}
participants$outcome <- participants[[OUTCOME_COLUMN]]

# Attribution is VERIFIED from the data, not assumed from the column name.
# Under home assignment each participant is counted in exactly one
# municipality, so municipality counts sum to the province totals (ratio 1.00);
# under presence attribution the ratio has run 1.17-1.28 since 2021. The 2026-08
# data delivery is home-assigned but kept the historical column name, which is
# why this check exists.
province_path <- file.path("data", "raw",
                           "participants_spain_province_aug_windows.csv")
ATTRIBUTION <- "unverified (province file missing)"
if (file.exists(province_path)) {
  province <- read.csv(province_path)
  check_year <- max(intersect(participants$year, province$year)) - 1
  muni_sum <- sum(participants$outcome[participants$year == check_year])
  prov_sum <- sum(province$n_participants[province$year == check_year])
  attribution_ratio <- muni_sum / prov_sum
  ATTRIBUTION <- sprintf(
    "%s (municipality/province sum ratio %.3f, year %d)",
    if (abs(attribution_ratio - 1) < 0.02) "home-assigned partition"
    else "presence (multi-counting)",
    attribution_ratio, check_year)
}
cat("=== outcome definition ===\n")
cat("  column:", OUTCOME_COLUMN, "\n")
cat("  attribution:", ATTRIBUTION, "\n\n")

# --- eligible pool -----------------------------------------------------------

participants <- participants[participants$window_complete %in% c(TRUE, "TRUE"), ]
participants$unit_name <- paste(participants$NAME_4, participants$NAME_2, sep = ", ")

before <- participants[participants$period == "before", ]
after <- participants[participants$period == "after", ]

baseline <- aggregate(outcome ~ unit_name,
                      data = before[before$year %in% CALIBRATION_YEARS, ],
                      FUN = median)
names(baseline)[2] <- "median_pre_participants"

post_median <- aggregate(outcome ~ unit_name,
                         data = after[after$year %in% CALIBRATION_YEARS, ],
                         FUN = median)
names(post_median)[2] <- "median_post_participants"

crosswalk <- read.csv(crosswalk_path, colClasses = "character")
nameable <- crosswalk[crosswalk$match_type == "name+community" &
                        !is.na(crosswalk$google_criteria_id), ]

# One Google target must never reach two municipalities: it would put the same
# location into two arms.
if (any(duplicated(nameable$google_criteria_id))) {
  stop("Duplicate Criteria IDs in the nameable set: ",
       paste(unique(nameable$google_criteria_id[
         duplicated(nameable$google_criteria_id)]), collapse = ", "))
}

pool <- merge(baseline, post_median, by = "unit_name")
pool <- merge(pool, nameable[, c("unit_name", "province", "google_criteria_id",
                                 "google_name", "google_canonical_name")],
              by = "unit_name")

cat("=== eligibility ===\n")
cat("  targetable by name with participant history:", nrow(pool), "\n")
pool <- pool[pool$median_pre_participants >= MIN_MEDIAN_PARTICIPANTS, ]  # >= 0: no floor
cat("  after floor  (median pre >=", MIN_MEDIAN_PARTICIPANTS, "):", nrow(pool), "\n")
dropped_by_cap <- pool[pool$median_pre_participants > MAX_MEDIAN_PARTICIPANTS, ]
pool <- pool[pool$median_pre_participants <= MAX_MEDIAN_PARTICIPANTS, ]
cat("  after cap    (median pre <=", MAX_MEDIAN_PARTICIPANTS, "):", nrow(pool), "\n")
if (nrow(dropped_by_cap) > 0) {
  cat("  excluded by the cap:",
      paste(sprintf("%s (%.1f)", dropped_by_cap$unit_name,
                    dropped_by_cap$median_pre_participants), collapse = ", "), "\n")
}
if (nrow(pool) < length(BLOCK) * 2) {
  stop("Eligible pool of ", nrow(pool), " is too small to randomise")
}

# --- grid-masking geometry ---------------------------------------------------
#
# Carried into the assignment so the "core" robustness subset is fixed now.
# Cells are ~6 km2 and assigned whole to the municipality holding their
# centroid, so most units' cells straddle their boundary; interior_frac records
# what share of a unit's cells lie entirely inside it.

if (file.exists(geometry_path)) {
  geometry <- read.csv(geometry_path)
  pool <- merge(pool, geometry[, c("unit_name", "area_km2", "cells_centroid",
                                   "cells_interior", "interior_frac",
                                   "nearest_targetable_km")],
                by = "unit_name", all.x = TRUE)
  cat("\n=== grid-masking geometry ===\n")
  cat(sprintf("  median interior cell fraction: %.2f\n",
              median(pool$interior_frac, na.rm = TRUE)))
  cat(sprintf("  units in the core subset (interior_frac >= %.2f): %d of %d\n",
              CORE_INTERIOR_FRAC, sum(pool$interior_frac >= CORE_INTERIOR_FRAC,
                                      na.rm = TRUE), nrow(pool)))
} else {
  warning("Geometry file not found; run build_municipality_grid_geometry.R. ",
          "Core-subset columns will be NA.")
  pool$area_km2 <- NA_real_
  pool$cells_centroid <- NA_integer_
  pool$cells_interior <- NA_integer_
  pool$interior_frac <- NA_real_
  pool$nearest_targetable_km <- NA_real_
}
pool$core_subset <- !is.na(pool$interior_frac) & pool$interior_frac >= CORE_INTERIOR_FRAC

# --- block randomization -----------------------------------------------------
#
# Units are ordered by baseline and cut into consecutive blocks of 9. Each full
# block receives a random permutation of (4 framed, 4 neutral, 1 no-ad), so
# every block is balanced by construction and the arms match on the covariate
# that predicts the outcome.

set.seed(SEED, kind = RNG_KIND, normal.kind = RNG_NORMAL, sample.kind = RNG_SAMPLE)

units <- pool[order(-pool$median_pre_participants,
                    -pool$median_post_participants,
                    pool$unit_name), ]
rownames(units) <- NULL

block_size <- length(BLOCK)
units$block <- ((seq_len(nrow(units)) - 1L) %/% block_size) + 1L
# Full blocks get a random permutation of the arm vector. A trailing PARTIAL
# block is assigned entirely to the no-ad arm: under block fixed effects a
# single-arm block contributes no identifying variation to either contrast, so
# as advertising units its members would be pure spend with zero information.
# Assigning them to no-ad keeps every eligible unit in the frame, costs
# nothing, and -- decisively -- makes the two advertising arms EXACTLY equal
# (420/420), so all 20 campaigns hold exactly 42 municipalities and carry
# identical budgets. Symmetric campaign menus mean Google's within-campaign
# optimiser faces the same problem in both arms. The trailing block is
# processed last, so this rule consumes no RNG that would perturb the full
# blocks' draws.
units$arm <- unlist(lapply(split(units$block, units$block), function(b) {
  if (length(b) == block_size) sample(BLOCK) else rep("no_ad", length(b))
}))
units$arm <- factor(units$arm, levels = c("framed", "neutral", "no_ad"))

# --- campaign groups ---------------------------------------------------------
#
# Within each ad arm, municipalities are cut into CAMPAIGNS_PER_ARM CONTIGUOUS
# bands by baseline, so each campaign holds units of similar size and Google's
# optimiser can only reallocate spend among like units. (An earlier serpentine
# scheme made campaigns comparable to each other but internally heterogeneous;
# with 571 zero-baseline units that would mix villages and active towns in one
# campaign, inviting concentration on the towns -- the main threat to the
# framing contrast.) framed_k and neutral_k hold the same band, so the arms
# stay symmetric campaign by campaign.

banded <- function(n, groups) {
  rep(seq_len(groups), each = ceiling(n / groups))[seq_len(n)]
}

units$campaign_group <- NA_integer_
for (a in c("framed", "neutral")) {
  index <- which(units$arm == a)
  index <- index[order(-units$median_pre_participants[index],
                       -units$median_post_participants[index],
                       units$unit_name[index])]
  units$campaign_group[index] <- banded(length(index), CAMPAIGNS_PER_ARM)
}
units$campaign <- ifelse(is.na(units$campaign_group), NA_character_,
                         sprintf("%s_%02d", units$arm, units$campaign_group))

# --- Type I error on the REALISED assignment ---------------------------------
#
# Not the design-level rate averaged over fresh randomisations -- the rate
# conditional on the draw that will actually be used. These differ, and the gap
# is exactly what an unlucky draw looks like.
#
# Each simulated season resamples an observed pre/post pair per municipality, so
# real year-to-year variation is carried.
#
# The two hypotheses have DIFFERENT nulls, and simulating one null for both is a
# silent way to report a power figure as though it were a false-positive rate:
#
#   H1 null   both ad arms receive their installs; only the framing advantage is
#             zero. The no-ad arm plays no part in the test.
#   H2 null   NO arm receives installs at all. Delivering installs to the ad arms
#             and then testing ads against no-ad is the H2 alternative, not its
#             null, and returns 1.000.
#
# Inference uses HC3 rather than the ordinary t-test. With a small no-ad arm
# and a right-skewed count outcome, the t approximation has been
# anti-conservative on earlier draws (0.098 against a nominal 0.05, where HC3
# gave 0.033). The pre-registered PRIMARY test is randomisation inference,
# which is exact over the randomisation distribution by construction; HC3 is
# used for this pre-launch screen because it is cheap enough to run on every
# draw and catches the same imbalance.

check_realised_type_i <- function(units, n_sims) {
  panel <- merge(before[, c("unit_name", "year", "outcome")],
                 after[, c("unit_name", "year", "outcome")],
                 by = c("unit_name", "year"), suffixes = c(".pre", ".post"))
  panel <- panel[panel$unit_name %in% units$unit_name &
                   panel$year %in% CALIBRATION_YEARS, ]
  seasons <- sort(unique(panel$year))
  n <- nrow(units)
  key <- paste(panel$unit_name, panel$year)

  budget <- 5000; cpi <- 0.39
  installs <- budget / cpi / sum(units$arm != "no_ad")

  draws <- replicate(n_sims, {
    season <- sample(seasons, n, replace = TRUE)
    index <- match(paste(units$unit_name, season), key)
    base_post <- panel$outcome.post[index]
    base_pre <- panel$outcome.pre[index]

    # H1 null: installs delivered to both ad arms, no framing advantage.
    delivered <- ifelse(units$arm == "no_ad", 0,
                        installs * exp(rnorm(n, -0.08, 0.4)))
    post_h1 <- rpois(n, pmax(base_post + delivered, 1e-8))
    ad <- units$arm != "no_ad"
    fit_h1 <- lm(post_h1[ad] ~ factor(units$arm[ad], levels = c("neutral", "framed")) +
                   factor(units$block[ad]) + base_pre[ad] +
                   units$median_post_participants[ad])
    h1 <- lmtest::coeftest(fit_h1, vcov. = sandwich::vcovHC(fit_h1, type = "HC3"))[2, 4]

    # H2 null: no arm receives installs.
    post_h2 <- rpois(n, pmax(base_post, 1e-8))
    group <- factor(ifelse(units$arm == "no_ad", "no_ad", "ads"),
                    levels = c("no_ad", "ads"))
    fit_h2 <- lm(post_h2 ~ group + factor(units$block) + base_pre +
                   units$median_post_participants)
    h2 <- lmtest::coeftest(fit_h2, vcov. = sandwich::vcovHC(fit_h2, type = "HC3"))[2, 4]
    c(h1 = h1, h2 = h2)
  })
  c(h1 = mean(draws["h1", ] < 0.05, na.rm = TRUE),
    h2 = mean(draws["h2", ] < 0.05, na.rm = TRUE))
}

cat("\n=== Type I error check on the realised draw ===\n")
set.seed(SEED + 1L)
realised <- check_realised_type_i(units, n_check_sims)
cat(sprintf("  H1 (framed vs neutral): %.3f\n", realised["h1"]))
cat(sprintf("  H2 (ads vs no ads):     %.3f   [%d simulations]\n",
            realised["h2"], n_check_sims))
if (any(realised > 0.09)) {
  warning("Realised Type I error is ANTI-conservative (",
          paste(sprintf("%.3f", realised), collapse = ", "),
          "). Do NOT launch on this draw -- investigate baseline balance first.")
  cat("  *** WARNING: anti-conservative. See the note at the head of this script. ***\n")
} else if (any(realised < 0.02)) {
  cat("  note: conservative (HC3 over-corrects with block dummies and a small\n")
  cat("  no-ad arm). Not a launch risk; randomization inference is the primary\n")
  cat("  test and is exact.\n")
} else {
  cat("  both within tolerance of 0.05\n")
}

# --- outputs -----------------------------------------------------------------

if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

assignment <- units[order(units$arm, units$campaign_group,
                          -units$median_pre_participants, units$unit_name),
                    c("unit_name", "province", "block", "arm", "campaign",
                      "median_pre_participants", "median_post_participants",
                      "area_km2", "cells_centroid", "cells_interior",
                      "interior_frac", "core_subset", "nearest_targetable_km",
                      "google_criteria_id", "google_name", "google_canonical_name")]

assignment_path <- file.path(output_dir, "assignment_2026_final.csv")
write.csv(assignment, assignment_path, row.names = FALSE)

# Campaign build files, three formats per campaign:
#   <campaign>.csv        full detail, one row per municipality -- the record
#   <campaign>_names.txt  canonical names for the web UI's "add locations in
#                         bulk" box (paste up to 1,000 names)
#   <campaign>.txt        bare Criteria IDs (Editor / API)
# plus google_ads_upload_all.csv: every ad campaign in one sheet with
# Campaign / Location ID / Location columns for a single Ads Editor import.
# Google-side campaign names are prefixed MA2026_ so platform reports join back
# to the assignment unambiguously.
campaign_dir <- file.path(output_dir, "campaign_criteria_ids")
if (!dir.exists(campaign_dir)) dir.create(campaign_dir, recursive = TRUE, showWarnings = FALSE)
unlink(file.path(campaign_dir, c("*.txt", "*.csv")))
ad_rows <- assignment[!is.na(assignment$campaign), ]
upload <- data.frame(
  Campaign = paste0("MA2026_", ad_rows$campaign),
  `Location ID` = ad_rows$google_criteria_id,
  Location = ad_rows$google_canonical_name,
  unit_name = ad_rows$unit_name,
  province = ad_rows$province,
  median_pre_participants = ad_rows$median_pre_participants,
  check.names = FALSE)
write.csv(upload, file.path(campaign_dir, "google_ads_upload_all.csv"),
          row.names = FALSE)
# Editor import sheet: exactly the two columns Google Ads Editor's
# "Make multiple changes -> Locations" paste dialog needs, with the LOCATION
# GIVEN AS THE NUMERIC CRITERIA ID. This is the only bulk path that cannot
# mis-resolve: 180 other Spanish geo targets (provinces, cities, homonymous
# municipalities) share a display name with a study municipality, and 341 of
# our targets are "City"-type entities in Google's table, so matching by typed
# name -- or hand-picking "the Municipality entry" -- silently substitutes a
# different Criteria ID. The web UI's bulk box does not accept IDs at all.
write.csv(data.frame(Campaign = upload$Campaign,
                     Location = upload$`Location ID`),
          file.path(campaign_dir, "editor_locations_import.csv"),
          row.names = FALSE)
for (cmp in sort(unique(ad_rows$campaign))) {
  rows <- upload[upload$Campaign == paste0("MA2026_", cmp), ]
  write.csv(rows, file.path(campaign_dir, paste0(cmp, ".csv")), row.names = FALSE)
  writeLines(rows$Location, file.path(campaign_dir, paste0(cmp, "_names.txt")))
  writeLines(rows$`Location ID`, file.path(campaign_dir, paste0(cmp, ".txt")))
}
writeLines(assignment$google_criteria_id[assignment$arm == "no_ad"],
           file.path(campaign_dir, "NO_AD_do_not_target.txt"))

# Campaign budgets: PROPORTIONAL to municipality count, not equal per campaign.
# With every campaign at exactly 42 municipalities this reduces to equal
# budgets (EUR 250), but the rule is stated generally: equal per-campaign
# budgets over UNEQUAL campaigns would give some municipalities more expected
# dose than others in an arm-correlated way, which would undermine
# label-invariance under the null.
TOTAL_BUDGET_EUR <- 5000
n_by_campaign <- table(ad_rows$campaign)
budgets <- data.frame(
  campaign = paste0("MA2026_", names(n_by_campaign)),
  n_municipalities = as.integer(n_by_campaign),
  budget_total_eur = round(TOTAL_BUDGET_EUR * as.integer(n_by_campaign) /
                             nrow(ad_rows), 2))
budgets$budget_per_municipality_eur <- round(budgets$budget_total_eur /
                                               budgets$n_municipalities, 4)
budgets$daily_30d_flight_eur <- round(budgets$budget_total_eur / 30, 2)
budgets$daily_60d_flight_eur <- round(budgets$budget_total_eur / 60, 2)
write.csv(budgets, file.path(campaign_dir, "campaign_budgets.csv"),
          row.names = FALSE)
cat("\n=== campaign budgets (proportional to municipality count) ===\n")
cat(sprintf("  EUR %.4f per municipality, every campaign\n",
            TOTAL_BUDGET_EUR / nrow(ad_rows)))
cat(sprintf("  totals: %s\n", paste(sprintf("%s=%.2f", sub("MA2026_", "", budgets$campaign),
            budgets$budget_total_eur), collapse=" ")))
cat(sprintf("  sum of rounded totals: EUR %.2f (rounding drift vs %d: %.2f)\n",
            sum(budgets$budget_total_eur), TOTAL_BUDGET_EUR,
            sum(budgets$budget_total_eur) - TOTAL_BUDGET_EUR))

# --- report ------------------------------------------------------------------

cat("\n=== assignment ===\n")
balance <- do.call(rbind, lapply(levels(units$arm), function(a) {
  rows <- units[units$arm == a, ]
  data.frame(arm = a, n = nrow(rows), campaigns = length(unique(na.omit(rows$campaign))),
             median_baseline = median(rows$median_pre_participants),
             mean_baseline = round(mean(rows$median_pre_participants), 2),
             max_baseline = max(rows$median_pre_participants),
             core = sum(rows$core_subset))
}))
print(balance, row.names = FALSE)
cat("\n  blocks:", max(units$block), "of size", block_size, "\n")
cat("  max gap in mean baseline across arms:",
    round(max(balance$mean_baseline) - min(balance$mean_baseline), 3), "\n")
cat("  duplicate Criteria IDs:", sum(duplicated(assignment$google_criteria_id)), "\n")

cat("\n=== campaigns to build (Android only) ===\n")
cmp <- table(assignment$campaign)
cat("  ", length(cmp), " campaigns, ", min(cmp), "-", max(cmp),
    " municipalities each\n", sep = "")
cat("   Criteria ID files in", campaign_dir, "\n")

manifest_path <- file.path(output_dir, "manifest_2026_final.txt")
writeLines(c(
  "IDAlert T5.4 2026 randomization manifest",
  paste("generated:", format(Sys.time(), tz = "UTC", usetz = TRUE)),
  paste("seed:", SEED),
  paste("RNG:", RNG_KIND, "/", RNG_NORMAL, "/", RNG_SAMPLE),
  paste("R version:", R.version.string),
  paste("outcome column:", OUTCOME_COLUMN),
  paste("attribution:", ATTRIBUTION),
  paste("units:", nrow(units), "(all eligible; N follows the rule, not a target)"),
  paste("arms:", paste(sprintf("%s=%d", balance$arm, balance$n), collapse = ", ")),
  paste("block:", paste(BLOCK, collapse = "/")),
  paste("campaigns per ad arm:", CAMPAIGNS_PER_ARM, "(Android only)"),
  paste("eligibility: median pre-window participants in [",
        MIN_MEDIAN_PARTICIPANTS, ",", MAX_MEDIAN_PARTICIPANTS, "]"),
  paste("calibration seasons:", paste(CALIBRATION_YEARS, collapse = ", ")),
  paste("core subset: interior_frac >=", CORE_INTERIOR_FRAC,
        sprintf("(%d units)", sum(units$core_subset))),
  paste("realised Type I error: H1", sprintf("%.3f", realised["h1"]),
        "| H2", sprintf("%.3f", realised["h2"]),
        sprintf("(%d sims)", n_check_sims)),
  "",
  "input checksums (md5):",
  paste(" ", participants_path, tools::md5sum(participants_path)),
  paste(" ", crosswalk_path, tools::md5sum(crosswalk_path)),
  if (file.exists(geometry_path)) paste(" ", geometry_path, tools::md5sum(geometry_path)) else "  (geometry file absent)",
  "",
  "output checksum (md5):",
  paste(" ", assignment_path, tools::md5sum(assignment_path))),
  manifest_path)

cat("\nWritten:\n  ", assignment_path, "\n   ", manifest_path, "\n", sep = "")
