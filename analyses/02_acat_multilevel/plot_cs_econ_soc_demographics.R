library(ggplot2)
library(dplyr)
library(tidybayes)
library(tidyr)
library(brms)
library(forcats)

fit_econ <- readRDS("cache/fit_cs_econ_soc_acat.rds")

# Extract posterior draws for the strict demographic fixed effects from the Econ/Soc model
draws_demog <- fit_econ |>
  gather_draws(
    `b_educ.fHighSchoolorLess`, `b_educ.fSomeCollege`, `b_educ.fProf.DGraduateDegree`,
    `b_gend.fWoman`,
    `b_race.fAsian`, `b_race.fBlack`, `b_race.fHispanic`
  ) |>
  mutate(
    .variable = case_when(
      .variable == "b_educ.fHighSchoolorLess" ~ "Educ: High School or Less",
      .variable == "b_educ.fSomeCollege" ~ "Educ: Some College",
      .variable == "b_educ.fProf.DGraduateDegree" ~ "Educ: Prof/Grad Degree",
      .variable == "b_gend.fWoman" ~ "Gender: Woman",
      .variable == "b_race.fAsian" ~ "Race: Asian",
      .variable == "b_race.fBlack" ~ "Race: Black",
      .variable == "b_race.fHispanic" ~ "Race: Hispanic",
      TRUE ~ .variable
    )
  )

# Calculate the average effect for the category-specific variables
draws_ideology_avg <- fit_econ |>
  spread_draws(`bcs_social_c\\[.*`, `bcs_economic_c\\[.*`, regex = TRUE) |>
  mutate(
    `Social Conservatism (Avg)` = (`bcs_social_c[1]` + `bcs_social_c[2]` + `bcs_social_c[3]` + `bcs_social_c[4]` + `bcs_social_c[5]` + `bcs_social_c[6]`) / 6,
    `Economic Conservatism (Avg)` = (`bcs_economic_c[1]` + `bcs_economic_c[2]` + `bcs_economic_c[3]` + `bcs_economic_c[4]` + `bcs_economic_c[5]` + `bcs_economic_c[6]`) / 6
  ) |>
  select(.chain, .iteration, .draw, `Social Conservatism (Avg)`, `Economic Conservatism (Avg)`) |>
  pivot_longer(
    cols = c(`Social Conservatism (Avg)`, `Economic Conservatism (Avg)`),
    names_to = ".variable",
    values_to = ".value"
  )

# Combine them with the regular demographic draws
draws_combined <- bind_rows(draws_demog, draws_ideology_avg) |>
  mutate(
    .variable = factor(.variable, levels = c(
      "Educ: High School or Less",
      "Educ: Some College",
      "Educ: Prof/Grad Degree",
      "Economic Conservatism (Avg)",
      "Social Conservatism (Avg)",
      "Gender: Woman",
      "Race: Asian",
      "Race: Black",
      "Race: Hispanic"
    ))
  )

p_demog_forest_combined <- ggplot(draws_combined, aes(x = .value, y = .variable)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50", linewidth = 1) +
  stat_halfeye(fill = "mediumpurple", alpha = 0.7, .width = c(0.8, 0.95)) +
  labs(
    title = "Demographic Effects (Controlling for Econ & Social Ideology)",
    subtitle = "Positive = More likely to rate as 'Professional Chef' (7)\nNegative = More likely to rate as 'Traditional Elder' (1)\n*Ideology effects are averaged across thresholds*",
    x = "Log-Odds Shift (Location Parameter)",
    y = ""
  ) +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(face = "bold"))

ggsave("Plots/02_acat_multilevel/cs_econ_soc_demographic_effects.png", p_demog_forest_combined, width = 9, height = 7, bg = "white")
cat("Saved plot to Plots/02_acat_multilevel/cs_econ_soc_demographic_effects.png\n")
