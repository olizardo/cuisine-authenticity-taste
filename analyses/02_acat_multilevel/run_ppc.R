#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(ggplot2)
  library(brms)
  library(here)
})

cat("Loading category-specific model for PPC...\n")
fit <- readRDS(here::here("cache", "fit_cs_acat.rds"))

cat("Generating posterior predictive checks (bars)...\n")
# Using a subset of draws to limit memory footprint
p_ppc <- pp_check(fit, type = "bars", ndraws = 100) +
  theme_minimal() +
  labs(
    title = "Posterior Predictive Check: Category-Specific ACAT Model",
    subtitle = "Observed ordinal ratings (dark bars) vs. model predictions (light bars)",
    x = "Ordinal Rating (1=Elder at Home, 7=Pro Chef)",
    y = "Count"
  ) +
  theme(
    plot.title = element_text(face = "bold", size = 14)
  )

out_file <- here::here("Plots", "02_acat_multilevel", "ppc_bars.png")
ggsave(out_file, plot = p_ppc, width = 8, height = 6, bg = "white")

cat("Plot successfully saved to", out_file, "\n")
