library(brms)
library(dplyr)
library(ggplot2)
library(tidybayes)
library(tidyr)
library(forcats)

fit_econ <- readRDS("cache/fit_cs_econ_soc_acat.rds")

draws_cs <- fit_econ |>
  gather_draws(`bcs_social_c\\[.*`, `bcs_economic_c\\[.*`, regex = TRUE) |>
  mutate(
    Ideology = ifelse(grepl("social", .variable), "Social Conservatism", "Economic Conservatism"),
    Threshold = as.numeric(gsub(".*\\[([0-9])\\]", "\\1", .variable)),
    Transition = case_when(
      Threshold == 1 ~ "1 (Elder) vs 2",
      Threshold == 2 ~ "2 vs 3",
      Threshold == 3 ~ "3 vs 4 (Neutral)",
      Threshold == 4 ~ "4 (Neutral) vs 5",
      Threshold == 5 ~ "5 vs 6",
      Threshold == 6 ~ "6 vs 7 (Chef)",
    ),
    Transition = factor(Transition, levels = c(
      "1 (Elder) vs 2", "2 vs 3", "3 vs 4 (Neutral)", 
      "4 (Neutral) vs 5", "5 vs 6", "6 vs 7 (Chef)"
    ))
  )

p_cs <- ggplot(draws_cs, aes(x = .value, y = fct_rev(Transition), fill = Ideology)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray40", linewidth = 1) +
  stat_halfeye(alpha = 0.7, .width = c(0.8, 0.95)) +
  facet_wrap(~Ideology, ncol = 2) +
  scale_fill_manual(values = c("Social Conservatism" = "coral", "Economic Conservatism" = "steelblue")) +
  labs(
    title = "Category-Specific Effects: Economic vs. Social Ideology",
    subtitle = "Positive log-odds = Conservatism pushes rating toward the right side of transition\nNegative = Conservatism pushes rating toward the left side of transition",
    x = "Log-Odds Shift at Threshold",
    y = "Rating Transition"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "none",
    strip.text = element_text(face = "bold", size = 12)
  )

ggsave("Plots/02_acat_multilevel/ideology_cs_effects.png", p_cs, width = 10, height = 6)
cat("Saved plot to Plots/02_acat_multilevel/ideology_cs_effects.png\n")