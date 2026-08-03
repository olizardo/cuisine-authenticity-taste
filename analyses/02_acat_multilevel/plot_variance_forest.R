library(ggplot2)
library(dplyr)
library(tidybayes)
library(brms)

fit_var <- readRDS("cache/fit_variance_acat.rds")

# Extract posterior draws for the fixed effects of the discrimination parameter
draws_disc <- fit_var |>
  gather_draws(`b_disc_social_c`, `b_disc_educ.f.*`, `b_disc_arts.f.*`, regex = TRUE) |>
  mutate(
    .variable = case_when(
      .variable == "b_disc_social_c" ~ "Social Conservatism",
      .variable == "b_disc_educ.fHighSchoolorLess" ~ "Educ: High School or Less",
      .variable == "b_disc_educ.fSomeCollege" ~ "Educ: Some College",
      .variable == "b_disc_educ.fProf.DGraduateDegree" ~ "Educ: Prof/Grad Degree",
      .variable == "b_disc_arts.fLowExposuretoArtsasChild" ~ "Arts: Low Childhood Exposure",
      .variable == "b_disc_arts.fHighExposuretoArtsasChild" ~ "Arts: High Childhood Exposure",
      TRUE ~ .variable
    )
  ) |>
  # Re-order the variables so education is stacked properly, with baseline College Degree implied 
  mutate(
    .variable = factor(.variable, levels = c(
      "Educ: High School or Less",
      "Educ: Some College",
      "Educ: Prof/Grad Degree",
      "Arts: Low Childhood Exposure",
      "Arts: High Childhood Exposure",
      "Social Conservatism"
    ))
  )

p_forest <- ggplot(draws_disc, aes(x = .value, y = .variable)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
  stat_halfeye(fill = "steelblue", alpha = 0.7, .width = c(0.8, 0.95)) +
  labs(
    title = "Demographic Effects on Cultural Consensus",
    subtitle = "Positive = Higher Consensus (Lower Variance)\nNegative = Lower Consensus (Higher Variance)",
    x = "Effect on Discrimination Parameter (Log Scale)",
    y = ""
  ) +
  theme_minimal(base_size = 14) +
  theme(plot.title = element_text(face = "bold"))

ggsave("Plots/02_acat_multilevel/demographic_variance_effects_forest.png", p_forest, width = 8, height = 6)
cat("Saved demographic forest plot to Plots/02_acat_multilevel/demographic_variance_effects_forest.png\n")