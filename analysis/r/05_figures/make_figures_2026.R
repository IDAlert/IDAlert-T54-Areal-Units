# =============================================================================
# Figures and LaTeX table fragments for the article.
#
# Reads only committed outputs of the earlier steps (assignment, outcomes,
# primary-analysis logs, secondary and orientation results, derived delivery
# tables), the deposited participant window counts and the GADM boundaries.
# It computes no new inference: every estimate, p-value and interval is read
# from the files the analysis scripts wrote.
#
# Writes analysis/r/output/figures/<name>.pdf (+ .png preview) and
# analysis/r/output/tables/<name>.tex (booktabs fragments for \input).
# Usage: Rscript analysis/r/05_figures/make_figures_2026.R
# =============================================================================
suppressPackageStartupMessages({ library(ggplot2); library(sf); library(cowplot); library(scales); library(dplyr) })
sf::sf_use_s2(FALSE)
out <- file.path("analysis", "r", "output")
figdir <- file.path(out, "figures"); tabdir <- file.path(out, "tables")
dir.create(figdir, showWarnings = FALSE); dir.create(tabdir, showWarnings = FALSE)

arm_levels <- c("framed", "neutral", "no_ad")
arm_labels <- c(framed = "Framed ads", neutral = "Neutral ads", no_ad = "No ads")
short_labels <- c(framed = "Framed", neutral = "Neutral", no_ad = "No ads")
arm_cols <- c(framed = "#D55E00", neutral = "#0072B2", no_ad = "#7F7F7F")      # Okabe-Ito
ori_cols <- c(Prevention = "#E69F00", Promotion = "#56B4E9", Neutral = "#999999")
BASE <- 9                                                                     # pt, at the rendered width
theme_set(theme_minimal(base_size = BASE) +
            theme(panel.grid.minor = element_blank(), legend.position = "bottom",
                  legend.key.size = unit(0.8, "lines"), plot.margin = margin(4, 8, 2, 4)))
WIDE <- 7.1                                                                   # inches: 180 mm journal width
save_fig <- function(p, name, w, h) {
  ggsave(file.path(figdir, paste0(name, ".pdf")), p, width = w, height = h, device = cairo_pdf)
  ggsave(file.path(figdir, paste0(name, ".png")), p, width = w, height = h, dpi = 200, bg = "white")
  cat("  wrote", name, "\n")
}
fmt <- function(x, d = 2) formatC(x, format = "f", digits = d, big.mark = ",")
fmt0 <- function(x) formatC(round(x), format = "d", big.mark = ",")
sg <- function(x, d = 2) sprintf("$%+.*f$", d, x)                              # signed number, math mode
pct_tex <- function(x) sprintf("$%+d$%%", round(x))
p_tex <- function(p) ifelse(p < 0.001, "$<$0.001", formatC(p, format = "f", digits = 3))
p_lab <- function(p) ifelse(p < 0.001, "p < 0.001", sprintf("p = %s", formatC(p, format = "f", digits = 3)))

# --- inputs -------------------------------------------------------------------------
a <- read.csv(file.path(out, "assignment_2026_final.csv")); a$arm <- factor(a$arm, arm_levels)
o <- read.csv(file.path(out, "outcomes_2026.csv")); o <- o[match(a$unit_name, o$unit_name), ]
stopifnot(!anyNA(o$post_participants), nrow(a) == 949)
sec <- read.csv(file.path(out, "secondary_results_2026.csv"))
ori <- read.csv(file.path(out, "orientation_delivery_2026.csv"))
dm <- read.csv(file.path(out, "delivery_by_municipality_2026.csv")); dm <- dm[match(a$unit_name, dm$unit_name), ]
dd <- read.csv(file.path(out, "delivery_by_campaign_day_2026.csv")); dd$date <- as.Date(dd$date)
a$installs <- dm$installs; a$impressions <- dm$impressions; a$cost <- dm$cost
stopifnot(all(is.na(a$installs) == (a$arm == "no_ad")))

