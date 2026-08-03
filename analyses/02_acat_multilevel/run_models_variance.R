#!/usr/bin/env Rscript
.libPaths(c("/home/omarlizardo/CULTURE PROJECTS/CLAYTON PROJECTS/childress-lizardo-cuisine-authenticity-taste/renv/library/linux-debian-trixie/R-4.5/x86_64-pc-linux-gnu", .libPaths()))

suppressPackageStartupMessages({
  library(tidyverse)
  library(haven)
  library(brms)
  library(here)
})

cat("Starting model fitting process for Distributional (Variance) ACAT Model...\n")

source(here::here("data", "recode.dat.R"))
dat <- recode.dat()
dat$respondent_id <- seq_len(nrow(dat))

cuisines_cols <- c("japanese", "french", "italian", "mexican", "moroccan", 
                   "korean", "peruvian", "native_american", "swedish", 
                   "pakistani", "ethiopian", "vietnamese", "nigerian", 
                   "jamaican", "lebanese")
# Added arts.f to demographic controls
demographics <- c("age.f", "race.f", "gend.f", "educ.f", "inc.f", "city.f", "arts.f")

dat_long <- dat |>
  select(respondent_id, all_of(cuisines_cols), all_of(demographics), social) |>
  pivot_longer(cols = all_of(cuisines_cols), names_to = "cuisine", values_to = "rating") |>
  filter(!is.na(rating), !is.na(social)) |>
  mutate(
    rating_ord = factor(rating, levels = 1:7, ordered = TRUE),
    cuisine = as.factor(cuisine),
    respondent_id = as.factor(respondent_id),
    social_c = scale(social, center = TRUE, scale = FALSE)
  )

# Multi-part formula for location-scale (distributional) model
# Using proportional odds (strict effects) for the main location to ensure convergence.
# The 'disc' formula predicts the discrimination parameter (inverse of variance).
formula_variance <- bf(
  rating_ord ~ 1 + social_c + age.f + race.f + gend.f + educ.f + inc.f + arts.f + 
    (1 | respondent_id) + (1 | cuisine),
  disc ~ 1 + social_c + educ.f + arts.f + (1 | cuisine)
)

cat("Fitting Distributional Model...\n")
fit_variance <- brm(
  formula = formula_variance,
  data = dat_long,
  family = acat("logit"),
  prior = c(
    # Standard location priors
    prior(normal(0, 1.5), class = "Intercept"),
    prior(normal(0, 1), class = "b"),
    prior(exponential(1), class = "sd"),
    # Priors for the discrimination (variance) equation
    # The intercept for disc is typically centered at 0 on the log scale (exp(0) = 1)
    prior(normal(0, 1), class = "Intercept", dpar = "disc"),
    prior(normal(0, 0.5), class = "b", dpar = "disc"),
    prior(exponential(1), class = "sd", dpar = "disc")
  ),
  chains = 4,
  cores = 1,
  iter = 4000,
  warmup = 2000,
  seed = 1234,
  control = list(adapt_delta = 0.95),
  backend = "rstan",
  save_pars = save_pars(all = FALSE)
)

cat("Saving fit_variance_acat.rds...\n")
saveRDS(fit_variance, file = here::here("cache", "fit_variance_acat.rds"))

gc()

cat("Computing WAIC (subsampled)...\n")
fit_variance <- add_criterion(fit_variance, "waic", ndraws = 1000)
saveRDS(fit_variance, file = here::here("cache", "fit_variance_acat.rds"))

cat("Loading base strict model for comparison...\n")
fit_strict <- readRDS(here::here("cache", "fit_strict_acat.rds"))
if (is.null(fit_strict$criteria$waic)) {
    fit_strict <- add_criterion(fit_strict, "waic", ndraws = 1000)
    saveRDS(fit_strict, file = here::here("cache", "fit_strict_acat.rds"))
}

waic_comp_var <- loo_compare(fit_strict, fit_variance, criterion = "waic")
saveRDS(waic_comp_var, file = here::here("cache", "waic_comparison_variance.rds"))

sink(here::here("cache", "waic_comparison_variance.txt"))
print(waic_comp_var)
sink()

cat("Finished Variance Model!\n")