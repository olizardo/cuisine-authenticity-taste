#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(tidyverse)
  library(here)
})

cat("Loading comparison dataframe...\n")
comp_df <- readRDS(here::here("cache", "waic_comparison_df.rds"))

# Order by elpd_diff
comp_df <- comp_df |>
  arrange(elpd_diff) |>
  mutate(model_clean = factor(model_clean, levels = model_clean))

# Create a forest plot showing out-of-sample fit
p <- ggplot(comp_df, aes(x = elpd_diff, y = model_clean)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
  # Use exact standard error (assuming normal approximation: +/- 1.96 * se_diff)
  geom_errorbarh(aes(xmin = elpd_diff - 1.96 * se_diff, xmax = elpd_diff + 1.96 * se_diff), height = 0, color = "#2c3e50", linewidth = 1) +
  geom_point(size = 4, aes(color = elpd_diff == 0)) +
  scale_color_manual(values = c("TRUE" = "#27ae60", "FALSE" = "#c0392b")) +
  theme_minimal(base_size = 14) +
  labs(
    title = "Model Fit Comparison: Expected Log Predictive Density (ELPD)",
    subtitle = "Relative out-of-sample fit (higher is better). 0 represents the best-fitting model.",
    x = "Difference in ELPD (with 95% Confidence Interval)",
    y = NULL
  ) +
  theme(
    plot.title = element_text(face = "bold"),
    plot.subtitle = element_text(color = "gray30", margin = margin(b = 15)),
    axis.title.x = element_text(margin = margin(t = 15), face = "bold"),
    legend.position = "none",
    panel.grid.major.y = element_blank()
  )

out_path <- here::here("Plots", "02_acat_multilevel", "model_fit_comparison.png")
ggsave(out_path, p, width = 10, height = 5, dpi = 300, bg = "white")

cat("Plot saved to:", out_path, "\n")
