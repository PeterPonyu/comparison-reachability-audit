# Figure entry point for 002. Emits into figs/out/.
# Refuses to draw anything that is not bound in evidence/evidence_manifest.json.
#
# Side effect by design: also writes tex/generated_numbers.tex and the generated
# result tables, so no quantity in the manuscript is retyped by hand.
#
# The work is split so that each file has one reason to change: figs/lib holds
# reading, the ladder, the record checks and formatting; figs/panels holds one
# figure each; this file holds the order they run in and the checks that must
# pass before any of them run.
#
# Run from the paper directory:  Rscript figs/make_figs.R

suppressPackageStartupMessages({
  library(ggplot2)
  library(jsonlite)
  library(patchwork)
})

for (unit in c("rtx_theme.R", "lib/evidence.R", "lib/emit.R", "lib/ladder.R",
               "lib/sweep.R", "lib/complement.R", "lib/breakeven.R")) {
  source(file.path("figs", unit))
}

dir.create(file.path("figs", "out"), showWarnings = FALSE, recursive = TRUE)

manifest <- load_manifest()
read_bound <- evidence_reader(manifest, find_repo_root())

probe <- read_bound$json("E-PROBE")
sweep <- read_bound$json("E-SWEEP")
paired <- read_bound$json("E-PAIRED")
inventory <- read_bound$json("E-INVENTORY")

## ---------------------------------------------------------------------------
## The ladder. Built once because both the figure and the table label it.
## ---------------------------------------------------------------------------

REACHABLE <- "reachable here"
BROKEN <- "not reachable here"
status_colours <- c("#D9EAD3", "#F6CFCF")
names(status_colours) <- c(REACHABLE, BROKEN)

rungs <- probe$rungs
vendor <- rungs$observed[[2]]
assert_probe_matches_bridge(vendor, read_bound$json("E-BRIDGE"))
ladder <- build_ladder(rungs, REACHABLE, BROKEN)
FIRST_BREAK <- probe$first_break

# The arrow in the figure and the claim in the prose both say that the break is
# what makes the top rung unreachable. That reading only holds while the rung
# the probe names as the first break is in fact the lowest one that failed.
if (!identical(as.integer(FIRST_BREAK), as.integer(min(ladder$y[!ladder$reachable])))) {
  stop("the probe names a first break that is not the lowest rung that failed")
}

## ---------------------------------------------------------------------------
## The reproducible half: one summary row and one per-trial contest per offset.
## ---------------------------------------------------------------------------

sr <- sweep$results
pr <- paired$rows
assert_sweep_matches_paired(sr, pr)

# The two ladder-tier summaries record one condition of this same sweep. Nothing
# in the manuscript displays them: they carry means, and the display rule keeps
# means out of the headline quantities. They were bound anyway, and until now
# nothing read them -- which is the state in which an artifact can go stale
# without anyone noticing, because a digest only proves the bytes have not
# changed, not that they still agree with what the analysis says. Reading them
# here as a consistency check is what makes binding them mean something.
assert_tier_summaries_match_sweep(sr,
                                  read_bound$json("E-NAIVE"),
                                  read_bound$json("E-AWARE"))

arm_labels <- c(naive = "Offset-agnostic least squares",
                aware = "Offset-aware maximum a posteriori")
arm_colours <- c("#B2182B", "#2166AC")
names(arm_colours) <- arm_labels

## ---------------------------------------------------------------------------
## The third comparison, and the three rules a reader could read it under.
##
## This record is the only one in the set that carries both a cell summary of
## the kind a paper prints and the per-trial pairs that summary came from, which
## is what makes the two readable against each other at all.
## ---------------------------------------------------------------------------

complement <- read_bound$json_with_absences("E-COMPLEMENT")
cx <- complement$data
assert_declared_display(cx)

# Named for what each estimator is given rather than for whose method it is.
# Both arms are local re-implementations; neither is anyone's released code, and
# attaching an author's name to an arm whose behaviour we then report would
# assert something about their work that this record cannot support.
CX_FULL <- "Both measurement sets"
CX_REDUCED <- "One measurement set"
cx_colours <- c("#1B7837", "#762A83")
names(cx_colours) <- c(CX_FULL, CX_REDUCED)

