#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(tidyverse)
  library(brms)
  library(tidybayes)
  library(ggrepel)
  library(here)
})

generate_domain <- function(domain_prefix, domain_name) {
  cat("\n===========================================\n")
  cat(sprintf("Processing Domain: %s\n", domain_name))
  cat("===========================================\n")
  
  plot_dir <- here("Plots", paste0(domain_prefix, "-acat-multilevel"))
  if (!dir.exists(plot_dir)) dir.create(plot_dir, recursive = TRUE)
  
  # Helper to construct file paths
  cfile <- function(m) {
    if(domain_prefix == "cuisine" && m == "6_relaxed_rs") {
      # The cuisine models don't have the domain prefix
      here("cache", "hier_6_relaxed_rs.rds")
    } else if(domain_prefix == "cuisine") {
      here("cache", paste0("hier_", m, ".rds"))
    } else {
      here("cache", paste0(domain_prefix, "_hier_", m, ".rds"))
    }
  }
  pfile <- function(p) file.path(plot_dir, paste0(p, ".png"))
  
  # Load models
  cat("Loading models...\n")
  load_model <- function(m_name) {
    path <- cfile(m_name)
    if (file.exists(path)) {
      cat(sprintf("  - Found cached model: %s\n", m_name))
      return(tryCatch(readRDS(path), error = function(e) NULL))
    }
    cat(sprintf("  - Model not found (still running or uncompiled): %s\n", m_name))
    return(NULL)
  }
  
  m1 <- load_model("1_baseline")
  m2 <- load_model("2_relaxed")
  m3 <- load_model("3_rs")
  m4 <- load_model("4_var")
  m5 <- load_model("5_var_rs")
  m6 <- load_model("6_relaxed_rs")

  if(domain_prefix == "cuisine") {
      # The cuisine models use 'cuisine' instead of 'genre' for the random effect grouping variable
      genre_var_name <- "cuisine"
  } else {
      genre_var_name <- "genre"
  }

  if(is.null(m5)) {
    cat("Model 5 not found! Skipping domain...\n")
    return()
  }

  # --- 1. WAIC Comparison ---
  cat("Plotting WAIC comparison...\n")
  waic_list <- list()
  models_to_check <- list("1. Baseline Strict"=m1, "2. Relaxed CS"=m2, "3. Random Slopes Strict"=m3, "4. Variance Strict"=m4, "5. Variance + Random Slopes"=m5, "6. Relaxed CS + Random Slopes"=m6)
  for(n in names(models_to_check)) {
    m <- models_to_check[[n]]
    if(!is.null(m) && !is.null(m$criteria$waic)) {
      w <- m$criteria$waic$estimates["waic", ]
      waic_list[[n]] <- data.frame(Model = n, WAIC = w["Estimate"], SE = w["SE"])
    }
  }
  if(length(waic_list) > 0) {
    waic_df <- bind_rows(waic_list) |>
      mutate(Delta_WAIC = WAIC - min(WAIC)) |>
      arrange(WAIC)
    
    saveRDS(waic_df, here("cache", paste0(domain_prefix, "_waic_comparison.rds")))
    
    p_waic <- ggplot(waic_df, aes(x = reorder(Model, -WAIC), y = WAIC)) +
      geom_point(size = 3) +
      geom_errorbar(aes(ymin = WAIC - SE, ymax = WAIC + SE), width = 0.2) +
      coord_flip() +
      labs(title = sprintf("WAIC Comparison: %s", domain_name), x = "", y = "WAIC (Lower is Better)") +
      theme_minimal(base_size = 14) +
      theme(plot.title = element_text(face = "bold"))
    ggsave(pfile("model_fit_comparison"), p_waic, width = 10, height = 5, bg="white")
  }
  
  # --- 2. Demographic Fixed Effects (Location) ---
  cat("Plotting Fixed Effects (Location)...\n")
  
  # For older models that don't have b_peduc_c or b_arts_c
  available_vars <- variables(m5)
  vars_to_extract <- c("b_educ_c", "b_peduc_c", "b_social_c", "b_economic_c", "b_income_c", "b_arts_c",
                       "b_age_c", "b_gend.fWoman", "b_gend.fNonbinaryDOther", 
                       "b_race.fAsian", "b_race.fBlack, b_race.fHispanic", 
                       "b_race.fMixedOther", "b_race.fMixedWhite")
  # Handle the case where MixedOther might be 'MixedDOther' or missing
  if("b_race.fBlack" %in% available_vars) { vars_to_extract <- c(vars_to_extract, "b_race.fBlack") }
  if("b_race.fHispanic" %in% available_vars) { vars_to_extract <- c(vars_to_extract, "b_race.fHispanic") }
  
  vars_to_extract <- intersect(vars_to_extract, available_vars)
  
  draws_fixed <- m5 |>
    gather_draws(!!!syms(vars_to_extract)) |>
    mutate(
      Predictor = case_when(
        .variable == "b_social_c" ~ "Social Conservatism",
        .variable == "b_economic_c" ~ "Economic Conservatism",
        .variable == "b_educ_c" ~ "Education",
        .variable == "b_peduc_c" ~ "Parental Education",
        .variable == "b_arts_c" ~ "Childhood Arts Exposure",
        .variable == "b_income_c" ~ "Income",
        .variable == "b_age_c" ~ "Age",
        .variable == "b_gend.fWoman" ~ "Gender: Woman",
        .variable == "b_gend.fNonbinaryDOther" ~ "Gender: Nonbinary/Other",
        .variable == "b_race.fAsian" ~ "Race: Asian",
        .variable == "b_race.fBlack" ~ "Race: Black",
        .variable == "b_race.fHispanic" ~ "Race: Hispanic",
        .variable == "b_race.fMixedOther" ~ "Race: Mixed/Other",
        .variable == "b_race.fMixedWhite" ~ "Race: Mixed White",
        TRUE ~ .variable
      ),
      Category = case_when(
        grepl("social|economic", .variable) ~ "Ideology (SD)",
        grepl("educ|peduc|income|arts", .variable) ~ "Capital & Socialization (SD)",
        grepl("age", .variable) ~ "Demographics (SD)",
        grepl("gend", .variable) ~ "Gender (vs. Man)",
        grepl("race", .variable) ~ "Race (vs. White)"
      )
    ) |>
    group_by(Predictor) |>
    mutate(med_val = median(.value)) |>
    ungroup() |>
    mutate(Predictor = fct_reorder(Predictor, med_val))

  subtitle_text <- if(domain_prefix == "cuisine") {
    "Posterior distributions from best-fitting model (Variance + Random Slopes)\nPositive values push ratings toward 'Professional Chef' (7) | Negative toward 'Elder' (1)"
  } else {
    "Posterior distributions from best-fitting model (Variance + Random Slopes)\nPositive values push ratings toward 'Like' (7) | Negative toward 'Dislike' (1)"
  }

  p_fixed <- ggplot(draws_fixed, aes(x = .value, y = Predictor, fill = Category)) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "gray30", linewidth = 1) +
    stat_halfeye(alpha = 0.7, .width = c(0.8, 0.95)) +
    scale_fill_viridis_d(option = "turbo", end = 0.9) +
    theme_minimal(base_size = 14) +
    labs(
      title = sprintf("Demographic Fixed Effects on %s Ratings", domain_name),
      subtitle = subtitle_text,
      x = "Effect Size (Log-Odds Shift)",
      y = NULL,
      fill = "Variable Type"
    ) +
    theme(
      plot.title = element_text(face = "bold"),
      plot.subtitle = element_text(color = "gray30", margin = margin(b = 15)),
      legend.position = "bottom",
      panel.grid.major.y = element_blank()
    )
  ggsave(pfile("demographic_fixed_effects"), p_fixed, width = 11, height = 8, dpi = 300, bg = "white")

  # --- 3. Genre Random Effects (Location) ---
  cat("Plotting Random Intercepts...\n")
  
  if (domain_prefix == "cuisine") {
    genre_re <- m5 |> 
      spread_draws(r_cuisine[cuisine, term]) |>
      filter(term == "Intercept") |>
      group_by(cuisine) |>
      mutate(med_val = median(r_cuisine)) |>
      ungroup() |>
      mutate(
        genre_label = str_to_title(str_replace_all(cuisine, "_", " ")),
        genre_label = fct_reorder(genre_label, med_val)
      )
    p_re <- ggplot(genre_re, aes(x = r_cuisine, y = genre_label)) +
      geom_vline(xintercept = 0, linetype = "dashed", color = "gray30", linewidth = 1) +
      stat_halfeye(fill = "#2c3e50", alpha = 0.7, .width = c(0.8, 0.95)) +
      theme_minimal(base_size = 14) +
      labs(
        title = sprintf("Baseline Genre Effects (Random Intercepts): %s", domain_name),
        x = "Location Intercept (Log-Odds)",
        y = NULL
      ) +
      theme(plot.title = element_text(face = "bold"), panel.grid.major.y = element_blank())
  } else {
    genre_re <- m5 |> 
      spread_draws(r_genre[genre, term]) |>
      filter(term == "Intercept") |>
      group_by(genre) |>
      mutate(med_val = median(r_genre)) |>
      ungroup() |>
      mutate(
        genre_label = str_to_title(str_replace_all(genre, "_", " ")),
        genre_label = fct_reorder(genre_label, med_val)
      )
    p_re <- ggplot(genre_re, aes(x = r_genre, y = genre_label)) +
      geom_vline(xintercept = 0, linetype = "dashed", color = "gray30", linewidth = 1) +
      stat_halfeye(fill = "#2c3e50", alpha = 0.7, .width = c(0.8, 0.95)) +
      theme_minimal(base_size = 14) +
      labs(
        title = sprintf("Baseline Genre Effects (Random Intercepts): %s", domain_name),
        x = "Location Intercept (Log-Odds)",
        y = NULL
      ) +
      theme(plot.title = element_text(face = "bold"), panel.grid.major.y = element_blank())
  }
  ggsave(pfile("genre_random_effects"), p_re, width = 10, height = 8, dpi = 300, bg = "white")

  # --- 4. 2D Consensus Plot ---
  cat("Plotting 2D Consensus...\n")
  
  if (domain_prefix == "cuisine") {
    draws_loc <- m5 |> 
      spread_draws(r_cuisine[cuisine, term]) |>
      filter(term == "Intercept") |>
      rename(loc_effect = r_cuisine)

    draws_disc <- m5 |> 
      spread_draws(r_cuisine__disc[cuisine, term]) |>
      filter(term == "Intercept") |>
      rename(disc_effect = r_cuisine__disc)
  } else {
    draws_loc <- m5 |> 
      spread_draws(r_genre[genre, term]) |>
      filter(term == "Intercept") |>
      rename(loc_effect = r_genre)

    draws_disc <- m5 |> 
      spread_draws(r_genre__disc[genre, term]) |>
      filter(term == "Intercept") |>
      rename(disc_effect = r_genre__disc)
  }

  summary_df <- draws_loc |>
    left_join(draws_disc, by = c(".chain", ".iteration", ".draw", genre_var_name)) |>
    group_by(!!sym(genre_var_name)) |>
    summarize(
      loc_med = median(loc_effect),
      loc_lower = quantile(loc_effect, 0.025),
      loc_upper = quantile(loc_effect, 0.975),
      disc_med = median(disc_effect),
      disc_lower = quantile(disc_effect, 0.025),
      disc_upper = quantile(disc_effect, 0.975),
      .groups = "drop"
    ) |>
    mutate(genre_label = str_to_title(str_replace_all(!!sym(genre_var_name), "_", " ")))

  x_label_text <- if(domain_prefix == "cuisine") {
    "← Traditional Elder          Location (Intercept)                Professional Chef →"
  } else {
    "← Dislike (1)               Location (Intercept)               Like (7) →"
  }

  p_2d <- ggplot(summary_df, aes(x = loc_med, y = disc_med)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray60", alpha = 0.7) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "gray60", alpha = 0.7) +
    geom_errorbar(aes(ymin = disc_lower, ymax = disc_upper), width = 0, color = "gray40", alpha = 0.5) +
    geom_errorbar(aes(xmin = loc_lower, xmax = loc_upper), orientation = "y", width = 0, color = "gray40", alpha = 0.5) +
    geom_point(size = 3, color = "#2c3e50") +
    geom_label_repel(aes(label = genre_label), size = 4.5, box.padding = 0.5, point.padding = 0.3, max.overlaps = 20) +
    theme_minimal(base_size = 14) +
    labs(
      title = sprintf("%s: Consensus vs. Preference", domain_name),
      subtitle = "Posterior medians and 95% CIs for Genre Random Effects",
      x = x_label_text,
      y = "← High Disagreement (Polarized)      Consensus (Disc Parameter)      High Agreement (Consensus) →"
    ) +
    theme(
      plot.title = element_text(face = "bold"),
      plot.subtitle = element_text(color = "gray30", margin = margin(b = 15)),
      axis.title.x = element_text(margin = margin(t = 15), face = "bold"),
      axis.title.y = element_text(margin = margin(r = 15), face = "bold")
    )
  ggsave(pfile("genre_2d_consensus"), p_2d, width = 10, height = 8, dpi = 300, bg = "white")

  # --- 5. Demographic Effects on Global Variance ---
  cat("Plotting Demographic Effects on Variance...\n")
  
  available_var_vars <- variables(m5)
  var_vars_to_extract <- c("b_disc_educ_c", "b_disc_peduc_c", "b_disc_arts_c", "b_disc_social_c", "b_disc_economic_c")
  var_vars_to_extract <- intersect(var_vars_to_extract, available_var_vars)
  
  draws_disc_fixed <- m5 |>
    gather_draws(!!!syms(var_vars_to_extract)) |>
    mutate(
      Predictor = case_when(
        .variable == "b_disc_social_c" ~ "Social Conservatism",
        .variable == "b_disc_economic_c" ~ "Economic Conservatism",
        .variable == "b_disc_educ_c" ~ "Education",
        .variable == "b_disc_peduc_c" ~ "Parental Education",
        .variable == "b_disc_arts_c" ~ "Childhood Arts Exposure"
      )
    ) |>
    group_by(Predictor) |>
    mutate(med_val = median(.value)) |>
    ungroup() |>
    mutate(Predictor = fct_reorder(Predictor, med_val))

  p_disc <- ggplot(draws_disc_fixed, aes(x = .value, y = Predictor)) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "gray30", linewidth = 1) +
    stat_halfeye(fill = "#e67e22", alpha = 0.7, .width = c(0.8, 0.95)) +
    theme_minimal(base_size = 14) +
    labs(
      title = sprintf("Demographic Effects on Global %s Consensus", domain_name),
      subtitle = "Positive values = increased consensus | Negative values = increased variance (chaos)",
      x = "Effect Size on Disc Parameter",
      y = NULL
    ) +
    theme(
      plot.title = element_text(face = "bold"),
      plot.subtitle = element_text(color = "gray30", margin = margin(b = 15)),
      panel.grid.major.y = element_blank()
    )
  ggsave(pfile("demographic_variance_effects_forest"), p_disc, width = 10, height = 6, dpi = 300, bg = "white")

  # --- 6. Random Slopes (Location) ---
  cat("Plotting Random Slopes (Location)...\n")
  
  available_rs_terms <- c("social_c", "economic_c", "educ_c", "peduc_c", "arts_c")
  
  if (domain_prefix == "cuisine") {
    draws_rs_loc <- m5 |> 
      spread_draws(r_cuisine[cuisine, term]) |>
      filter(term %in% available_rs_terms) |>
      mutate(
        Category = ifelse(term %in% c("social_c", "economic_c"), "Ideology", "Cultural Capital"),
        Predictor = case_when(
          term == "social_c" ~ "Social Conservatism",
          term == "economic_c" ~ "Economic Conservatism",
          term == "educ_c" ~ "Education",
          term == "peduc_c" ~ "Parental Education",
          term == "arts_c" ~ "Arts Exposure"
        ),
        genre_label = str_to_title(str_replace_all(cuisine, "_", " "))
      )
      
      p_rs_loc_ideo <- draws_rs_loc |> filter(Category == "Ideology") |>
        ggplot(aes(x = r_cuisine, y = reorder(genre_label, r_cuisine), fill = Predictor)) +
        geom_vline(xintercept = 0, linetype = "dashed", color = "gray30") +
        stat_halfeye(alpha = 0.7) +
        facet_wrap(~Predictor, scales = "free_y") +
        theme_minimal() +
        labs(title = sprintf("Random Slopes: Ideological Effects on %s", domain_name),
             x = "Location Random Slope (Positive = Shift toward 'Professional Chef')", y = "") +
        theme(legend.position = "none")
      
      p_rs_loc_cult <- draws_rs_loc |> filter(Category == "Cultural Capital") |>
        ggplot(aes(x = r_cuisine, y = reorder(genre_label, r_cuisine), fill = Predictor)) +
        geom_vline(xintercept = 0, linetype = "dashed", color = "gray30") +
        stat_halfeye(alpha = 0.7) +
        facet_wrap(~Predictor, scales = "free_y") +
        theme_minimal() +
        labs(title = sprintf("Random Slopes: Cultural Capital Effects on %s", domain_name),
             x = "Location Random Slope (Positive = Shift toward 'Professional Chef')", y = "") +
        theme(legend.position = "none")
  } else {
    draws_rs_loc <- m5 |> 
      spread_draws(r_genre[genre, term]) |>
      filter(term %in% available_rs_terms) |>
      mutate(
        Category = ifelse(term %in% c("social_c", "economic_c"), "Ideology", "Cultural Capital"),
        Predictor = case_when(
          term == "social_c" ~ "Social Conservatism",
          term == "economic_c" ~ "Economic Conservatism",
          term == "educ_c" ~ "Education",
          term == "peduc_c" ~ "Parental Education",
          term == "arts_c" ~ "Arts Exposure"
        ),
        genre_label = str_to_title(str_replace_all(genre, "_", " "))
      )
      
      p_rs_loc_ideo <- draws_rs_loc |> filter(Category == "Ideology") |>
        ggplot(aes(x = r_genre, y = reorder(genre_label, r_genre), fill = Predictor)) +
        geom_vline(xintercept = 0, linetype = "dashed", color = "gray30") +
        stat_halfeye(alpha = 0.7) +
        facet_wrap(~Predictor, scales = "free_y") +
        theme_minimal() +
        labs(title = sprintf("Random Slopes: Ideological Effects on %s", domain_name),
             x = "Location Random Slope (Positive = Shift toward 'Like')", y = "") +
        theme(legend.position = "none")
      
      p_rs_loc_cult <- draws_rs_loc |> filter(Category == "Cultural Capital") |>
        ggplot(aes(x = r_genre, y = reorder(genre_label, r_genre), fill = Predictor)) +
        geom_vline(xintercept = 0, linetype = "dashed", color = "gray30") +
        stat_halfeye(alpha = 0.7) +
        facet_wrap(~Predictor, scales = "free_y") +
        theme_minimal() +
        labs(title = sprintf("Random Slopes: Cultural Capital Effects on %s", domain_name),
             x = "Location Random Slope (Positive = Shift toward 'Like')", y = "") +
        theme(legend.position = "none")
  }
  ggsave(pfile("rs_genre_slopes_ideology"), p_rs_loc_ideo, width = 10, height = 6, bg="white")
  ggsave(pfile("rs_genre_slopes_cultural"), p_rs_loc_cult, width = 10, height = 6, bg="white")

  # --- 7. Random Slopes (Variance) ---
  cat("Plotting Random Slopes (Variance)...\n")
  
  if (domain_prefix == "cuisine") {
    draws_rs_var <- m5 |> 
      spread_draws(r_cuisine__disc[cuisine, term]) |>
      filter(term %in% available_rs_terms) |>
      mutate(
        Category = ifelse(term %in% c("social_c", "economic_c"), "Ideology", "Cultural Capital"),
        Predictor = case_when(
          term == "social_c" ~ "Social Conservatism",
          term == "economic_c" ~ "Economic Conservatism",
          term == "educ_c" ~ "Education",
          term == "peduc_c" ~ "Parental Education",
          term == "arts_c" ~ "Arts Exposure"
        ),
        genre_label = str_to_title(str_replace_all(cuisine, "_", " "))
      )
      
      p_rs_var_ideo <- draws_rs_var |> filter(Category == "Ideology") |>
        ggplot(aes(x = r_cuisine__disc, y = reorder(genre_label, r_cuisine__disc), fill = Predictor)) +
        geom_vline(xintercept = 0, linetype = "dashed", color = "gray30") +
        stat_halfeye(alpha = 0.7) +
        facet_wrap(~Predictor, scales = "free_y") +
        theme_minimal() +
        labs(title = sprintf("Random Slopes: Ideological Effects on Consensus by Genre (%s)", domain_name),
             x = "Consensus Random Slope (Positive = Increased Consensus, Negative = Polarization)", y = "") +
        theme(legend.position = "none")
      
      p_rs_var_cult <- draws_rs_var |> filter(Category == "Cultural Capital") |>
        ggplot(aes(x = r_cuisine__disc, y = reorder(genre_label, r_cuisine__disc), fill = Predictor)) +
        geom_vline(xintercept = 0, linetype = "dashed", color = "gray30") +
        stat_halfeye(alpha = 0.7) +
        facet_wrap(~Predictor, scales = "free_y") +
        theme_minimal() +
        labs(title = sprintf("Random Slopes: Cultural Capital Effects on Consensus (%s)", domain_name),
             x = "Consensus Random Slope (Positive = Increased Consensus, Negative = Polarization)", y = "") +
        theme(legend.position = "none")
  } else {
    draws_rs_var <- m5 |> 
      spread_draws(r_genre__disc[genre, term]) |>
      filter(term %in% available_rs_terms) |>
      mutate(
        Category = ifelse(term %in% c("social_c", "economic_c"), "Ideology", "Cultural Capital"),
        Predictor = case_when(
          term == "social_c" ~ "Social Conservatism",
          term == "economic_c" ~ "Economic Conservatism",
          term == "educ_c" ~ "Education",
          term == "peduc_c" ~ "Parental Education",
          term == "arts_c" ~ "Arts Exposure"
        ),
        genre_label = str_to_title(str_replace_all(genre, "_", " "))
      )
      
      p_rs_var_ideo <- draws_rs_var |> filter(Category == "Ideology") |>
        ggplot(aes(x = r_genre__disc, y = reorder(genre_label, r_genre__disc), fill = Predictor)) +
        geom_vline(xintercept = 0, linetype = "dashed", color = "gray30") +
        stat_halfeye(alpha = 0.7) +
        facet_wrap(~Predictor, scales = "free_y") +
        theme_minimal() +
        labs(title = sprintf("Random Slopes: Ideological Effects on Consensus by Genre (%s)", domain_name),
             x = "Consensus Random Slope (Positive = Increased Consensus, Negative = Polarization)", y = "") +
        theme(legend.position = "none")
      
      p_rs_var_cult <- draws_rs_var |> filter(Category == "Cultural Capital") |>
        ggplot(aes(x = r_genre__disc, y = reorder(genre_label, r_genre__disc), fill = Predictor)) +
        geom_vline(xintercept = 0, linetype = "dashed", color = "gray30") +
        stat_halfeye(alpha = 0.7) +
        facet_wrap(~Predictor, scales = "free_y") +
        theme_minimal() +
        labs(title = sprintf("Random Slopes: Cultural Capital Effects on Consensus (%s)", domain_name),
             x = "Consensus Random Slope (Positive = Increased Consensus, Negative = Polarization)", y = "") +
        theme(legend.position = "none")
  }
  
  ggsave(pfile("rs_variance_ideology"), p_rs_var_ideo, width = 10, height = 6, bg="white")
  ggsave(pfile("rs_variance_cultural"), p_rs_var_cult, width = 10, height = 6, bg="white")

  # --- 8. Category-Specific (CS) Threshold Effects ---
  if(!is.null(m2)) {
    cat("Plotting CS Midpoint Contrasts and Raw Thresholds (from Model 2)...\n")
    draws_m2 <- as_draws_df(m2)
    
    calc_midpoint_contrasts <- function(d, var_prefix) {
      t1 <- d[[paste0("bcs_", var_prefix, "[1]")]]
      t2 <- d[[paste0("bcs_", var_prefix, "[2]")]]
      t3 <- d[[paste0("bcs_", var_prefix, "[3]")]]
      t4 <- d[[paste0("bcs_", var_prefix, "[4]")]]
      t5 <- d[[paste0("bcs_", var_prefix, "[5]")]]
      t6 <- d[[paste0("bcs_", var_prefix, "[6]")]]
      
      out <- data.frame(
        .draw = d$.draw,
        X1 = -(t1 + t2 + t3),
        X2 = -(t2 + t3),
        X3 = -t3,
        X5 = t4,
        X6 = t4 + t5,
        X7 = t4 + t5 + t6
      ) |>
        pivot_longer(cols = -c(.draw), names_to = "Contrast_raw", values_to = ".value")
      
      if(domain_prefix == "cuisine") {
        out |> mutate(
          Contrast = case_when(
            Contrast_raw == "X1" ~ "1 (Elder) vs 4",
            Contrast_raw == "X2" ~ "2 vs 4",
            Contrast_raw == "X3" ~ "3 vs 4",
            Contrast_raw == "X5" ~ "5 vs 4",
            Contrast_raw == "X6" ~ "6 vs 4",
            Contrast_raw == "X7" ~ "7 (Chef) vs 4"
          )
        ) |> select(-Contrast_raw)
      } else {
        out |> mutate(
          Contrast = case_when(
            Contrast_raw == "X1" ~ "1 (Dislike) vs 4",
            Contrast_raw == "X2" ~ "2 vs 4",
            Contrast_raw == "X3" ~ "3 vs 4",
            Contrast_raw == "X5" ~ "5 vs 4",
            Contrast_raw == "X6" ~ "6 vs 4",
            Contrast_raw == "X7" ~ "7 (Like) vs 4"
          )
        ) |> select(-Contrast_raw)
      }
    }

    # Ideology CS
    if("bcs_social_c[1]" %in% names(draws_m2)) {
      soc_cs <- calc_midpoint_contrasts(draws_m2, "social_c") |> mutate(Predictor = "Social Conservatism")
      econ_cs <- calc_midpoint_contrasts(draws_m2, "economic_c") |> mutate(Predictor = "Economic Conservatism")
      ideo_cs <- bind_rows(soc_cs, econ_cs) |>
        mutate(Contrast = factor(Contrast, levels = c("1 (Dislike) vs 4", "2 vs 4", "3 vs 4", "5 vs 4", "6 vs 4", "7 (Like) vs 4")))
      
      if(domain_prefix == "cuisine") {
        ideo_cs <- ideo_cs |> mutate(Contrast = factor(Contrast, levels = c("1 (Elder) vs 4", "2 vs 4", "3 vs 4", "5 vs 4", "6 vs 4", "7 (Chef) vs 4")))
      }
      
      p_ideo_mid <- ggplot(ideo_cs, aes(x = .value, y = fct_rev(Contrast), fill = Predictor)) +
        geom_vline(xintercept = 0, linetype = "dashed", color = "gray40", linewidth = 1) +
        stat_halfeye(slab_alpha = 0.35, .width = c(0.8, 0.95)) +
        facet_wrap(~Predictor, ncol = 2) +
        scale_fill_manual(values = c("Social Conservatism" = "coral", "Economic Conservatism" = "steelblue")) +
        labs(
          title = "Midpoint Contrasts: Economic vs. Social Ideology",
          subtitle = "Effect of higher conservatism on choosing a specific rating vs. the Neutral midpoint (4)",
          x = "Log-Odds Shift (vs. Rating 4)",
          y = "Rating vs Neutral Baseline"
        ) +
        theme_minimal(base_size = 14) +
        theme(plot.title = element_text(face = "bold"), legend.position = "none")
      ggsave(pfile("ideology_cs_midpoint_effects"), p_ideo_mid, width = 11, height = 7, bg="white")
      
      # Raw Ideology thresholds
      draws_raw_ideo <- draws_m2 |>
        select(.draw, starts_with("bcs_social_c"), starts_with("bcs_economic_c")) |>
        pivot_longer(cols = -c(.draw), names_to = "Param", values_to = ".value") |>
        mutate(
          Predictor = ifelse(grepl("social", Param), "Social Conservatism", "Economic Conservatism"),
          Threshold = str_extract(Param, "\\[\\d\\]"),
          Threshold = case_when(
            Threshold == "[1]" ~ "1|2",
            Threshold == "[2]" ~ "2|3",
            Threshold == "[3]" ~ "3|4",
            Threshold == "[4]" ~ "4|5",
            Threshold == "[5]" ~ "5|6",
            Threshold == "[6]" ~ "6|7"
          )
        )
      
      p_ideo_raw <- ggplot(draws_raw_ideo, aes(x = .value, y = fct_rev(Threshold), fill = Predictor)) +
        geom_vline(xintercept = 0, linetype = "dashed", color = "gray40", linewidth = 1) +
        stat_halfeye(slab_alpha = 0.35, .width = c(0.8, 0.95)) +
        facet_wrap(~Predictor, ncol = 2) +
        scale_fill_manual(values = c("Social Conservatism" = "coral", "Economic Conservatism" = "steelblue")) +
        labs(
          title = "Raw Category-Specific Thresholds: Ideology",
          subtitle = "Log-odds shift applied at each specific step between ratings",
          x = "Log-Odds Shift at Threshold",
          y = "Rating Boundary"
        ) +
        theme_minimal(base_size = 14) +
        theme(plot.title = element_text(face = "bold"), legend.position = "none")
      ggsave(pfile("ideology_cs_effects"), p_ideo_raw, width = 11, height = 7, bg="white")
    }
    
    # Cultural Capital CS
    if("bcs_educ_c[1]" %in% names(draws_m2)) {
      educ_cs <- calc_midpoint_contrasts(draws_m2, "educ_c") |> mutate(Predictor = "Education")
      cult_cs <- educ_cs
      
      if("bcs_peduc_c[1]" %in% names(draws_m2)) {
        peduc_cs <- calc_midpoint_contrasts(draws_m2, "peduc_c") |> mutate(Predictor = "Parental Education")
        cult_cs <- bind_rows(cult_cs, peduc_cs)
      }
      if("bcs_arts_c[1]" %in% names(draws_m2)) {
        arts_cs <- calc_midpoint_contrasts(draws_m2, "arts_c") |> mutate(Predictor = "Childhood Arts")
        cult_cs <- bind_rows(cult_cs, arts_cs)
      }
      
      cult_cs <- cult_cs |>
        mutate(Contrast = factor(Contrast, levels = c("1 (Dislike) vs 4", "2 vs 4", "3 vs 4", "5 vs 4", "6 vs 4", "7 (Like) vs 4")))
      
      if(domain_prefix == "cuisine") {
        cult_cs <- cult_cs |> mutate(Contrast = factor(Contrast, levels = c("1 (Elder) vs 4", "2 vs 4", "3 vs 4", "5 vs 4", "6 vs 4", "7 (Chef) vs 4")))
      }
      
      p_cult_mid <- ggplot(cult_cs, aes(x = .value, y = fct_rev(Contrast), fill = Predictor)) +
        geom_vline(xintercept = 0, linetype = "dashed", color = "gray40", linewidth = 1) +
        stat_halfeye(slab_alpha = 0.35, .width = c(0.8, 0.95)) +
        facet_wrap(~Predictor, ncol = 3) +
        labs(
          title = "Midpoint Contrasts: Cultural Capital",
          subtitle = "Effect of higher capital on choosing a specific rating vs. the Neutral midpoint (4)",
          x = "Log-Odds Shift (vs. Rating 4)",
          y = "Rating vs Neutral Baseline"
        ) +
        theme_minimal(base_size = 14) +
        theme(plot.title = element_text(face = "bold"), legend.position = "none")
      ggsave(pfile("cultural_cs_midpoint_effects"), p_cult_mid, width = 14, height = 6, bg="white")
      
      # Raw Cultural Capital thresholds
      raw_cols <- c("bcs_educ_c", "bcs_peduc_c", "bcs_arts_c")
      raw_cols_exist <- raw_cols[sapply(raw_cols, function(x) paste0(x, "[1]") %in% names(draws_m2))]
      
      draws_raw_cult <- draws_m2 |>
        select(.draw, starts_with(raw_cols_exist)) |>
        pivot_longer(cols = -c(.draw), names_to = "Param", values_to = ".value") |>
        mutate(
          Predictor = case_when(
            grepl("educ", Param) & !grepl("peduc", Param) ~ "Education",
            grepl("peduc", Param) ~ "Parental Education",
            grepl("arts", Param) ~ "Childhood Arts"
          ),
          Threshold = str_extract(Param, "\\[\\d\\]"),
          Threshold = case_when(
            Threshold == "[1]" ~ "1|2",
            Threshold == "[2]" ~ "2|3",
            Threshold == "[3]" ~ "3|4",
            Threshold == "[4]" ~ "4|5",
            Threshold == "[5]" ~ "5|6",
            Threshold == "[6]" ~ "6|7"
          )
        )
      
      p_cult_raw <- ggplot(draws_raw_cult, aes(x = .value, y = fct_rev(Threshold), fill = Predictor)) +
        geom_vline(xintercept = 0, linetype = "dashed", color = "gray40", linewidth = 1) +
        stat_halfeye(slab_alpha = 0.35, .width = c(0.8, 0.95)) +
        facet_wrap(~Predictor, ncol = 3) +
        labs(
          title = "Raw Category-Specific Thresholds: Cultural Capital",
          subtitle = "Log-odds shift applied at each specific step between ratings",
          x = "Log-Odds Shift at Threshold",
          y = "Rating Boundary"
        ) +
        theme_minimal(base_size = 14) +
        theme(plot.title = element_text(face = "bold"), legend.position = "none")
      ggsave(pfile("cultural_cs_effects"), p_cult_raw, width = 14, height = 6, bg="white")
    }
  } else {
    cat("Model 2 not found! Skipping CS Threshold plots...\n")
  }
}

# Generate plots for all three domains and cuisine test
generate_domain("cuisine", "Cuisine Authenticity")
generate_domain("music", "Musical Taste")
generate_domain("tv", "Television Taste")
generate_domain("mov", "Movie Taste")
