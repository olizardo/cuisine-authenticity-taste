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
- `analyses/02_acat_multilevel/`: The core Bayesian modeling pipeline using `brms`. Includes the finalized `analysis.qmd` Quarto report.
- `cache/`: Stores massive `.rds` model objects.
- `logs/`: Holds output from `nohup` background runs.
- `Plots/`: All generated plots, standardized to use Bayesian `stat_halfeye` density ribbons.

## The Bayesian Pipeline (`analyses/02_acat_multilevel/`)
We use multilevel Adjacent Category (ACAT) models. 

### Recent Breakthroughs (Aug 3, 2026):
1. **Variance/Consensus Models**: We discovered that the **Distributional Variance model** (which predicts the `disc` parameter, or inverse-variance) is massively superior in fit ($\Delta$ ELPD > 750). It proves that cultural *consensus* varies widely:
   - *High Consensus*: Ethiopian, Pakistani, Lebanese (everyone agrees they belong on the "Elder" side).
   - *Low Consensus/Chaos*: Italian, French, Japanese (massive disagreement on whether they are domestic or elite).
2. **Competing Ideologies**: We split ideology into **Social** and **Economic** dimensions using a category-specific (`cs()`) model:
   - *Social Conservatism* drives polarization (pushing people heavily toward the "Professional Chef" extreme).
   - *Economic Conservatism* drives centrism (pulling people inward toward the neutral 4 rating).
3. **Cultural vs. Economic Capital**: Graduate degrees strongly predict leaning toward "Professional Chef", but income is almost entirely non-significant across all brackets.
4. **Childhood Arts Exposure** (`arts.f`) was integrated into the active formulas but proved entirely null in its effects on variance/consensus.

### Computational Constraints & Active Queues:
- **CRITICAL WARNING**: Compiling and running these models requires strict RAM management. Compiling `rstan` C++ code for complex models (especially with `cs()` thresholds) will trigger the Linux Out-Of-Memory (OOM) killer if RAM dips below ~4-5 GB.
- **Current Active Queue**: `run_ideology_queue.sh` is currently running in the background (using `nohup`). 
  - It contains two new Distributional Ideology models (testing if the two ideologies predict *variance* differences) followed by the Education Random Slopes and Interaction models.
  - They are strictly set to `cores = 1` to survive the RAM limits.

## Next Steps / Directives for Future Agents
- **Do not restart or kill `run_ideology_queue.sh`** unless absolutely necessary. Let it run on 1 core. Monitor progress in `logs/run_variance_ideology.log` etc.
- When generating new visualizations, continue using `tidybayes::stat_halfeye()` for consistency with the rest of the report.
- When reading cached models, utilize `brms::as_draws_df()` or `spread_draws()` to build custom contrasts (like the midpoint contrast scripts we developed).