# A figure has room for the full name in a legend; a table column three across
# does not, and a table that runs into the margin is not more informative for
# having spelled the arm out. The caption carries the definition either way.
CX_SHORT <- c("both sets", "one set")
names(CX_SHORT) <- c(CX_FULL, CX_REDUCED)

cx_cells <- cx$cells
cx_sigma <- cx_cells$tdoa_sigma_s
cx_trials <- cx$trials_by_sigma[
  vapply(cx_sigma, function(s) which.min(abs(as.numeric(names(cx$trials_by_sigma)) - s)),
         integer(1))]

CX_COMPARISONS <- lapply(seq_along(cx_sigma), function(i) {
  tr <- cx_trials[[i]]
  full <- cx_cells$hybrid_gn_python[i, ]
  reduced <- cx_cells$su_tdoa_s_only[i, ]
  tag <- paste0(sigma_us(cx_sigma[i]), " us")
  assert_cell_matches_trials(full, tr$hybrid$mic_rmse_m, "mic_rmse_m",
                             paste(tag, "full"))
  assert_cell_matches_trials(reduced, tr$su$mic_rmse_m, "mic_rmse_m",
                             paste(tag, "reduced"))
  assert_efficiency_matches(full, tr$hybrid$mic_rmse_m, tr$hybrid$mic_crlb_m,
                            paste(tag, "full"))
  assert_efficiency_matches(reduced, tr$su$mic_rmse_m, tr$su$mic_crlb_m,
                            paste(tag, "reduced"))
  c(compare_condition(tr$hybrid$mic_rmse_m, tr$su$mic_rmse_m, CX_FULL, CX_REDUCED),
    list(sigma_s = cx_sigma[i],
         eff = c(full_mean = full$rmse_over_crlb_mic,
                 full_median = full$rmse_over_crlb_mic_median,
                 reduced_mean = reduced$rmse_over_crlb_mic,
                 reduced_median = reduced$rmse_over_crlb_mic_median)))
})

# Every measurement the record failed to produce should be accounted for twice:
# once as a bare non-finite token in the bytes, and once as a value this
# analysis reads as absent. If the two counts drift apart, some absence is being
# handled somewhere other than here, which is the failure this whole section is
# about.
CX_DROPPED <- sum(vapply(CX_COMPARISONS, function(x) x$dropped, integer(1)))
if (!identical(complement$n_absences, count_absent_measurements(cx_trials))) {
  stop("the record's non-finite tokens and the absences this analysis sees do not agree")
}
CX_FAILED_RUNS <- complement$n_absences %/% length(ESTIMATED_QUANTITIES)
if (CX_FAILED_RUNS != CX_DROPPED) {
  stop("a failed run is not costing exactly one pair")
}

CX_PAIRS <- sum(vapply(CX_COMPARISONS, function(x) x$n_pairs, integer(1)))
CX_PLANNED <- sum(vapply(CX_COMPARISONS, function(x) x$n_planned, integer(1)))

# The condition the argument is made on, chosen for having nothing missing. At a
# condition where a run failed, a reader can always answer that the mean and the
# median disagree because one of them had to drop a trial. Where every planned
# trial produced an error in both arms, that answer is not available and the
# disagreement can only be the summary.
CX_CLEAN <- Filter(function(x) x$dropped == 0L, CX_COMPARISONS)
if (length(CX_CLEAN) == 0L) {
  stop("no condition ran to completion in both arms; the clean demonstration is gone")
}
CX_CLEAN <- CX_CLEAN[[1]]
if (length(unique(CX_CLEAN$by_rule)) == 1L) {
  stop("the rules agree at the complete condition; the text says they do not")
}

CX_EFF <- vapply(CX_COMPARISONS, function(x) unname(x$eff[c("full_mean", "reduced_mean")]),
                 numeric(2))
CX_EFF_MEDIAN <- vapply(CX_COMPARISONS,
                        function(x) unname(x$eff[c("full_median", "reduced_median")]),
                        numeric(2))

