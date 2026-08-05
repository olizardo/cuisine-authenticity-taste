library(ggplot2)
library(dplyr)
library(tidybayes)
library(brms)

fit_strict <- readRDS(here::here("cache", "hier_1_baseline.rds"))

# Extract posterior draws for key demographic fixed effects
draws_strict <- fit_strict |>
  gather_draws(
    `b_social_c`, `b_economic_c`, `b_educ_c`, `b_peduc_c`, `b_arts_c`,
    `b_gend.fWoman`,
    `b_race.fAsian`, `b_race.fBlack`, `b_race.fHispanic`
  ) |>
  mutate(
    .variable = case_when(
      .variable == "b_social_c" ~ "Social Conservatism",
      .variable == "b_economic_c" ~ "Economic Conservatism",
      .variable == "b_educ_c" ~ "Education (Continuous)",
      .variable == "b_peduc_c" ~ "Parental Education (Continuous)",
      .variable == "b_arts_c" ~ "Arts Exposure",
      .variable == "b_gend.fWoman" ~ "Gender: Woman",
      .variable == "b_race.fAsian" ~ "Race: Asian",
      .variable == "b_race.fBlack" ~ "Race: Black",
      .variable == "b_race.fHispanic" ~ "Race: Hispanic",
      TRUE ~ .variable
    )
  ) |>
  mutate(
    .variable = factor(.variable, levels = c(
      "Parental Education (Continuous)",
      "Education (Continuous)",
      "Arts Exposure",
      "Economic Conservatism",
      "Social Conservatism",
      "Gender: Woman",
      "Race: Asian",
      "Race: Black",
      "Race: Hispanic"
    ))
  )

p_strict_forest <- ggplot(draws_strict, aes(x = .value, y = .variable)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50", linewidth = 1) +
  stat_halfeye(fill = "mediumseagreen", slab_alpha = 0.35, .width = c(0.8, 0.95)) +
  labs(
    title = "Demographic Effects on Authenticity Ratings",
    subtitle = "Positive Values = More likely to rate cuisine as 'Professional Chef' (7)\nNegative Values = More likely to rate cuisine as 'Traditional Elder' (1)",
    x = "Log-Odds Shift (Location Parameter)",
    y = ""
  ) +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(face = "bold"))

ggsave("Plots/02_acat_multilevel/strict_demographic_effects_forest.png", p_strict_forest, width = 9, height = 7)
cat("Saved plot to Plots/02_acat_multilevel/strict_demographic_effects_forest.png\n")