# primary results, as printed by the frozen analysis script
parse_primary <- function(path, outcome) {
  l <- readLines(path)
  cm <- grep("control means", l, value = TRUE)
  ctrl <- c(H1 = as.numeric(sub(".*neutral ([0-9.]+).*", "\\1", cm)), H2 = as.numeric(sub(".*no-ad ([0-9.]+).*", "\\1", cm)))
  nf <- grep("units in fit", l, value = TRUE)
  n <- c(H1 = as.integer(sub(".*H1 ([0-9]+).*", "\\1", nf)), H2 = as.integer(sub(".*H2 ([0-9]+).*", "\\1", nf)))
  do.call(rbind, lapply(grep("^H[12] ", l, value = TRUE), function(r) {
    f <- strsplit(trimws(r), "\\s+")[[1]]                     # H estimate pct p_ri p_hc3 lo "to" hi
    data.frame(outcome = outcome, hypothesis = f[1], estimate = as.numeric(f[2]), pct = as.numeric(sub("%", "", f[3])),
               p_ri = as.numeric(f[4]), p_hc3 = as.numeric(f[5]), ci_low = as.numeric(f[6]), ci_high = as.numeric(f[8]),
               control_mean = ctrl[[f[1]]], n = n[[f[1]]])
  }))
}
prim <- rbind(parse_primary(file.path(out, "primary_results_2026_tracks.log"), "Sampling-effort participants"),
              parse_primary(file.path(out, "primary_results_2026_reports.log"), "Reporters"))
stopifnot(nrow(prim) == 4)

# --- Figure 1: the experiment on the map ---------------------------------------------
b <- readRDS(file.path("data", "raw", "gadm", "gadm41_ESP_4_pk.rds"))
if (inherits(b, "PackedSpatVector")) b <- terra::vect(b)
b <- sf::st_as_sf(b); b$unit_name <- paste(b$NAME_4, b$NAME_2, sep = ", ")
b <- b[!sf::st_is_empty(sf::st_geometry(b)), ]
study <- b[b$unit_name %in% a$unit_name, ] %>% group_by(unit_name) %>% summarise(.groups = "drop") %>% sf::st_simplify(dTolerance = 0.003)
stopifnot(nrow(study) == 949)
study$arm <- a$arm[match(study$unit_name, a$unit_name)]; study$installs <- a$installs[match(study$unit_name, a$unit_name)]
bg <- sf::st_simplify(b, dTolerance = 0.01)
map_panel <- function(layer, xlim, ylim, legend = TRUE) {
  ggplot() + geom_sf(data = bg, fill = "grey94", colour = "grey82", linewidth = 0.05) + layer +
    coord_sf(xlim = xlim, ylim = ylim, expand = FALSE) + theme_void(base_size = BASE) +
    theme(legend.position = if (legend) "bottom" else "none", panel.border = element_rect(fill = NA, colour = "grey60", linewidth = 0.3))
}
with_canaries <- function(layer) {               # peninsula + Balearics, Canary Islands inset bottom right
  ggdraw(map_panel(layer, c(-9.6, 4.5), c(35.9, 43.9))) +
    draw_plot(map_panel(layer, c(-18.4, -13.3), c(27.5, 29.5), legend = FALSE), x = 0.68, y = 0.12, width = 0.30, height = 0.20)
}
arm_layer <- list(geom_sf(data = study, aes(fill = arm), colour = "grey30", linewidth = 0.08),
                  scale_fill_manual(values = arm_cols, labels = sprintf("%s (n = %d)", arm_labels, table(a$arm)[arm_levels]), name = NULL))
save_fig(with_canaries(arm_layer), "fig1_map_assignment", 7, 6)
inst_layer <- list(geom_sf(data = study[study$arm != "no_ad", ], aes(fill = installs), colour = "grey30", linewidth = 0.08),
                   scale_fill_viridis_c(transform = "log1p", breaks = c(0, 3, 10, 30, 100, 300), name = "Installs"))
save_fig(with_canaries(inst_layer), "figS1_map_installs", 7, 6)

# --- Figure 2: delivery ---------------------------------------------------------------
daily <- dd %>% group_by(date, arm) %>% summarise(cost = sum(cost), installs = sum(installs), .groups = "drop")
pA <- ggplot(daily, aes(date, cost, colour = arm)) + geom_line(linewidth = 0.6) +
  geom_vline(xintercept = as.Date("2026-09-15"), linetype = "dashed", colour = "grey45", linewidth = 0.4) +
  annotate("text", x = as.Date("2026-09-15"), y = max(daily$cost), label = "planned end (15 Sep)", hjust = 1.05, vjust = 1, size = 2.6, colour = "grey30") +
  scale_colour_manual(values = arm_cols, labels = arm_labels, name = NULL) + scale_x_date(date_labels = "%d %b") +
  labs(x = NULL, y = "Daily spend (EUR)")
