#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(tidyverse)
  library(haven)
  library(brms)
  library(here)
})

cat("Starting model fitting...\n")

source(here::here("data", "recode.dat.R"))
dat <- recode.dat()
dat$respondent_id <- seq_len(nrow(dat))

cuisines_cols <- c("japanese", "french", "italian", "mexican", "moroccan", 
                   "korean", "peruvian", "native_american", "swedish", 
                   "pakistani", "ethiopian", "vietnamese", "nigerian", 
                   "jamaican", "lebanese")
# Exclude educ.f, we will use the numerical "educ"
demographics <- c("age.f", "race.f", "gend.f", "inc.f", "city.f", "arts.f")

dat_long <- dat |>
  select(respondent_id, all_of(cuisines_cols), all_of(demographics), social, economic, educ) |>
  pivot_longer(cols = all_of(cuisines_cols), names_to = "cuisine", values_to = "rating") |>
  filter(!is.na(rating), !is.na(social), !is.na(economic), !is.na(educ)) |>
  mutate(
    rating_ord = factor(rating, levels = 1:7, ordered = TRUE),
    cuisine = as.factor(cuisine),
    respondent_id = as.factor(respondent_id),
    social_c = scale(social, center = TRUE, scale = FALSE),
    economic_c = scale(economic, center = TRUE, scale = FALSE),
    educ_c = scale(educ, center = TRUE, scale = FALSE)
  )

formula_mod <- bf(rating_ord ~ 1 + social_c + economic_c + educ_c + age.f + race.f + gend.f + inc.f + arts.f + (1 | respondent_id) + (1 + social_c + economic_c + educ_c | cuisine))

cat("Fitting Model 3: Random Slopes (Strict)...\n")
fit <- brm(
  formula = formula_mod,
  data = dat_long,
  family = acat("logit"),
  prior = c(
    prior(normal(0, 1.5), class = "Intercept"),
    prior(normal(0, 1), class = "b")
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

cat("Saving...\n")
saveRDS(fit, file = here::here("cache", "hier_3_rs.rds"))
gc()

cat("Computing WAIC...\n")
fit <- add_criterion(fit, "waic", ndraws = 1000)
saveRDS(fit, file = here::here("cache", "hier_3_rs.rds"))
cat("Finished!\n")

