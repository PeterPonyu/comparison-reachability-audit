# The 400-trial re-evaluation of the refined grid, and the checks that keep it
# a sensitivity rather than a replacement.
#
# The registered fourth result is the 40-trial crossing (E-FINE, E-CROSS). This
# record re-runs the same 72 cells to 400 paired trials each under the same
# seeding rule, so trials 0..39 of every cell are, by construction, the
# registered draw. It is read for one purpose: to say how the located crossing
# moves when every cell is read on ten times as many trials. Nothing here feeds
# a registered quantity. Every macro derived from this record carries
# "FourHundred" in its name so a sentence cannot quote it as the crossing.

FINE400_EXPECTED_CELLS <- 72L
FINE400_EXPECTED_TRIALS <- 400L

# The same design, differing only in trials per cell. Anything else that differs
# would make this a second experiment rather than a re-evaluation of the first.
assert_fine400_is_the_same_design <- function(f400, raw, manifest, raw_id) {
  row <- manifest$entries[manifest$entries$id == raw_id, ]
  if (nrow(row) != 1L) stop("no unique evidence entry bound under id ", raw_id)
  if (!identical(f400$stored_sweep$sha256, row$sha256[[1]])) {
    stop("the 400-trial record names a stored sweep other than the bound one")
  }
  if (!identical(f400$stored_sweep$file, row$path[[1]])) {
    stop("the 400-trial record names a stored sweep path other than the bound one")
  }
  if (!identical(f400$design_id, raw$design_id)) {
    stop("the 400-trial record was run under a different design id")
  }
  if (!isTRUE(all.equal(f400$levels_ms, raw$levels_ms))) {
    stop("the 400-trial record ran a different dispersion grid")
  }
  if (!identical(f400$geometries$id, raw$geometries$id)) {
    stop("the 400-trial record ran different arrays, or the same arrays in a different order")
  }
  for (param in c("sigma_prior_ms", "sigma_noise_ms", "n_restarts", "n_icm_iters")) {
    if (!isTRUE(all.equal(f400[[param]], raw[[param]]))) {
      stop("the 400-trial record changed ", param)
    }
  }
  if (!identical(f400$estimator_module$sha256, raw$estimator_module$sha256)) {
    stop("the 400-trial record ran different estimator code")
  }
  invisible(TRUE)
}

# The shape the manuscript states: 72 cells, 400 trials in each, every trial
# stored and finite.
assert_fine400_shape <- function(f400) {
  cells <- f400$cells
  if (nrow(cells) != FINE400_EXPECTED_CELLS ||
      !identical(as.integer(f400$n_cells), FINE400_EXPECTED_CELLS)) {
    stop("the 400-trial record does not carry ", FINE400_EXPECTED_CELLS, " cells")
  }
  if (!identical(as.integer(f400$n_trials_per_cell), FINE400_EXPECTED_TRIALS) ||
      any(as.integer(cells$n_trials) != FINE400_EXPECTED_TRIALS)) {
    stop("the 400-trial record does not run ", FINE400_EXPECTED_TRIALS, " trials in every cell")
  }
  for (i in seq_len(nrow(cells))) {
    naive <- cells$naive_err_m[[i]]
    aware <- cells$aware_err_m[[i]]
    if (length(naive) != FINE400_EXPECTED_TRIALS || length(aware) != FINE400_EXPECTED_TRIALS) {
      stop("a cell of the 400-trial record does not store all of its trials")
    }
    if (!all(is.finite(naive)) || !all(is.finite(aware))) {
      stop("a cell of the 400-trial record carries a non-finite error")
    }
  }
  invisible(TRUE)
}

# The registered draw is the first forty trials of every cell. That is checked
# three ways, from strictest to loosest: the stored trials are bit-identical to
# the bound 40-trial sweep; their medians are therefore identical to the medians
# of the bound sweep; and those medians agree with the per-cell medians the
# derived crossing record prints. The first check is exact; if it passes the
# second cannot fail, and it is kept because "reproduces the medians exactly" is
# the sentence the manuscript makes.
assert_fine400_first_trials_are_the_registered_draw <- function(f400, raw, rooms) {
  n_registered <- as.integer(raw$n_trials_per_cell)
  cells <- f400$cells
  key_of <- function(geometry, level) paste(geometry, sprintf("%.6f", level))
  raw_key <- key_of(raw$cells$geometry, raw$cells$offset_std_ms)
  derived <- do.call(rbind, lapply(rooms, function(room) {
    room$cells[, c("geometry", "offset_std_ms", "agnostic_median_m", "aware_median_m")]
  }))
  derived_key <- key_of(derived$geometry, derived$offset_std_ms)

  for (i in seq_len(nrow(cells))) {
    key <- key_of(cells$geometry[[i]], cells$offset_std_ms[[i]])
    j <- which(raw_key == key)
    k <- which(derived_key == key)
    if (length(j) != 1L || length(k) != 1L) stop("no unique registered cell behind ", key)
    if (!isTRUE(cells$first_40_trials_identical_to_stored_sweep[[i]])) {
      stop("the 400-trial record itself reports a cell whose first trials differ at ", key)
    }
    head_naive <- cells$naive_err_m[[i]][seq_len(n_registered)]
    head_aware <- cells$aware_err_m[[i]][seq_len(n_registered)]
    if (!identical(head_naive, raw$cells$naive_err_m[[j]]) ||
        !identical(head_aware, raw$cells$aware_err_m[[j]])) {
      stop("the first ", n_registered, " trials of the 400-trial record are not the ",
           "registered draw at ", key)
    }
    head_medians <- c(stats::median(head_naive), stats::median(head_aware))
    registered_medians <- c(stats::median(raw$cells$naive_err_m[[j]]),
                            stats::median(raw$cells$aware_err_m[[j]]))
    if (!identical(head_medians, registered_medians)) {
      stop("the first-", n_registered, "-trial medians do not reproduce the registered ",
           "medians exactly at ", key)
    }
    printed <- c(derived$agnostic_median_m[[k]], derived$aware_median_m[[k]])
    if (max(abs(head_medians - printed)) > CELL_TOLERANCE) {
      stop("the first-", n_registered, "-trial medians do not agree with the derived ",
           "record's printed medians at ", key)
    }
  }
  if (!identical(as.integer(f400$cells_whose_first_trials_reproduce_stored_sweep),
                 nrow(cells))) {
    stop("the 400-trial record does not report every cell as reproducing the stored sweep")
  }
  invisible(TRUE)
}

# The crossing at 400 trials, located by the same rule as the registered one:
# the median gap per cell, interpolated linearly, settled where the sign turns
# positive for the last time, censored where the curve has not turned by the top
# of the grid or is not positive at its last level. Reusing crossing_points()
# is the point: a different rule would make the two crossings incomparable.
fine400_crossings <- function(f400) {
  cells <- f400$cells
  do.call(rbind, lapply(f400$geometries$id, function(geometry) {
    sub <- cells[cells$geometry == geometry, ]
    sub <- sub[order(sub$offset_std_ms), ]
    signal <- vapply(seq_len(nrow(sub)), function(i) {
      stats::median(sub$naive_err_m[[i]]) - stats::median(sub$aware_err_m[[i]])
    }, numeric(1))
    located <- crossing_points(sub$offset_std_ms, signal)
    data.frame(geometry = geometry, crossed = located$crossed,
               settled_ms = located$settled, first_ms = located$first,
               censored_above = located$censored_above,
               stringsAsFactors = FALSE)
  }))
}
