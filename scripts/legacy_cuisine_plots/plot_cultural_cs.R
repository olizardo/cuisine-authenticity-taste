library(brms)
library(dplyr)
library(ggplot2)
library(tidybayes)
library(tidyr)
library(forcats)

fit <- readRDS(here::here("cache", "hier_2_relaxed.rds"))

draws_cs <- fit |>
  gather_draws(`bcs_educ_c\\[.*`, `bcs_peduc_c\\[.*`, `bcs_arts_c\\[.*`, regex = TRUE) |>
  mutate(
    Variable = case_when(
      grepl("peduc_c", .variable) ~ "Parental Education",
      grepl("educ_c", .variable) ~ "Education",
      grepl("arts_c", .variable) ~ "Arts Exposure"
    ),
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
    )),
    Variable = factor(Variable, levels = c("Education", "Parental Education", "Arts Exposure"))
  )

p_cs <- ggplot(draws_cs, aes(x = .value, y = fct_rev(Transition), fill = Variable)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray40", linewidth = 1) +
  stat_halfeye(slab_alpha = 0.5, .width = c(0.8, 0.95)) +
  facet_wrap(~Variable, ncol = 3) +
  scale_fill_manual(values = c("Education" = "#2980b9", "Parental Education" = "#3498db", "Arts Exposure" = "#8e44ad")) +
  labs(
    title = "Category-Specific Effects: Cultural Capital",
    subtitle = "Positive log-odds = Higher capital pushes rating toward the right side of transition\nNegative = Higher capital pushes rating toward the left side of transition",
    x = "Log-Odds Shift at Threshold",
    y = "Rating Transition"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "none",
    strip.text = element_text(face = "bold", size = 12)
  )

ggsave(here::here("Plots", "cuisine-acat-multilevel", "cultural_cs_effects.png"), p_cs, width = 12, height = 6, bg = "white")
cat("Saved plot to Plots/cuisine-acat-multilevel/cultural_cs_effects.png\n")