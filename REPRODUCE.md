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
| `data/e-paired/offset_sweep_paired_test.json` | derived_table | 3531 | `e81e6d772d228d2d…` |
| `data/e-inventory/inventory.json` | recorded_state | 1934 | `a08fc117afabc171…` |
| `data/e-bridge/hybrid_tdoa_bridge.json` | recorded_state | 1253 | `42498d6f993ddc1d…` |
| `data/e-primary/paper_primary.json` | recorded_state | 337 | `1fb96a8e854c6f93…` |
| `data/e-sotacopy/sota_copy.json` | recorded_state | 304 | `ee61d33aa06acfa9…` |
| `data/e-static/static.json` | recorded_state | 585 | `a1c9a9f0fcb6a96e…` |
| `data/e-naive/naive.json` | derived_table | 357 | `3dc6ad94eca0e9a0…` |
| `data/e-aware/simple.json` | derived_table | 382 | `83aa34405d56a939…` |
| `data/e-complement/hybrid_gn_python_vs_su.json` | derived_table | 148676 | `d240f0308b9526fb…` |
| `data/e-warehouse/002-acoustic-field.md` | narrative_record | 3943 | `c27189a95b4f2b1c…` |

Some of these files recorded the paths of the machine that produced them. Those path strings were rewritten before deposit; `REDACTION.md` states the rules, lists every file touched with both digests, and describes the check that proves no number changed.

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

Stage order is verify, regenerate, typeset. Each stage is a hard gate on the
next.
