# =============================================================================
# THE pre-registered analysis for the 2026 experiment.
#
# This is the code the registration points at. It implements, exactly:
#
#   model      lm(post ~ treat + block + pre + historical_median), one row per
#              municipality, on the count scale. Block fixed effects are not
#              optional: the design blocked on baseline, and a model without
#              the blocks lets the curvature of the count outcome in baseline
#              re-enter -- on the realised draw that put H2's conditional
#              Type I error at 0.10, against 0.06 with the blocks in. Power is
#              unchanged for H1 and slightly better for H2. Analyze as you
#              randomize.
#   H1         framed vs neutral among the advertising municipalities
#   H2         advertising pooled vs no-ad, all units
#   inference  randomization inference: the treat coefficient re-estimated
#              under permutations of the arm labels WITHIN the realised blocks,
#              which is the design's own randomization distribution. Exact under
#              the sharp null regardless of outcome distribution or spatial
#              dependence between municipalities.
#   secondary  HC3 robust p-value from the same model, reported alongside.
#   interval   95% CI by inverting the randomization test under a constant
#              additive per-municipality effect. The statistic is linear in the
#              hypothesised shift tau -- coef(post - tau*treat_obs ~ treat_perm
#              + X) = a_perm - tau*b_perm -- so the whole tau line is known from
#              two coefficients per permutation and the inversion is exact, not
#              a grid search.
#
# Why randomization inference and not the t-test: with a small no-ad arm (~1/9
# of units) and a right-skewed count outcome, the t-test without block terms
# rejected a true null 0.098 of the time on an earlier draw. RI is exact by
# construction; HC3 (conservative here) is the parametric check.
#
# Permutation scheme, per hypothesis:
#   H1  no-ad units are set aside; framed/neutral labels are permuted within
#       blocks among the advertising units. This is the randomization
#       distribution CONDITIONAL on the no-ad positions, which is valid because
#       the no-ad positions are themselves a function of the assignment.
#   H2  the ads/no-ad indicator is permuted within blocks across all units.
#       Blocks without a no-ad unit (the trailing partial block) permute
#       trivially, exactly as the design allows.
#
# Usage:
#   Rscript analyse_assignment.R --outcomes=path.csv [--outcome=tracks|reports]
#   Rscript analyse_assignment.R --demo         # simulated outcomes, one run
#   Rscript analyse_assignment.R --calibrate    # Type I error of this exact
#                                               # code under the null
#
# The outcomes CSV must carry unit_name plus, for tracks,
# post_participants/pre_participants, or, for reports,
# post_reporters/pre_reporters, for the 2026 windows.
# =============================================================================

suppressWarnings({
  options(stringsAsFactors = FALSE)
})

suppressPackageStartupMessages({
  library(sandwich)
  library(lmtest)
})

N_PERMUTATIONS <- 10000L
ALPHA <- 0.05
RI_SEED <- 20261014L   # frozen: date the post window closes

output_dir <- file.path("analysis", "r", "output")
assignment_path <- file.path(output_dir, "assignment_2026_final.csv")

# --- the test ----------------------------------------------------------------
#
# For each permutation p of the treatment labels, fit ONE least-squares problem
# with two responses:
#
#   lm(cbind(post, treat_obs) ~ treat_perm + covariates)
#
# giving a_p (coefficient of treat_perm on post) and b_p (on treat_obs). Under
# the sharp null "every treated unit's outcome would have been lower by tau",
# the adjusted outcome is post - tau*treat_obs, and the statistic under
# permutation p is a_p - tau*b_p. For the observed labels b = 1, so the observed
# statistic is a_obs - tau. The p-value at any tau follows without refitting.

