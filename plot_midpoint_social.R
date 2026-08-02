#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(brms)
  library(here)
})

cat("Loading category-specific model...\n")
fit <- readRDS(here::here("fit_cs_acat.rds"))
draws <- as_draws_df(fit)

cat("Calculating contrasts against the midpoint (4)...\n")
# The scale is 1 to 7. Midpoint is 4.
# ACAT transitions are:
# 1 = 1|2, 2 = 2|3, 3 = 3|4, 4 = 4|5, 5 = 5|6, 6 = 6|7

b1 <- draws[["bcs_social_c[1]"]]
b2 <- draws[["bcs_social_c[2]"]]
b3 <- draws[["bcs_social_c[3]"]]
b4 <- draws[["bcs_social_c[4]"]]
b5 <- draws[["bcs_social_c[5]"]]
b6 <- draws[["bcs_social_c[6]"]]

contrasts_diff <- list(
  "1 vs 4" = -(b1 + b2 + b3),
  "2 vs 4" = -(b2 + b3),
  "3 vs 4" = -b3,
  "5 vs 4" = b4,
  "6 vs 4" = b4 + b5,
  "7 vs 4" = b4 + b5 + b6
)

plot_data <- data.frame()

for (c_name in names(contrasts_diff)) {
  draws_diff <- contrasts_diff[[c_name]]
  
  plot_data <- rbind(plot_data, data.frame(
    Threshold = c_name,
    estimate = mean(draws_diff),
    conf.low = quantile(draws_diff, 0.025),
    conf.high = quantile(draws_diff, 0.975)
  ))
}

plot_data <- plot_data %>%
  mutate(
    Threshold = factor(Threshold, levels = rev(c("1 vs 4", "2 vs 4", "3 vs 4", "5 vs 4", "6 vs 4", "7 vs 4"))),
    # If the 95% CI doesn't cross zero, flag it as credible
    Credible = ifelse(conf.low > 0 | conf.high < 0, "Credible Shift", "No Credible Shift")
  )

cat("Creating plot...\n")
p_midpoint <- ggplot(plot_data, aes(x = estimate, y = Threshold, shape = Credible, color = Credible)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
  geom_point(size = 4) +
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high), width = 0.2, linewidth = 1) +
  scale_color_manual(values = c("Credible Shift" = "firebrick", "No Credible Shift" = "gray30")) +
  scale_shape_manual(values = c("Credible Shift" = 16, "No Credible Shift" = 1)) +
  theme_minimal() +
  labs(
    title = "Effect of Social Conservatism on Cuisine Ratings",
    subtitle = "Contrasts against the midpoint (Rating = 4). Positive value = higher conservatism increases probability of rating.",
    x = "Log-Odds Shift per 1-Unit Increase in Social Conservatism",
    y = "Rating Contrast (vs 4)"
  ) +
  theme(
    legend.position = "bottom",
    axis.text.y = element_text(face = "bold", size = 11),
    axis.text.x = element_text(size = 11),
    plot.title = element_text(face = "bold", size = 14)
  )

dir.create(here::here("Plots"), showWarnings = FALSE)
out_file <- here::here("Plots", "social_midpoint_contrast.png")
ggsave(out_file, plot = p_midpoint, width = 8, height = 6, bg = "white")

cat("Plot successfully saved to", out_file, "\n")
