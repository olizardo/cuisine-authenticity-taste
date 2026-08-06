#!/bin/bash

# 1. Generate all plots
echo "Generating plots for all domains..."
Rscript scripts/generate_domain_plots.R

# 2. Render Music Report
echo "Rendering Music Report..."
quarto render scripts/analysis_template.qmd -P domain:"music" -P title:"Musical Taste" --output analysis.html
mv scripts/analysis.html analyses/music-acat-multilevel/analysis.html

# 3. Render TV Report
echo "Rendering TV Report..."
quarto render scripts/analysis_template.qmd -P domain:"tv" -P title:"Television Taste" --output analysis.html
mv scripts/analysis.html analyses/tv-acat-multilevel/analysis.html

# 4. Render Movie Report
echo "Rendering Movie Report..."
quarto render scripts/analysis_template.qmd -P domain:"mov" -P title:"Movie Taste" --output analysis.html
mv scripts/analysis.html analyses/movie-acat-multilevel/analysis.html

# 5. Render Cuisine Report (Testing legacy)
echo "Rendering Cuisine Report..."
quarto render scripts/analysis_template.qmd -P domain:"cuisine" -P title:"Cuisine Authenticity" --output analysis.html
mv scripts/analysis.html analyses/cuisine-acat-multilevel/analysis.html

echo "All reports successfully rendered!"
