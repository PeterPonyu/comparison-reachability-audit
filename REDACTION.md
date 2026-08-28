# Redaction of recorded paths

The result files in this archive were written by the runs that produced them,
and they recorded where they were running. Those paths describe a private
machine and are not published, so the archived copies were rewritten before
deposit. Describing the rules below without reproducing the paths they remove is
the point of this file, so the left column names each class of string rather
than quoting it.

The rewrite is textual and total: it substitutes path strings and nothing else.
Rules are applied longest match first.

| replaced | with |
|---|---|
| the absolute filesystem prefix of the machine the archive was assembled on | removed |
| the checkout prefix of a rented machine a run executed on | removed |
| the remaining scratch-mount prefix of that rented machine | `<remote>/` |
| the recorded path of an artifact that is archived here | the path it now has in this archive |
| the home directory of the account the runs executed under | `~/` |
| any remaining directory prefix belonging to the private source tree | `source-tree/` |

Both machine prefixes are removed before an archived artifact is mapped to its
new location, so a path recorded on the rented machine and the same path
recorded locally become the same archived string rather than two. The rules are
the full declared set; a direction whose runs never left one machine will show
substitutions for only some of them.

## What was checked

Every rewritten file was reparsed after substitution and compared against the
original with all string leaves erased. A changed number, a dropped key, a
reordered list or a lost record fails the export rather than being deposited.
For line-oriented records the record count is compared as well.

## Files rewritten

The digest on the left is the file as the run wrote it; the digest on the right
is the file in this archive, and it is the one the manifest binds and the build
verifies.

| path | substitutions | original sha256 | archived sha256 |
|---|---|---|---|
| `paper/evidence/reachability_probe.json` | 3 | `5e2ad88b5c80696b…` | `09a5c564f369cf30…` |
| `data/e-paired/offset_sweep_paired_test.json` | 1 | `5c5f2892fb74b72f…` | `e81e6d772d228d2d…` |
| `data/e-primary/paper_primary.json` | 1 | `81fd2de7dab54310…` | `1fb96a8e854c6f93…` |
| `data/e-naive/naive.json` | 1 | `2f7faa2e35672d5d…` | `3dc6ad94eca0e9a0…` |
| `data/e-aware/simple.json` | 1 | `17910cc8cc0834ae…` | `83aa34405d56a939…` |
| `data/e-warehouse/002-acoustic-field.md` | 3 | `9a79afd5808186ad…` | `c27189a95b4f2b1c…` |
| `paper/evidence/probe_reachability.py` | 3 | `4cf83f92dd9657e3…` | `abac4707c9e23245…` |

## Scripts

The rules above were applied to archived scripts as well as to archived records, so a script here shows what it inspected but points at paths that no longer exist. Repoint it at a local checkout before running it. The scripts affected are `paper/evidence/probe_reachability.py`.