# What the disclosure would have cost. The three objects are serialised by one
# writer at full precision so that the sizes are comparable to each other; they
# are a measure of the argument's price, not of any particular file format.
json_bytes <- function(x) {
  nchar(jsonlite::toJSON(x, digits = NA, auto_unbox = TRUE, null = "null"), type = "bytes")
}
CX_BYTES_CELLS <- json_bytes(cx_cells)
CX_BYTES_TRIALS <- json_bytes(cx_trials)
CX_BYTES_MINIMAL <- json_bytes(lapply(cx_trials, function(tr) {
  # The smallest thing that would have let a reader apply a rule of their own:
  # the two paired error columns, and nothing else.
  list(both_sets = tr$hybrid$mic_rmse_m, one_set = tr$su$mic_rmse_m)
}))

# The paper's sentence is that two rules read off the same trials disagree. It
# is worth nothing unless the trials really are the same ones, so the claim is
# made only about rules applied to a single set of pairs.
CX_RULE_WINNERS <- do.call(rbind, lapply(CX_COMPARISONS, function(x) x$by_rule))
CX_DISAGREEING <- sum(apply(CX_RULE_WINNERS, 1, function(r) length(unique(r)) > 1L))

## How much of the printed conclusion one trial is carrying. The curve is a
## measurement of leverage, not a proposal to trim: no number this paper reports
## as a result comes from a trimmed sample.
CX_TRIM_DEPTH <- 5L
CX_INFLUENCE <- do.call(rbind, lapply(seq_along(cx_sigma), function(i) {
  tr <- cx_trials[[i]]
  keep <- usable_pairs(tr$hybrid$mic_rmse_m, tr$su$mic_rmse_m)
  a <- sort(tr$hybrid$mic_rmse_m[keep], decreasing = TRUE)
  b <- sort(tr$su$mic_rmse_m[keep], decreasing = TRUE)
  do.call(rbind, lapply(0:CX_TRIM_DEPTH, function(k) {
    trimmed <- function(v) mean(v[seq.int(k + 1L, length(v))])
    data.frame(sigma_s = cx_sigma[i], excluded = k,
               mean_gap = trimmed(a) - trimmed(b),
               median_gap = stats::median(a) - stats::median(b))
  }))
}))

# The depth at which the mean first names the estimator the median and the
# paired test already named. Computed, not asserted, because the whole point is
# how small it turns out to be.
CX_FLIP_DEPTH <- vapply(split(CX_INFLUENCE, CX_INFLUENCE$sigma_s), function(g) {
  g <- g[order(g$excluded), ]
  agree <- sign(g$mean_gap) == sign(g$median_gap)
  if (!any(agree)) NA_integer_ else as.integer(g$excluded[which(agree)[1]])
}, integer(1))

## ---------------------------------------------------------------------------
## The condition the coarse grid never ran.
##
## The offset sweep above attaches its reversal to a single point, offsets
## exactly zero, because its grid has nothing between zero and its lowest
## non-zero level. This record refines the grid inside that interval and crosses
## it with independent rooms, so that the dispersion at which the ordering
## changes sign can be located rather than assumed to sit at zero.
## ---------------------------------------------------------------------------

fine <- read_bound$json("E-FINE")
cross <- read_bound$json("E-CROSS")
geom20 <- read_bound$json("E-GEOM20")

assert_derived_reads_the_bound_raw(cross, manifest, "E-FINE")
assert_grid_is_crossed(fine)
ROOMS <- room_list(cross)
assert_cells_match_trials(fine, ROOMS)
assert_crossings_match_cells(ROOMS)
FINE_ADDED_LEVELS <- assert_refinement_sits_in_the_gap(cross, sr$offset_std_ms)

# The rooms are named for how they were obtained, not for a file. One is the
# array the coarse sweep itself ran on, which is what makes its crossing
# comparable with the coarse record's own numbers; the rest are independent
# draws, recorded by the seed that produced them.
RECORDED_ROOM <- fine$geometries$id[[1]]
room_label <- function(id) if (identical(id, RECORDED_ROOM)) "as recorded" else
  paste("seed", sub("^draw-", "", id))

FINE_GAP <- breakeven_frame(ROOMS, room_label)

