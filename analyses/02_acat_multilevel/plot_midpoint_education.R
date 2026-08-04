#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(brms)
  library(here)
  library(tidybayes)
  library(tidyr)
  library(forcats)
})

cat("Loading category-specific model...\n")
fit <- readRDS(here::here("cache", "fit_cs_acat.rds"))
draws <- as_draws_df(fit)

cat("Calculating contrasts against the midpoint (4) for College Degree...\n")

# We calculate the difference between the Grad Degree coefficient and the High School coefficient
b_grad_vs_hs <- draws[["b_educ.fProf.DGraduateDegree"]] - draws[["b_educ.fHighSchoolorLess"]]

# Because it's a strict effect, we just multiply it by the steps from the midpoint (4)
plot_data <- tibble::tibble(
  .draw = draws$.draw,
  "1 (Elder at Home) vs 4" = -3 * b_grad_vs_hs,
  "2 vs 4" = -2 * b_grad_vs_hs,
  "3 vs 4" = -1 * b_grad_vs_hs,
  "5 vs 4" =  1 * b_grad_vs_hs,
  "6 vs 4" =  2 * b_grad_vs_hs,
  "7 (Professional Chef) vs 4" = 3 * b_grad_vs_hs
) %>%
  pivot_longer(
    cols = -c(.draw),
    names_to = "Threshold",
    values_to = ".value"
  ) %>%
  mutate(
    Threshold = factor(Threshold, levels = c(
      "1 (Elder at Home) vs 4", 
      "2 vs 4", 
      "3 vs 4", 
      "5 vs 4", 
      "6 vs 4", 
      "7 (Professional Chef) vs 4"
    ))
  )

cat("Creating half-eye plot...\n")
p_midpoint <- ggplot(plot_data, aes(x = .value, y = fct_rev(Threshold))) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "black", linewidth = 1) +
  stat_halfeye(fill = "mediumseagreen", alpha = 0.7, .width = c(0.8, 0.95)) +
  theme_minimal(base_size = 14) +
  labs(
    title = "Effect of Graduate Degree on Authenticity Ratings",
    subtitle = "Relative to High School or Less. Contrasts against neutral (4).\nPositive = More likely to choose rating than neutral.",
    x = "Log-Odds Shift (Grad vs High School)",
    y = "Rating Contrast (vs Neutral 4)"
  ) +
  theme(
    plot.title = element_text(face = "bold"),
    axis.text.y = element_text(face = "bold", size = 11)
  )

out_file <- here::here("Plots", "02_acat_multilevel", "education_midpoint_contrast.png")
ggsave(out_file, plot = p_midpoint, width = 8, height = 6, bg = "white")

cat("Plot successfully saved to", out_file, "\n")
