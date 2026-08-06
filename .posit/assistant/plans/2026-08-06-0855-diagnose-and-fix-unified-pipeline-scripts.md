# Plan - Diagnose and Fix Unified Pipeline (Music, TV, Movies)

## 1. Status & Diagnostics of the Pipeline

We have completed a comprehensive diagnostic of the current pipeline, running processes, scripts, and model cache files. Here is the current landscape:

### A. Background Modeling Queue Status
- **Cuisine**: Models 1 through 6 are **fully completed** and cached in `cache/`.
- **Music**: Models 1, 3, 4, and 5 are **fully completed** and cached in `cache/`. Models 2 (`relaxed`) and 6 (`relaxed_rs`) are currently being processed sequentially in background processes (CPU usage indicates an active MCMC chain sampling for `music_hier_2_relaxed.R`).
- **TV & Movies**: Currently in queue. `tv_hier_1_baseline.R` is sampling in the background.

### B. Plot Generation Script (`scripts/generate_domain_plots.R`)
- We ran a test execution of the plotting function in R for the **Cuisine** and **Music** domains.
- **Success**: The plotting script is robust! It generated the full suite of plots for Cuisine and Music (including WAIC comparisons, 2D consensus maps, fixed effects, random intercepts, random slopes, and category-specific contrasts where applicable) into `Plots/cuisine-acat-multilevel/` and `Plots/music-acat-multilevel/`.
- **Observations / Robustness Fixes**: 
  - If some models are missing (e.g. Model 2 in Music is still running), the script warns about the missing file, skips the category-specific threshold plots, but **successfully generates all other 9 plots** without crashing.
  - We can further polish the script to suppress warnings from `gzfile` when checking missing files, making the log cleaner.

### C. Quarto Report Render Issue (`build_all_reports.sh`)
- **The Bug**: The command `quarto render scripts/analysis_template.qmd --output analysis.html` fails with a Deno file-not-found error (`NotFound: No such file or directory (os error 2): readfile 'analysis_template_files/libs/quarto-html/quarto.js'`).
- **The Cause**: Quarto's `--output` flag can disrupt relative paths for self-contained libraries (libs) when targeting a different name than the `.qmd` base name in some older Quarto versions.
- **The Solution**: Render the template without renaming it first, and then rename/move the resulting HTML file. This was tested and verified to work flawlessly:
  ```bash
  quarto render scripts/analysis_template.qmd -P domain:"music" -P title:"Musical Taste"
  mv scripts/analysis_template.html analyses/music-acat-multilevel/analysis.html
  ```

---

## 2. Proposed Fixes & Steps

We will implement the following targeted, low-risk changes to make the unified pipeline completely reliable:

### Step 1: Update `build_all_reports.sh`
Modify the Quarto render commands to compile the reports safely to their standard names first, then move and rename them. This bypasses the Quarto path-resolution bug.

```bash
# Example update in build_all_reports.sh:
quarto render scripts/analysis_template.qmd -P domain:"music" -P title:"Musical Taste"
mv scripts/analysis_template.html analyses/music-acat-multilevel/analysis.html
```

### Step 2: Add Robustness Tweaks to `scripts/generate_domain_plots.R`
- Wrap `readRDS` checks with silent `file.exists()` checks instead of triggering raw file-connection warning outputs.
- Ensure that if `m2` or other files are absent, we log a neat message: `"Model 2 (Relaxed CS) is still running or not cached; skipping category-specific plots."` instead of dumping standard R warnings.

### Step 3: Run / Validate the Pipeline
- Render the current reports for **Cuisine** and **Music** (since their core Models 1-5 are already in cache, we can build beautiful, functional reports right now!).
- Keep the background model queues running safely in the background (no interruption to the RAM-heavy sampling).

---

## 3. Approval Request
We are ready to implement these clean-up items. Please confirm if you would like us to apply these changes to `build_all_reports.sh` and `scripts/generate_domain_plots.R` and render the available reports.
