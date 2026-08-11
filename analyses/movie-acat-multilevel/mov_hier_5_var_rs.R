#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(tidyverse)
  library(brms)
  library(here)
})

cat("Starting mov 5_var_rs Model...\n")
source(here::here("data", "recode.qualtrics.R"))
dat <- recode.qualtrics()
dat$respondent_id <- seq_len(nrow(dat))

genres_cols <- c("mov_comedy", "mov_drama", "mov_doc", "mov_animat", "mov_action", "mov_scifi", "mov_horror", "mov_crime", "mov_musicl", "mov_romanc", "mov_thrill", "mov_intl", "mov_classc")

dat_long <- dat |>
  select(respondent_id, all_of(genres_cols), gend.f, race.f, social_c, economic_c, educ_c, peduc_c, income_c, age_c, arts_c) |>
  pivot_longer(cols = all_of(genres_cols), names_to = "genre", values_to = "rating") |>
  filter(!is.na(rating), !is.na(social_c), !is.na(economic_c), !is.na(educ_c), !is.na(peduc_c), !is.na(arts_c),
         !is.na(income_c), !is.na(age_c), !is.na(gend.f), !is.na(race.f)) |>
  mutate(
    rating_ord = factor(rating, levels = 1:7, ordered = TRUE),
    genre = as.factor(genre),
    respondent_id = as.factor(respondent_id)
  )


formula_mod <- bf(
  rating_ord ~ 1 + educ_c + peduc_c + social_c + economic_c + income_c + age_c + arts_c + gend.f + race.f + (1 | respondent_id) + (1 + educ_c + peduc_c + social_c + economic_c + arts_c | genre),
  disc ~ 1 + educ_c + peduc_c + social_c + economic_c + arts_c + (1 + educ_c + peduc_c + social_c + economic_c + arts_c | genre)
)
prior_mod <- c(
  prior(normal(0, 1.5), class = "Intercept"),
  prior(normal(0, 1), class = "b"),
  prior(lkj(2), class = "cor")
)


fit <- brm(
  formula = formula_mod,
  data = dat_long,
  family = acat("logit"),
  prior = prior_mod,
  chains = 4, cores = 4, iter = 1000, warmup = 500, seed = 1234,
  control = list(adapt_delta = 0.85),
  backend = "cmdstanr", threads = threading(3),
  save_pars = save_pars(all = FALSE)
)

saveRDS(fit, file = here::here("cache", "mov_hier_5_var_rs.rds"))
fit <- add_criterion(fit, "waic", ndraws = 1000)
saveRDS(fit, file = here::here("cache", "mov_hier_5_var_rs.rds"))
cat("Finished mov Model 5_var_rs!\n")
