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
* **Status**: A master queue script is sequentially processing the Music models in the background.
* **Active Process**: `music_hier_2_relaxed.R` is actively sampling in the background (PIDs 3578 running chains at 100%+ CPU). It is executing MCMC sampling.
* **Completed Runs**: `music_hier_1_baseline.R` completed successfully at 11:00 AM on Aug 6, 2026, and its results are cached in `cache/music_hier_1_baseline.rds`.
* **Execution State & Timing Increase**: 
  - Model fitting times have increased in this round compared to the Cuisine round. This is due to a **45% increase in dataset size** (the long format Music dataset has **25,966 observations** across 20 genres, compared to Cuisine's ~18,000 observations across 15 cuisines).
  - Additionally, Music genres (such as classical, rap, metal) exhibit much higher polarization and visual variation than cuisines, which increases NUTS tree depths, making ordinal threshold boundaries (`cs()`) computationally harder to locate and sample.
* **Subsequent Queue**: Models 3, 4, 5, and 6 will run sequentially after Model 2 finishes. 

### 3. TV and Movies Domains (In Queue ⏳)
* **Status**: Positioned sequentially in the queue behind Music.
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

### B. Smart Resuming Capability (`run_master_queue_smart.sh`)
* **The Solution**: We developed `run_master_queue_smart.sh` to prevent overwriting successfully completed model caches when restarting the queue. Before launching any script, the runner performs a silent check:
  - If `cache/<domain>_hier_<model_number>_*.rds` already exists, it prints a success message and **skips** fitting, proceeding instantly to the next model in the queue.
  - If the `.rds` file is missing, it fits the model.
* **Usage**: If you close your laptop, lose connectivity, or restart the server, simply run:
  ```bash
  nohup ./run_master_queue_smart.sh > logs/run_master_queue_all.log 2>&1 &
  ```
  It will automatically resume right where it was paused without wasting time on completed models.

### C. Robust Plot Generation
* Shared plots are generated using `scripts/generate_domain_plots.R`. 
* The script is resilient; if any complex category-specific models (e.g., Model 2/6 with relaxed thresholds) are still running or missing, the script cleanly logs a warning, skips those specific plots, and successfully renders the remaining 9 plots without crashing.

---

## Directives for Future Agents

1. **Monitor the Queue**: Use `ps aux | grep R` or `tail -f logs/run_master_queue_all.log` to monitor the active sequential queue. Do not run any other brms models in parallel to protect RAM.
2. **Resuming Queue**: Always use `./run_master_queue_smart.sh` to run or resume model fitting.
3. **Rendering Reports**: To build updated reports for domains that have completed models, run `./build_all_reports.sh`.
4. **Model Fitting Style**: Ensure all models continue to use `backend = "cmdstanr"` and threading configurations to optimize core usage without exhausting memory.
5. **Visualizations**: Continue using `tidybayes::stat_halfeye()` for any additional density ribbon plots to maintain visual consistency.
