#!/usr/bin/env Rscript
.libPaths(c("/home/omarlizardo/CULTURE PROJECTS/CLAYTON PROJECTS/childress-lizardo-cuisine-authenticity-taste/renv/library/linux-debian-trixie/R-4.5/x86_64-pc-linux-gnu", .libPaths()))

suppressPackageStartupMessages({
  library(tidyverse)
  library(haven)
  library(brms)
  library(here)
})

cat("Starting model fitting process for Random Slopes Model (Education by Cuisine)...\n")

source(here::here("data", "recode.dat.R"))
dat <- recode.dat()
dat$respondent_id <- seq_len(nrow(dat))

cuisines_cols <- c("japanese", "french", "italian", "mexican", "moroccan", 
                   "korean", "peruvian", "native_american", "swedish", 
                   "pakistani", "ethiopian", "vietnamese", "nigerian", 
                   "jamaican", "lebanese")
demographics <- c("age.f", "race.f", "gend.f", "educ", "inc.f", "city.f", "arts.f")

dat_long <- dat |>
  select(respondent_id, all_of(cuisines_cols), all_of(demographics), social) |>
  pivot_longer(cols = all_of(cuisines_cols), names_to = "cuisine", values_to = "rating") |>
  filter(!is.na(rating), !is.na(social), !is.na(educ)) |>
  mutate(
    rating_ord = factor(rating, levels = 1:7, ordered = TRUE),
    cuisine = as.factor(cuisine),
    respondent_id = as.factor(respondent_id),
    social_c = scale(social, center = TRUE, scale = FALSE),
    educ_c = scale(educ, center = TRUE, scale = FALSE)
  )

# Random slopes for education (treated as continuous and mean-centered) by cuisine
formula_rs_educ <- bf(
  rating_ord ~ 1 + social_c + age.f + race.f + gend.f + educ_c + inc.f + arts.f + 
    (1 | respondent_id) + (1 + educ_c | cuisine)
)

cat("Fitting Random Slopes Model (Education)...\n")
fit_rs_educ <- brm(
  formula = formula_rs_educ,
  data = dat_long,
  family = acat("logit"),
  prior = c(
    prior(normal(0, 1.5), class = "Intercept"),
    prior(normal(0, 1), class = "b"),
    prior(exponential(1), class = "sd"),
    prior(lkj(2), class = "cor")
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

cat("Saving fit_rs_educ_acat.rds...\n")
saveRDS(fit_rs_educ, file = here::here("cache", "fit_rs_educ_acat.rds"))

gc()

cat("Computing WAIC (subsampled)...\n")
fit_rs_educ <- add_criterion(fit_rs_educ, "waic", ndraws = 1000)
saveRDS(fit_rs_educ, file = here::here("cache", "fit_rs_educ_acat.rds"))

cat("Loading base strict model for comparison...\n")
fit_strict <- readRDS(here::here("cache", "fit_strict_acat.rds"))
if (is.null(fit_strict$criteria$waic)) {
    fit_strict <- add_criterion(fit_strict, "waic", ndraws = 1000)
    saveRDS(fit_strict, file = here::here("cache", "fit_strict_acat.rds"))
}

waic_comp_rs_educ <- loo_compare(fit_strict, fit_rs_educ, criterion = "waic")
saveRDS(waic_comp_rs_educ, file = here::here("cache", "waic_comparison_rs_educ.rds"))

sink(here::here("cache", "waic_comparison_rs_educ.txt"))
print(waic_comp_rs_educ)
sink()

cat("Finished!\n")