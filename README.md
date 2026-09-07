# Citable, obtainable, unrunnable: recording where the reconstruction of a published comparison actually stops

Probe code, probe output, sweep results, figure code and manuscript source for an audit that records, rung by rung, where the reconstruction of a published acoustic-localisation comparison stops on an ordinary machine.

Archived at [10.5281/zenodo.22647014](https://doi.org/10.5281/zenodo.22647014).

Repository: https://github.com/PeterPonyu/comparison-reachability-audit

## What is here

- `paper/tex/` — manuscript source
- `paper/figs/` — the R code that draws the figures and writes the printed numbers
- `paper/evidence/` — a file list with SHA-256 hashes
- `data/` — the 14 data files named in that list

## Not included

This archive leaves out one extra file named in the paper's evidence list. The paper does not take any number from it.

- A private working note. The one count the paper uses from it -- how large the missing corpus is -- is also written in the inventory file included here.

## Rebuild

```bash
bash build.sh
```

The build checks every data file against its hash and stops if a file has
changed. Figures and printed numbers are generated from those files, not typed
in by hand.

Requires `python3`, `Rscript` with `digest`, `ggplot2`, `jsonlite`, `patchwork`
and `systemfonts`, and a TeX distribution with `latexmk`.

## Status

Working draft. Not submitted to any venue.

## Licence

Code: MIT (`LICENSE`). Manuscript text, figures and recorded result data:
CC BY 4.0 (`LICENSE-CONTENT`).
