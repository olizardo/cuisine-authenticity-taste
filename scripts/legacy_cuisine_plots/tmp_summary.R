library(brms)
library(dplyr)
library(tidybayes)
fit <- readRDS('cache/hier_2_relaxed.rds')

draws <- fit |> gather_draws(
  `bcs_social_c[1]`, `bcs_social_c[2]`, `bcs_social_c[3]`, `bcs_social_c[4]`, `bcs_social_c[5]`, `bcs_social_c[6]`,
  `bcs_economic_c[1]`, `bcs_economic_c[2]`, `bcs_economic_c[3]`, `bcs_economic_c[4]`, `bcs_economic_c[5]`, `bcs_economic_c[6]`,
  `bcs_educ_c[1]`, `bcs_educ_c[2]`, `bcs_educ_c[3]`, `bcs_educ_c[4]`, `bcs_educ_c[5]`, `bcs_educ_c[6]`,
  `bcs_peduc_c[1]`, `bcs_peduc_c[2]`, `bcs_peduc_c[3]`, `bcs_peduc_c[4]`, `bcs_peduc_c[5]`, `bcs_peduc_c[6]`
)

res <- draws |> group_by(.variable) |> summarize(med = round(median(.value), 3)) |> as.data.frame()
print(res)
