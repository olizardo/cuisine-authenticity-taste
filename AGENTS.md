# AI Agent Handoff Document: Childress-Lizardo Cuisine Authenticity & Taste

## Project Overview
This project analyzes survey data (combined Qualtrics & Prolific samples) to understand how respondents view the "authenticity" of 15 different cuisines. 
The core dependent variable is a 1-to-7 ordinal rating scale asking where the food is best prepared:
- **1** = A Traditional Recipe by an Elder at Home
- **4** = Neutral / Midpoint
- **7** = A Developed Recipe by a Professional Chef at a High-End Restaurant

## Folder Structure
The project was recently restructured to separate analytical streams:
- `data/`: Contains raw data (`dat/`) and the universal prep script (`recode.dat.R`). `recode.dat.R` centers continuous predictors (like `social_c`).
- `docs/`: Variable metadata and codebooks. Includes `survey_instruments/` for raw survey PDFs and txt files.
- `analyses/01_baseline_analysis/`: Standard descriptive, correspondence, and basic statistical reports.
- `analyses/02_acat_multilevel/`: The Bayesian modeling pipeline using `brms`.
- `cache/`: Ignored by Git. Stores massive `.rds` model objects (`fit_cs_acat.rds`) and saved criteria (`waic_comparison.rds`).
- `logs/`: Holds output from `nohup` background runs.
- `Plots/` & `Tabs/`: Outputs are split into subfolders corresponding to the analysis streams (`01_baseline_analysis/`, `02_acat_multilevel/`).

## The Bayesian Pipeline (`analyses/02_acat_multilevel/`)
We pivoted the data to "long" format to use multilevel Adjacent Category (ACAT) models.
1. **Model Specifications**: 
   - We compared a Strict model (assumes predictors have the same effect across all rating transitions) against a Category-Specific (`cs()`) model (allows slopes to vary across thresholds).
   - *Key File*: `run_models_3.R`
2. **Computational Constraints**: 
   - The ACAT models are massive. They require `iter = 6000` to prevent low Bulk ESS warnings.
   - **CRITICAL WARNING**: Attempting to run sampling on >2 cores or calculating full `loo()` on this machine **will cause an Out-Of-Memory (OOM) crash**. 
   - We use `waic(..., ndraws = 1000)` and `cores = 2` for sampling to survive RAM limits.
3. **Current Status**: 
   - Model 2 (Category-Specific) decisively won the WAIC comparison ($\Delta$ ELPD = 33.7). The fitted model is cached at `cache/fit_cs_acat.rds`.
4. **Visualizations**: 
   - ACAT category-specific slopes are very hard to interpret raw. We calculate **Midpoint Contrasts** mathematically recombining transition log-odds to plot the probability of choosing a specific rating *vs* the neutral midpoint (4). 
   - See `plot_midpoint_social.R` for the logic template.

## Next Steps / Directives for Future Agents
- When generating reports, use `knitr::include_graphics()` and `readRDS()` to pull from `Plots/` and `cache/` rather than re-running the models.
- Apply the midpoint contrast logic (`plot_midpoint_social.R`) to other key demographic variables (e.g., education, income) to map class effects on authenticity.
- Do not attempt to run `add_criterion(fit, "loo")` on the `fit_cs_acat.rds` object without subsampling; the likelihood matrix is too large for the environment's RAM.