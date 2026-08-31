# Reading hash-bound evidence, and refusing to read anything else.
#
# A figure in this tree may only see bytes whose digest still matches the one
# recorded in the manifest, so a stale artifact stops the build instead of
# quietly becoming a plausible number.

find_repo_root <- function(start = normalizePath(".")) {
  cur <- start
  repeat {
    if (file.exists(file.path(cur, ".git"))) return(cur)
    nxt <- dirname(cur)
    if (identical(nxt, cur)) stop("no repository root above ", start)
    cur <- nxt
  }
}

load_manifest <- function() {
  manifest <- jsonlite::fromJSON(file.path("evidence", "evidence_manifest.json"),
                                 simplifyVector = TRUE)
  if (!identical(manifest$state, "BOUND") || length(manifest$entries) == 0) {
    stop("evidence manifest is not BOUND; bind the evidence before drawing anything.")
  }
  manifest
}

# Built once by the driver and closed over by the readers below, so a panel
# cannot reach past the manifest by constructing a path of its own.
evidence_reader <- function(manifest, repo_root) {
  bound_path <- function(id) {
    row <- manifest$entries[manifest$entries$id == id, ]
    if (nrow(row) != 1L) stop("no unique evidence entry bound under id ", id)
    path <- file.path(repo_root, row$path[[1]])
    if (!file.exists(path)) stop("bound evidence has disappeared: ", id)
    actual <- digest::digest(path, algo = "sha256", file = TRUE)
    if (!identical(actual, row$sha256[[1]])) stop("bound evidence drifted on disk: ", id)
    path
  }
  list(
    json = function(id) jsonlite::fromJSON(bound_path(id), simplifyVector = TRUE),
    # One entry is prose rather than a record. It is read as lines so that the
    # one quantity taken from it is matched out of the bound bytes rather than
    # retyped from a reading of them.
    text = function(id) readLines(bound_path(id), warn = FALSE),
    # One bound record contains runs that left the finite reals, and it writes
    # them as the bare token NaN, which JSON has no way to express. A strict
    # parser refuses the whole file and a permissive one accepts the token
    # without comment, so the reader either sees nothing or sees a number-shaped
    # thing that is not a number. The substitution is done here, in one place,
    # and the count is returned beside the data, so that a failed run is carried
    # into the manuscript as a fact about the experiment rather than discovered
    # as a parse error or lost as a silently dropped row.
    json_with_absences = function(id) {
      bare_nonfinite <- "(?<![\"\\w])(NaN|-?Infinity)(?![\"\\w])"
      raw <- readLines(bound_path(id), warn = FALSE)
      hits <- gregexpr(bare_nonfinite, raw, perl = TRUE)
      list(
        data = jsonlite::fromJSON(gsub(bare_nonfinite, "null", raw, perl = TRUE),
                                  simplifyVector = TRUE),
        n_absences = sum(vapply(hits, function(m) sum(m > 0L), integer(1)))
      )
    }
  )
}
