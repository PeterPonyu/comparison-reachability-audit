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
