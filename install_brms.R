source("renv/activate.R")
options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/jammy/latest"))
renv::install(c("rstan", "brms"), prompt = FALSE)
