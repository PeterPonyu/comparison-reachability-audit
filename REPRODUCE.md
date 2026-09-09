# Reproducing the numbers

Every quantity printed in the manuscript is emitted by `paper/figs/make_figs.R`
from the artifacts listed below. None is typed into the prose. The figure code
re-hashes each artifact before reading it, so a modified or missing file stops
the build instead of producing a stale number.

## Bound artifacts

| path | role | bytes | sha256 |
|---|---|---|---|
| `paper/evidence/reachability_probe.json` | live_observation | 1839 | `09a5c564f369cf30…` |
| `data/e-sweep/offset_sweep_results.json` | raw_sweep | 4941 | `bea4b6733963dadd…` |
| `data/e-paired/offset_sweep_paired_test.json` | derived_table | 3527 | `d7dc168a809a944e…` |
| `data/e-inventory/inventory.json` | recorded_state | 1930 | `cd9e0a1a7cb2b8c3…` |
| `data/e-bridge/hybrid_tdoa_bridge.json` | recorded_state | 1253 | `42498d6f993ddc1d…` |
| `data/e-primary/paper_primary.json` | recorded_state | 337 | `1fb96a8e854c6f93…` |
| `data/e-sotacopy/sota_copy.json` | recorded_state | 304 | `ee61d33aa06acfa9…` |
| `data/e-static/static.json` | recorded_state | 585 | `a1c9a9f0fcb6a96e…` |
| `data/e-naive/naive.json` | derived_table | 357 | `3dc6ad94eca0e9a0…` |
| `data/e-aware/simple.json` | derived_table | 382 | `83aa34405d56a939…` |
| `data/e-complement/hybrid_gn_python_vs_su.json` | derived_table | 148674 | `202b9f5df4b28309…` |
| `data/e-fine/breakeven_sweep_20260828T185258Z.json` | live_observation | 186240 | `2929cb29383960fd…` |
| `data/e-cross/breakeven_crossing.json` | derived_table | 58959 | `c4d2e7891617aa1a…` |
| `data/e-geom20/geometry_level_interval.json` | derived_table | 2100 | `7ac67231683afa1d…` |
| `data/e-miccount/miccount_sweep_results.json` | raw_sweep | 28440 | `725b7db4c48c3c0e…` |
| `data/e-reverb/reverb_severity_sweep_results.json` | raw_sweep | 17671 | `352d1567c8b6937c…` |
| `data/e-joint/joint_posterior_results.json` | derived_table | 9786 | `3fff057fb9115c33…` |

Some of these files recorded the paths of the machine that produced them. Those path strings and source links were refreshed before deposit; `REDACTION.md` states the rules, lists every file touched with both digests, and describes the check that proves no number changed.

## Not included

This archive leaves out one extra file named in the paper's evidence list. The paper does not take any number from it.

- A private working note. The one count the paper uses from it -- how large the missing corpus is -- is also written in the inventory file included here.

## Checking the archive without building it

```bash
python3 tools/bind_evidence.py paper --check
```

This re-hashes every path above against `paper/evidence/evidence_manifest.json`
and reports the first artifact that has drifted.

## Rebuilding

```bash
bash build.sh
```

The steps are check the files, redraw the figures, then typeset. Each step
must finish before the next one starts.
