# libraries --------------------------------------------------------------------
library(cmdstanr)
library(posterior)
library(bayesplot)
library(mcmcse)
library("loo")
setwd("~/bayesian-color-analysis/src")


# modelling and data prep ------------------------------------------------------
# compile the model
model <- cmdstan_model("../models/RGB_uniform.stan")


# generate data
RGB_data <- c(127, 127, 127)
for (i in 1:100) {
  RGB_data <- rbind(RGB_data, c(127 + rnorm(1, 0, 1),
                                127 + rnorm(1, 0, 10), 
                                127 + rnorm(1, 0, 30)))
}
n <- nrow(RGB_data)

# prepare input data
stan_data <- list(n = n, RGB_data_raw = RGB_data)


# fit
fit <- model$sample(
  data = stan_data,
  iter_warmup = 1000,
  iter_sampling = 1000,
  chains = 1
)



# diagnostics ------------------------------------------------------------------
df <- as_draws_df(fit$draws())
mcmc_trace(df[, 1:10])

mcmc_hist(fit$draws("mu"))

fit$summary("mu_RGB")

loo_result <- fit$loo()
loo_result