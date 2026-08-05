#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(brms)
  library(tidybayes)
  library(here)
})

cat("Loading category-specific model...\n")
fit <- readRDS(here::here("cache", "hier_1_baseline.rds"))

cat("Extracting cuisine random effects as posterior draws...\n")
draws <- fit |>
  spread_draws(r_cuisine[cuisine, term]) |>
  filter(term == "Intercept") |>
  mutate(
    Cuisine = stringr::str_to_title(gsub("_", " ", cuisine))
  )

# Calculate summary to determine colors based on 95% CIs
summary_df <- draws |>
  group_by(Cuisine) |>
  median_qi(r_cuisine, .width = 0.95) |>
  mutate(
    Lean = case_when(
      .upper < 0 ~ "Elder at Home",
      .lower > 0 ~ "Professional Chef",
      TRUE ~ "Neutral (Crosses 0)"
    )
  )

# Join the lean category back to the draws for coloring
draws <- draws |>
  left_join(select(summary_df, Cuisine, Lean), by = "Cuisine")

# Reorder cuisine by median estimate for the plot
draws <- draws |>
  mutate(Cuisine = factor(Cuisine, levels = summary_df$Cuisine[order(summary_df$r_cuisine)]))

cat("Creating half-eye plot...\n")
p_ranef <- ggplot(draws, aes(x = r_cuisine, y = Cuisine, fill = Lean)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50", linewidth = 1) +
  stat_halfeye(slab_alpha = 0.35, .width = c(0.8, 0.95)) +
  scale_fill_manual(values = c("Elder at Home" = "firebrick", "Neutral (Crosses 0)" = "gray40", "Professional Chef" = "steelblue")) +
  theme_minimal(base_size = 14) +
  labs(
    title = "Baseline Authenticity Leans by Cuisine",
    subtitle = "Extracted from random intercepts. Negative = Elder at Home, Positive = Pro Chef.",
    x = "Log-Odds Shift (Baseline Lean)",
    y = NULL,
    fill = "Credible Baseline Lean:"
  ) +
  theme(
    legend.position = "bottom",
    axis.text.y = element_text(face = "bold", size = 11),
    plot.title = element_text(face = "bold")
  )

out_file <- here::here("Plots", "02_acat_multilevel", "cuisine_random_effects.png")
ggsave(out_file, plot = p_ranef, width = 9, height = 7, bg = "white")

cat("Plot successfully saved to", out_file, "\n")
