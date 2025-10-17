# Sanctions Leakage – Reproduction Guide

This repository accompanies the study **“Leakages in Russian Sanctions: Evidence from 20 Critical Products.”** It documents how to reproduce the EXIOBASE MRIO simulations and UN Comtrade visuals and how each script maps to tables/figures in the thesis. Paper link: https://www.dropbox.com/scl/fi/2n5makgdnhttgpmssnvg0/Writing-Sample_Jinyang_Huang.pdf?rlkey=bg5h973ccv9unnmi3yfy5uidx&st=rhi6gml5&dl=0

---

## Repository Layout

```
.
├── mrio.py
├── comtrade_import_aggregate.R
├── comtrade_visual.R
├── naics_hs_concordance.R
├── trade_analysis.R
├── Writing Sample_Jinyang_Huang.pdf
└── data/                      # place inputs here (see below)
```
---

## 1) Environments

### Python (for MRIO / EXIOBASE)
- Python ≥ 3.10
- Packages: `numpy`, `pandas`, `matplotlib`, `pymrio`, `openpyxl` (optional)

```bash
# Example using conda
conda create -n sanctions python=3.11 -y
conda activate sanctions
pip install numpy pandas matplotlib pymrio openpyxl
```

### R (for Comtrade wrangling & visuals; HS→NAICS→EXIOBASE concordance)
- R ≥ 4.2
- Packages: `tidyverse`, `readr`, `dplyr`, `tidyr`, `purrr`, `janitor`, `ggplot2`, `openxlsx`, `readxl`, `concordance`

```r
install.packages(c(
  "tidyverse","readr","dplyr","tidyr","purrr",
  "janitor","ggplot2","openxlsx","readxl","concordance"
))
```

**Important**: Do **not** run `install.packages()` inside production scripts. Install once in your R session.

---

## 2) Data & Folder Structure

