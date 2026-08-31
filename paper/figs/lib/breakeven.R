# The refined sweep, and the checks that keep its two files describing one run.
#
# The raw record stores every trial of a crossed design: dispersion level by
# room, both arms, nothing summarised. The derived record stores the cell
# summaries and the located sign change. Reading the second without re-deriving
# it from the first would reproduce, inside this manuscript, exactly the gap
# between a summary and its trials that the manuscript is about.

# The reader simplifies each record into nested frames. One room per element,
# with the pieces the checks and the panels need, so nothing below has to know
# how the parser chose to fold the file.
room_list <- function(derived) {
  g <- derived$geometries
  lapply(seq_len(nrow(g)), function(i) {
    list(
      geometry = g$geometry[[i]],
      levels_ms = g$levels_ms[[i]],
      by_median = as.list(g$by_median[i, , drop = FALSE]),
      by_paired = as.list(g$by_paired[i, , drop = FALSE]),
      n_levels_named_agnostic = g$nonzero_levels_named_agnostic_by_median[[i]],
      highest_level_named_agnostic = g$highest_nonzero_level_named_agnostic_ms[[i]],
      at_anchor = as.list(g$at_the_coarse_anchor[i, , drop = FALSE]),
      cells = g$cells[[i]]
    )
  })
}

# The derived record names the digest of the bytes it read. The manifest binds
# both files independently, so if the two disagree the derived table is
# summarising a run other than the one bound here, and no amount of internal
# consistency would show it.
assert_derived_reads_the_bound_raw <- function(derived, manifest, raw_id) {
  row <- manifest$entries[manifest$entries$id == raw_id, ]
  if (nrow(row) != 1L) stop("no unique evidence entry bound under id ", raw_id)
  if (!identical(derived$reads$sha256, row$sha256[[1]])) {
    stop("the crossing record was derived from a sweep other than the bound one")
  }
  if (!identical(derived$reads$file, basename(row$path[[1]]))) {
    stop("the crossing record names a sweep file other than the bound one")
  }
  invisible(TRUE)
}

# A crossed design is only crossed if every room ran every level. A room missing
# a level would silently shorten its own curve, and a curve read for the level
# at which it changes sign cannot afford a hole.
assert_grid_is_crossed <- function(raw) {
  rooms <- raw$geometries$id
  levels_ms <- raw$levels_ms
  cells <- raw$cells
  if (nrow(cells) != length(rooms) * length(levels_ms)) {
    stop("the refined sweep is not fully crossed: room count times level count ",
         "does not equal the number of cells")
  }
  for (room in rooms) {
    got <- sort(cells$offset_std_ms[cells$geometry == room])
    if (!isTRUE(all.equal(got, sort(levels_ms)))) {
      stop("room ", room, " did not run the whole grid")
    }
  }
  if (length(unique(cells$n_trials)) != 1L) {
    stop("the cells of the refined sweep do not all run the same number of trials")
  }
  invisible(TRUE)
}

# Every summary the derived record carries, re-derived from the trials it
# summarises. Medians, means and win counts are recomputed; the paired p value
# is not, because the exact signed-rank conventions of two libraries differ and
# comparing them would test the libraries rather than the record.
CELL_TOLERANCE <- 5e-9

assert_cells_match_trials <- function(raw, rooms) {
  raw_key <- paste(raw$cells$geometry, sprintf("%.6f", raw$cells$offset_std_ms))
  for (room in rooms) {
    for (i in seq_len(nrow(room$cells))) {
      cell <- room$cells[i, ]
      key <- paste(cell$geometry, sprintf("%.6f", cell$offset_std_ms))
      j <- which(raw_key == key)
      if (length(j) != 1L) stop("no unique raw cell behind ", key)
      naive <- raw$cells$naive_err_m[[j]]
      aware <- raw$cells$aware_err_m[[j]]
      if (!all(is.finite(naive)) || !all(is.finite(aware))) {
        stop("a cell of the refined sweep carries a non-finite error")
      }
      if (length(naive) != cell$n_trials || length(aware) != cell$n_trials) {
        stop("a cell's stored trials do not match its recorded trial count at ", key)
      }
      recomputed <- c(stats::median(naive), stats::median(aware),
                      mean(naive), mean(aware))
      recorded <- c(cell$agnostic_median_m, cell$aware_median_m,
                    cell$agnostic_mean_m, cell$aware_mean_m)
      if (max(abs(recomputed - recorded)) > CELL_TOLERANCE) {
        stop("a recorded cell summary does not follow from its trials at ", key)
      }
      if (sum(aware < naive) != cell$wins_aware) {
        stop("a recorded win count does not follow from its trials at ", key)
      }
    }
  }
  invisible(TRUE)
}

