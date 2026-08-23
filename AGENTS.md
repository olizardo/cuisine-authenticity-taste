# AI Agent Handoff Document: Variance and Liking Across Cultural Domains

## Project Overview
This project analyzes survey data (combined Qualtrics & Prolific samples) to model and compare the structure of aesthetic taste, genre evaluation, and audience polarization across three cultural media domains: **Music**, **TV**, and **Movies**.
The core dependent variable is a 1-to-7 ordinal rating scale (1 = Strongly Dislike to 7 = Strongly Like).

*(Note: The Cuisine Authenticity analysis has been decoupled into its own dedicated repository at `/home/omarlizardo/projects/cuisine-authenticity`).*

## Folder Structure
- `data/`: Contains raw data (`dat/`) and universal prep scripts (`recode.dat.R`, `recode.qualtrics.R`).
- `analyses/music-acat-multilevel/`: Music modeling pipeline and Quarto reports.
- `analyses/tv-acat-multilevel/`: TV modeling pipeline and Quarto reports.
- `analyses/movie-acat-multilevel/`: Movie modeling pipeline and Quarto reports.
- `cache/`: Stores compiled `.rds` model objects.
- `logs/`: Holds output from sequential background runs (e.g., `music_hier_1_baseline.log`).
- `Plots/`: Generated plots for each domain, standardized using Bayesian density ribbons (`tidybayes::stat_halfeye()`).
- `scripts/`: Shared scripts like `generate_domain_plots.R` and `analysis_template.qmd`.

---

## Active Pipeline Status

### 1. Music Domain
* **Model Fits**: Models 1 through 6 are fitted, evaluated via WAIC, and cached in `cache/` (`music_hier_*.rds`).
* **Deliverables**: Plots generated in `Plots/music-acat-multilevel/`, report in `analyses/music-acat-multilevel/analysis.html`.

### 2. TV Domain
* **Model Fits**: Models 1 through 6 are fitted, evaluated via WAIC, and cached in `cache/` (`tv_hier_*.rds`).
* **Deliverables**: Plots generated in `Plots/tv-acat-multilevel/`, report in `analyses/tv-acat-multilevel/analysis.html`.

### 3. Movie Domain
* **Model Fits**: Models 1 through 6 are fitted, evaluated via WAIC, and cached in `cache/` (`mov_hier_*.rds`).
* **Deliverables**: Plots generated in `Plots/movie-acat-multilevel/`, report in `analyses/movie-acat-multilevel/analysis.html`.

---

## Key Technical Solutions & Best Practices

### A. Quarto Path-Resolution Bug Fix
* Render using Quarto parameterization, then move HTML to the respective directory:
  ```bash
  ./build_all_reports.sh
  ```

### B. Smart Resuming Capability (`run_master_queue_smart.sh`)
* Checks `cache/<domain>_hier_<model_number>_*.rds` before running to avoid recomputing completed models.

### C. Systemd Background Daemon (`systemctl --user`)
* User-level `systemd` unit `~/.config/systemd/user/acat-queue.service` manages long-running sequential MCMC runs safely across SSH sessions.