## The stored 20-geometry audit is a sensitivity analysis at the independent
## geometry level. Keep it separate from the six-room finite-grid estimand:
## this figure must not inherit FINE_GAP's room labels or trial denominator.
if (!identical(as.integer(geom20$n_geometries), 20L) ||
    !identical(geom20$resampling_unit, "independent room/source/microphone geometry")) {
  stop("E-GEOM20 is not the expected geometry-level audit")
}
GEOM20_LEVELS <- do.call(rbind, lapply(names(geom20$levels), function(level) {
  row <- geom20$levels[[level]]
  data.frame(offset = as.numeric(level), mean_gap = row$mean_naive_minus_aware_m,
             lower = row$bootstrap95_geometry_mean_m[[1]],
             upper = row$bootstrap95_geometry_mean_m[[2]],
             aware_wins = row$geometry_wins_aware,
             n_geometry = row$geometry_wins_total)
}))
if (any(!is.finite(unlist(GEOM20_LEVELS[c("offset", "mean_gap", "lower", "upper")])))) {
  stop("E-GEOM20 contains a non-finite plotting quantity")
}
CROSS_ANCHOR <- cross$at_the_coarse_grid_anchor
CROSS_MEDIAN <- cross$crossing_by_median
CROSS_PREDICTION <- cross$prediction_check
CROSS_INDEPENDENCE <- cross$cell_independence_check

if (!isTRUE(CROSS_INDEPENDENCE$all_identical)) {
  stop("a cell of the refined sweep did not reproduce when it was re-run alone")
}

# The two summary rules locate the same sign change in different places. The
# manuscript says so, and the range it quotes is computed here rather than read
# off a figure.
RULE_SEPARATION <- cross$where_the_rules_disagree$separation_ms
if (length(RULE_SEPARATION) == 0L) {
  stop("no room resolved a crossing under both rules; the comparison the text makes is gone")
}

# The crossings, censored where a room never crossed inside the refined grid.
# A room that has not crossed by the top of the grid has not measured a
# crossing, and recording the top level as its answer would invent one.
CROSSINGS <- do.call(rbind, lapply(ROOMS, function(room) {
  data.frame(
    room = room_label(room$geometry),
    median_ms = if (isTRUE(room$by_median$crossed_within_grid))
      room$by_median$settled_crossing_ms else NA_real_,
    paired_ms = if (isTRUE(room$by_paired$crossed_within_grid))
      room$by_paired$settled_crossing_ms else NA_real_,
    censored_above = if (isTRUE(room$by_median$crossed_within_grid)) NA_real_ else
      room$by_median$censored_above_ms,
    named_at_anchor = room$at_anchor$named_by_median,
    levels_named_agnostic = room$n_levels_named_agnostic,
    highest_named_agnostic = room$highest_level_named_agnostic,
    stringsAsFactors = FALSE
  )
}))
FINE_NONZERO_LEVELS <- sum(fine$levels_ms > 0)

## ---------------------------------------------------------------------------
## Figures. Each panel reads the objects above and writes one file.
## ---------------------------------------------------------------------------

for (unit in c("fig1_reachability_ladder.R", "fig2_offset_sweep.R",
               "fig3_paired_wins.R", "fig4_display_rule.R",
               "fig5_paired_trials.R", "fig6_influence.R",
               "fig7_efficiency.R", "fig8_breakeven.R",
               "fig9_robustness.R", "fig10_geometry_sensitivity.R")) {
  source(file.path("figs", "panels", unit))
}

## ---------------------------------------------------------------------------
## Numbers and tables. Emitted, never retyped.
## ---------------------------------------------------------------------------

zero <- sr[sr$offset_std_ms == 0, ]
zero_pair <- pr[pr$offset_std_ms == 0, ]
worst <- sr[which.max(sr$offset_std_ms), ]
worst_pair <- pr[which.max(pr$offset_std_ms), ]

# Derived from the bound inventory rather than retyped, so a change to the
# recorded corpus size cannot silently disagree with the manuscript. The
# inventory is the first-party record of what is and is not on disk, which is
# the fact this number states.
locata <- inventory$blockers$locata
corpus_gb <- regmatches(locata, regexpr("[0-9]+(?=GB)", locata, perl = TRUE))
if (length(corpus_gb) != 1L) {
  stop("the bound inventory does not record exactly one corpus size in GB")
}

blocked_tiers <- sum(vapply(
  list(read_bound$json("E-PRIMARY"), read_bound$json("E-SOTACOPY"),
       read_bound$json("E-STATIC")),
  function(x) identical(x$status, "blocked"), logical(1)
))

