#!/bin/bash
echo "Starting Hierarchy Model Queue..."

RSCRIPT="Rscript"

echo "1/5: Fitting Baseline Strict Model..."
"$RSCRIPT" analyses/cuisine-acat-multilevel/hier_1_baseline.R > logs/hier_1_baseline.log 2>&1

echo "2/5: Fitting Relaxed CS Model..."
"$RSCRIPT" analyses/cuisine-acat-multilevel/hier_2_relaxed.R > logs/hier_2_relaxed.log 2>&1

echo "3/5: Fitting Random Slopes (Strict) Model..."
"$RSCRIPT" analyses/cuisine-acat-multilevel/hier_3_rs.R > logs/hier_3_rs.log 2>&1

echo "4/5: Fitting Relaxed CS + Random Slopes Model..."
"$RSCRIPT" analyses/cuisine-acat-multilevel/hier_6_relaxed_rs.R > logs/hier_6_relaxed_rs.log 2>&1

echo "5/5: Fitting Variance Strict Model..."
"$RSCRIPT" analyses/cuisine-acat-multilevel/hier_4_var.R > logs/hier_4_var.log 2>&1

echo "6/6: Fitting Variance + Random Slopes Strict Model..."
"$RSCRIPT" analyses/cuisine-acat-multilevel/hier_5_var_rs.R > logs/hier_5_var_rs.log 2>&1

echo "Finished Hierarchy Queue!"

