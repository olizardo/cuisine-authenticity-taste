library(brms)
library(tidybayes)
library(tidyverse)
library(here)

cat("Loading model...\n")
fit <- readRDS(here("cache", "hier_2_relaxed.rds"))
draws <- as_draws_df(fit)

# Function to calculate midpoint contrasts for a given CS variable
plot_midpoint_contrasts <- function(var_name, title_name) {
  # Base log-odds parameters for the specific variable at each threshold
  cs_vars <- paste0("bcs_", var_name, "[", 1:6, "]")
  
  # Calculate contrasts against midpoint (4)
  # For ACAT, a shift from 4 is the sum of thresholds between the target and 4
  draws_calc <- draws |>
    mutate(
      c_1_vs_4 = -(.data[[cs_vars[3]]] + .data[[cs_vars[2]]] + .data[[cs_vars[1]]]),
      c_2_vs_4 = -(.data[[cs_vars[3]]] + .data[[cs_vars[2]]]),
      c_3_vs_4 = -(.data[[cs_vars[3]]]),
      c_4_vs_4 = 0,
      c_5_vs_4 = .data[[cs_vars[4]]],
      c_6_vs_4 = .data[[cs_vars[4]]] + .data[[cs_vars[5]]],
      c_7_vs_4 = .data[[cs_vars[4]]] + .data[[cs_vars[5]]] + .data[[cs_vars[6]]]
    ) |>
    select(starts_with("c_")) |>
    pivot_longer(everything(), names_to = "contrast", values_to = "value") |>
    mutate(
      Rating = case_when(
        contrast == "c_1_vs_4" ~ "1 - Traditional Elder",
        contrast == "c_2_vs_4" ~ "2",
        contrast == "c_3_vs_4" ~ "3",
        contrast == "c_4_vs_4" ~ "4 - Neutral Midpoint",
        contrast == "c_5_vs_4" ~ "5",
        contrast == "c_6_vs_4" ~ "6",
        contrast == "c_7_vs_4" ~ "7 - Professional Chef"
      )
    )
    
  p <- ggplot(draws_calc, aes(y = factor(Rating, levels = rev(unique(Rating))), x = value)) +
    stat_halfeye(fill = "steelblue", alpha = 0.7) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "red") +
    theme_minimal() +
    labs(
      title = paste("Effect of", title_name, "on Authenticity Rating"),
      subtitle = "Log-Odds Shift Relative to Neutral Midpoint (4) (Standardized)",
      x = "Log-Odds Contrast (vs Rating of 4)",
      y = ""
    )
    
  ggsave(here("Plots", "02_acat_multilevel", paste0("cs_midpoint_", var_name, ".png")), p, width = 8, height = 5)
}

plot_midpoint_contrasts("educ_c", "Education")
plot_midpoint_contrasts("peduc_c", "Parental Education")
plot_midpoint_contrasts("social_c", "Social Conservatism")
plot_midpoint_contrasts("economic_c", "Economic Conservatism")
plot_midpoint_contrasts("arts_c", "Childhood Arts Exposure")

cat("Plots generated!\n")
