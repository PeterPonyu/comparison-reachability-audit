# The third comparison, read three ways.
#
# The complement record holds, for each timing-noise condition, both a cell
# summary of the kind a paper prints and the per-trial pairs that summary was
# computed from. Having both in one file is what makes the comparison between
# display rules possible at all: everywhere else in the literature one of the
# two is missing, and the reader cannot tell whether the printed row and the
# underlying trials name the same winner.
#
# Nothing here re-runs the simulation. Every quantity is a re-summary of the
# per-trial pairs already in the bound bytes, and each one is checked against
# the cell summary the record itself carries wherever the record carries it.

# A run that left the finite reals is not a large error; it is an absent
# measurement, and averaging over what remains changes the denominator without
# saying so. The two are kept apart everywhere below.
usable_pairs <- function(a, b) is.finite(a) & is.finite(b)

# When a run diverges it takes every error it would have reported with it, so
# one failed run writes one bare non-finite token per estimated quantity. The
# bounds recorded beside those errors are properties of the array geometry and
# the noise rather than of the estimator, so they survive, which is why the
# efficiency ratios below have a denominator on trials that have no numerator.
ESTIMATED_QUANTITIES <- c("mic_rmse_m", "off_rmse_s", "dri_rmse", "src_rmse_m")

count_absent_measurements <- function(trials_by_condition) {
  sum(vapply(trials_by_condition, function(tr) {
    sum(vapply(c("hybrid", "su"), function(arm) {
      sum(vapply(ESTIMATED_QUANTITIES,
                 function(q) sum(!is.finite(tr[[arm]][[q]])), integer(1)))
    }, integer(1)))
  }, integer(1)))
}

# The rule a paper prints, the rule this record declares primary, and the rule
# that needs the per-trial pairs. They are named once so that a figure, a table
# and a sentence cannot drift into describing different things.
RULE_MEAN <- "Mean over trials"
RULE_MEDIAN <- "Median over trials"
RULE_PAIRED <- "Paired, per trial"
DISPLAY_RULES <- c(RULE_MEAN, RULE_MEDIAN, RULE_PAIRED)

# Complete-case, arm by arm: exactly what a summary column contains when one run
# of one arm failed and the row does not mention it.
per_arm_summary <- function(x) {
  kept <- x[is.finite(x)]
  list(n_planned = length(x), n_finite = length(kept),
       mean = mean(kept), median = stats::median(kept), max = max(kept),
       # The single largest trial, expressed against the middle of the same
       # arm's own distribution, which is the comparison that says whether a
       # mean is describing the arm or describing one run of it.
       max_over_median = max(kept) / stats::median(kept),
       mean_without_max = (sum(kept) - max(kept)) / (length(kept) - 1L))
}

# One condition, both arms, all three rules. The paired rule is the only one of
# the three that must drop a trial from both arms when either arm loses it, and
# that asymmetry is recorded rather than smoothed over.
compare_condition <- function(a, b, label_a, label_b) {
  keep <- usable_pairs(a, b)
  pa <- per_arm_summary(a)
  pb <- per_arm_summary(b)
  wins_a <- sum(a[keep] < b[keep])
  w <- stats::wilcox.test(a[keep], b[keep], paired = TRUE)

  winner <- function(va, vb) if (va < vb) label_a else label_b
  list(
    n_planned = length(a),
    n_pairs = sum(keep),
    dropped = sum(!keep),
    a = pa, b = pb,
    wins_a = wins_a,
    p_two_sided = unname(w$p.value),
    by_rule = c(
      structure(winner(pa$mean, pb$mean), names = RULE_MEAN),
      structure(winner(pa$median, pb$median), names = RULE_MEDIAN),
      structure(if (wins_a > sum(keep) / 2) label_a else label_b, names = RULE_PAIRED)
    ),
    # What the mean would have said had each arm's single worst trial not
    # happened. Not a proposal to trim: a measure of how much of the printed
    # conclusion one trial in forty is carrying.
    winner_mean_trimmed = winner(pa$mean_without_max, pb$mean_without_max)
  )
}

# The record names its own display rule in a field. If that ever stops saying
# median, the argument this paper builds on top of it is about a different
# record, so the build should stop rather than quietly re-aim.
assert_declared_display <- function(record) {
  if (!identical(record$primary_display_metric, "median_rmse")) {
    stop("the complement record no longer declares the median its primary display")
  }
  if (!identical(record$secondary_display_metric, "mean_rmse")) {
    stop("the complement record no longer labels the mean secondary")
  }
  invisible(TRUE)
}

# The per-trial pairs and the cell summary were written by the same run, and the
# paper reads from both. Re-deriving the cell's own mean, median and convergence
# count from the trials it summarises is the check that they still agree; a
# mismatch means the file has been assembled from two different runs and no
# sentence below it can be trusted.
assert_cell_matches_trials <- function(cell_arm, trials, metric, label, tol = 1e-9) {
  kept <- trials[is.finite(trials)]
  recorded <- list(mean = cell_arm[[metric]],
                   median = cell_arm[[paste0(metric, "_median")]],
                   max = cell_arm[[paste0(metric, "_max")]])
  derived <- list(mean = mean(kept), median = stats::median(kept), max = max(kept))
  for (what in names(recorded)) {
    if (!isTRUE(all.equal(recorded[[what]], derived[[what]], tolerance = tol))) {
      stop(sprintf("%s: the cell's %s (%g) is not the %s of the trials it summarises (%g)",
                   label, what, recorded[[what]], what, derived[[what]]))
    }
  }
  if (!identical(as.integer(cell_arm$n_converged), length(kept))) {
    stop(sprintf("%s: the cell counts %d converged runs but %d trials carry a finite error",
                 label, as.integer(cell_arm$n_converged), length(kept)))
  }
  invisible(TRUE)
}

# The two efficiency ratios the record carries are the same measurement divided
# by the same bound under two display rules, so they are checked the same way
# the errors are. Both share a denominator: the bound is a property of the array
# geometry and the noise, so it is defined on every trial including the one
# where an estimator diverged, and it is averaged over all of them. Only the
# numerator loses that trial. Stating the two counts is the point of checking
# this rather than assuming it.
assert_efficiency_matches <- function(cell_arm, trials, crlb, label, tol = 1e-6) {
  finite_err <- trials[is.finite(trials)]
  bound <- mean(crlb[is.finite(crlb)])
  if (!isTRUE(all.equal(cell_arm$mic_crlb_m, bound, tolerance = tol))) {
    stop(sprintf("%s: the recorded bound %g is not the mean of the per-trial bounds (%g)",
                 label, cell_arm$mic_crlb_m, bound))
  }
  for (rule in list(list("rmse_over_crlb_mic", mean(finite_err), "mean"),
                    list("rmse_over_crlb_mic_median", stats::median(finite_err), "median"))) {
    derived <- rule[[2]] / bound
    if (!isTRUE(all.equal(cell_arm[[rule[[1]]]], derived, tolerance = tol))) {
      stop(sprintf("%s: the recorded %s efficiency %g is not %s error over the bound (%g)",
                   label, rule[[3]], cell_arm[[rule[[1]]]], rule[[3]], derived))
    }
  }
  invisible(TRUE)
}

# Ratios of the same measurement under two rules, which is what the efficiency
# columns are, are read on a log scale and against one. Formatting them here
# keeps the figure and the table printing the same string.
ratio_label <- function(x) formatC(x, format = "f", digits = 2)

sigma_us <- function(sigma_s) formatC(sigma_s * 1e6, format = "d")
