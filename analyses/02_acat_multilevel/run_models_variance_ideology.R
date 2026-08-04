#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(tidyverse)
  library(haven)
  library(brms)
  library(here)
})

cat("Starting model fitting process for Distributional Multi-Dimensional Ideology Model...\n")

source(here::here("data", "recode.dat.R"))
dat <- recode.dat()
dat$respondent_id <- seq_len(nrow(dat))

cuisines_cols <- c("japanese", "french", "italian", "mexican", "moroccan", 
                   "korean", "peruvian", "native_american", "swedish", 
                   "pakistani", "ethiopian", "vietnamese", "nigerian", 
                   "jamaican", "lebanese")
demographics <- c("age.f", "race.f", "gend.f", "educ.f", "inc.f", "city.f", "arts.f")

dat_long <- dat |>
  select(respondent_id, all_of(cuisines_cols), all_of(demographics), social, economic) |>
  pivot_longer(cols = all_of(cuisines_cols), names_to = "cuisine", values_to = "rating") |>
  filter(!is.na(rating), !is.na(social), !is.na(economic)) |>
  mutate(
    rating_ord = factor(rating, levels = 1:7, ordered = TRUE),
    cuisine = as.factor(cuisine),
    respondent_id = as.factor(respondent_id),
    social_c = scale(social, center = TRUE, scale = FALSE),
    economic_c = scale(economic, center = TRUE, scale = FALSE)
  )

# Multi-part formula: 
# 1. Location equation includes both ideologies
# 2. Variance (disc) equation includes both ideologies with just a random intercept for cuisine
formula_var_ideo <- bf(
  rating_ord ~ 1 + social_c + economic_c + age.f + race.f + gend.f + educ.f + inc.f + arts.f + 
    (1 | respondent_id) + (1 | cuisine),
  disc ~ 1 + social_c + economic_c + educ.f + arts.f + (1 | cuisine)
)

cat("Fitting Distributional Ideology Model (1 core to save RAM)...\n")
fit_var_ideo <- brm(
  formula = formula_var_ideo,
  data = dat_long,
  family = acat("logit"),
  prior = c(
    prior(normal(0, 1.5), class = "Intercept"),
    prior(normal(0, 1), class = "b"),
    prior(exponential(1), class = "sd"),
    
    prior(normal(0, 1), class = "Intercept", dpar = "disc"),
    prior(normal(0, 0.5), class = "b", dpar = "disc"),
    prior(exponential(1), class = "sd", dpar = "disc")
  ),
  chains = 4,
  cores = 2,
  iter = 4000,
  warmup = 2000,
  seed = 1234,
  control = list(adapt_delta = 0.95),
  backend = "cmdstanr",
  save_pars = save_pars(all = FALSE)
)

cat("Saving fit_var_ideo_acat.rds...\n")
saveRDS(fit_var_ideo, file = here::here("cache", "fit_var_ideo_acat.rds"))
gc()

cat("Computing WAIC (subsampled)...\n")
fit_var_ideo <- add_criterion(fit_var_ideo, "waic", ndraws = 1000)
saveRDS(fit_var_ideo, file = here::here("cache", "fit_var_ideo_acat.rds"))

cat("Loading base variance model for comparison...\n")
fit_var_base <- readRDS(here::here("cache", "fit_variance_acat.rds"))
if (is.null(fit_var_base$criteria$waic)) {
    fit_var_base <- add_criterion(fit_var_base, "waic", ndraws = 1000)
    saveRDS(fit_var_base, file = here::here("cache", "fit_variance_acat.rds"))
}

waic_comp <- loo_compare(fit_var_base, fit_var_ideo, criterion = "waic")
saveRDS(waic_comp, file = here::here("cache", "waic_comparison_var_ideo.rds"))

sink(here::here("cache", "waic_comparison_var_ideo.txt"))
print(waic_comp)
sink()

cat("Finished Distributional Ideology Model!\n")
