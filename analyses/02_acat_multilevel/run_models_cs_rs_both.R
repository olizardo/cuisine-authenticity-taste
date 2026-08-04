#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(tidyverse)
  library(haven)
  library(brms)
  library(here)
})

cat("Starting model fitting process for Social + Economic CS + Random Slopes Model...\n")

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

formula_cs_rs_both <- bf(
  rating_ord ~ 1 + cs(social_c) + cs(economic_c) + age.f + race.f + gend.f + educ.f + inc.f + arts.f + 
    (1 | respondent_id) + (1 + social_c + economic_c | cuisine)
)

cat("Fitting Model...\n")
fit_cs_rs_both <- brm(
  formula = formula_cs_rs_both,
  data = dat_long,
  family = acat("logit"),
  prior = c(
    prior(normal(0, 1.5), class = "Intercept"),
    prior(normal(0, 1), class = "b"),
    prior(exponential(1), class = "sd")
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

cat("Saving fit_cs_rs_both_acat.rds...\n")
saveRDS(fit_cs_rs_both, file = here::here("cache", "fit_cs_rs_both_acat.rds"))

gc()

cat("Computing WAIC (subsampled)...\n")
fit_cs_rs_both <- add_criterion(fit_cs_rs_both, "waic", ndraws = 1000)
saveRDS(fit_cs_rs_both, file = here::here("cache", "fit_cs_rs_both_acat.rds"))

cat("Loading base CS model for comparison...\n")
fit_cs <- readRDS(here::here("cache", "fit_cs_acat.rds"))
# Check if fit_cs has waic. If not, add it.
if (is.null(fit_cs$criteria$waic)) {
    fit_cs <- add_criterion(fit_cs, "waic", ndraws = 1000)
    saveRDS(fit_cs, file = here::here("cache", "fit_cs_acat.rds"))
}

waic_comp_cs_rs <- loo_compare(fit_cs, fit_cs_rs_both, criterion = "waic")
saveRDS(waic_comp_cs_rs, file = here::here("cache", "waic_comparison_cs_rs_both.rds"))

sink(here::here("cache", "waic_comparison_cs_rs_both.txt"))
print(waic_comp_cs_rs)
sink()

cat("Finished Step 3!\n")