ad <- a[a$arm != "no_ad", ]
pB <- ggplot(ad, aes(installs, colour = arm)) + stat_ecdf(linewidth = 0.6) +
  scale_x_continuous(transform = "log1p", breaks = c(0, 1, 3, 10, 30, 100, 300)) +
  scale_colour_manual(values = arm_cols, labels = arm_labels, name = NULL) +
  labs(x = "Installs per municipality (log scale)", y = "Cumulative share of municipalities")
orid <- ori[ori$level == "arm x orientation", ]; orid$share <- orid$impressions / ave(orid$impressions, orid$arm, FUN = sum)
orid$orientation <- factor(orid$orientation, c("prevention", "promotion", "neutral"), names(ori_cols))
orid$arm_label <- short_labels[orid$arm]
pC <- ggplot(orid, aes(x = arm_label, y = share, fill = orientation)) + geom_col(width = 0.6, colour = "grey30", linewidth = 0.2) +
  geom_text(aes(label = sprintf("%s\n%s", orientation, percent(share, accuracy = 1))), position = position_stack(vjust = 0.5), size = 2.6, lineheight = 0.9) +
  scale_fill_manual(values = ori_cols, guide = "none") + scale_y_continuous(labels = percent) +
  labs(x = NULL, y = "Share of impressions")
no_legend <- theme(legend.position = "none")
shared_legend <- cowplot::get_plot_component(pA + theme(legend.position = "bottom"), "guide-box-bottom")
panels <- plot_grid(pA + no_legend, pB + no_legend, pC, labels = c("a", "b", "c"), label_size = 11, ncol = 3, rel_widths = c(1.3, 1, 0.9), align = "h", axis = "tb")
save_fig(plot_grid(panels, shared_legend, ncol = 1, rel_heights = c(1, 0.08)), "fig2_delivery", WIDE, 2.9)

# --- Figure 3: every pre-specified estimate -------------------------------------------
lab_sec <- c("1 presence attribution" = "Presence attribution (tertiary outcome)", "2 core subset" = "Core subset (least grid-blurred)",
             "4 equal exposure (impressions covariate)" = "Equal-exposure adjustment", "7 minimum-delivery subset" = "Minimum-delivery subset",
             "7 minimum-delivery subset (+ no-ad arm)" = "Minimum-delivery subset", "8 activation subgroup" = "Activation subgroup (zero baseline)",
             "8 activation subgroup (H1 for completeness)" = "Activation subgroup (zero baseline)")
stopifnot(all(sec$analysis %in% names(lab_sec)))
sec$label <- lab_sec[sec$analysis]; sec$p_show <- ifelse(sec$method == "RI", sec$p_ri, sec$p_hc3)
forest <- rbind(data.frame(label = ifelse(prim$outcome == "Reporters", "Reporters (secondary outcome)", "Sampling-effort participants (primary outcome)"),
                           hypothesis = prim$hypothesis, estimate = prim$estimate, ci_low = prim$ci_low, ci_high = prim$ci_high, pct = prim$pct, p_show = prim$p_ri, method = "RI"),
                data.frame(label = sec$label, hypothesis = sec$hypothesis, estimate = sec$estimate, ci_low = sec$ci_low, ci_high = sec$ci_high,
                           pct = sec$pct_vs_control, p_show = sec$p_show, method = sec$method))
row_order <- c("Sampling-effort participants (primary outcome)", "Reporters (secondary outcome)", "Presence attribution (tertiary outcome)",
               "Core subset (least grid-blurred)", "Activation subgroup (zero baseline)", "Equal-exposure adjustment", "Minimum-delivery subset")
