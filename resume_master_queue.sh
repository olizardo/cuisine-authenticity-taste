#!/bin/bash

# This script resumes the sequential background model fitting queue 
# after the system restart on Aug 6 at 2:54 PM.
# It starts from Music Model 2 (since Music Model 1 successfully completed and is cached)
# and then proceeds through the remaining Music, TV, and Movie models.

echo "Resuming master model fitting queue..."

# 1. Music Domain (starting from Model 2)
echo "Starting Music models sequentially (from Model 2)..."
for script in analyses/music-acat-multilevel/music_hier_2_relaxed.R \
              analyses/music-acat-multilevel/music_hier_3_rs.R \
              analyses/music-acat-multilevel/music_hier_4_var.R \
              analyses/music-acat-multilevel/music_hier_5_var_rs.R \
              analyses/music-acat-multilevel/music_hier_6_relaxed_rs.R; do
  echo "Running $script"
  Rscript "$script" > "logs/$(basename "$script" .R).log" 2>&1
done
echo "Music models finished."

# 2. TV Domain
echo "Starting TV models sequentially..."
for script in analyses/tv-acat-multilevel/tv_hier_*.R; do
  echo "Running $script"
  Rscript "$script" > "logs/$(basename "$script" .R).log" 2>&1
done
echo "TV models finished."

# 3. Movie Domain
echo "Starting Movie models sequentially..."
for script in analyses/movie-acat-multilevel/mov_hier_*.R; do
  echo "Running $script"
  Rscript "$script" > "logs/$(basename "$script" .R).log" 2>&1
done
echo "Movie models finished."

echo "All queued models completed successfully!"