# Where a signal that is negative at the bottom of the grid first turns
# positive, and where it turns positive for the last time. Both are reported
# because a curve read on forty trials per point need not turn only once, and
# quoting the first as if it were final would overstate what the grid resolves.
crossing_points <- function(levels_ms, signal) {
  if (length(levels_ms) != length(signal)) stop("a signal and its grid differ in length")
  turns <- which(utils::head(signal, -1L) <= 0 & utils::tail(signal, -1L) > 0)
  if (length(turns) == 0L || utils::tail(signal, 1L) <= 0) {
    return(list(crossed = FALSE, first = NA_real_, settled = NA_real_,
                censored_above = utils::tail(levels_ms, 1L)))
  }
  interp <- function(i) {
    lo <- levels_ms[i]; hi <- levels_ms[i + 1L]
    a <- signal[i]; b <- signal[i + 1L]
    lo + (hi - lo) * (-a) / (b - a)
  }
  list(crossed = TRUE, first = interp(turns[1]), settled = interp(utils::tail(turns, 1L)),
       censored_above = NA_real_)
}

# The located crossings, recomputed here from the cell summaries rather than
# read out of the derived record. The manuscript quotes a position on an axis;
# a position is worth quoting only if the rule that produced it can be applied
# again to the same numbers and land in the same place.
CROSSING_TOLERANCE_MS <- 1e-6

assert_crossings_match_cells <- function(rooms) {
  for (room in rooms) {
    cells <- room$cells[order(room$cells$offset_std_ms), ]
    checks <- list(
      list(recorded = room$by_median,
           signal = cells$agnostic_median_m - cells$aware_median_m),
      list(recorded = room$by_paired,
           signal = cells$wins_aware - cells$n_trials / 2)
    )
    for (check in checks) {
      ours <- crossing_points(cells$offset_std_ms, check$signal)
      if (!identical(ours$crossed, check$recorded$crossed_within_grid)) {
        stop("the recorded and recomputed crossings disagree about whether room ",
             room$geometry, " crossed at all")
      }
      if (ours$crossed) {
        gap <- max(abs(c(ours$first - check$recorded$first_crossing_ms,
                         ours$settled - check$recorded$settled_crossing_ms)))
        if (gap > CROSSING_TOLERANCE_MS) {
          stop("a recorded crossing does not follow from the cells in room ", room$geometry)
        }
      }
    }
  }
  invisible(TRUE)
}

# The interval the coarse grid never visited, taken from the coarse record
# rather than from the refined one, so the manuscript's claim about a gap is a
# statement about the design that left it.
assert_refinement_sits_in_the_gap <- function(derived, coarse_levels_ms) {
  gap <- derived$gap_the_coarse_grid_skipped_ms
  if (!isTRUE(all.equal(sort(derived$coarse_grid_ms), sort(coarse_levels_ms)))) {
    stop("the refined sweep recorded a coarse grid other than the bound one")
  }
  inside <- derived$grid_ms[derived$grid_ms > gap[1] & derived$grid_ms < gap[2]]
  if (length(inside) == 0L) {
    stop("the refined grid adds no level inside the interval the coarse grid skipped")
  }
  length(inside)
}

# The gap between the two arms, one row per cell. Negative is the agnostic
# estimator named, which is the side of zero the coarse grid never sampled.
breakeven_frame <- function(rooms, labeller) {
  do.call(rbind, lapply(rooms, function(room) {
    cells <- room$cells[order(room$cells$offset_std_ms), ]
    data.frame(room = labeller(room$geometry), offset = cells$offset_std_ms,
               gap = cells$agnostic_median_m - cells$aware_median_m,
               agnostic = cells$agnostic_median_m, aware = cells$aware_median_m,
               wins = cells$wins_aware, n = cells$n_trials,
               stringsAsFactors = FALSE)
  }))
}