All datasets used are in the `data` branch, create a `data/` folder at repo root and populate with:
- **EXIOBASE3** EXIOBASE3 MRIO data should be downloaded through `pymrio` package (guidlines: https://pymrio.readthedocs.io/en/latest/notebooks/autodownload.html)
- **UN Comtrade extracts** CSV: e.g., `data/TradeData_2_26_2025_14_50_13.csv` (or your filename).
- **Concordance sheets**:
  - `data/NAICS2017_EXIOBASEp.xlsx` (NAICS ↔ EXIOBASE mapping)
  - Generated: `data/transposed_filtered_file.xlsx` (written by `mrio.py` during concordance step)
- **Aggregated trade tables** for plotting (if reusing): `data/top7sectors_trade.csv`, `data/next7sectors_trade.csv`

Example:
```
data/
├── EXIO3/
│   └── IOT_2021_pxp.zip                  # product level IOT
├── TradeData_YYYY_MM_DD.csv              # Raw Comtrade Data
├── NAICS2017_EXIOBASEp.xlsx              # EXIOBASE3 -- NAICS concordance table 
│   └── transposed_filtered_file.xlsx     # Transposed concordance table for conversion
├── top7sectors_trade.csv                 # cleaed trade data for top 1-7 products (5 left due to missing values)
└── next7sectors_trade.csv                # cleaed trade data for top 8-14 products (5 left due to missing values)
```

> **Paths**: The current scripts use absolute `setwd(...)`/`os.chdir(...)` paths. Before running, change these to your local machine or refactor to project‑relative paths (recommended).

---

## 3) How to Reproduce

All codes are in the `codes` branch.

### A. Input–Output simulations (Figures 2, 3, 7 in thesis)
Script: `mrio.py`  
What it does:
- Downloads/parses EXIOBASE3 (2021), computes `Z`, `Y`, `A`, `L` and runs sanctions counterfactuals for a **32‑country EU+ coalition** vs **World**.  
- Builds HS→NAICS→EXIOBASE link and writes a transposed mapping file `transposed_filtered_file.xlsx` under `data/` for later use.  
- Produces **rankings** by output reduction and **stacked bar** plots: *EU+(32) Coalition* vs *Third‑Party Countries*.

Run:
```bash
# Edit os.chdir() and file paths at the top of mrio.py
python mrio.py
```

Outputs (indicative):
- Plots: *Reduction in Russian Production* and *Reduction from Third Parties*.
- Summary vectors: total reduction from EU+ vs World; product‑level reductions.

**Notes / small fixes**:
- Logging line uses `exio3.meta.note(...)` but the parsed object is `exio2021p`; change to `exio2021p.meta.note(...)`.
- In the per‑country (“EX2”) loop, use the **country‑specific** final demand when computing output: replace
  `x_RU_temp = L_p.dot(FD_RU)` and `IO_temp.L.dot(FD_RU)` with the correctly defined `FD_RU_temp`.  
- Keep the EU+ list in one place and consider parameterizing via YAML/CSV.

### B. Clean & aggregate Comtrade by HS‑2 (basis=2013)
Script: `comtrade_import_aggregate.R`  
What it does:
- Reads raw Comtrade CSV, drops `refYear == 2024`, derives `hs2 = substr(cmdCode,1,2)`, aggregates by `reporterISO × hs2 × year`, ranks **top 10** reporters per HS‑2 **using 2013** as the base year, reshapes wide, and writes multi‑sheet **`HS2_Sorted_By_2013.xlsx`**.  
Run:
```r
# Open in RStudio; update setwd() and file names to your machine
source("comtrade_import_aggregate.R")
```

### C. Split per‑HS tables & workbook for Figure 6
Script: `comtrade_visual.R`  
What it does:
- Filters to reporters with multiple years, splits datasets by `cmdCode`, writes per‑HS CSVs, and exports **`Trade_Tables.xlsx`** (one sheet per HS).  
Run:
```r
# Open in RStudio; remove install.packages("purrr") from the script; update setwd()
source("comtrade_visual.R")
```

### D. Product‑group substitution visuals (Figures 4 & 5)
Script: `trade_analysis.R`  
What it does:
- Reads `top7sectors_trade.csv` and `next7sectors_trade.csv`, builds **Top‑5 exporter share** stacked columns by product group and year (2021–2023), with in‑facet labels for large shares.  
Run:
```r
# Open in RStudio; update setwd() paths inside script
source("trade_analysis.R")
```

### E. HS→NAICS→EXIOBASE crosswalk utilities
Script: `naics_hs_concordance.R`  
What it does:
- Uses `concordance` to map the 20 HS‑6 products to 6‑digit NAICS, selects overlapping columns from the transposed NAICS–EXIOBASE, and extracts EXIOBASE sector IDs used in `mrio.py`.  
Run:
```r
# Open in RStudio; update setwd()
source("naics_hs_concordance.R")
```

---

## 4) Figure Map (script → figure)

| Thesis Figure | Description | Script(s) |
|---|---|---|
| **Fig. 2** | Reduction in Russian Production (Top products) | `mrio.py` |
| **Fig. 3** | Reduction from **Third‑Party** Countries | `mrio.py` |
| **Fig. 4** | Top‑5 exporters to Russia by product group (panel 1) | `trade_analysis.R` |
| **Fig. 5** | Top‑5 exporters to Russia by product group (panel 2) | `trade_analysis.R` |
| **Fig. 6** | HS‑level tables workbook | `comtrade_visual.R` |
| **Fig. 7** | Extended product set ranking / visualization | `mrio.py` |

---

## 5) Recent Changes (this version)

- **Comtrade aggregation** now filters out 2024, ranks HS‑2 reporters using **2013 as base**, and writes `HS2_Sorted_By_2013.xlsx`.  
- **Visuals** script splits by `cmdCode`, writes per‑HS CSVs, and collates all sheets into **`Trade_Tables.xlsx`**.  
- **MRIO pipeline** includes explicit EXIOBASE download/cache and creates the transposed NAICS–EXIOBASE mapping file. Minor fixes recommended for logging and FD vector selection in the third‑country loop.

---

## 6) Troubleshooting

- **Hard‑coded paths**: Replace absolute `setwd()`/`os.chdir()` with project‑relative paths (e.g., `{here}` in R, `pathlib.Path` in Python).  
- **R packages installed inside script**: Remove `install.packages()` from code and install once per environment.  
- **EXIOBASE object names**: Use a consistent object (`exio2021p`) for `.meta.note()` and subsequent attributes.  
- **Country‑specific FD**: In per‑country counterfactuals, use `FD_RU_temp` for the dot‑product; otherwise results mix baselines.

---

## 7) Citation & Contact

Please cite the thesis and data sources (EXIOBASE, UN Comtrade) when using these materials.  
For questions, contact the author.
