#!/usr/bin/env python3
"""Observe, right now, how far the published comparison can be reconstructed here.

The recorded project state already asserts which rungs are broken. This probe
does not trust that record: it re-checks each rung against the live machine and
writes what it saw, with a timestamp. The manuscript binds the probe output, so
a reader is looking at an observation rather than a recollection.

Deliberately read-only. It resolves interpreter paths, reads a git ref, and
counts files. It never installs, downloads, or executes vendor code.

    python3 evidence/probe_reachability.py > evidence/reachability_probe.json
"""

from __future__ import annotations

import datetime as _dt
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

# Recorded by the project's own inventory as the entry points of the official
# implementation. Presence is checked; execution is not attempted.
RECORDED_ENTRYPOINTS = (
    "DataAnalysis.m", "GN_Solver.m", "any2s.m", "compute_CRLB.m", "compute_J.m",
    "compute_error.m", "get_tdoa.m", "gt_generation.m", "high2low.m",
    "init_generation1.m", "init_generation2.m", "low2high.m", "plot_g.m",
    "quick_start.m", "real_main.m", "sg_generation.m", "sim_main.m",
    "sound_gen.m", "tdoa_detection.m",
)

RECORDED_PIN = "150df084e0cb3c390da0df765c61b0d637cbaf32"
VENDOR_REL = "source-tree/002-acoustic-field/vendor/Hybrid-TDOA-Calib"

# The corpus the official evaluation needs. A resolvable public URL is not a
# local asset, and this probe exists partly to keep those two apart.
CORPUS_CANDIDATES = (
    "data/locata",
    "source-tree/002-acoustic-field/data/locata",
    "source-tree/_fire_data/locata",
)


def repo_root(start: Path) -> Path:
    for candidate in [start, *start.parents]:
        if (candidate / ".git").exists():
            return candidate
    raise SystemExit(f"no git root above {start}")


def probe_runtime(names: tuple[str, ...]) -> dict:
    found = {name: shutil.which(name) for name in names}
    return {
        "searched": list(names),
        "resolved": {name: bool(path) for name, path in found.items()},
        "any_available": any(found.values()),
    }


def probe_vendor(root: Path) -> dict:
    vendor = root / VENDOR_REL
    if not vendor.is_dir():
        return {"present": False, "path_checked": VENDOR_REL}

    try:
        head = subprocess.run(
            ["git", "-C", str(vendor), "rev-parse", "HEAD"],
            capture_output=True, text=True, check=True,
        ).stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        head = ""

    present = sorted(p.name for p in vendor.glob("*.m"))
    missing = [name for name in RECORDED_ENTRYPOINTS if name not in set(present)]
    return {
        "present": True,
        "path_checked": VENDOR_REL,
        "head": head,
        "head_matches_recorded_pin": head == RECORDED_PIN,
        "entrypoints_recorded": len(RECORDED_ENTRYPOINTS),
        "entrypoints_found": len(present),
        "entrypoints_missing": missing,
    }


def probe_corpus(root: Path) -> dict:
    checked = {rel: (root / rel).exists() for rel in CORPUS_CANDIDATES}
    return {
        "paths_checked": checked,
        "env_data_root": os.environ.get("FRONTIER_DATA_ROOT", ""),
        "present_anywhere_checked": any(checked.values()),
    }


def main() -> int:
    root = repo_root(Path(__file__).resolve())

    runtime = probe_runtime(("matlab", "octave", "octave-cli"))
    vendor = probe_vendor(root)
    corpus = probe_corpus(root)

    rungs = [
        {
            "rung": 1,
            "assertion": "the work has a citable published record",
            "reachable": True,
            "observed": "an identifier for the reference implementation's paper is recorded "
                        "in the project's own artifacts; the probe does not fetch the network",
        },
        {
            "rung": 2,
            "assertion": "the reference source can be obtained at a fixed revision",
            "reachable": bool(vendor.get("present") and vendor.get("head_matches_recorded_pin")),
            "observed": vendor,
        },
        {
            "rung": 3,
            "assertion": "the runtime the reference source needs is available here",
            "reachable": runtime["resolved"]["matlab"],
            "observed": runtime,
        },
        {
            "rung": 4,
            "assertion": "the published table can be recomputed here",
            "reachable": False,
            "observed": "unreachable as a consequence of rung 3; no substitute interpreter "
                        "is treated as equivalent and no table is synthesised",
        },
    ]

    payload = {
        "probe": "reachability_of_a_published_comparison",
        "observed_utc": _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "read_only": True,
        "platform": sys.platform,
        "rungs": rungs,
        "corpus": corpus,
        "first_break": next((r["rung"] for r in rungs if not r["reachable"]), None),
    }
    json.dump(payload, sys.stdout, indent=2)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
