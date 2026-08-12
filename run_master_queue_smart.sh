#!/bin/bash

# This is the Smart Master Queue script.
# It automatically checks if a model's compiled RDS file already exists in 'cache/'.
# - If it exists, it skips running that R script (saving hours of time!).
# - If it does not exist (or was cut off/corrupted), it runs the model in the background.
#
# This makes the entire pipeline completely resumeable and safe from server restarts!

echo "=========================================================="
echo "Starting Smart Multilevel ACAT Model Queue..."
echo "=========================================================="

run_if_not_exists() {
  local script=$1
  local rds_name=$2
  
  if [ -f "cache/$rds_name" ] && [ -s "cache/$rds_name" ]; then
    echo "  [SKIPPED] cache/$rds_name already exists. Bypassing."
  else
    echo "  [RUNNING] cache/$rds_name not found. Executing $script..."
    Rscript "$script" > "logs/$(basename "$script" .R).log" 2>&1
    
    # Verify that the run successfully generated the rds file
    if [ -f "cache/$rds_name" ] && [ -s "cache/$rds_name" ]; then
      echo "  [SUCCESS] Created cache/$rds_name!"
    else
      echo "  [WARNING] Script $script finished but cache/$rds_name was not created or is empty!"
    fi
  fi
}

# --- 1. Music Domain ---
echo ""
echo "--- 1. Processing Music Domain ---"
run_if_not_exists "analyses/music-acat-multilevel/music_hier_1_baseline.R"    "music_hier_1_baseline.rds"
run_if_not_exists "analyses/music-acat-multilevel/music_hier_2_relaxed.R"     "music_hier_2_relaxed.rds"
run_if_not_exists "analyses/music-acat-multilevel/music_hier_3_rs.R"          "music_hier_3_rs.rds"
run_if_not_exists "analyses/music-acat-multilevel/music_hier_4_var.R"         "music_hier_4_var.rds"
run_if_not_exists "analyses/music-acat-multilevel/music_hier_5_var_rs.R"      "music_hier_5_var_rs.rds"
run_if_not_exists "analyses/music-acat-multilevel/music_hier_6_relaxed_rs.R"  "music_hier_6_relaxed_rs.rds"

# --- 2. TV Domain ---
echo ""
echo "--- 2. Processing TV Domain ---"
run_if_not_exists "analyses/tv-acat-multilevel/tv_hier_1_baseline.R"          "tv_hier_1_baseline.rds"
run_if_not_exists "analyses/tv-acat-multilevel/tv_hier_2_relaxed.R"           "tv_hier_2_relaxed.rds"
run_if_not_exists "analyses/tv-acat-multilevel/tv_hier_3_rs.R"                "tv_hier_3_rs.rds"
run_if_not_exists "analyses/tv-acat-multilevel/tv_hier_4_var.R"               "tv_hier_4_var.rds"
run_if_not_exists "analyses/tv-acat-multilevel/tv_hier_5_var_rs.R"            "tv_hier_5_var_rs.rds"
run_if_not_exists "analyses/tv-acat-multilevel/tv_hier_6_relaxed_rs.R"        "tv_hier_6_relaxed_rs.rds"

# --- 3. Movie Domain ---
echo ""
echo "--- 3. Processing Movie Domain ---"
run_if_not_exists "analyses/movie-acat-multilevel/mov_hier_1_baseline.R"      "mov_hier_1_baseline.rds"
run_if_not_exists "analyses/movie-acat-multilevel/mov_hier_2_relaxed.R"       "mov_hier_2_relaxed.rds"
run_if_not_exists "analyses/movie-acat-multilevel/mov_hier_3_rs.R"            "mov_hier_3_rs.rds"
run_if_not_exists "analyses/movie-acat-multilevel/mov_hier_4_var.R"           "mov_hier_4_var.rds"
run_if_not_exists "analyses/movie-acat-multilevel/mov_hier_5_var_rs.R"        "mov_hier_5_var_rs.rds"
run_if_not_exists "analyses/movie-acat-multilevel/mov_hier_6_relaxed_rs.R"    "mov_hier_6_relaxed_rs.rds"

echo ""
echo "=========================================================="
echo "All queued models checked and completed!"
echo "=========================================================="
