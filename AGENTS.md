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

## Active Pipeline Status (As of August 12, 2026)

### 1. Cuisine Domain (Completed 🎉)
* **Model Fits**: Models 1 through 6 are fully run, cached in `cache/` (as `hier_*.rds`), and analyzed.
* **Results**: The **Variance + Random Slopes model** (`hier_5_var_rs`) is the definitive best-fitting model ($\Delta$ WAIC > 1,800 over baseline). 
* **Deliverables**: 
  - Complete set of 10 standard plots generated in `Plots/cuisine-acat-multilevel/`.
  - Finalized `analysis.html` compiled and verified.

### 2. Music Domain (Active Execution 🔄)
* **Status**: A master queue script is sequentially processing the Music models in the background.
* **Active Process**: `music_hier_5_var_rs.R` is actively sampling in the background using the newly optimized 16-core configuration (PIDs 25045-25048 running chains with 4 threads per chain, maxing CPU). It bypassed already completed cached models 1-4.
* **Completed Runs**: Models 1 through 4 have completed successfully and are fully cached.
* **Execution State & Timing Optimization**: 
  - Model fitting times have been dramatically improved due to upgrading the computer hardware (16 cores, ~14GB RAM) and optimizing parallel execution configurations.
  - Additionally, compiler-level optimizations (`-O3 -march=native -mtune=native`) have been added to the CmdStan backend to maximize speed on this specific architecture.
* **Subsequent Queue**: Model 6 will run sequentially after Model 5 finishes. 

### 3. TV and Movies Domains (In Queue ⏳)
* **Status**: Positioned sequentially in the queue behind Music.
* **Execution Strategy**: To prevent triggering the Linux Out-Of-Memory (OOM) killer on this shared instance, these models **must** be executed sequentially. Compiling multiple `rstan`/`cmdstanr` C++ models simultaneously will exceed RAM headroom. All scripts have been optimized to use `threads = threading(4)` (16 logical threads total across 4 chains) to fit as fast as possible on the new hardware.

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

### D. System Environment & Hardware Optimizations (August 12, 2026)
* **The Hardware**: Upgraded to a 16-core CPU machine with ~14GB RAM.
* **Compiler Flags**: Configured optimized `gcc` flags (`CXXFLAGS += -O3 -march=native -mtune=native`) in `~/.cmdstan/cmdstan-2.39.0/make/local` to compile specialized, maximum-speed C++ binaries for this exact CPU.
* **Optimal Threading**: Configured `chains = 4, cores = 4` and `threads = threading(4)` across all R scripts. This executes 4 chains in parallel, each containing 4 parallelized computation threads, perfectly using all 16 cores without oversubscribing.
* **Environment Configuration**: Set up R 4.5.3 (via CRAN Bookworm repo) with all necessary development headers (`cmake`, `libx11-dev`, `pandoc`, `libnode-dev`, etc.) and fully restored the 225-package `renv` environment using precompiled binaries from Posit Package Manager (RSPM). Added missing `shiny` dependency and updated `renv.lock`.

### E. Systemd Background Daemon (`systemctl --user`) (New - August 12, 2026)
* **The Solution**: To make model fitting completely robust against SSH disconnects and laptop shutdowns, we configured a user-level `systemd` daemon. 
* **The Configuration**: 
  - Created `~/.config/systemd/user/acat-queue.service`.
  - Set `Restart=on-failure` and `RestartSec=60s` to automatically restart the queue if it gets interrupted or killed (e.g., by the Linux OOM killer).
  - Enabled "linger" (`loginctl enable-linger omarlizardo`) so the daemon stays alive and runs even when the user logs out completely.
* **Why it's safe**: Since `run_master_queue_smart.sh` skips completed models, restarting the queue automatically has zero overhead and resumes exactly where the code crashed.

---

## Directives for Future Agents

1. **Monitor the Queue**: Use `ps aux | grep R` or `tail -f logs/music_hier_5_var_rs.log` to monitor the active sequential queue. Do not run other brms models in parallel.
2. **Resuming Queue via Systemctl**: Once the currently active manual background run finishes, **all future queue runs should be managed natively via systemd** to ensure immunity from terminal hangups and shutdowns:
   ```bash
   # Start the queue
   systemctl --user start acat-queue
   # Stop/pause the queue
   systemctl --user stop acat-queue
   # Check status
   systemctl --user status acat-queue
   # Tail logs
   tail -f logs/systemd_queue.log
   ```
3. **Rendering Reports**: To build updated reports for domains that have completed models, run `./build_all_reports.sh`.
4. **Model Fitting Style**: Ensure all models continue to use `backend = "cmdstanr"` and threading configurations (`threading(4)`) to optimize core usage without exhausting memory.
5. **Visualizations**: Continue using `tidybayes::stat_halfeye()` for any additional density ribbon plots to maintain visual consistency.
