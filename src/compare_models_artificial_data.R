# libraries --------------------------------------------------------------------
library(cmdstanr)
library(posterior)
library(bayesplot)
library(mcmcse)
library(dplyr)
library(ggplot2)
library("loo")
setwd("~/bayesian-color-analysis/src")

# hyperparameter settings
num_warmup_iterations = 1000
num_sampling_iterations = 1000
num_chains = 3

########################################################################################

# data preparation
RGB_data <- c(127, 127, 127)
for (i in 1:100) {
  RGB_data <- rbind(RGB_data, c(127 + rnorm(1, 0, 1), 
                                127 + rnorm(1, 0, 10), 
                                127 + rnorm(1, 0, 30)))
}
n <- nrow(RGB_data)

########################################################################################

# compile the model
model_CIELAB <- cmdstan_model("../models/CIELAB_uniform.stan")

# prepare input data
stan_data_CIELAB <- list(n = n, RGB_data = RGB_data)

# fit
fit_CIELAB <- model_CIELAB$sample(
  data = stan_data_CIELAB,
  iter_warmup = num_warmup_iterations,
  iter_sampling = num_sampling_iterations,
  chains = num_chains
)

########################################################################################

# compile the model
model_RGB <- cmdstan_model("../models/RGB_uniform.stan")

# prepare input data
stan_data_RGB <- list(n = n, RGB_data_raw = RGB_data)

# fit
fit_RGB <- model_RGB$sample(
  data = stan_data_RGB,
  iter_warmup = num_warmup_iterations,
  iter_sampling = num_sampling_iterations,
  chains = num_chains
)

########################################################################################

# CIELAB
print("CIELAB:")
df <- as_draws_df(fit_CIELAB$draws())
mcmc_trace(df[, 1:16])
mcmc_hist(fit_CIELAB$draws("mu"))

fit_CIELAB$summary("mu_RGB")

loo_result_CIELAB <- fit_CIELAB$loo()
loo_result_CIELAB


# RGB
print("RGB:")
df <- as_draws_df(fit_RGB$draws())
mcmc_trace(df[, 1:10])
mcmc_hist(fit_RGB$draws("mu"))

fit_RGB$summary("mu_RGB")

loo_result_RGB <- fit_RGB$loo()
loo_result_RGB


# Comparison
comparison <- loo_compare(loo_result_CIELAB, loo_result_RGB)
comparison