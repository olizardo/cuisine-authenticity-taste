#!/bin/bash
echo "Starting sequential model runs (Resuming from Step 2)..."

# echo "1/4: Running variance model..."
# Rscript analyses/02_acat_multilevel/run_models_variance.R > logs/run_variance.log 2>&1

echo "2/4: Running econ/soc category-specific model..."
Rscript analyses/02_acat_multilevel/run_models_econ_soc_cs.R > logs/run_econ_soc_cs.log 2>&1

echo "3/4: Running random slopes (education) model..."
Rscript analyses/02_acat_multilevel/run_models_rs_educ.R > logs/run_rs_educ.log 2>&1

echo "4/4: Running interaction strict model..."
Rscript analyses/02_acat_multilevel/run_models_interaction_strict.R > logs/run_interaction_strict.log 2>&1

echo "All sequential model runs completed!"
