library(tidyverse)
library(brms)
library(tidybayes)
library(here)

cat("Loading models...\n")
m1 <- readRDS(here("cache", "music_hier_1_baseline.rds"))
m3 <- readRDS(here("cache", "music_hier_3_rs.rds"))
m4 <- readRDS(here("cache", "music_hier_4_var.rds"))
m5 <- readRDS(here("cache", "music_hier_5_var_rs.rds"))

# 1. WAIC Comparison
cat("Comparing WAIC...\n")
w1 <- m1$criteria$waic
w3 <- m3$criteria$waic
w4 <- m4$criteria$waic
w5 <- m5$criteria$waic

waic_df <- data.frame(
  Model = c("1. Baseline Strict", "3. Random Slopes Strict", "4. Variance Strict", "5. Variance + Random Slopes"),
  WAIC = c(w1$estimates["waic","Estimate"], w3$estimates["waic","Estimate"], w4$estimates["waic","Estimate"], w5$estimates["waic","Estimate"]),
  SE = c(w1$estimates["waic","SE"], w3$estimates["waic","SE"], w4$estimates["waic","SE"], w5$estimates["waic","SE"])
) %>%
  mutate(Delta_WAIC = WAIC - max(WAIC)) %>%
  arrange(WAIC)

saveRDS(waic_df, here("cache", "music_waic_comparison.rds"))

# Plot WAIC
ggplot(waic_df, aes(x = reorder(Model, -WAIC), y = WAIC)) +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = WAIC - SE, ymax = WAIC + SE), width = 0.2) +
  coord_flip() +
  labs(title = "WAIC Comparison: Music Taste Models", x = "", y = "WAIC (Lower is Better)") +
  theme_minimal()
ggsave(here("Plots", "music-acat-multilevel", "model_fit_comparison.png"), width = 8, height = 4)

# Free memory
rm(m1, m3, m4)
gc()

# 2. Demographic Fixed Effects (Location)
cat("Plotting Fixed Effects...\n")
draws_fixed <- m5 %>%
  spread_draws(`b_educ_c`, `b_social_c`, `b_economic_c`, `b_income_c`, `b_age_c`) %>%
  pivot_longer(cols = starts_with("b_"), names_to = "Parameter", values_to = "Value") %>%
  mutate(Parameter = str_remove(Parameter, "b_"))

ggplot(draws_fixed, aes(x = Value, y = Parameter)) +
  stat_halfeye() +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red") +
  labs(title = "Global Demographic Fixed Effects (Location)", x = "Estimate (Log-Odds)", y = "") +
  theme_minimal()
ggsave(here("Plots", "music-acat-multilevel", "demographic_fixed_effects.png"), width = 8, height = 5)

# 3. Genre Random Effects (Location)
cat("Plotting Genre Random Effects...\n")
genre_re <- m5 %>%
  spread_draws(r_genre[genre, term]) %>%
  filter(term == "Intercept")

ggplot(genre_re, aes(x = r_genre, y = reorder(genre, r_genre))) +
  stat_halfeye() +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red") +
  labs(title = "Baseline Genre Effects (Random Intercepts)", x = "Estimate", y = "Genre") +
  theme_minimal()
ggsave(here("Plots", "music-acat-multilevel", "genre_random_effects.png"), width = 8, height = 6)

# 4. 2D Consensus Plot
cat("Plotting 2D Consensus...\n")
genre_disc <- m5 %>%
  spread_draws(r_genre__disc[genre, term]) %>%
  filter(term == "Intercept") %>%
  rename(r_genre_disc = r_genre__disc)

genre_2d <- genre_re %>%
  group_by(genre) %>%
  summarize(mean_loc = mean(r_genre)) %>%
  left_join(
    genre_disc %>% group_by(genre) %>% summarize(mean_disc = mean(r_genre_disc)),
    by = "genre"
  )

ggplot(genre_2d, aes(x = mean_loc, y = mean_disc, label = genre)) +
  geom_point(color = "blue", size = 2) +
  geom_text(vjust = -0.5, hjust = 0.5) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(title = "Music 2D Consensus Map", x = "Location Intercept (Low=Traditional/Authentic, High=Modern/Elite)", y = "Consensus (Discrimination Intercept)") +
  theme_minimal()
ggsave(here("Plots", "music-acat-multilevel", "genre_2d_consensus.png"), width = 8, height = 6)

# 5. Demographic Effects on Global Variance
cat("Plotting Demographic Effects on Variance...\n")
draws_disc <- m5 %>%
  spread_draws(`b_disc_educ_c`, `b_disc_social_c`, `b_disc_economic_c`) %>%
  pivot_longer(cols = starts_with("b_disc_"), names_to = "Parameter", values_to = "Value") %>%
  mutate(Parameter = str_remove(Parameter, "b_disc_"))

ggplot(draws_disc, aes(x = Value, y = Parameter)) +
  stat_halfeye() +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red") +
  labs(title = "Demographic Effects on Global Consensus (Variance)", x = "Estimate (Positive = Higher Consensus)", y = "") +
  theme_minimal()
ggsave(here("Plots", "music-acat-multilevel", "demographic_variance_effects_forest.png"), width = 8, height = 4)

cat("Done!\n")
