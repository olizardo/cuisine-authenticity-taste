#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(brms)
  library(tidybayes)
  library(here)
})

cat("Loading Random Slopes model...\n")
fit_rs <- readRDS(here::here("cache", "fit_strict_rs_acat.rds"))

cat("Extracting posterior draws for cuisine-specific slopes...\n")
draws <- fit_rs |>
  spread_draws(b_social_c, r_cuisine[cuisine, term]) |>
  filter(term == "social_c") |>
  mutate(
    cuisine_slope = b_social_c + r_cuisine,
    cuisine_label = stringr::str_to_title(gsub("_", " ", cuisine))
  )

# Calculate summary to order the y-axis
summary_df <- draws |>
  group_by(cuisine_label) |>
  median_qi(cuisine_slope) |>
  arrange(cuisine_slope)

draws <- draws |>
  mutate(cuisine_label = factor(cuisine_label, levels = summary_df$cuisine_label))

cat("Creating half-eye plot...\n")
p_slopes <- ggplot(draws, aes(x = cuisine_slope, y = cuisine_label)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "black", linewidth = 1) +
  stat_halfeye(fill = "dodgerblue4", alpha = 0.7, .width = c(0.8, 0.95)) +
  theme_minimal(base_size = 14) +
  labs(
    title = "Effect of Social Conservatism by Cuisine",
    subtitle = "Positive value: Conservatism pushes ratings toward 'Professional Chef' (7)\nNegative value: Conservatism pushes ratings toward 'Traditional Elder' (1)",
    x = "Log-Odds Shift (Per 1-unit increase in Conservatism)",
    y = "Cuisine"
  ) +
  theme(
    plot.title = element_text(face = "bold"),
    axis.text.y = element_text(face = "bold", size = 11)
  )

out_file <- here::here("Plots", "02_acat_multilevel", "rs_cuisine_slopes.png")
ggsave(out_file, plot = p_slopes, width = 9, height = 7, bg = "white")

cat("Plot successfully saved to", out_file, "\n")