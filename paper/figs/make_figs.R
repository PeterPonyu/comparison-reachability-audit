# Figure entry point for 002. Emits into figs/out/.
# Refuses to draw anything that is not bound in evidence/evidence_manifest.json.
#
# Side effect by design: also writes tex/generated_numbers.tex and the generated
# result tables, so no quantity in the manuscript is retyped by hand.
#
# Run from the paper directory:  Rscript figs/make_figs.R

suppressPackageStartupMessages({
  library(ggplot2)
  library(jsonlite)
})

source(file.path("figs", "rtx_theme.R"))

out_dir <- file.path("figs", "out")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

find_repo_root <- function(start = normalizePath(".")) {
  cur <- start
  repeat {
    if (file.exists(file.path(cur, ".git"))) return(cur)
    nxt <- dirname(cur)
    if (identical(nxt, cur)) stop("no repository root above ", start)
    cur <- nxt
  }
}

repo_root <- find_repo_root()

manifest <- jsonlite::fromJSON(file.path("evidence", "evidence_manifest.json"),
                               simplifyVector = TRUE)
if (!identical(manifest$state, "BOUND") || length(manifest$entries) == 0) {
  stop("evidence manifest is not BOUND; bind the evidence before drawing anything.")
}

bound_path <- function(id) {
  row <- manifest$entries[manifest$entries$id == id, ]
  if (nrow(row) != 1L) stop("no unique evidence entry bound under id ", id)
  path <- file.path(repo_root, row$path[[1]])
  if (!file.exists(path)) stop("bound evidence has disappeared: ", id)
  actual <- digest::digest(path, algo = "sha256", file = TRUE)
  if (!identical(actual, row$sha256[[1]])) stop("bound evidence drifted on disk: ", id)
  path
}

read_bound <- function(id) jsonlite::fromJSON(bound_path(id), simplifyVector = TRUE)

probe <- read_bound("E-PROBE")
sweep <- read_bound("E-SWEEP")
paired <- read_bound("E-PAIRED")
inventory <- read_bound("E-INVENTORY")
warehouse <- readLines(bound_path("E-WAREHOUSE"), warn = FALSE)

REACHABLE <- "reachable here"
BROKEN <- "not reachable here"
status_colours <- c("#D9EAD3", "#F6CFCF")
names(status_colours) <- c(REACHABLE, BROKEN)

save_fig <- function(plot, name, width, height) {
  ggplot2::ggsave(file.path(out_dir, paste0(name, ".pdf")), plot,
                  width = width, height = height, units = "in", device = cairo_pdf)
  invisible(NULL)
}

## ---------------------------------------------------------------------------
## Figure 1 -- the reachability ladder, as observed rather than as recorded.
## ---------------------------------------------------------------------------

rungs <- probe$rungs
vendor <- rungs$observed[[2]]
runtime <- rungs$observed[[3]]

observation <- c(
  "A citable published record for the reference implementation exists.",
  sprintf(paste("Source tree present at a fixed revision matching the recorded pin;",
                "all %d recorded entry points found."),
          vendor$entrypoints_found),
  paste("The interpreter the source requires does not resolve on this machine.",
        "A commonly suggested substitute is also absent, and would not count if present."),
  "Not attempted. Unreachable through the rung below; no table is synthesised."
)

wrap_to <- function(x, width = 88) {
  vapply(x, function(s) paste(strwrap(s, width = width), collapse = "\n"), character(1),
         USE.NAMES = FALSE)
}
sentence_case <- function(x) paste0(toupper(substr(x, 1, 1)), substring(x, 2))

ladder <- data.frame(
  y = rungs$rung,
  label = sprintf("Rung %d.  %s", rungs$rung, sentence_case(rungs$assertion)),
  observation = wrap_to(observation),
  status = ifelse(rungs$reachable, REACHABLE, BROKEN),
  stringsAsFactors = FALSE
)

first_break <- probe$first_break
corpus_note <- wrap_to(paste(
  "Separate axis: the evaluation corpus is publicly archived and openly downloadable,",
  "but is not present on this machine. A resolvable link is not a local asset."
))

fig1 <- ggplot(ladder) +
  geom_rect(aes(xmin = 0, xmax = 1, ymin = y - 0.40, ymax = y + 0.40, fill = status),
            colour = "grey25", linewidth = 0.3) +
  geom_text(aes(x = 0.018, y = y + 0.19, label = label),
            hjust = 0, vjust = 0.5, size = 2.9, fontface = "bold", colour = "grey10") +
  geom_text(aes(x = 0.018, y = y - 0.17, label = observation),
            hjust = 0, vjust = 0.5, size = 2.3, colour = "grey25", lineheight = 0.98) +
  annotate("segment", x = 1.035, xend = 1.035,
           y = first_break + 0.42, yend = 0.7, colour = "#B2182B", linewidth = 0.5,
           arrow = grid::arrow(length = unit(0.06, "in"), type = "closed")) +
  annotate("text", x = 1.055, y = (first_break + 0.7) / 2 + 0.25,
           label = "everything above\nthe first break is\nunreachable too",
           hjust = 0, size = 2.3, colour = "#B2182B", lineheight = 0.98) +
  annotate("rect", xmin = 0, xmax = 1, ymin = 0.14, ymax = 0.62,
           fill = "grey93", colour = "grey60", linewidth = 0.25) +
  annotate("text", x = 0.018, y = 0.38, label = corpus_note,
           hjust = 0, vjust = 0.5, size = 2.3, colour = "grey25", lineheight = 0.98) +
  scale_fill_manual(values = status_colours, name = NULL,
                    breaks = c(REACHABLE, BROKEN)) +
  scale_x_continuous(limits = c(0, 1.30), expand = expansion(add = 0.01)) +
  scale_y_continuous(expand = expansion(add = 0.22)) +
  theme_void(base_size = 9) +
  theme(legend.position = "top",
        legend.margin = margin(0, 0, -2, 0),
        legend.key.size = unit(0.16, "in"),
        plot.margin = margin(2, 2, 2, 2))

