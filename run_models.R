#!/usr/bin/env Rscript
.libPaths(c("/home/omarlizardo/CULTURE PROJECTS/CLAYTON PROJECTS/childress-lizardo-cuisine-authenticity-taste/renv/library/linux-debian-trixie/R-4.5/x86_64-pc-linux-gnu", .libPaths()))

# Run Bayesian Adjacent Category Mixed Effects Models in the Background
# Saves output to .rds files for later loading in Quarto or interactive sessions

suppressPackageStartupMessages({
  library(tidyverse)
  library(haven)
  library(brms)
  library(here)
})

cat("Starting model fitting process for Model 2 only...\n")

# 2. Data Preparation
cat("Loading and preparing data...\n")
source(here::here("recode.dat.R"))
dat <- recode.dat()

dat$respondent_id <- seq_len(nrow(dat))

cuisines_cols <- c("japanese", "french", "italian", "mexican", "moroccan", 
                   "korean", "peruvian", "native_american", "swedish", 
                   "pakistani", "ethiopian", "vietnamese", "nigerian", 
                   "jamaican", "lebanese")

demographics <- c("age.f", "race.f", "gend.f", "educ.f", "inc.f", "city.f")

dat_long <- dat |>
  select(respondent_id, all_of(cuisines_cols), all_of(demographics), social, spol.f) |>
  pivot_longer(
    cols = all_of(cuisines_cols),
    names_to = "cuisine",
    values_to = "rating"
  ) |>
  filter(!is.na(rating), !is.na(social)) |>
  mutate(
    rating_ord = factor(rating, levels = 1:7, ordered = TRUE),
    cuisine = as.factor(cuisine),
    respondent_id = as.factor(respondent_id),
    social_c = scale(social, center = TRUE, scale = FALSE)
  )

formula_cs <- bf(
  rating_ord ~ 1 + cs(social_c) + age.f + race.f + gend.f + educ.f + inc.f + 
    (1 | respondent_id) + (1 | cuisine)
)

# 4. Fit Category-Specific Model
cat("Fitting Model 2: Category-Specific Effects Model...\n")
fit_cs <- brm(
  formula = formula_cs,
  data = dat_long,
  family = acat("logit"),
  prior = c(
    prior(normal(0, 1.5), class = "Intercept"),
    prior(normal(0, 1), class = "b"),
    prior(exponential(1), class = "sd")
  ),
  chains = 4,
  cores = 4,
  iter = 2000,
  seed = 1234,
  backend = "rstan"
)
fit_cs <- add_criterion(fit_cs, "loo")
cat("Saving fit_cs_acat.rds...\n")
saveRDS(fit_cs, file = here::here("fit_cs_acat.rds"))

# 5. Model Comparison
cat("Loading Model 1 from disk to run model comparison...\n")
fit_strict <- readRDS(here::here("fit_strict_acat.rds"))

cat("Comparing models and saving comparison summary...\n")
loo_comp <- loo_compare(fit_strict, fit_cs)
saveRDS(loo_comp, file = here::here("loo_comparison.rds"))
sink(here::here("loo_comparison.txt"))
print(loo_comp)
sink()

cat("Finished! All models and comparisons have been saved to disk.\n")
