#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(brms)
  library(tidyverse)
  library(here)
})

cat("Extracting WAIC objects...\n")
models <- c(
  "1_baseline" = "hier_1_baseline.rds",
  "2_relaxed" = "hier_2_relaxed.rds",
  "3_rs" = "hier_3_rs.rds",
  "4_var" = "hier_4_var.rds",
  "5_var_rs" = "hier_5_var_rs.rds",
  "6_relaxed_rs" = "hier_6_relaxed_rs.rds"
)

waic_list <- list()

for (m_name in names(models)) {
  f_path <- here::here("cache", models[[m_name]])
  if (file.exists(f_path)) {
    cat("Loading", m_name, "...\n")
    fit <- readRDS(f_path)
    if (!is.null(fit$criteria$waic)) {
      waic_list[[m_name]] <- fit$criteria$waic
    } else {
      cat("  No WAIC found for", m_name, "\n")
    }
    rm(fit)
    gc()
  }
}

cat("Comparing WAIC...\n")
comp <- loo_compare(waic_list)
print(comp)

comp_df <- as.data.frame(comp) |> 
  rownames_to_column("model_name") |>
  mutate(
    model_clean = case_when(
      model_name == "5_var_rs" ~ "Variance + Random Slopes",
      model_name == "4_var" ~ "Variance Strict",
      model_name == "6_relaxed_rs" ~ "Category-Specific + Random Slopes",
      model_name == "3_rs" ~ "Baseline + Random Slopes",
      model_name == "2_relaxed" ~ "Category-Specific Baseline",
      model_name == "1_baseline" ~ "Baseline Strict",
      TRUE ~ model_name
    )
  )

saveRDS(comp_df, here::here("cache", "waic_comparison_df.rds"))
cat("Saved comparison dataframe.\n")
