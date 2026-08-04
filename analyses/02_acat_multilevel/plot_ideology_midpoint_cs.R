library(brms)
library(dplyr)
library(ggplot2)
library(tidybayes)
library(tidyr)
library(forcats)

fit_econ <- readRDS("cache/fit_cs_econ_soc_acat.rds")

# Extract posterior draws for category-specific effects
draws <- as_draws_df(fit_econ)

# Function to calculate midpoint (4) contrasts from ACAT raw thresholds
calc_midpoint_contrasts <- function(d, var_prefix) {
  t1 <- d[[paste0("bcs_", var_prefix, "[1]")]]
  t2 <- d[[paste0("bcs_", var_prefix, "[2]")]]
  t3 <- d[[paste0("bcs_", var_prefix, "[3]")]]
  t4 <- d[[paste0("bcs_", var_prefix, "[4]")]]
  t5 <- d[[paste0("bcs_", var_prefix, "[5]")]]
  t6 <- d[[paste0("bcs_", var_prefix, "[6]")]]
  
  data.frame(
    .draw = d$.draw,
    `1 (Elder) vs 4` = -(t1 + t2 + t3),
    `2 vs 4` = -(t2 + t3),
    `3 vs 4` = -t3,
    `5 vs 4` = t4,
    `6 vs 4` = t4 + t5,
    `7 (Chef) vs 4` = t4 + t5 + t6
  ) %>%
    pivot_longer(
      cols = -c(.draw),
      names_to = "Contrast",
      values_to = ".value"
    )
}

# Calculate contrasts for social and economic
social_contrasts <- calc_midpoint_contrasts(draws, "social_c") %>%
  mutate(Ideology = "Social Conservatism")

econ_contrasts <- calc_midpoint_contrasts(draws, "economic_c") %>%
  mutate(Ideology = "Economic Conservatism")

# Combine and set factor levels
all_contrasts <- bind_rows(social_contrasts, econ_contrasts) %>%
  mutate(
    Contrast = factor(Contrast, levels = c(
      "1 (Elder) vs 4", "2 vs 4", "3 vs 4",
      "5 vs 4", "6 vs 4", "7 (Chef) vs 4"
    ))
  )

# Plot
p_midpoint <- ggplot(all_contrasts, aes(x = .value, y = fct_rev(Contrast), fill = Ideology)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray40", linewidth = 1) +
  stat_halfeye(alpha = 0.7, .width = c(0.8, 0.95)) +
  facet_wrap(~Ideology, ncol = 2) +
  scale_fill_manual(values = c("Social Conservatism" = "coral", "Economic Conservatism" = "steelblue")) +
  labs(
    title = "Midpoint Contrasts: Economic vs. Social Ideology",
    subtitle = "Effect of higher conservatism on choosing a specific rating vs. the Neutral midpoint (4)\nPositive = More likely to choose that rating than neutral",
    x = "Log-Odds Shift (vs. Rating 4)",
    y = "Rating vs Neutral Baseline"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "none",
    strip.text = element_text(face = "bold", size = 12)
  )

ggsave("Plots/02_acat_multilevel/ideology_cs_midpoint_effects.png", p_midpoint, width = 11, height = 7)
cat("Saved plot to Plots/02_acat_multilevel/ideology_cs_midpoint_effects.png\n")