write_generated(c(
  macro("NRungs", nrow(ladder)),
  macro("FirstBreak", FIRST_BREAK),
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
  macro("NonZeroConditions", sum(sr$offset_std_ms > 0)),

  ## The third comparison, and the rules it can be read under.
  macro("CxConditions", length(CX_COMPARISONS)),
  macro("CxPlanned", CX_PLANNED),
  macro("CxPairs", CX_PAIRS),
  macro("CxTrialsPerCondition", single_valued(
    vapply(CX_COMPARISONS, function(x) x$n_planned, integer(1)),
    "how many trials each condition of the third comparison ran")),
  macro("CxRules", length(DISPLAY_RULES)),
  macro("CxDisagreeing", CX_DISAGREEING),
  macro("CxAgreeing", length(CX_COMPARISONS) - CX_DISAGREEING),
  macro("CxFailedRuns", CX_FAILED_RUNS),
  macro("CxAbsentValues", complement$n_absences),
  macro("CxFlipDepth", max(CX_FLIP_DEPTH)),
  macro("CxCleanSigma", sigma_us(CX_CLEAN$sigma_s)),
  macro("CxCleanMeanFull", fmt(CX_CLEAN$a$mean, 3)),
  macro("CxCleanMeanReduced", fmt(CX_CLEAN$b$mean, 3)),
  macro("CxCleanMedianFull", fmt(CX_CLEAN$a$median, 4)),
  macro("CxCleanMedianReduced", fmt(CX_CLEAN$b$median, 4)),
  macro("CxCleanWins", CX_CLEAN$wins_a),
  macro("CxCleanP", p_cell(CX_CLEAN$p_two_sided)),
  macro("CxCleanLeverage", formatC(CX_CLEAN$a$max_over_median, format = "d")),
  macro("CxCleanMeanWithoutMax", fmt(CX_CLEAN$a$mean_without_max, 4)),
  macro("CxPairedWinsLow", min(vapply(CX_COMPARISONS, function(x) x$wins_a, integer(1)))),
  macro("CxPairedWinsHigh", max(vapply(CX_COMPARISONS, function(x) x$wins_a, integer(1)))),
  macro("CxPairedPHigh", p_cell(max(vapply(CX_COMPARISONS,
                                           function(x) x$p_two_sided, numeric(1))))),
  macro("CxEffMeanLow", ratio_label(min(CX_EFF))),
  macro("CxEffMeanHigh", ratio_label(max(CX_EFF))),
  macro("CxEffMedianLow", ratio_label(min(CX_EFF_MEDIAN))),
  macro("CxEffMedianHigh", ratio_label(max(CX_EFF_MEDIAN))),
  macro("CxBytesCells", formatC(CX_BYTES_CELLS, format = "d", big.mark = ",")),
  macro("CxBytesTrials", formatC(round(CX_BYTES_TRIALS / 1024), format = "d")),
  macro("CxBytesMinimal", formatC(CX_BYTES_MINIMAL, format = "d", big.mark = ",")),
  # How the disclosure compares with the other thing this project cannot put on
  # a laptop. Rounded to an order of magnitude, because the corpus size is
  # itself matched out of prose to the nearest gigabyte.
  macro("CxCorpusOrders", floor(log10(as.numeric(corpus_gb) * 1e9 / CX_BYTES_TRIALS))),

  ## The condition the coarse grid never ran.
  macro("FineRooms", length(ROOMS)),
  macro("FineLevels", length(fine$levels_ms)),
  macro("FineNonzeroLevels", FINE_NONZERO_LEVELS),
  macro("FineAdded", FINE_ADDED_LEVELS),
  macro("FineTrials", fine$n_trials_per_cell),
  macro("FinePairs", formatC(cross$n_paired_trials, format = "d", big.mark = ",")),
  macro("CoarseGapHigh", fmt(cross$gap_the_coarse_grid_skipped_ms[2], 1)),
  macro("ReversalLow", fmt(cross$reversal_is_not_a_point$min_across_geometries_ms, 1)),
  macro("ReversalHigh", fmt(cross$reversal_is_not_a_point$max_across_geometries_ms, 1)),
  macro("ReversalLevelsLow", min(CROSSINGS$levels_named_agnostic)),
  macro("ReversalLevelsHigh", max(CROSSINGS$levels_named_agnostic)),
  macro("CrossedRooms", CROSS_MEDIAN$geometries_that_crossed),
  macro("CensoredRooms", CROSS_MEDIAN$geometries_censored),
  macro("CrossingLow", fmt(CROSS_MEDIAN$settled_range_ms[1], 2)),
  macro("CrossingHigh", fmt(CROSS_MEDIAN$settled_range_ms[2], 2)),
  macro("CrossingSpread", fmt(CROSS_MEDIAN$spread_ms, 2)),
  macro("AnchorAgnosticRooms", CROSS_ANCHOR$n_naming_agnostic),
  macro("PredictedCrossing", fmt(CROSS_PREDICTION$predicted_crossing_ms, 2)),
  macro("MeasuredCrossing",
        fmt(CROSS_PREDICTION$measured_settled_crossing_ms_recorded_geometry, 2)),
  macro("PredictionError", fmt(CROSS_PREDICTION$absolute_error_ms, 2)),
  macro("PredictionTolerance", fmt(CROSS_PREDICTION$tolerance_ms, 1)),
  macro("RuleSepLow", fmt(min(RULE_SEPARATION), 2)),
  macro("RuleSepHigh", fmt(max(RULE_SEPARATION), 2)),
  macro("IndependenceCells", CROSS_INDEPENDENCE$cells_rechecked),
  macro("InsertedLevel", fmt(CROSS_INDEPENDENCE$inserted_level_ms, 2)),
  macro("NEvidence", nrow(manifest$entries)),
  macro("EvidenceBytes", format(sum(manifest$entries$bytes), big.mark = ","))
), "generated_numbers.tex")

