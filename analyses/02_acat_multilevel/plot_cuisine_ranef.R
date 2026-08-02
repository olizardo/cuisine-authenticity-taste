#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(brms)
  library(here)
})

cat("Loading category-specific model...\n")
fit <- readRDS(here::here("fit_cs_acat.rds"))

cat("Extracting cuisine random effects...\n")
ranef_cuisine <- ranef(fit)$cuisine

cuisine_df <- data.frame(
  Cuisine = stringr::str_to_title(gsub("_", " ", rownames(ranef_cuisine[, , "Intercept"]))),
  Estimate = ranef_cuisine[, "Estimate", "Intercept"],
  conf.low = ranef_cuisine[, "Q2.5", "Intercept"],
  conf.high = ranef_cuisine[, "Q97.5", "Intercept"]
) %>%
  arrange(Estimate) %>%
  mutate(
    Cuisine = factor(Cuisine, levels = Cuisine),
    Lean = case_when(
      conf.high < 0 ~ "Elder at Home",
      conf.low > 0 ~ "Professional Chef",
      TRUE ~ "Neutral (Crosses 0)"
    )
  )

cat("Creating plot...\n")
p_ranef <- ggplot(cuisine_df, aes(x = Estimate, y = Cuisine, color = Lean)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
  geom_point(size = 4) +
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high), width = 0.2, linewidth = 1) +
  scale_color_manual(values = c("Elder at Home" = "firebrick", "Neutral (Crosses 0)" = "gray40", "Professional Chef" = "steelblue")) +
  theme_minimal() +
  labs(
    title = "Baseline Authenticity Leans by Cuisine",
    subtitle = "Extracted from random intercepts. Negative = Elder at Home, Positive = Pro Chef.",
    x = "Log-Odds Shift (Baseline Lean)",
    y = NULL,
    color = "Credible Baseline Lean:"
  ) +
  theme(
    legend.position = "bottom",
    axis.text.y = element_text(face = "bold", size = 11),
    axis.text.x = element_text(size = 11),
    plot.title = element_text(face = "bold", size = 14)
  )

out_file <- here::here("Plots", "02_acat_multilevel", "cuisine_random_effects.png")
ggsave(out_file, plot = p_ranef, width = 8, height = 6, bg = "white")

cat("Plot successfully saved to", out_file, "\n")
