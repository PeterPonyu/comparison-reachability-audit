# Local paths rewritten before deposit

Some result files recorded the machine they ran on, including local folder
names. Those strings are not published. The copies in this archive were
rewritten before deposit. The left column names each class of string rather
than quoting it.

The rewrite changes path strings only. Numbers and table structure stay the
same. Longer matches are applied first.

| replaced | with |
|---|---|
| the absolute filesystem prefix of the machine the archive was assembled on | removed |
| the checkout prefix of a rented machine a run executed on | removed |
| the remaining scratch-mount prefix of that rented machine | `<remote>/` |
| the recorded path of an artifact that is archived here | the path it now has in this archive |
| the home directory of the account the runs executed under | `~/` |
| any remaining directory prefix belonging to the private source tree | `source-tree/` |
| a branch of the private repository named in a recorded instruction | `<private-branch>` |
| a private project status word | the ordinary word it stands for |

Both machine prefixes are removed before a file is mapped to its place in this
archive, so the same path recorded on two machines becomes the same archived
string. A study that never left one machine will only show some of these
substitutions.

The last two rows rewrite recorded values, never keys. A reader comparing an
archived file with the original should see the same fields and the same
numbers; only a local name is changed.

## What was checked

Every rewritten file was read again after substitution and compared with the
original after all string values were blanked. A changed number, a dropped
field, a reordered list or a lost record stops the export. For line-oriented
files the line count is compared as well.

## Files rewritten

The hash on the left is the file as the run wrote it. The hash on the right is
the file in this archive, and it is the one the file list names and the build
checks.

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
