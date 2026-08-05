library(brms)
library(tidybayes)
library(dplyr)

fit <- readRDS("cache/hier_4_var.rds")
# Check variables
vars <- get_variables(fit)
print(head(vars[grepl("^r_cuisine", vars)], 10))
