# Warehouse 002 — Acoustic field / async SSL

| 字段 | 值 |
|---|---|
| ID | 002 |
| Slug | `acoustic-field` |
| Direction card | `directions/002-bayesian-acoustic-field-reconstruction.md` |
| Incubator | `source-tree/002-acoustic-field/` |
| Science SSOT | 本仓 `source-tree/002-acoustic-field/results/sota_copy/` + complements |
| Disposition | **S4 ARCHIVE**（localization scooped；不是 novelty 论文） |
| Pages | none. frontier `has_pages` stays false. Do not enable. 计划主题仓现网 404。 |
| SOTA stage | `.omc/research/research-2026-08-10-sota-copy-plan/stages/stage-002.md` |
| Data audit | `.omc/research/research-2026-08-10-data-baseline-audit/stages/stage-002.md` |

This card is private markdown, not a site.

---

## Clone targets

| Role | Repo | Local target |
|---|---|---|
| **Primary** | [AISLAB-sustech/Calibration_of_Multi_Mic_Arrays](https://github.com/AISLAB-sustech/Calibration_of_Multi_Mic_Arrays) | `vendor/Calibration_of_Multi_Mic_Arrays` |
| Sibling SOTA | [AISLAB-sustech/Hybrid-TDOA-Calib](https://github.com/AISLAB-sustech/Hybrid-TDOA-Calib) / [zcj808/Hybrid-TDOA-Calib](https://github.com/zcj808/Hybrid-TDOA-Calib) | `vendor/Hybrid-TDOA-Calib` |
| Field recon | [d-caviedes/acoustic_gps](https://github.com/d-caviedes/acoustic_gps) | `vendor/acoustic_gps` |
| Placement | [samuel-verburg/optimal_sensor_placement](https://github.com/samuel-verburg/optimal_sensor_placement) | `vendor/optimal_sensor_placement` |
| Sim tooling | pyroomacoustics | pip / already in `acoustic-bo` env |

**Live pin：** `vendor/Hybrid-TDOA-Calib` PIN `150df084e0cb3c390da0df765c61b0d637cbaf32`。官方 MATLAB 表仍未执行。`Calibration_of_Multi_Mic_Arrays` / `acoustic_gps` 仍未 clone。

---

## Data

| Asset | Status | URL / path | On disk? |
|---|---|---|---|
| LOCATA | URL located (Zenodo 10.5281/zenodo.3630470, ~19GB) | Zenodo | **no** — URL ≠ 本地资产 |
| Hybrid-TDOA recordings | 随 vendor repo | vendor | vendor 在；官方表未跑 |
| acoustic_gps paper data | 随 repo | — | repo 未 clone |
| pyroomacoustics env | ALREADY_LOCAL | `acoustic-bo` | yes |
| dEchorate（第二源候选） | 未拉取 | Zenodo | no |

**LOCATA：** inventory `locata` = **not on disk**。不要把 FOUND_PUBLIC 读成本地文件。不要把 `$FRONTIER_DATA_ROOT/locata` 当成已拉取。

---

## Baseline stack（on-disk）

SSOT: `results/sota_copy/{static,naive,simple,paper_primary,sota_copy,inventory}.json` + `complements/hybrid_gn_python_*.json`.  
**FORBIDDEN_TOUCH：** `paper_primary.json` / `sota_copy.json` / `static.json` / `core/hybrid_tdoa_bridge.json` — 不要改。  
**Quote-only：** `naive.json` / `simple.json` / complements JSON — 不要重写。主展示是 median。

| Tier | Method | Status |
|---|---|---|
| Static | SRP-PHAT | **blocked** — `sim_data.npz` 无波形；不要从 TOA-only 造 SRP 表 |
| Naive | LS offset=0 | **ok** — 科学是 **offset sweep**（n=40），不是 CPU smoke。`primary_display_metric=median_err_m`。mean 为 outlier-pulled 次级。 |
| Simple | Offset-aware MAP | **ok** — 同一 sweep；display=`median_err_m`。offset_std=0 时 naive 优于 aware — 不要藏。 |
| Paper×2 | Hybrid-TDOA；acoustic_gps | **blocked** — `missing_matlab`。Octave ≠ MATLAB。不要发明 Table II。 |
| SOTA-copy | Hybrid-TDOA + BCRB/BO | **blocked** — 依赖 official Hybrid + LOCATA not on disk |
| Complement | Python Hybrid-GN | display=`median_rmse`；`not_official_r`；`not_novelty_claim`；`matlab_executed=false` |

**Display rule：** 只引 `median_rmse` / `median_err_m`。mean 不删、不升格。Official Hybrid 仍 `missing_matlab`。

---

## Experimental code home

- `source-tree/002-acoustic-field/`
- Env: `acoustic-bo`
- Venue pointer: `submissions/S4-002-archive-scooped-loc/ARCHIVE.md`（disposition，不是稿）

## Honesty

- 不要从本栈投 TASLP/SPL。不要开 Pages。不要重开 extra 4090。
