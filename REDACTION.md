# Redaction of recorded paths and internal names

The result files in this archive were written by the runs that produced them,
and they recorded where they were running and how the work was coordinated.
Those strings describe a private machine and a private workspace and are not
published, so the archived copies were rewritten before deposit. Describing the
rules below without reproducing the strings they remove is the point of this
file, so the left column names each class of string rather than quoting it.

The rewrite is textual and total: it substitutes path strings and internal
names and refreshes the explicit source/hash links in derived receipts, without
changing a numeric or structural value. Rules are applied longest match first.

| replaced | with |
|---|---|
| the absolute filesystem prefix of the machine the archive was assembled on | removed |
| the checkout prefix of a rented machine a run executed on | removed |
| the remaining scratch-mount prefix of that rented machine | `<remote>/` |
| the recorded path of an artifact that is archived here | the path it now has in this archive |
| the home directory of the account the runs executed under | `~/` |
| any remaining directory prefix belonging to the private source tree | `source-tree/` |
| a branch of the private repository named in a recorded instruction | `<private-branch>` |
| a disposition label of the private workspace's own series | the plain word it stands for |

Both machine prefixes are removed before an archived artifact is mapped to its
new location, so a path recorded on the rented machine and the same path
recorded locally become the same archived string rather than two. The rules are
the full declared set; a direction whose runs never left one machine will show
substitutions for only some of them.

The last two classes rewrite recorded values, never keys. A reader comparing an
archived record against the original finds the same schema and the same numbers;
what changes is a name that only resolves inside the workspace that coined it.

## What was checked

Every rewritten file was reparsed after substitution and compared against the
original with all string leaves erased. A changed number, a dropped key, a
reordered list or a lost record fails the export rather than being deposited.
For line-oriented records the record count is compared as well.

## Files rewritten

The digest on the left is the file as the run wrote it; the digest on the right
is the file in this archive, and it is the one the manifest binds and the build
verifies.

| path | path substitutions | receipt-link refreshes | original sha256 | archived sha256 |
|---|---:|---:|---|---|
| `paper/evidence/reachability_probe.json` | 3 | 0 | `5e2ad88b5c80696b…` | `09a5c564f369cf30…` |
| `data/e-paired/offset_sweep_paired_test.json` | 3 | 0 | `5c5f2892fb74b72f…` | `d7dc168a809a944e…` |
| `data/e-inventory/inventory.json` | 2 | 0 | `a08fc117afabc171…` | `cd9e0a1a7cb2b8c3…` |
| `data/e-primary/paper_primary.json` | 1 | 0 | `81fd2de7dab54310…` | `1fb96a8e854c6f93…` |
| `data/e-naive/naive.json` | 1 | 0 | `2f7faa2e35672d5d…` | `3dc6ad94eca0e9a0…` |
| `data/e-aware/simple.json` | 1 | 0 | `17910cc8cc0834ae…` | `83aa34405d56a939…` |
| `data/e-complement/hybrid_gn_python_vs_su.json` | 1 | 0 | `d240f0308b9526fb…` | `202b9f5df4b28309…` |
| `data/e-geom20/geometry_level_interval.json` | 1 | 0 | `9bd14f721b452cbc…` | `7ac67231683afa1d…` |
| `paper/evidence/probe_reachability.py` | 3 | 0 | `4cf83f92dd9657e3…` | `abac4707c9e23245…` |

## Scripts

The rules above were applied to archived scripts as well as to archived records, so a script here shows what it inspected but points at paths that no longer exist. Repoint it at a local checkout before running it. The scripts affected are `paper/evidence/probe_reachability.py`.
