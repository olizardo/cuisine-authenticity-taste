# AI Agent Handoff Document: Childress-Lizardo Cuisine Authenticity & Taste

## Project Overview
This project analyzes survey data (combined Qualtrics & Prolific samples) to understand how respondents view the "authenticity" of 15 different cuisines. 
The core dependent variable is a 1-to-7 ordinal rating scale asking where the food is best prepared:
- **1** = A Traditional Recipe by an Elder at Home
- **4** = Neutral / Midpoint
- **7** = A Developed Recipe by a Professional Chef at a High-End Restaurant

## Folder Structure
- `data/`: Contains raw data (`dat/`) and the universal prep script (`recode.dat.R`).
- `analyses/01_baseline_analysis/`: Standard descriptive, correspondence, and basic statistical reports.
- `analyses/cuisine-acat-multilevel/`: The core Bayesian modeling pipeline using `brms`. Includes the finalized `analysis.qmd` Quarto report.
- `cache/`: Stores massive `.rds` model objects.
- `logs/`: Holds output from `nohup` background runs.
- `Plots/`: All generated plots, standardized to use Bayesian `stat_halfeye` density ribbons.

## The Bayesian Pipeline (`analyses/cuisine-acat-multilevel/`)
We use multilevel Adjacent Category (ACAT) models. 

### Recent Breakthroughs & Finalized Analyses (Aug 5, 2026):
1. **Variance/Consensus Models (Model Fit Comparison)**: We generated ELPD/WAIC comparisons for models 1 through 6. The **Variance + Random Slopes model** (`hier_5_var_rs`) is massively superior in fit ($\Delta$ WAIC > 1,800 over the baseline). It proves that cultural *consensus* varies widely.
2. **2D Cuisine Consensus Mapping**: We built a definitive 2D scatterplot mapping Location (Traditional vs. Chef) against Consensus (High vs. Low Variance):
   - *High Consensus & Traditional*: Ethiopian, Pakistani, Lebanese (everyone agrees they belong on the "Elder" side).
   - *Low Consensus/Chaos*: Italian, French, Japanese (massive disagreement on whether they are domestic or elite).
3. **Competing Ideologies**: We split ideology into **Social** and **Economic** dimensions using a category-specific (`cs()`) model:
   - *Social Conservatism* drives polarization (pushing people heavily toward the "Professional Chef" extreme).
   - *Economic Conservatism* drives centrism (pulling people inward toward the neutral 4 rating).
4. **Cultural vs. Economic Capital**: Graduate degrees strongly predict leaning toward "Professional Chef", but income is almost entirely non-significant across all brackets (proven via fixed-effect comparisons).
5. **Childhood Arts Exposure** (`arts.f`) was integrated into the active formulas but proved entirely null in its effects on variance/consensus.

### Computational Constraints & Pipeline Status:
- **CRITICAL WARNING**: Compiling and running these models requires strict RAM management. Compiling `rstan`/`cmdstanr` C++ code for complex models (especially with `cs()` thresholds) will trigger the Linux Out-Of-Memory (OOM) killer if RAM dips below ~4-5 GB.
- **Queue Status**: The major background runs (Models 1 through 6) have completed and their `.rds` objects are successfully stored in `cache/`.

## Next Steps / Directives for Future Agents
- `analysis.qmd` has been successfully updated and rendered to `analysis.html`. It currently features the Model Fit forest plot and the 2D Cuisine Consensus scatterplot alongside the core random/fixed effect visualizations.
- When generating new visualizations, continue using `tidybayes::stat_halfeye()` for consistency with the rest of the report.
- When reading cached models, utilize `brms::as_draws_df()` or `spread_draws()` to build custom contrasts.