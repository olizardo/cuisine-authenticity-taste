#!/bin/bash

# 1. Generate all plots
echo "Generating plots for all domains..."
Rscript scripts/generate_domain_plots.R

# 2. Render Music Report
echo "Rendering Music Report..."
quarto render scripts/analysis_template.qmd -P domain:"music" -P title:"Musical Taste"
mv scripts/analysis_template.html analyses/music-acat-multilevel/analysis.html

# 3. Render TV Report
echo "Rendering TV Report..."
quarto render scripts/analysis_template.qmd -P domain:"tv" -P title:"Television Taste"
mv scripts/analysis_template.html analyses/tv-acat-multilevel/analysis.html

# 4. Render Movie Report
echo "Rendering Movie Report..."
quarto render scripts/analysis_template.qmd -P domain:"mov" -P title:"Movie Taste"
mv scripts/analysis_template.html analyses/movie-acat-multilevel/analysis.html

echo "All reports successfully rendered!"