ri_test <- function(post, treat_obs, covariates, block,
                    n_permutations = N_PERMUTATIONS, seed = RI_SEED) {
  X <- cbind(treat = treat_obs, covariates)
  fit <- lm(post ~ X)
  estimate <- coef(fit)[["Xtreat"]]
  # HC3 divides by (1 - h_i)^2; a block dummy isolating a single unit puts its
  # hat value at 1 and returns NaN (possible in subset analyses). Fall back.
  hc3_type <- if (any(stats::hatvalues(fit) > 0.999)) "HC1" else "HC3"
  hc3_p <- lmtest::coeftest(fit,
                            vcov. = sandwich::vcovHC(fit, type = hc3_type))["Xtreat", 4]

  blocks <- split(seq_along(block), block)
  set.seed(seed, kind = "Mersenne-Twister", normal.kind = "Inversion",
           sample.kind = "Rejection")
  ab <- vapply(seq_len(n_permutations), function(p) {
    treat_perm <- treat_obs
    for (index in blocks) treat_perm[index] <- sample(treat_obs[index])
    fit_p <- lm(cbind(post, treat_obs) ~ cbind(treat = treat_perm, covariates))
    coef(fit_p)[2, ]     # row 2 = treat_perm; columns = (post, treat_obs)
  }, numeric(2))
  a <- ab[1, ]
  b <- ab[2, ]

  # p-value at shift tau; tau = 0 is the headline test of no effect.
  p_at <- function(tau) {
    (1 + sum(abs(a - tau * b) >= abs(estimate - tau))) / (1 + length(a))
  }
  p_value <- p_at(0)

  # 95% CI: the set of tau with p(tau) > ALPHA. |a - tau*b| >= |estimate - tau|
  # flips at the roots of two linear equations per permutation, so the interval
  # bounds are located by bisection on p_at, which is monotone near the bounds.
  se_proxy <- sd(a)
  locate <- function(lower, upper) {
    for (i in 1:60) {
      mid <- (lower + upper) / 2
      if (p_at(mid) > ALPHA) upper <- mid else lower <- mid
    }
    (lower + upper) / 2
  }
  wide <- 20 * max(se_proxy, 1e-9)
  ci_low <- locate(estimate - wide, estimate)
  upper_locate <- function(lower, upper) {
    for (i in 1:60) {
      mid <- (lower + upper) / 2
      if (p_at(mid) > ALPHA) lower <- mid else upper <- mid
    }
    (lower + upper) / 2
  }
  ci_high <- upper_locate(estimate, estimate + wide)

  data.frame(estimate = estimate, p_ri = p_value, p_hc3 = hc3_p,
             ci_low = ci_low, ci_high = ci_high,
             n_permutations = length(a))
}

# --- hypothesis wrappers -----------------------------------------------------

analyse <- function(assignment, post, pre, historical, label) {
  arm <- factor(assignment$arm, levels = c("framed", "neutral", "no_ad"))
  ok <- !is.na(post) & !is.na(pre) & !is.na(historical)
  if (any(!ok)) {
    cat(sprintf("  [%s] dropping %d units with missing values\n", label, sum(!ok)))
  }

  # Covariates: block fixed effects (dropping one level; lm adds the
  # intercept), the pre-window count, and the historical median.
  covariates_for <- function(keep) {
    cbind(model.matrix(~ factor(assignment$block[keep]))[, -1, drop = FALSE],
          pre = pre[keep], hist = historical[keep])
  }

  # H1: framed vs neutral among advertising units, no-ad positions fixed.
  ad <- ok & arm != "no_ad"
  h1 <- ri_test(post[ad], as.numeric(arm[ad] == "framed"),
                covariates_for(ad), assignment$block[ad])

  # H2: ads vs no-ad, all units.
  h2 <- ri_test(post[ok], as.numeric(arm[ok] != "no_ad"),
                covariates_for(ok), assignment$block[ok])

  neutral_mean <- mean(post[ok & arm == "neutral"])
  noad_mean <- mean(post[ok & arm == "no_ad"])

  cat(sprintf("\n=== %s ===\n", label))
  cat(sprintf("%-4s %10s %12s %10s %10s %22s\n",
              "", "estimate", "vs control", "p (RI)", "p (HC3)", "95% CI (RI)"))
  cat(sprintf("%-4s %10.2f %11.0f%% %10.4f %10.4f %10.2f to %.2f\n",
              "H1", h1$estimate, 100 * h1$estimate / neutral_mean,
              h1$p_ri, h1$p_hc3, h1$ci_low, h1$ci_high))
  cat(sprintf("%-4s %10.2f %11.0f%% %10.4f %10.4f %10.2f to %.2f\n",
              "H2", h2$estimate, 100 * h2$estimate / noad_mean,
              h2$p_ri, h2$p_hc3, h2$ci_low, h2$ci_high))
  cat(sprintf("  control means: neutral %.2f | no-ad %.2f\n", neutral_mean, noad_mean))
  invisible(list(h1 = h1, h2 = h2))
}

# --- entry points ------------------------------------------------------------

