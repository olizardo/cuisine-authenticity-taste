#!/usr/bin/env Rscript
.libPaths(c("/home/omarlizardo/CULTURE PROJECTS/CLAYTON PROJECTS/childress-lizardo-cuisine-authenticity-taste/renv/library/linux-debian-trixie/R-4.5/x86_64-pc-linux-gnu", .libPaths()))

suppressPackageStartupMessages({
  library(tidyverse)
  library(haven)
  library(brms)
  library(here)
})

cat("Starting model fitting process for Interaction Model (Strict Effects)...\n")

source(here::here("data", "recode.dat.R"))
dat <- recode.dat()
dat$respondent_id <- seq_len(nrow(dat))

cuisines_cols <- c("japanese", "french", "italian", "mexican", "moroccan", 
                   "korean", "peruvian", "native_american", "swedish", 
                   "pakistani", "ethiopian", "vietnamese", "nigerian", 
                   "jamaican", "lebanese")
demographics <- c("age.f", "race.f", "gend.f", "educ.f", "inc.f", "city.f")

dat_long <- dat |>
  select(respondent_id, all_of(cuisines_cols), all_of(demographics), social, spol.f) |>
  pivot_longer(cols = all_of(cuisines_cols), names_to = "cuisine", values_to = "rating") |>
  filter(!is.na(rating), !is.na(social)) |>
  mutate(
    rating_ord = factor(rating, levels = 1:7, ordered = TRUE),
    cuisine = as.factor(cuisine),
    respondent_id = as.factor(respondent_id),
    social_c = scale(social, center = TRUE, scale = FALSE)
  )

formula_interaction <- bf(
  rating_ord ~ 1 + social_c * educ.f + age.f + race.f + gend.f + inc.f + 
    (1 | respondent_id) + (1 | cuisine)
)

cat("Fitting Interaction Model (Strict Effects)...\n")
fit_interaction <- brm(
  formula = formula_interaction,
  data = dat_long,
  family = acat("logit"),
  prior = c(
    prior(normal(0, 1.5), class = "Intercept"),
    prior(normal(0, 1), class = "b"),
    prior(exponential(1), class = "sd")
  ),
  chains = 4,
  cores = 2,
  iter = 6000,
  warmup = 3000,
  seed = 1234,
  control = list(adapt_delta = 0.95),
  backend = "rstan",
  save_pars = save_pars(all = FALSE)
)

cat("Saving fit_strict_interaction_acat.rds...\n")
saveRDS(fit_interaction, file = here::here("cache", "fit_strict_interaction_acat.rds"))

gc()

cat("Computing WAIC (subsampled)...\n")
fit_interaction <- add_criterion(fit_interaction, "waic", ndraws = 1000)
saveRDS(fit_interaction, file = here::here("cache", "fit_strict_interaction_acat.rds"))

cat("Loading base strict model for comparison...\n")
fit_strict <- readRDS(here::here("cache", "fit_strict_acat.rds"))
if (is.null(fit_strict$criteria$waic)) {
    fit_strict <- add_criterion(fit_strict, "waic", ndraws = 1000)
    saveRDS(fit_strict, file = here::here("cache", "fit_strict_acat.rds"))
}

waic_comp_int <- loo_compare(fit_strict, fit_interaction, criterion = "waic")
saveRDS(waic_comp_int, file = here::here("cache", "waic_comparison_interaction_strict.rds"))

sink(here::here("cache", "waic_comparison_interaction_strict.txt"))
print(waic_comp_int)
sink()

cat("Finished Step 5!\n")
