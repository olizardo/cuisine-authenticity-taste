# AI Agent Handoff Document: Cuisine Authenticity & Taste Multilevel Modeling Pipeline

## Project Overview
This project analyzes survey data (combined Qualtrics & Prolific samples) to understand how respondents view the "authenticity" and taste of items in four domains: **Cuisine**, **Music**, **TV**, and **Movies**.
The core dependent variable is a 1-to-7 ordinal rating scale asking where/how an item is best prepared, performed, or produced (e.g. Traditional/Elder/Domestic vs. Elite/Professional Chef/Professional Producer).

## Folder Structure
- `data/`: Contains raw data (`dat/`) and the universal prep script (`recode.dat.R`).
- `analyses/cuisine-acat-multilevel/`: Completed cuisine analysis, including Quarto reports (`analysis.qmd` / `analysis.html`).
- `analyses/music-acat-multilevel/`: Active music modeling pipeline, scripts, and Quarto reports.
- `analyses/tv-acat-multilevel/`: TV pipeline, waiting in sequential queue.
- `analyses/movie-acat-multilevel/`: Movie pipeline, waiting in sequential queue.
- `cache/`: Stores compiled `.rds` model objects.
- `logs/`: Holds output from sequential background runs (e.g., `music_hier_1_baseline.log`).
- `Plots/`: Generated plots for each domain, standardized using Bayesian density ribbons (`tidybayes::stat_halfeye()`).
- `scripts/`: Shared scripts like `generate_domain_plots.R` and `analysis_template.qmd`.

---

## Active Pipeline Status (As of August 6, 2026)

### 1. Cuisine Domain (Completed 🎉)
* **Model Fits**: Models 1 through 6 are fully run, cached in `cache/` (as `hier_*.rds`), and analyzed.
* **Results**: The **Variance + Random Slopes model** (`hier_5_var_rs`) is the definitive best-fitting model ($\Delta$ WAIC > 1,800 over baseline). 
* **Deliverables**: 
  - Complete set of 10 standard plots generated in `Plots/cuisine-acat-multilevel/`.
  - Finalized `analysis.html` compiled and verified.

### 2. Music Domain (Active Execution 🔄)
* **Status**: A master queue script (`./run_master_queue.sh`) was started on **Aug 6, 2026 at 09:18 AM** to sequentially process the Music models.
* **Active Process**: `music_hier_1_baseline.R` is actively sampling in the background (PIDs 3797-3800 running chains at 100%+ CPU).
* **Previous Runs**: Music Models 3, 4, and 5 successfully completed during overnight background runs. However, starting the new master queue truncated existing logs and will re-calculate and overwrite cache files sequentially. 

### 3. TV and Movies Domains (In Queue ⏳)
* **Status**: Positioned sequentially in the queue behind Music inside `run_master_queue.sh`.
* **Execution Strategy**: To prevent triggering the Linux Out-Of-Memory (OOM) killer on this shared instance, these models **must** be executed sequentially. Compiling multiple `rstan`/`cmdstanr` C++ models simultaneously will exceed RAM headroom.

---

## Key Technical Solutions & Best Practices

### A. Quarto Path-Resolution Bug Fix
* **The Issue**: Executing `quarto render scripts/analysis_template.qmd --output analysis.html` was failing with a Deno `NotFound` error due to relative asset paths in older Quarto versions.
* **The Fix**: Instead of using Quarto's `--output` flag, compile the report to its default HTML name first, then rename and move it to its respective analysis folder:
  ```bash
  quarto render scripts/analysis_template.qmd -P domain:"music" -P title:"Musical Taste"
  mv scripts/analysis_template.html analyses/music-acat-multilevel/analysis.html
  ```
* This is standardized in `build_all_reports.sh`.

### B. Robust Plot Generation
* Shared plots are generated using `scripts/generate_domain_plots.R`. 
* The script is resilient; if any complex category-specific models (e.g., Model 2/6 with relaxed thresholds) are still running or missing, the script cleanly logs a warning, skips those specific plots, and successfully renders the remaining 9 plots without crashing.

---

## Directives for Future Agents

1. **Monitor the Queue**: Use `ps aux | grep R` or `tail -f logs/run_master_queue_all.log` to monitor the active sequential queue. Do not run any other brms models in parallel to protect RAM.
2. **Rendering Reports**: To build updated reports for domains that have completed models, run `./build_all_reports.sh`.
3. **Model Fitting Style**: Ensure all models continue to use `backend = "cmdstanr"` and threading configurations to optimize core usage without exhausting memory.
4. **Visualizations**: Continue using `tidybayes::stat_halfeye()` for any additional density ribbon plots to maintain visual consistency.