save_fig(fig1, "fig1_reachability_ladder", 6.4, 3.9)

## ---------------------------------------------------------------------------
## Figure 2 -- the part that IS reproducible, including the condition where the
## more sophisticated method loses badly. Log axis because the arms differ by
## more than two orders of magnitude at one condition.
## ---------------------------------------------------------------------------

sr <- sweep$results
arm_labels <- c(naive = "Offset-agnostic least squares",
                aware = "Offset-aware maximum a posteriori")
arm_colours <- c("#B2182B", "#2166AC")
names(arm_colours) <- arm_labels

f2 <- data.frame(
  offset = rep(sr$offset_std_ms, 2L),
  arm = factor(rep(arm_labels, each = nrow(sr)), levels = arm_labels),
  median_err = c(sr$naive_median_err_m, sr$aware_median_err_m)
)

fig2 <- ggplot(f2, aes(offset, median_err, colour = arm, shape = arm)) +
  # Finite bounds: an infinite ymin is undefined once the axis is log-scaled.
  annotate("rect", xmin = -3.2, xmax = 2.5, ymin = 5e-4, ymax = 5,
           fill = "grey90", alpha = 0.7) +
  annotate("text", x = 3.4, y = 0.006,
           label = "no offsets present:\nthe offset-aware method\nestimates what is not there",
           hjust = 0, size = 2.4, colour = "grey25", lineheight = 0.95) +
  geom_line(linewidth = 0.5) +
  geom_point(size = 2, fill = "white", stroke = 0.5) +
  scale_colour_manual(values = arm_colours, name = NULL) +
  scale_shape_manual(values = c(21, 24), name = NULL) +
  scale_x_continuous(name = "Dispersion of the unknown per-channel offsets (ms)",
                     breaks = sr$offset_std_ms) +
  scale_y_log10(name = "Median localisation error (m)",
                breaks = c(0.001, 0.01, 0.1, 1),
                labels = c("0.001", "0.01", "0.1", "1")) +
  annotation_logticks(sides = "l", linewidth = 0.25,
                      short = unit(0.03, "in"), mid = unit(0.045, "in"),
                      long = unit(0.06, "in")) +
  rtx_theme() +
  theme(legend.position = c(0.99, 0.03), legend.justification = c(1, 0),
        legend.background = element_rect(fill = "white", colour = "grey70",
                                         linewidth = 0.25),
        legend.margin = margin(2, 4, 2, 4))

save_fig(fig2, "fig2_offset_sweep", 5.8, 3.4)

## ---------------------------------------------------------------------------
## Figure 3 -- the same comparison as a per-trial win count, which shows the
## zero-offset condition is unanimous rather than merely significant.
## ---------------------------------------------------------------------------

pr <- paired$rows
f3 <- data.frame(
  offset = factor(pr$offset_std_ms, levels = pr$offset_std_ms),
  wins = pr$n_trials_aware_better,
  n = pr$n_pairs
)
f3$losses <- f3$n - f3$wins

fig3 <- ggplot(f3, aes(offset, wins)) +
  geom_hline(yintercept = f3$n[1] / 2, linetype = "22", colour = "grey35",
             linewidth = 0.35) +
  geom_col(aes(fill = wins == 0), width = 0.66, colour = "grey20", linewidth = 0.25) +
  geom_text(aes(label = sprintf("%d/%d", wins, n)), vjust = -0.5, size = 2.5) +
  annotate("text", x = 0.55, y = f3$n[1] / 2, label = "a coin flip",
           hjust = 0, vjust = -0.5, size = 2.4, colour = "grey30") +
  scale_fill_manual(values = c(`FALSE` = "#2166AC", `TRUE` = "#B2182B"), guide = "none") +
  scale_x_discrete(name = "Dispersion of the unknown per-channel offsets (ms)") +
  scale_y_continuous(name = "Trials where the offset-aware method won",
                     limits = c(0, f3$n[1] * 1.12),
                     breaks = seq(0, f3$n[1], 10)) +
  rtx_theme()

save_fig(fig3, "fig3_paired_wins", 5.8, 2.9)

## ---------------------------------------------------------------------------
## Generated LaTeX.
## ---------------------------------------------------------------------------

