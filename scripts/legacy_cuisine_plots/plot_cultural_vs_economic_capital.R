#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(brms)
  library(dplyr)
  library(ggplot2)
  library(tidybayes)
  library(tidyr)
  library(here)
  library(forcats)
})

cat("Loading model...\n")
fit <- readRDS(here::here("cache", "hier_4_var.rds"))

cat("Extracting fixed effects...\n")
draws <- fit |> 
  spread_draws(b_educ_c, b_peduc_c, b_income_c) |>
  pivot_longer(
    cols = starts_with("b_"),
    names_to = "Predictor",
    values_to = "Effect"
  ) |>
  mutate(
    Predictor = case_when(
      Predictor == "b_educ_c" ~ "Education (Cultural Capital)",
      Predictor == "b_peduc_c" ~ "Parental Education (Inherited Cultural)",
      Predictor == "b_income_c" ~ "Income (Economic Capital)"
    ),
    Predictor = factor(Predictor, levels = c(
      "Education (Cultural Capital)",
      "Parental Education (Inherited Cultural)",
      "Income (Economic Capital)"
    ))
  )

cat("Creating Forest Plot...\n")
p <- ggplot(draws, aes(x = Effect, y = fct_rev(Predictor), fill = Predictor)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "black", linewidth = 1) +
  stat_halfeye(
    alpha = 0.7, 
    .width = c(0.8, 0.95),
    point_interval = median_qi
  ) +
  scale_fill_manual(values = c(
    "Education (Cultural Capital)" = "#2980b9",
    "Parental Education (Inherited Cultural)" = "#3498db",
    "Income (Economic Capital)" = "#27ae60"
  )) +
  theme_minimal(base_size = 14) +
  labs(
    title = "Cultural vs. Economic Capital: Decoupled Effects on Authenticity",
    subtitle = "Posterior distributions of a 1-SD increase in capital on rating (Model 4: Distributional Variance)\nPositive values push ratings toward 'Professional Chef' (7).",
    x = "Effect Size (Log-Odds shift per 1 SD increase)",
    y = NULL
  ) +
  theme(
    plot.title = element_text(face = "bold"),
    plot.subtitle = element_text(color = "gray30", margin = margin(b = 15)),
    legend.position = "none",
    axis.text.y = element_text(face = "bold", size = 12),
    panel.grid.major.y = element_blank()
  )

out_path <- here::here("Plots", "cuisine-acat-multilevel", "cultural_vs_economic_capital.png")
ggsave(out_path, p, width = 10, height = 5, dpi = 300, bg = "white")

cat("Plot saved to:", out_path, "\n")