forest$label <- factor(forest$label, rev(row_order))
forest$hyp_lab <- ifelse(forest$hypothesis == "H1", "H1: framed vs neutral ads", "H2: ads vs no ads")
forest$note <- sprintf("%+.0f%%, %s %s", forest$pct, forest$method, p_lab(forest$p_show))
fig3 <- ggplot(forest, aes(x = estimate, y = label)) + geom_vline(xintercept = 0, colour = "grey55", linewidth = 0.4) +
  geom_errorbar(aes(xmin = ci_low, xmax = ci_high), width = 0.25, colour = "grey30", linewidth = 0.4) +
  geom_point(aes(shape = method), size = 2.2, fill = "white") +
  scale_shape_manual(values = c(RI = 16, HC3 = 22), name = NULL, breaks = c("RI", "HC3"),
                     labels = c(RI = "Randomization inference (RI)", HC3 = "HC3 regression")) +
  geom_text(aes(x = ci_high, label = note), hjust = -0.08, size = 2.4, colour = "grey20") +
  facet_wrap(~hyp_lab) + scale_x_continuous(expand = expansion(mult = c(0.04, 0.85))) +
  labs(x = "Difference in participants (or reporters) per municipality, with 95% CI", y = NULL) +
  theme(panel.spacing.x = unit(1, "lines"), strip.text = element_text(face = "bold"))
save_fig(fig3, "fig3_forest_estimates", WIDE, 3.1)

# --- Figure 4: levels, activation, season ----------------------------------------------
ci <- function(x) { m <- mean(x); s <- sd(x) / sqrt(length(x)); c(m, m - 1.96 * s, m + 1.96 * s) }
means <- do.call(rbind, lapply(arm_levels, function(g) { k <- a$arm == g
  rbind(data.frame(arm = g, window = "Pre-window (16 Jun–14 Aug)", t(ci(o$pre_participants[k]))),
        data.frame(arm = g, window = "Post-window (16 Aug–14 Oct)", t(ci(o$post_participants[k])))) }))
names(means)[3:5] <- c("mean", "lo", "hi"); means$arm <- factor(means$arm, arm_levels); means$window <- factor(means$window, unique(means$window))
pA4 <- ggplot(means, aes(short_labels[as.character(arm)], mean, colour = arm, shape = window)) +
  geom_pointrange(aes(ymin = lo, ymax = hi), position = position_dodge(width = 0.5), size = 0.35, linewidth = 0.5) +
  scale_shape_manual(values = c(1, 16), name = NULL) + scale_colour_manual(values = arm_cols, guide = "none") +
  guides(shape = guide_legend(nrow = 2)) + labs(x = NULL, y = "Participants per municipality\n(mean and 95% CI)")
zero <- a$median_pre_participants == 0
act <- do.call(rbind, lapply(arm_levels, function(g) { k <- zero & a$arm == g; x <- sum(o$post_participants[k] > 0); n <- sum(k)
  w <- binom.test(x, n)$conf.int; data.frame(arm = g, share = x / n, lo = w[1], hi = w[2], n = n) }))
act$arm <- factor(act$arm, arm_levels)
pB4 <- ggplot(act, aes(short_labels[as.character(arm)], share, fill = arm)) + geom_col(width = 0.6) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.15, linewidth = 0.4) +
  scale_x_discrete(labels = setNames(sprintf("%s\n(n = %d)", short_labels[as.character(act$arm)], act$n), short_labels[as.character(act$arm)])) +
  scale_fill_manual(values = arm_cols, guide = "none") + scale_y_continuous(labels = percent) +
  labs(x = NULL, y = "Zero-baseline municipalities with any\nparticipant in the post-window (95% CI)")
w <- read.csv(file.path("data", "raw", "participants_spain_municipality_aug_windows_2026-10.csv"))
w$unit_name <- paste(w$NAME_4, w$NAME_2, sep = ", ")
w <- w[w$window_complete %in% c(TRUE, "TRUE") & w$year >= 2021, ]
stopifnot(all(a$unit_name %in% w$unit_name))
season <- rbind(cbind(scope = "All Spain", w %>% group_by(year, period) %>% summarise(n = sum(n_participants), .groups = "drop")),
                cbind(scope = "949 study municipalities", w[w$unit_name %in% a$unit_name, ] %>% group_by(year, period) %>% summarise(n = sum(n_participants), .groups = "drop")))
season$period <- factor(season$period, c("before", "after"), c("Pre-window", "Post-window")); season$scope <- factor(season$scope, unique(season$scope))
pC4 <- ggplot(season, aes(factor(year), n, fill = period)) + geom_col(position = position_dodge(width = 0.7), width = 0.65) +
  facet_wrap(~scope, ncol = 1, scales = "free_y") + scale_fill_manual(values = c("grey70", "grey35"), name = NULL) +
  scale_y_continuous(transform = "log10", labels = comma) + labs(x = NULL, y = "Participants (log scale)") +
  theme(strip.text = element_text(face = "bold", hjust = 0))