fmt <- function(x, digits = 3) formatC(x, format = "f", digits = digits)

p_cell <- function(p) {
  if (is.na(p)) return("---")
  if (p >= 0.01) formatC(p, format = "f", digits = 3) else format(signif(p, 3), scientific = TRUE)
}

zero <- sr[sr$offset_std_ms == 0, ]
zero_pair <- pr[pr$offset_std_ms == 0, ]
worst <- sr[which.max(sr$offset_std_ms), ]
worst_pair <- pr[which.max(pr$offset_std_ms), ]

# Derived from the bound warehouse text rather than retyped, so a change to the
# recorded corpus size cannot silently disagree with the manuscript.
corpus_gb <- regmatches(paste(warehouse, collapse = " "),
                        regexpr("[0-9]+(?=GB)", paste(warehouse, collapse = " "), perl = TRUE))

blocked_tiers <- sum(vapply(
  list(read_bound("E-PRIMARY"), read_bound("E-SOTACOPY"), read_bound("E-STATIC")),
  function(x) identical(x$status, "blocked"), logical(1)
))

macro <- function(name, value) sprintf("\\newcommand{\\%s}{%s}", name, value)

numbers <- c(
  "% Generated by the figure script from hash-bound evidence. Do not hand-edit.",
  macro("NRungs", nrow(ladder)),
  macro("FirstBreak", first_break),
  macro("EntryPoints", vendor$entrypoints_found),
  macro("BlockedTiers", blocked_tiers),
  macro("CorpusGB", corpus_gb),
  macro("ProbeDate", substr(probe$observed_utc, 1, 10)),
  macro("NTrials", zero_pair$n_pairs),
  macro("NConditions", nrow(sr)),
  macro("ZeroNaiveMedian", fmt(zero$naive_median_err_m, 4)),
  macro("ZeroAwareMedian", fmt(zero$aware_median_err_m, 3)),
  macro("ZeroRatio", formatC(zero$aware_median_err_m / zero$naive_median_err_m,
                             format = "d", big.mark = ",")),
  macro("ZeroWins", zero_pair$n_trials_aware_better),
  macro("ZeroP", format(signif(zero_pair$p_two_sided, 3), scientific = TRUE)),
  macro("MaxOffset", worst$offset_std_ms),
  macro("MaxOffsetNaive", fmt(worst$naive_median_err_m, 3)),
  macro("MaxOffsetAware", fmt(worst$aware_median_err_m, 3)),
  macro("MaxOffsetWins", worst_pair$n_trials_aware_better),
  macro("AwareFloorLow", fmt(min(sr$aware_median_err_m[sr$offset_std_ms > 0]), 3)),
  macro("AwareFloorHigh", fmt(max(sr$aware_median_err_m[sr$offset_std_ms > 0]), 3)),
  macro("NaiveRangeLow", fmt(min(sr$naive_median_err_m[sr$offset_std_ms > 0]), 3)),
  macro("NaiveRangeHigh", fmt(max(sr$naive_median_err_m[sr$offset_std_ms > 0]), 3)),
  macro("SweepSeed", sweep$seed),
  macro("NonZeroConditions", sum(sr$offset_std_ms > 0))
)

writeLines(numbers, file.path("tex", "generated_numbers.tex"))

ladder_tab <- c(
  "% Generated by the figure script from hash-bound evidence. Do not hand-edit.",
  "\\begin{tabular}{clp{0.44\\linewidth}c}",
  "\\toprule",
  "Rung & Assertion & What was observed & Status \\\\",
  "\\midrule",
  paste0(
    ladder$y, " & ",
    c("Citable record", "Source at a fixed revision", "Required runtime present",
      "Published table recomputable"), " & ",
    ladder$observation, " & ",
    ifelse(rungs$reachable, "reachable", "\\textbf{broken}"),
    " \\\\"
  ),
  "\\bottomrule",
  "\\end{tabular}"
)
writeLines(ladder_tab, file.path("tex", "generated_table_ladder.tex"))

sweep_tab <- c(
  "% Generated by the figure script from hash-bound evidence. Do not hand-edit.",
  "\\begin{tabular}{rrrrrc}",
  "\\toprule",
  paste("Offset s.d. (ms) & Agnostic (m) & Aware (m) & Paired diff. (m) &",
        "Aware wins & Exact $p$ \\\\"),
  "\\midrule",
  paste0(
    sr$offset_std_ms, " & ",
    fmt(sr$naive_median_err_m, 4), " & ",
    fmt(sr$aware_median_err_m, 4), " & ",
    sprintf("%+.4f", pr$median_paired_diff_naive_minus_aware_m), " & ",
    sprintf("%d/%d", pr$n_trials_aware_better, pr$n_pairs), " & ",
    vapply(pr$p_two_sided, p_cell, character(1)),
    " \\\\"
  ),
  "\\bottomrule",
  "\\end{tabular}"
)
writeLines(sweep_tab, file.path("tex", "generated_table_sweep.tex"))

message(sprintf("wrote 3 figures to %s and 3 generated tex files to tex/", out_dir))
