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
