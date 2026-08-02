suppressPackageStartupMessages(library(brms))
fit <- readRDS("fit_cs_acat.rds")
print(summary(fit))
