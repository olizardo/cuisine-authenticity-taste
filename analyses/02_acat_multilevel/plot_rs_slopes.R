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
# Extract the random effects for cuisine.
# The term is r_cuisine[cuisine_name,social_c] which is the deviation from the fixed effect.
# The fixed effect is b_social_c.
# Total cuisine-specific slope = b_social_c + r_cuisine[cuisine_name,social_c]

# We can use tidybayes for a cleaner extraction of random effects plus the global effect
draws <- fit_rs |>
  spread_draws(b_social_c, r_cuisine[cuisine, term]) |>
  filter(term == "social_c") |>
  mutate(cuisine_slope = b_social_c + r_cuisine) |>
  group_by(cuisine) |>
  summarise(
    estimate = mean(cuisine_slope),
    conf.low = quantile(cuisine_slope, 0.025),
    conf.high = quantile(cuisine_slope, 0.975)
  ) |>
  ungroup() |>
  # Order cuisines by the size of the slope
  arrange(estimate) |>
  mutate(cuisine = factor(cuisine, levels = cuisine)) |>
  # Clean up cuisine names for the plot
  mutate(cuisine_label = stringr::str_to_title(gsub("_", " ", cuisine)))

cat("Creating plot...\n")
p_slopes <- ggplot(draws, aes(x = estimate, y = reorder(cuisine_label, estimate))) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "black", linewidth = 0.8) +
  geom_point(size = 3, color = "dodgerblue4") +
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high), width = 0.2, linewidth = 0.8, color = "dodgerblue4") +
  theme_minimal() +
  labs(
    title = "Effect of Social Conservatism by Cuisine",
    subtitle = "Positive value: Conservatism pushes ratings toward 'Professional Chef' (7)\nNegative value: Conservatism pushes ratings toward 'Traditional Elder' (1)",
    x = "Log-Odds Shift (Per 1-unit increase in Conservatism)",
    y = "Cuisine"
  ) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    axis.text.y = element_text(face = "bold", size = 11),
    axis.text.x = element_text(size = 11)
  )

out_file <- here::here("Plots", "02_acat_multilevel", "rs_cuisine_slopes.png")
ggsave(out_file, plot = p_slopes, width = 8, height = 6, bg = "white")

cat("Plot successfully saved to", out_file, "\n")