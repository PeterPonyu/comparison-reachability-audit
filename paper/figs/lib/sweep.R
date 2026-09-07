# The two records the reproducible half of this paper rests on, and the checks
# that keep them describing the same experiment.
#
# The sweep holds one summary row per offset condition; the paired record holds
# the per-trial contest at the same conditions. They were written by separate
# runs, so the manuscript may read a median from one and a win count from the
# other only while both still describe the same conditions in the same order.

# A constant of the design rather than a variable of it. Refusing a second value
# keeps two differently-sized conditions from being described by one sentence.
single_valued <- function(x, what) {
  v <- unique(x)
  if (length(v) != 1L) stop("the records disagree about ", what)
  v
}

assert_sweep_matches_paired <- function(sweep_rows, paired_rows) {
  if (!identical(sweep_rows$offset_std_ms, paired_rows$offset_std_ms)) {
    stop("the sweep and the paired record no longer cover the same offset conditions")
  }
  if (any(paired_rows$n_trials_aware_better > paired_rows$n_pairs)) {
    stop("a condition records more wins than it ran trials")
  }
  invisible(TRUE)
}

# The ladder-tier summaries against the sweep they were derived from.
#
# Each tier record summarises one arm at one condition of the sweep. They are
# separate files written by a separate step, so they can drift from the sweep
# while both remain internally consistent and both keep matching their recorded
# digests. A digest detects a file changing; it cannot detect two files that
# never changed but no longer agree. This is the check that does.
#
# The comparison is exact rather than approximate. Both records were serialised
# from the same computed values, so the decimal expansions should be identical;
# a tolerance here would hide precisely the small drift worth catching.
assert_tier_summaries_match_sweep <- function(sweep_rows, naive_tier, aware_tier) {
  condition <- single_valued(
    c(naive_tier$metrics$offset_std_ms, aware_tier$metrics$offset_std_ms),
    "which condition the tier summaries describe")

  row <- sweep_rows[sweep_rows$offset_std_ms == condition, ]
  if (nrow(row) != 1L) {
    stop("the tier summaries describe an offset condition the sweep does not hold: ", condition)
  }
  if (!identical(as.integer(naive_tier$metrics$n_trials), as.integer(row$n_trials))) {
    stop("the tier summary and the sweep disagree on how many trials the condition ran")
  }
  for (arm in c("naive", "aware")) {
    tier <- if (arm == "naive") naive_tier else aware_tier
    recorded <- tier$metrics[[paste0(arm, "_mean_err_m")]]
    in_sweep <- row[[paste0(arm, "_mean_err_m")]]
    if (!isTRUE(all.equal(recorded, in_sweep, tolerance = 0))) {
      stop("the ", arm, " tier summary no longer matches the sweep at ", condition,
           " ms: ", format(recorded, digits = 17), " against ",
           format(in_sweep, digits = 17))
    }
  }
  invisible(TRUE)
}
