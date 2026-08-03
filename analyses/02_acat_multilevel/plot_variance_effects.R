library(brms)
library(ggplot2)
library(dplyr)
library(tidybayes)

# 1. Load the cached model
fit_var <- readRDS("cache/fit_variance_acat.rds")

# ==========================================
# PLOT 1: Baseline Variance by Cuisine
# ==========================================
# Extract the random intercepts for the discrimination (variance) equation
draws_disc <- fit_var |>
  spread_draws(r_cuisine__disc[cuisine, term]) |>
  filter(term == "Intercept") |>
  mutate(cuisine = stringr::str_to_title(gsub("_", " ", cuisine)))

# Calculate summary to determine colors and ordering
summary_disc <- draws_disc |>
  group_by(cuisine) |>
  median_qi(r_cuisine__disc, .width = 0.95) |>
  mutate(
    consensus_category = case_when(
      .lower > 0 ~ "High Consensus (Above Average)",
      .upper < 0 ~ "Low Consensus (Below Average)",
      TRUE ~ "Average Consensus (Crosses Zero)"
    )
  ) |>
  arrange(r_cuisine__disc)

# Join category and order factor
draws_disc <- draws_disc |>
  left_join(select(summary_disc, cuisine, consensus_category), by = "cuisine") |>
  mutate(cuisine = factor(cuisine, levels = summary_disc$cuisine))

p_baseline_variance <- ggplot(draws_disc, aes(x = r_cuisine__disc, y = cuisine, fill = consensus_category)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "black", linewidth = 1) +
  stat_halfeye(alpha = 0.7, .width = c(0.8, 0.95)) +
  scale_fill_manual(values = c(
    "High Consensus (Above Average)" = "royalblue",
    "Average Consensus (Crosses Zero)" = "gray50",
    "Low Consensus (Below Average)" = "firebrick"
  )) +
  labs(
    title = "Baseline Consensus by Cuisine",
    subtitle = "Zero line = Global Average Consensus across all ratings\nHigher Values (Discrimination) = More Consensus / Less Variance",
    x = "Discrimination Intercept Shift", 
    y = "Cuisine",
    fill = NULL 
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom"
  ) +
  guides(fill = guide_legend(nrow = 3, byrow = TRUE))

ggsave("Plots/02_acat_multilevel/cuisine_variance_baseline.png", p_baseline_variance, width = 8, height = 7)

