#!/bin/bash
echo "Starting Music Hierarchy Model Queue..."

RSCRIPT="Rscript"

echo "1/5: Fitting Baseline Strict Model..."
"$RSCRIPT" analyses/music-acat-multilevel/music_hier_1_baseline.R > logs/music_hier_1_baseline.log 2>&1

echo "2/5: Fitting Relaxed CS Model..."
"$RSCRIPT" analyses/music-acat-multilevel/music_hier_2_relaxed.R > logs/music_hier_2_relaxed.log 2>&1

echo "3/5: Fitting Random Slopes (Strict) Model..."
"$RSCRIPT" analyses/music-acat-multilevel/music_hier_3_rs.R > logs/music_hier_3_rs.log 2>&1

echo "4/5: Fitting Variance Strict Model..."
"$RSCRIPT" analyses/music-acat-multilevel/music_hier_4_var.R > logs/music_hier_4_var.log 2>&1

echo "5/5: Fitting Variance + Random Slopes Strict Model..."
"$RSCRIPT" analyses/music-acat-multilevel/music_hier_5_var_rs.R > logs/music_hier_5_var_rs.log 2>&1

echo "Finished Music Hierarchy Queue!"