save_fig(plot_grid(pA4, pB4, pC4, labels = c("a", "b", "c"), label_size = 11, ncol = 3, rel_widths = c(1.05, 1, 1.15)),
         "fig4_outcomes_activation_season", WIDE, 3.2)

# --- tables ----------------------------------------------------------------------------
esc <- function(x) { x <- gsub("%", "\\\\%", x); x <- gsub("_", "\\\\_", x); x <- gsub("—", "---", x); gsub("–", "--", x) }
tex_table <- function(df, path, align) {
  body <- apply(df, 1, function(r) paste(esc(r), collapse = " & "))
  writeLines(c(sprintf("\\begin{tabular}{%s}", align), "\\toprule", paste(esc(names(df)), collapse = " & "), "\\midrule",
               paste0(body, " \\\\"), "\\bottomrule", "\\end{tabular}") |> (\(l) { l[3] <- paste(l[3], "\\\\"); l })(), path)
  cat("  wrote", basename(path), "\n")
}
NA_CELL <- "--"
by_arm <- function(f) vapply(arm_levels, function(g) f(a$arm == g), numeric(1))
t1 <- data.frame(check.names = FALSE, ` ` = character(0), Framed = character(0), Neutral = character(0), `No ads` = character(0))
add <- function(label, cells) t1[nrow(t1) + 1, ] <<- c(label, cells)
ad_only <- function(f) c(vapply(c("framed", "neutral"), function(g) f(a$arm == g), character(1)), NA_CELL)
add("Municipalities", fmt0(by_arm(sum)))
add("Zero-baseline municipalities", fmt0(by_arm(function(k) sum(a$median_pre_participants[k] == 0))))
add("Historical median participants (post-window), mean", fmt(by_arm(function(k) mean(a$median_post_participants[k])), 2))
add("Pre-window participants in 2026, mean", fmt(by_arm(function(k) mean(o$pre_participants[k])), 2))
add("Campaigns", c("10", "10", NA_CELL))
add("Budget (EUR)", c("2,500", "2,500", NA_CELL))
add("Spend (EUR)", ad_only(function(k) fmt(sum(a$cost[k]), 2)))
add("Impressions", ad_only(function(k) fmt0(sum(a$impressions[k]))))
add("Installs", ad_only(function(k) fmt0(sum(a$installs[k]))))
add("Installs per municipality, mean (median)", ad_only(function(k) sprintf("%.1f (%.0f)", mean(a$installs[k]), median(a$installs[k]))))
add("Municipalities with zero installs", ad_only(function(k) fmt0(sum(a$installs[k] == 0))))
add("Cost per install (EUR)", ad_only(function(k) fmt(sum(a$cost[k]) / sum(a$installs[k]), 3)))
tex_table(t1, file.path(tabdir, "tab1_design_delivery.tex"), "lrrr")

t2 <- data.frame(check.names = FALSE, Outcome = ifelse(prim$outcome == "Reporters", "Reporters", "Sampling effort"),
                 Test = ifelse(prim$hypothesis == "H1", "H1 framed vs neutral", "H2 ads vs none"),
                 Estimate = sg(prim$estimate), Change = pct_tex(prim$pct), `$p$ (RI)` = p_tex(prim$p_ri), `$p$ (HC3)` = p_tex(prim$p_hc3),
                 `95% CI` = sprintf("%s to %s", sg(prim$ci_low), sg(prim$ci_high)), `$n$` = fmt0(prim$n))
tex_table(t2, file.path(tabdir, "tab2_primary_results.tex"), "llrrrrlr")

s <- sec[order(match(sec$label, row_order), sec$hypothesis), ]
short_lab <- c("Presence attribution (tertiary outcome)" = "Presence attribution", "Core subset (least grid-blurred)" = "Core subset",
               "Activation subgroup (zero baseline)" = "Activation subgroup", "Equal-exposure adjustment" = "Equal exposure",
               "Minimum-delivery subset" = "Minimum delivery")