## The ladder again, as a table, so each rung's observation can be read in full.

write_generated(c(
  "\\begin{tabular}{clp{0.44\\linewidth}c}",
  "\\toprule",
  "Rung & Assertion & What was observed & Status \\\\",
  "\\midrule",
  paste0(
    ladder$y, " & ",
    ladder$heading, " & ",
    ladder$observation, " & ",
    ifelse(ladder$reachable, "reachable", "\\textbf{broken}"),
    " \\\\"
  ),
  "\\bottomrule",
  "\\end{tabular}"
), "generated_table_ladder.tex")

## Every offset condition, with the median pair and the per-trial contest.

write_generated(c(
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
), "generated_table_sweep.tex")

## The third comparison, transposed. Three conditions read down three rules, so
## that the row a reader would have been shown sits directly above the rows they
## would not have been.

cx_row <- function(label, values, indent = FALSE) {
  paste0(if (indent) "\\quad \\emph{" else "", label, if (indent) "}" else "",
         " & ", paste(values, collapse = " & "), " \\\\")
}
cx_get <- function(f) vapply(CX_COMPARISONS, f, character(1))

write_generated(c(
  paste0("\\begin{tabular}{l", strrep("r", length(CX_COMPARISONS)), "}"),
  "\\toprule",
  cx_row("Timing-noise s.d.", paste0(cx_get(function(x) sigma_us(x$sigma_s)),
                                     "\\,$\\mu$s")),
  "\\midrule",
  cx_row("Trials run per arm", cx_get(function(x) as.character(x$n_planned))),
  cx_row("Returned an error, both sets",
         cx_get(function(x) as.character(x$a$n_finite))),
  cx_row("Returned an error, one set",
         cx_get(function(x) as.character(x$b$n_finite))),
  "\\midrule",
  cx_row("Mean error (m), both sets", cx_get(function(x) fmt(x$a$mean, 4))),
  cx_row("Mean error (m), one set", cx_get(function(x) fmt(x$b$mean, 4))),
  cx_row("named by the mean",
         cx_get(function(x) CX_SHORT[[x$by_rule[[RULE_MEAN]]]]), TRUE),
  "\\midrule",
  cx_row("Median error (m), both sets", cx_get(function(x) fmt(x$a$median, 4))),
  cx_row("Median error (m), one set", cx_get(function(x) fmt(x$b$median, 4))),
  cx_row("named by the median",
         cx_get(function(x) CX_SHORT[[x$by_rule[[RULE_MEDIAN]]]]), TRUE),
  "\\midrule",
  cx_row("Paired trials usable", cx_get(function(x) sprintf("%d/%d", x$n_pairs,
                                                            x$n_planned))),
  cx_row("Won by both sets", cx_get(function(x) sprintf("%d/%d", x$wins_a, x$n_pairs))),
  cx_row("Two-sided signed-rank $p$", cx_get(function(x) p_cell(x$p_two_sided))),
  cx_row("named by the paired test",
         cx_get(function(x) CX_SHORT[[x$by_rule[[RULE_PAIRED]]]]), TRUE),
  "\\bottomrule",
  "\\end{tabular}"
), "generated_table_complement.tex")

