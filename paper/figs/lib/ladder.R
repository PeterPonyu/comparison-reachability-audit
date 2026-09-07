# The reachability ladder: the object this paper proposes, assembled once.
#
# A rung is an assertion about the reconstruction that can be checked on one
# machine on one date. The ladder is ordered, so the first rung that fails makes
# every rung above it unreachable regardless of its own merits. The figure and
# the table both label these rungs, so they are built here rather than each
# spelling the same four assertions out in its own words.

# What was seen at each rung, in the order the rungs are numbered. The counted
# quantity comes from the probe rather than the sentence, so a re-probe that
# found a different number of entry points changes the text with it.
ladder_observations <- function(rungs) {
  vendor <- rungs$observed[[2]]
  c(
    "A citable published record for the reference implementation exists.",
    sprintf(paste("Source tree present at a fixed revision matching the recorded pin;",
                  "all %d recorded entry points found."),
            vendor$entrypoints_found),
    paste("The interpreter the source requires does not resolve on this machine.",
          "A commonly suggested substitute is also absent, and would not count if present."),
    "Not attempted. Unreachable through the rung below; no table is synthesised."
  )
}

# The probe's rung-2 observation against the record it claims to be observing.
#
# The probe reports how many entry points it expected and how many it found, and
# the manuscript prints the second number under the word "all". Both figures come
# from the probe, so on its own the sentence is the probe agreeing with itself.
# The bridge record is the independent statement of what the reference tree is
# supposed to contain, and until this check existed nothing compared the two: a
# bridge record that gained an entry point would leave the probe still reporting
# the old expectation, none missing, and the manuscript still saying "all".
#
# Nothing from the bridge record is printed. The manuscript names a third-party
# artifact and states that it could not be run, which is a claim about this
# project rather than about that artifact; enumerating that project's source
# files in a paper making that claim would widen it for no evidential gain. Only
# the count crosses over.
assert_probe_matches_bridge <- function(vendor, bridge) {
  recorded <- bridge$hybrid_tdoa_vendor
  n_recorded <- length(recorded$matlab_entrypoints)

  if (!identical(as.integer(vendor$entrypoints_recorded), as.integer(n_recorded))) {
    stop("the probe expected ", vendor$entrypoints_recorded,
         " entry points but the bridge record lists ", n_recorded)
  }
  if (!identical(vendor$head, recorded$pin)) {
    stop("the revision the probe observed is not the revision the bridge record pins")
  }
  if (!isTRUE(vendor$head_matches_recorded_pin)) {
    stop("the probe reports the observed revision does not match its recorded pin")
  }
  # "All found" has to mean the arithmetic as well as the flag.
  if (!identical(as.integer(vendor$entrypoints_found) + length(vendor$entrypoints_missing),
                 as.integer(n_recorded))) {
    stop("found plus missing entry points does not account for the recorded list")
  }
  invisible(TRUE)
}

# The short form used as a column heading and as the bold line of each rung.
LADDER_ASSERTIONS <- c("Citable record", "Source at a fixed revision",
                       "Required runtime present", "Published table recomputable")

build_ladder <- function(rungs, reachable_label, broken_label) {
  observations <- ladder_observations(rungs)
  if (length(observations) != nrow(rungs) ||
      length(LADDER_ASSERTIONS) != nrow(rungs)) {
    stop("the probe records a different number of rungs than the ladder describes")
  }
  data.frame(
    y = rungs$rung,
    label = sprintf("Rung %d.  %s", rungs$rung, sentence_case(rungs$assertion)),
    observation = wrap_to(observations),
    heading = LADDER_ASSERTIONS,
    status = ifelse(rungs$reachable, reachable_label, broken_label),
    reachable = rungs$reachable,
    stringsAsFactors = FALSE
  )
}
