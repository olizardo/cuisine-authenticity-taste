library(brms)
library(dplyr)
library(ggplot2)
library(patchwork)

fit_econ <- readRDS(here::here("cache", "hier_2_relaxed.rds"))

# Extract conditional effects
ce_social <- conditional_effects(fit_econ, effects = "social_c", categorical = TRUE)
ce_econ <- conditional_effects(fit_econ, effects = "economic_c", categorical = TRUE)

# Function to filter data to just 1, 4, 7 and create a clean plot
plot_clean_probs <- function(ce_data, list_name, x_var, title_text, x_label) {
  # Extract the underlying dataframe from the conditional_effects object
  df <- ce_data[[list_name]] |>
    filter(cats__ %in% c("1", "4", "7")) |>
    mutate(
      cats__ = case_when(
        cats__ == "1" ~ "1 (Elder)",
        cats__ == "4" ~ "4 (Neutral)",
        cats__ == "7" ~ "7 (Pro Chef)"
      )
    )
  
  ggplot(df, aes(x = !!sym(x_var), y = estimate__, color = cats__, fill = cats__)) +
    geom_ribbon(aes(ymin = lower__, ymax = upper__), alpha = 0.2, color = NA) +
    geom_line(linewidth = 1.5) +
    scale_color_manual(values = c("1 (Elder)" = "firebrick", "4 (Neutral)" = "gray50", "7 (Pro Chef)" = "steelblue")) +
    scale_fill_manual(values = c("1 (Elder)" = "firebrick", "4 (Neutral)" = "gray50", "7 (Pro Chef)" = "steelblue")) +
    coord_cartesian(ylim = c(0, 0.45)) +
    labs(
      title = title_text,
      x = x_label,
      y = "Predicted Probability",
      color = "Rating Choice",
      fill = "Rating Choice"
    ) +
    theme_minimal(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", size = 12),
      legend.position = "bottom",
      legend.title = element_text(face = "bold")
    )
}

p1 <- plot_clean_probs(ce_social, "social_c:cats__", "social_c", "Social Ideology", "Social Conservatism (Centered)")
p2 <- plot_clean_probs(ce_econ, "economic_c:cats__", "economic_c", "Economic Ideology", "Economic Conservatism (Centered)")

# Combine plots side by side, sharing the same legend
p_combined <- p1 + p2 + plot_layout(guides = "collect") & theme(legend.position = "bottom")

# Add a master title
p_final <- p_combined + plot_annotation(
  title = "Predicted Probabilities of Extreme vs. Neutral Ratings",
  subtitle = "How ideology shapes the absolute probability of choosing 1, 4, or 7",
  theme = theme(plot.title = element_text(face = "bold", size = 16))
)

ggsave("Plots/cuisine-acat-multilevel/ideology_predicted_probs.png", p_final, width = 11, height = 6, bg = "white")
cat("Saved plot to Plots/cuisine-acat-multilevel/ideology_predicted_probs.png\n")
