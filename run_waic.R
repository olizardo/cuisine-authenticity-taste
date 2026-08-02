#!/usr/bin/env Rscript
.libPaths(c("/home/omarlizardo/CULTURE PROJECTS/CLAYTON PROJECTS/childress-lizardo-cuisine-authenticity-taste/renv/library/linux-debian-trixie/R-4.5/x86_64-pc-linux-gnu", .libPaths()))

suppressPackageStartupMessages({
  library(brms)
  library(here)
})

cat("Loading models...\n")
fit_cs <- readRDS(here::here("fit_cs_acat.rds"))
fit_strict <- readRDS(here::here("fit_strict_acat.rds"))

cat("Computing WAIC for strict model (subsetting to 1000 draws to save RAM)...\n")
waic_strict <- waic(fit_strict, ndraws = 1000, cores = 1)

cat("Computing WAIC for category-specific model (subsetting to 1000 draws to save RAM)...\n")
waic_cs <- waic(fit_cs, ndraws = 1000, cores = 1)

cat("Comparing WAIC...\n")
waic_comp <- loo_compare(waic_strict, waic_cs)

cat("Saving comparison results...\n")
saveRDS(waic_comp, file = here::here("waic_comparison.rds"))
sink(here::here("waic_comparison.txt"))
print(waic_comp)
sink()

cat("Finished!\n")