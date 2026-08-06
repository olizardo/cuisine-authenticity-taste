#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(brms)
  library(tidybayes)
  library(tidyverse)
  library(here)
})

cat("Loading best fitting model (hier_5_var_rs)...\n")
fit <- readRDS(here::here("cache", "hier_5_var_rs.rds"))

cat("Extracting demographic fixed effects...\n")
draws <- fit |>
  gather_draws(b_educ_c, b_peduc_c, b_social_c, b_economic_c, b_income_c, 
               b_age_c, b_arts_c, b_gend.fWoman, b_gend.fNonbinaryDOther, 
               b_race.fAsian, b_race.fBlack, b_race.fHispanic, 
               b_race.fMixedOther, b_race.fMixedWhite) |>
  mutate(
    Predictor = case_when(
      .variable == "b_social_c" ~ "Social Conservatism",
      .variable == "b_economic_c" ~ "Economic Conservatism",
      .variable == "b_educ_c" ~ "Education",
      .variable == "b_peduc_c" ~ "Parental Education",
      .variable == "b_income_c" ~ "Income",
      .variable == "b_age_c" ~ "Age",
      .variable == "b_arts_c" ~ "Childhood Arts Exposure",
      .variable == "b_gend.fWoman" ~ "Gender: Woman",
      .variable == "b_gend.fNonbinaryDOther" ~ "Gender: Nonbinary/Other",
      .variable == "b_race.fAsian" ~ "Race: Asian",
      .variable == "b_race.fBlack" ~ "Race: Black",
      .variable == "b_race.fHispanic" ~ "Race: Hispanic",
      .variable == "b_race.fMixedOther" ~ "Race: Mixed/Other",
      .variable == "b_race.fMixedWhite" ~ "Race: Mixed White"
    ),
    Category = case_when(
      grepl("social|economic", .variable) ~ "Ideology (SD)",
      grepl("educ|peduc|income|arts", .variable) ~ "Capital & Socialization (SD)",
      grepl("age", .variable) ~ "Demographics (SD)",
      grepl("gend", .variable) ~ "Gender (vs. Man)",
      grepl("race", .variable) ~ "Race (vs. White)"
    )
  ) |>
  # Order by median effect size for a cleaner look
  group_by(Predictor) |>
  mutate(med_val = median(.value)) |>
  ungroup() |>
  mutate(Predictor = fct_reorder(Predictor, med_val))

cat("Creating Forest Plot...\n")
p <- ggplot(draws, aes(x = .value, y = Predictor, fill = Category)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray30", linewidth = 1) +
  stat_halfeye(alpha = 0.7, .width = c(0.8, 0.95)) +
  scale_fill_viridis_d(option = "turbo", end = 0.9) +
  theme_minimal(base_size = 14) +
  labs(
    title = "Demographic Fixed Effects on Authenticity Ratings",
    subtitle = "Posterior distributions from best-fitting model (Variance + Random Slopes)\nPositive values push ratings toward 'Professional Chef' (7) | Negative toward 'Elder' (1)",
    x = "Effect Size (Log-Odds Shift)",
    y = NULL,
    fill = "Variable Type"
  ) +
  theme(
    plot.title = element_text(face = "bold"),
    plot.subtitle = element_text(color = "gray30", margin = margin(b = 15)),
    legend.position = "bottom",
    panel.grid.major.y = element_blank()
  )

out_path <- here::here("Plots", "cuisine-acat-multilevel", "demographic_fixed_effects.png")
ggsave(out_path, p, width = 11, height = 8, dpi = 300, bg = "white")

cat("Plot saved to:", out_path, "\n")
