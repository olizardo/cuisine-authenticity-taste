library(brms)
library(ggplot2)
library(dplyr)
library(tidybayes)

# 1. Load the cached model
fit_var <- readRDS("cache/fit_variance_acat.rds")

# ==========================================
# PLOT 1: Baseline Variance by Cuisine
# ==========================================
# Extract the random intercepts for the discrimination (variance) equation
ranef_disc <- ranef(fit_var)$cuisine[, , "disc_Intercept"] |> 
  as.data.frame() |> 
  tibble::rownames_to_column("cuisine") |>
  arrange(Estimate) |>
  mutate(
    consensus_category = case_when(
      Q2.5 > 0 ~ "High Consensus (Above Average)",
      Q97.5 < 0 ~ "Low Consensus (Below Average)",
      TRUE ~ "Average Consensus (Crosses Zero)"
    )
  )

p_baseline_variance <- ggplot(ranef_disc, aes(x = reorder(cuisine, Estimate), y = Estimate, ymin = Q2.5, ymax = Q97.5, color = consensus_category)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "black", alpha = 0.6) +
  geom_pointrange(size = 0.8) +
  coord_flip() +
  scale_color_manual(values = c(
    "High Consensus (Above Average)" = "royalblue",
    "Average Consensus (Crosses Zero)" = "gray50",
    "Low Consensus (Below Average)" = "firebrick"
  )) +
  labs(
    title = "Baseline Consensus by Cuisine",
    subtitle = "Zero line = Global Average Consensus across all ratings\nHigher Values (Discrimination) = More Consensus / Less Variance",
    x = "Cuisine", 
    y = "Discrimination Intercept Shift",
    color = "Consensus Level"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom"
  ) +
  guides(color = guide_legend(nrow = 3, byrow = TRUE))

ggsave("Plots/02_acat_multilevel/cuisine_variance_baseline.png", p_baseline_variance, width = 8, height = 6)


# ==========================================
# PLOT 2: Variance by Ideology, Education, & Specific Cuisines
# ==========================================
# Pick 4 illustrative cuisines spanning the spectrum of variance
conditions <- data.frame(cuisine = c("italian", "french", "mexican", "ethiopian"))

# Calculate conditional effects for the discrimination parameter
ce_cuisines <- conditional_effects(
  fit_var, 
  effects = "social_c:educ.f", 
  dpar = "disc",
  conditions = conditions,
  re_formula = NULL # Crucial: incorporates the cuisine-level random intercepts
)

p_demographics_variance <- plot(ce_cuisines, plot = FALSE)[[1]] +
  facet_wrap(~cuisine) +
  labs(
    title = "Consensus in Authenticity Ratings",
    subtitle = "Higher values = More Consensus (Less Variance)\nDownward slope = Social conservatives have less consensus.",
    y = "Discrimination Parameter (Inverse Variance)",
    x = "Social Conservatism (Mean-Centered)",
    color = "Education",
    fill = "Education"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold"),
    legend.position = "bottom"
  )

ggsave("Plots/02_acat_multilevel/cuisine_variance_demographics.png", p_demographics_variance, width = 10, height = 7)

cat("Plots saved to Plots/02_acat_multilevel/\n")