if (sys.nframe() == 0) {
  args <- commandArgs(trailingOnly = TRUE)
  get_arg <- function(name, default = NULL) {
    hit <- grep(paste0("^--", name, "="), args, value = TRUE)
    if (length(hit)) sub(paste0("^--", name, "="), "", hit[[1]]) else default
  }

  assignment <- read.csv(assignment_path)
  assignment <- assignment[order(assignment$block, assignment$unit_name), ]
  cat("Assignment:", assignment_path, "\n")
  cat("Units:", nrow(assignment), "| blocks:", length(unique(assignment$block)),
      "| arms:", paste(table(assignment$arm), collapse = "/"), "\n")

  outcome <- get_arg("outcome", "tracks")
  historical <- if (outcome == "reports") {
    reporters <- read.csv(file.path(output_dir, "municipality_reporter_counts.csv"))
    reporters <- reporters[reporters$year %in% 2021:2025 &
                             !is.na(reporters$post_reporters), ]
    med <- aggregate(post_reporters ~ unit_name, reporters, median)
    med$post_reporters[match(assignment$unit_name, med$unit_name)]
  } else {
    assignment$median_post_participants
  }

  if ("--demo" %in% args || "--calibrate" %in% args) {
    # Simulated outcomes from each unit's historical level, with the unit-level
    # noise the power analysis measured. Demo applies a known effect;
    # calibrate applies none and measures how often this exact code rejects.
    participants <- read.csv(file.path("data", "raw",
                                       "participants_spain_municipality_aug_windows.csv"))
    outcome_column <- if ("n_participants_home" %in% names(participants)) {
      "n_participants_home"
    } else {
      "n_participants"
    }
    participants$outcome_value <- participants[[outcome_column]]
    participants <- participants[participants$window_complete %in% c(TRUE, "TRUE") &
                                   participants$year %in% 2021:2025, ]
    participants$unit_name <- paste(participants$NAME_4, participants$NAME_2, sep = ", ")
    before <- participants[participants$period == "before",
                           c("unit_name", "year", "outcome_value")]
    after <- participants[participants$period == "after",
                          c("unit_name", "year", "outcome_value")]
    panel <- merge(before, after, by = c("unit_name", "year"),
                   suffixes = c(".pre", ".post"))
    panel <- panel[panel$unit_name %in% assignment$unit_name, ]
    seasons <- sort(unique(panel$year))
    panel_key <- paste(panel$unit_name, panel$year)
    n <- nrow(assignment)
    arm <- factor(assignment$arm, levels = c("framed", "neutral", "no_ad"))
    installs <- 5000 / 0.39 / sum(arm != "no_ad")

    draw <- function(delta, deliver = TRUE) {
      season <- sample(seasons, n, replace = TRUE)
      index <- match(paste(assignment$unit_name, season), panel_key)
      base_post <- panel$outcome_value.post[index]
      base_pre <- panel$outcome_value.pre[index]
      added <- if (deliver) {
        ifelse(arm == "no_ad", 0,
               installs * exp(rnorm(n, -0.08, 0.4)) *
                 ifelse(arm == "framed", 1 + delta, 1))
      } else {
        0
      }
      list(post = rpois(n, pmax(base_post + added, 1e-8)), pre = base_pre)
    }

    if ("--demo" %in% args) {
      set.seed(1)
      sim <- draw(delta = 0.15)
      cat("\nDemonstration on SIMULATED outcomes, true framing effect +15%,",
          "\ninstalls delivered to both ad arms. Expect H1 ~ the powered rate,",
          "\nH2 to reject overwhelmingly.\n")
      analyse(assignment, sim$post, sim$pre, historical,
              sprintf("simulated %s", outcome))
    } else {
      n_runs <- as.integer(get_arg("runs", "300"))
      n_perm <- as.integer(get_arg("perms", "600"))
      cat(sprintf("\nCalibration: %d simulated null datasets x %d permutations.\n",
                  n_runs, n_perm))
      cat("H1 null: installs delivered, no framing advantage.",
          "\nH2 null: no installs delivered anywhere.\n")
      set.seed(2)
      ad <- arm != "no_ad"
      block_dummies <- model.matrix(~ factor(assignment$block))[, -1, drop = FALSE]
      block_dummies_ad <- model.matrix(~ factor(assignment$block[ad]))[, -1, drop = FALSE]
      rejections <- vapply(seq_len(n_runs), function(r) {
        sim1 <- draw(delta = 0, deliver = TRUE)
        h1 <- ri_test(sim1$post[ad], as.numeric(arm[ad] == "framed"),
                      cbind(block_dummies_ad, sim1$pre[ad], historical[ad]),
                      assignment$block[ad], n_permutations = n_perm, seed = r)
        sim2 <- draw(delta = 0, deliver = FALSE)
        h2 <- ri_test(sim2$post, as.numeric(arm != "no_ad"),
                      cbind(block_dummies, sim2$pre, historical),
                      assignment$block, n_permutations = n_perm, seed = r + 5e5)
        c(h1$p_ri < ALPHA, h2$p_ri < ALPHA)
      }, logical(2))
      cat(sprintf("\n  H1 Type I: %.3f\n  H2 Type I: %.3f\n",
                  mean(rejections[1, ]), mean(rejections[2, ])))
      cat("  (both should sit near 0.05)\n")
    }
  } else {
    outcomes_path <- get_arg("outcomes")
    if (is.null(outcomes_path)) {
      stop("Provide --outcomes=<csv>, or --demo / --calibrate. See the header.")
    }
    outcomes <- read.csv(outcomes_path)
    columns <- if (outcome == "reports") {
      c("post_reporters", "pre_reporters")
    } else {
      c("post_participants", "pre_participants")
    }
    if (!all(c("unit_name", columns) %in% names(outcomes))) {
      stop("Outcomes file must carry unit_name, ", paste(columns, collapse = ", "))
    }
    index <- match(assignment$unit_name, outcomes$unit_name)
    analyse(assignment, outcomes[[columns[1]]][index],
            outcomes[[columns[2]]][index], historical,
            sprintf("2026 outcomes: %s", outcome))
  }
}
