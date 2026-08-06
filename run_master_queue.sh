#!/bin/bash

echo "Starting Music models sequentially..."
for script in analyses/music-acat-multilevel/music_hier_*.R; do
  echo "Running $script"
  Rscript "$script" > "logs/$(basename "$script" .R).log" 2>&1
done
echo "Music models finished."

echo "Starting TV models sequentially..."
for script in analyses/tv-acat-multilevel/tv_hier_*.R; do
  echo "Running $script"
  Rscript "$script" > "logs/$(basename "$script" .R).log" 2>&1
done
echo "TV models finished."

echo "Starting Movie models sequentially..."
for script in analyses/movie-acat-multilevel/mov_hier_*.R; do
  echo "Running $script"
  Rscript "$script" > "logs/$(basename "$script" .R).log" 2>&1
done
echo "Movie models finished."
