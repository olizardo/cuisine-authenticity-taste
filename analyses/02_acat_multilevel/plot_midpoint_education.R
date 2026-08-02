#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(brms)
  library(here)
})

cat("Loading category-specific model...\n")
fit <- readRDS(here::here("cache", "fit_cs_acat.rds"))
draws <- as_draws_df(fit)

cat("Calculating contrasts against the midpoint (4) for College Degree...\n")
# The reference category for educ.f in the model is "College Degree". 
# The model gives us the effect of "High School or Less", "Some College", and "Grad Degree" 
# RELATIVE to "College Degree".
#
# Let's plot the effect of having a Graduate Degree vs having High School or Less.

# We calculate the difference between the Grad Degree coefficient and the High School coefficient
b_grad_vs_hs <- draws[["b_educ.fProf.DGraduateDegree"]] - draws[["b_educ.fHighSchoolorLess"]]

# Because it's a strict effect, we just multiply it by the steps from the midpoint (4)
contrasts_diff <- list(
  "1 (Elder at Home) vs 4" = -3 * b_grad_vs_hs,
  "2 vs 4" = -2 * b_grad_vs_hs,
  "3 vs 4" = -1 * b_grad_vs_hs,
  "5 vs 4" =  1 * b_grad_vs_hs,
  "6 vs 4" =  2 * b_grad_vs_hs,
  "7 (Professional Chef) vs 4" = 3 * b_grad_vs_hs
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
    Threshold = factor(Threshold, levels = rev(c(
      "1 (Elder at Home) vs 4", 
      "2 vs 4", 
      "3 vs 4", 
      "5 vs 4", 
      "6 vs 4", 
      "7 (Professional Chef) vs 4"
    ))),
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
    title = "Effect of Graduate Degree on Authenticity Ratings",
    subtitle = "Relative to High School or Less. Contrasts against neutral (4).\n1 = Elder at Home, 7 = Pro Chef at High-End Restaurant.",
    x = "Log-Odds Shift (Grad vs High School)",
    y = "Rating Contrast (vs Neutral 4)"
  ) +
  theme(
    legend.position = "bottom",
    axis.text.y = element_text(face = "bold", size = 11),
    axis.text.x = element_text(size = 11),
    plot.title = element_text(face = "bold", size = 14)
  )

out_file <- here::here("Plots", "02_acat_multilevel", "education_midpoint_contrast.png")
ggsave(out_file, plot = p_midpoint, width = 8, height = 6, bg = "white")

cat("Plot successfully saved to", out_file, "\n")
