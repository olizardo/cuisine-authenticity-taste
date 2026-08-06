#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(brms)
  library(tidybayes)
  library(here)
  library(tidyr)
})

cat("Loading Random Slopes model...\n")
fit_rs <- readRDS(here::here("cache", "hier_3_rs.rds"))

cat("Extracting posterior draws for all cuisine-specific slopes...\n")
draws_rs <- fit_rs |>
  gather_draws(r_cuisine[cuisine, term]) |>
  filter(term %in% c("social_c", "economic_c", "educ_c", "peduc_c", "arts_c"))

draws_b <- fit_rs |>
  gather_draws(b_social_c, b_economic_c, b_educ_c, b_peduc_c, b_arts_c) |>
  mutate(term = sub("^b_", "", .variable)) |>
  ungroup() |>
  select(.draw, term, global_effect = .value)

draws <- draws_rs |>
  left_join(draws_b, by = c(".draw", "term")) |>
  mutate(
    cuisine_slope = .value + global_effect,
    cuisine_label = stringr::str_to_title(gsub("_", " ", cuisine)),
    Term_Label = case_when(
      term == "social_c" ~ "Social Conservatism",
      term == "economic_c" ~ "Economic Conservatism",
      term == "educ_c" ~ "Education",
      term == "peduc_c" ~ "Parental Education",
      term == "arts_c" ~ "Arts Exposure"
    ),
    Term_Label = factor(Term_Label, levels = c(
      "Education", "Parental Education", 
      "Social Conservatism", "Economic Conservatism", 
      "Arts Exposure"
    ))
  )

# Reverse alphabetical order for y-axis so it plots A-Z top to bottom
draws <- draws |>
  mutate(cuisine_label = factor(cuisine_label, levels = rev(sort(unique(cuisine_label)))))

cat("Creating ideology plot...\n")
draws_ideology <- draws |> filter(term %in% c("social_c", "economic_c"))
p_ideology <- ggplot(draws_ideology, aes(x = cuisine_slope, y = cuisine_label)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50", linewidth = 1) +
  stat_halfeye(fill = "coral", slab_alpha = 0.35, .width = c(0.8, 0.95)) +
  facet_wrap(~Term_Label, ncol = 2, scales = "free_x") +
  theme_minimal(base_size = 14) +
  labs(
    title = "Ideological Effects by Cuisine (Random Slopes)",
    subtitle = "Positive value: Variable pushes ratings toward 'Professional Chef' (7)\nNegative value: Variable pushes ratings toward 'Traditional Elder' (1)",
    x = "Log-Odds Shift (Per 1-unit increase)",
    y = "Cuisine"
  ) +
  theme(
    plot.title = element_text(face = "bold"),
    axis.text.y = element_text(face = "bold", size = 11),
    strip.text = element_text(face = "bold", size = 12)
  )

out_file_ideology <- here::here("Plots", "cuisine-acat-multilevel", "rs_cuisine_slopes_ideology.png")
ggsave(out_file_ideology, plot = p_ideology, width = 10, height = 7, bg = "white")

cat("Creating cultural capital plot...\n")
draws_cultural <- draws |> filter(term %in% c("educ_c", "peduc_c", "arts_c"))
p_cultural <- ggplot(draws_cultural, aes(x = cuisine_slope, y = cuisine_label)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50", linewidth = 1) +
  stat_halfeye(fill = "mediumseagreen", slab_alpha = 0.35, .width = c(0.8, 0.95)) +
  facet_wrap(~Term_Label, ncol = 3, scales = "free_x") +
  theme_minimal(base_size = 14) +
  labs(
    title = "Cultural Capital Effects by Cuisine (Random Slopes)",
    subtitle = "Positive value: Variable pushes ratings toward 'Professional Chef' (7)\nNegative value: Variable pushes ratings toward 'Traditional Elder' (1)",
    x = "Log-Odds Shift (Per 1-unit increase)",
    y = "Cuisine"
  ) +
  theme(
    plot.title = element_text(face = "bold"),
    axis.text.y = element_text(face = "bold", size = 11),
    strip.text = element_text(face = "bold", size = 12)
  )

out_file_cultural <- here::here("Plots", "cuisine-acat-multilevel", "rs_cuisine_slopes_cultural.png")
ggsave(out_file_cultural, plot = p_cultural, width = 13, height = 7, bg = "white")

cat("Plots successfully saved\n")