## What one trial in forty is worth, arm by arm.

influence_rows <- do.call(rbind, lapply(CX_COMPARISONS, function(x) {
  do.call(rbind, lapply(list(list(CX_FULL, x$a), list(CX_REDUCED, x$b)), function(e) {
    data.frame(sigma = sigma_us(x$sigma_s), arm = CX_SHORT[[e[[1]]]],
               largest = fmt(e[[2]]$max, 3),
               leverage = formatC(e[[2]]$max_over_median, format = "d"),
               mean = fmt(e[[2]]$mean, 4),
               without = fmt(e[[2]]$mean_without_max, 4),
               inflation = sprintf("%.2f", e[[2]]$mean / e[[2]]$mean_without_max))
  }))
}))

write_generated(c(
  "\\begin{tabular}{llrrrrr}",
  "\\toprule",
  paste("Noise s.d. & Given & Largest (m) & $\\times$ own median & Mean (m) &",
        "Mean without it & Ratio \\\\"),
  "\\midrule",
  paste0(
    ifelse(duplicated(influence_rows$sigma), "",
           paste0(influence_rows$sigma, "\\,$\\mu$s")), " & ",
    influence_rows$arm, " & ", influence_rows$largest, " & ",
    influence_rows$leverage, " & ", influence_rows$mean, " & ",
    influence_rows$without, " & ", influence_rows$inflation, " \\\\"
  ),
  "\\bottomrule",
  "\\end{tabular}"
), "generated_table_influence.tex")

## Where each room's ordering changes sign, and where it has not yet.

# A crossing that never happened inside the grid is printed as a bound rather
# than as the last level run, for the same reason the record censors it.
crossing_cell <- function(x, censored) {
  ifelse(is.na(x), paste0("$>$", fmt(censored, 1)), fmt(x, 2))
}
short_arm <- function(x) sub("^offset-", "", x)

write_generated(c(
  "\\begin{tabular}{lccccc}",
  "\\toprule",
  paste("& \\multicolumn{2}{c}{Agnostic named} &",
        "\\multicolumn{2}{c}{Sign change (ms)} & Named at \\\\"),
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  paste("Array & levels & up to (ms) & median & paired &",
        "\\CoarseGapHigh{}\\,ms \\\\"),
  "\\midrule",
  paste0(
    CROSSINGS$room, " & ",
    sprintf("%d/%d", CROSSINGS$levels_named_agnostic, FINE_NONZERO_LEVELS), " & ",
    fmt(CROSSINGS$highest_named_agnostic, 1), " & ",
    crossing_cell(CROSSINGS$median_ms, CROSSINGS$censored_above), " & ",
    crossing_cell(CROSSINGS$paired_ms, CROSSINGS$censored_above), " & ",
    short_arm(CROSSINGS$named_at_anchor),
    " \\\\"
  ),
  "\\bottomrule",
  "\\end{tabular}"
), "generated_table_breakeven.tex")

## The manifest itself, so the evidence discipline can be checked rather than believed.

write_generated(evidence_table(manifest), "generated_table_evidence.tex")

message(sprintf(paste("wrote 10 figures to figs/out and 6 generated tex files to tex/",
                      "(first break at rung %d; %d of %d conditions read differently",
                      "under different summaries; the ordering changes sign inside",
                      "the refined grid in %d of %d rooms)"),
                FIRST_BREAK, CX_DISAGREEING, length(CX_COMPARISONS),
                CROSS_MEDIAN$geometries_that_crossed, length(ROOMS)))
