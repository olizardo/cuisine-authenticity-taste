#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(tidyverse)
  library(haven)
  library(brms)
  library(here)
})

cat("Starting model fitting process for Random Slopes Model (Strict Effects)...\n")

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

formula_rs_strict <- bf(
  rating_ord ~ 1 + social_c + age.f + race.f + gend.f + educ.f + inc.f + 
    (1 | respondent_id) + (1 + social_c | cuisine)
)

cat("Fitting Random Slopes Model (Strict Effects)...\n")
fit_rs_strict <- brm(
  formula = formula_rs_strict,
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
  backend = "cmdstanr",
  save_pars = save_pars(all = FALSE)
)

cat("Saving fit_strict_rs_acat.rds...\n")
saveRDS(fit_rs_strict, file = here::here("cache", "fit_strict_rs_acat.rds"))

gc()

cat("Computing WAIC (subsampled)...\n")
fit_rs_strict <- add_criterion(fit_rs_strict, "waic", ndraws = 1000)
saveRDS(fit_rs_strict, file = here::here("cache", "fit_strict_rs_acat.rds"))

cat("Loading base strict model for comparison...\n")
fit_strict <- readRDS(here::here("cache", "fit_strict_acat.rds"))
# Check if fit_strict has waic. If not, add it.
if (is.null(fit_strict$criteria$waic)) {
    fit_strict <- add_criterion(fit_strict, "waic", ndraws = 1000)
    saveRDS(fit_strict, file = here::here("cache", "fit_strict_acat.rds"))
}

waic_comp_rs <- loo_compare(fit_strict, fit_rs_strict, criterion = "waic")
saveRDS(waic_comp_rs, file = here::here("cache", "waic_comparison_rs_strict.rds"))

sink(here::here("cache", "waic_comparison_rs_strict.txt"))
print(waic_comp_rs)
sink()

cat("Finished Step 2!\n")
