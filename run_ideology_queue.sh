#!/bin/bash
echo "Starting Master Model Queue..."

RSCRIPT="C:/Program Files/R/R-4.5.3/bin/x64/Rscript.exe"

echo "1/4: Running Distributional Ideology Model with Random Slopes (Model 2)..."
"$RSCRIPT" analyses/02_acat_multilevel/run_models_variance_ideology_rs.R > logs/run_variance_ideology_rs.log 2>&1

echo "2/4: Running random slopes (education) model..."
"$RSCRIPT" analyses/02_acat_multilevel/run_models_rs_educ.R > logs/run_rs_educ.log 2>&1

echo "3/4: Running interaction strict model..."
"$RSCRIPT" analyses/02_acat_multilevel/run_models_interaction_strict.R > logs/run_interaction_strict.log 2>&1

echo "4/4: Running social+economic CS + RS model (New Model)..."
"$RSCRIPT" analyses/02_acat_multilevel/run_models_cs_rs_both.R > logs/run_cs_rs_both.log 2>&1

echo "Finished Master Model Queue!"