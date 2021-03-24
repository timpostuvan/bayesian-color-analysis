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
stimuli_color = "red"                  # red, blue, green, yellow, cyan, magenta

########################################################################################

# data preparation
load("../data/after_images.rda")

data_red = after_images %>% filter(stimuli == stimuli_color)
RGB_data = data.frame(r=data_red$r,
                      g=data_red$g,
                      b=data_red$b)

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