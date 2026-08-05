library(ggplot2)
library(dplyr)
library(tidybayes)
library(brms)

fit_var <- readRDS(here::here("cache", "hier_5_var_rs.rds"))

# Extract posterior draws for the fixed effects of the discrimination parameter
draws_disc <- fit_var |>
  gather_draws(`b_disc_social_c`, `b_disc_economic_c`, `b_disc_educ_c`, `b_disc_peduc_c`, `b_disc_arts_c`, regex = TRUE) |>
  mutate(
    .variable = case_when(
      .variable == "b_disc_social_c" ~ "Social Conservatism",
      .variable == "b_disc_economic_c" ~ "Economic Conservatism",
      .variable == "b_disc_educ_c" ~ "Education (Continuous)",
      .variable == "b_disc_peduc_c" ~ "Parental Education (Continuous)",
      .variable == "b_disc_arts_c" ~ "Arts Exposure (Continuous)",
      TRUE ~ .variable
    )
  ) |>
  mutate(
    .variable = factor(.variable, levels = c(
      "Parental Education (Continuous)",
      "Education (Continuous)",
      "Arts Exposure (Continuous)",
      "Economic Conservatism",
      "Social Conservatism"
    ))
  )

p_forest <- ggplot(draws_disc, aes(x = .value, y = .variable)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
  stat_halfeye(fill = "steelblue", slab_alpha = 0.35, .width = c(0.8, 0.95)) +
  labs(
    title = "Demographic Effects on Cultural Consensus",
    subtitle = "Positive = Higher Consensus (Lower Variance)\nNegative = Lower Consensus (Higher Variance)",
    x = "Effect on Discrimination Parameter (Log Scale)",
    y = ""
  ) +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(face = "bold"))

ggsave("Plots/cuisine-acat-multilevel/demographic_variance_effects_forest.png", p_forest, width = 8, height = 6)
cat("Saved demographic forest plot to Plots/cuisine-acat-multilevel/demographic_variance_effects_forest.png\n")
