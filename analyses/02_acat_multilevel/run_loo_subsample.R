#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(brms)
  library(here)
})

cat("Loading models...\n")
fit_cs <- readRDS(here::here("fit_cs_acat.rds"))
fit_strict <- readRDS(here::here("fit_strict_acat.rds"))

cat("Computing Subsampled LOO for strict model...\n")
# We use subsampled LOO to avoid out-of-memory errors
loo_strict <- loo_subsample(fit_strict, observations = 1000, cores = 1)

cat("Computing Subsampled LOO for category-specific model...\n")
loo_cs <- loo_subsample(fit_cs, observations = 1000, cores = 1)

cat("Comparing models...\n")
loo_comp <- loo_compare(loo_strict, loo_cs)

cat("Saving comparison results...\n")
saveRDS(loo_comp, file = here::here("loo_subsample_comparison.rds"))
sink(here::here("loo_subsample_comparison.txt"))
print(loo_comp)
sink()

cat("Finished!\n")