t3 <- data.frame(check.names = FALSE, Analysis = short_lab[s$label], Test = s$hypothesis, Method = s$method, `$n$` = fmt0(s$n_units),
                 Estimate = sg(s$estimate), Change = pct_tex(s$pct_vs_control), `$p$` = p_tex(s$p_show),
                 `95% CI` = sprintf("%s to %s", sg(s$ci_low), sg(s$ci_high)))
tex_table(t3, file.path(tabdir, "tab3_secondary_analyses.tex"), "lllrrrrl")

camp <- dd %>% group_by(campaign) %>% arrange(date) %>%
  summarise(spend = sum(cost), installs = sum(installs), crossed = { cs <- cumsum(cost); if (any(cs >= 250)) format(date[which(cs >= 250)[1]], "%d %b") else "no" },
            last_spend = format(max(date[cost > 0]), "%d %b"), .groups = "drop") %>% arrange(campaign)
tS1 <- data.frame(check.names = FALSE, Campaign = camp$campaign, `Spend (EUR)` = fmt(camp$spend, 2), Installs = fmt0(camp$installs),
                  `Per install (EUR)` = fmt(camp$spend / camp$installs, 3), `Cap reached` = camp$crossed, `Last spend` = camp$last_spend)
tex_table(tS1, file.path(tabdir, "tabS1_campaigns.tex"), "lrrrll")

cap <- function(x) paste0(toupper(substring(x, 1, 1)), substring(x, 2))
o1 <- ori[ori$level == "arm x orientation", ]; o2 <- ori[ori$level == "arm x orientation x theme", ]
tot <- function(arm) sum(o1$impressions[o1$arm == arm])
rows <- list()
for (orn in c("prevention", "promotion")) {
  r1 <- o1[o1$arm == "framed" & o1$orientation == orn, ]
  rows[[length(rows) + 1]] <- data.frame(check.names = FALSE, Arm = "Framed", Orientation = paste("Framed:", cap(orn)), Theme = "all themes", imp = r1$impressions, inst = r1$installs, cost = r1$cost)
  for (th in sort(unique(o2$theme[o2$orientation == orn]))) { r2 <- o2[o2$arm == "framed" & o2$orientation == orn & o2$theme == th, ]
    rows[[length(rows) + 1]] <- data.frame(check.names = FALSE, Arm = "", Orientation = "", Theme = paste0("\\quad ", th), imp = r2$impressions, inst = r2$installs, cost = r2$cost) }
}
rn <- o1[o1$arm == "neutral", ]
rows[[length(rows) + 1]] <- data.frame(check.names = FALSE, Arm = "Neutral", Orientation = "Neutral", Theme = "single ad group", imp = rn$impressions, inst = rn$installs, cost = rn$cost)
r <- do.call(rbind, rows); r$share <- r$imp / ifelse(r$Arm == "Neutral", tot("neutral"), tot("framed"))
tS2 <- data.frame(check.names = FALSE, Orientation = r$Orientation, Theme = r$Theme, Impressions = fmt0(r$imp),
                  `Share` = sprintf("%.0f%%", 100 * r$share), Installs = fmt0(r$inst), Cost = fmt(r$cost, 2), `Cost/install` = fmt(r$cost / r$inst, 3))
tex_table(tS2, file.path(tabdir, "tabS2_orientation_theme.tex"), "llrrrrr")

msd <- function(x) sprintf("%.2f (%.2f)", mean(x), sd(x))
tS3 <- data.frame(check.names = FALSE, Covariate = c("Historical median participants (post-window)", "Historical median participants (pre-window)",
                                                     "Pre-window participants, 2026", "Pre-window reporters, 2026", "Interior cell fraction", "Area (km$^2$)", "Core subset (share)"),
                  Framed = "", Neutral = "", `No ads` = "")
for (j in 1:3) { k <- a$arm == arm_levels[j]
  tS3[, j + 1] <- c(msd(a$median_post_participants[k]), msd(a$median_pre_participants[k]), msd(o$pre_participants[k]), msd(o$pre_reporters[k]),
                    msd(a$interior_frac[k]), msd(a$area_km2[k]), sprintf("%.2f", mean(a$core_subset[k] %in% c(TRUE, "TRUE")))) }
tex_table(tS3, file.path(tabdir, "tabS3_balance.tex"), "lrrr")
cat("done\n")
