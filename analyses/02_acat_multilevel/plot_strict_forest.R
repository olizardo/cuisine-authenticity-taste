library(ggplot2)
library(dplyr)
library(tidybayes)
library(brms)

fit_strict <- readRDS("cache/fit_strict_acat.rds")

# Extract posterior draws for key demographic fixed effects
draws_strict <- fit_strict |>
  gather_draws(
    `b_social_c`, 
    `b_educ.fHighSchoolorLess`, `b_educ.fSomeCollege`, `b_educ.fProf.DGraduateDegree`,
    `b_gend.fWoman`,
    `b_race.fAsian`, `b_race.fBlack`, `b_race.fHispanic`
  ) |>
  mutate(
    .variable = case_when(
      .variable == "b_social_c" ~ "Social Conservatism",
      .variable == "b_educ.fHighSchoolorLess" ~ "Educ: High School or Less",
      .variable == "b_educ.fSomeCollege" ~ "Educ: Some College",
      .variable == "b_educ.fProf.DGraduateDegree" ~ "Educ: Prof/Grad Degree",
      .variable == "b_gend.fWoman" ~ "Gender: Woman",
      .variable == "b_race.fAsian" ~ "Race: Asian",
      .variable == "b_race.fBlack" ~ "Race: Black",
      .variable == "b_race.fHispanic" ~ "Race: Hispanic",
      TRUE ~ .variable
    )
  ) |>
  mutate(
    .variable = factor(.variable, levels = c(
      "Educ: High School or Less",
      "Educ: Some College",
      "Educ: Prof/Grad Degree",
      "Social Conservatism",
      "Gender: Woman",
      "Race: Asian",
      "Race: Black",
      "Race: Hispanic"
    ))
  )

p_strict_forest <- ggplot(draws_strict, aes(x = .value, y = .variable)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50", linewidth = 1) +
  stat_halfeye(fill = "mediumseagreen", alpha = 0.7, .width = c(0.8, 0.95)) +
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
