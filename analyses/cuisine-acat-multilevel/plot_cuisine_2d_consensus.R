#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(brms)
  library(tidybayes)
  library(tidyverse)
  library(ggrepel)
  library(here)
})

cat("Loading model...\n")
fit <- readRDS(here::here("cache", "hier_4_var.rds"))

cat("Extracting posterior draws...\n")
draws_loc <- fit |> 
  spread_draws(r_cuisine[cuisine, term]) |>
  filter(term == "Intercept") |>
  rename(loc_effect = r_cuisine)

draws_disc <- fit |> 
  spread_draws(r_cuisine__disc[cuisine, term]) |>
  filter(term == "Intercept") |>
  rename(disc_effect = r_cuisine__disc)

# Combine and summarize
summary_df <- draws_loc |>
  left_join(draws_disc, by = c(".chain", ".iteration", ".draw", "cuisine")) |>
  group_by(cuisine) |>
  summarize(
    loc_med = median(loc_effect),
    loc_lower = quantile(loc_effect, 0.025),
    loc_upper = quantile(loc_effect, 0.975),
    disc_med = median(disc_effect),
    disc_lower = quantile(disc_effect, 0.025),
    disc_upper = quantile(disc_effect, 0.975),
    .groups = "drop"
  ) |>
  mutate(cuisine_label = str_to_title(str_replace_all(cuisine, "_", " ")))

cat("Generating plot...\n")
p <- ggplot(summary_df, aes(x = loc_med, y = disc_med)) +
  # Draw quadrants if desired, based on 0,0 (average effect)
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray60", alpha = 0.7) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray60", alpha = 0.7) +
  # 2D error bars
  geom_errorbar(aes(ymin = disc_lower, ymax = disc_upper), width = 0, color = "gray40", alpha = 0.5) +
  geom_errorbarh(aes(xmin = loc_lower, xmax = loc_upper), height = 0, color = "gray40", alpha = 0.5) +
  # Points
  geom_point(size = 3, color = "#2c3e50") +
  # Labels
  geom_label_repel(aes(label = cuisine_label), size = 4.5, box.padding = 0.5, point.padding = 0.3, max.overlaps = 20) +
  theme_minimal(base_size = 14) +
  labs(
    title = "Cuisine Authenticity: Consensus vs. Type",
    subtitle = "Posterior medians and 95% CIs for Cuisine Random Effects (Model 4: Distributional Variance)",
    x = "← Traditional Elder          Location (Intercept)                Professional Chef →",
    y = "← High Disagreement          Consensus (Disc Parameter)          High Agreement →"
  ) +
  theme(
    plot.title = element_text(face = "bold"),
    plot.subtitle = element_text(color = "gray30", margin = margin(b = 15)),
    axis.title.x = element_text(margin = margin(t = 15), face = "bold"),
    axis.title.y = element_text(margin = margin(r = 15), face = "bold")
  )

out_path <- here::here("Plots", "cuisine-acat-multilevel", "cuisine_2d_consensus.png")
ggsave(out_path, p, width = 10, height = 8, dpi = 300, bg = "white")

cat("Plot saved to:", out_path, "\n")
