# Generate basic elements
data <- sushi_rankings[1:100, ]
n_items <- ncol(sushi_rankings)
metric <- "footrule"
num_new_obs <- 10

# Prepare exact partition function
cardinalities <- prepare_partition_function(metric = metric,
                                            n_items = n_items)$cardinalities

# Calculating rho and alpha samples
samples <- smc_mallows_new_users(
  R_obs = data, type = "complete", n_items = n_items, metric = metric,
  leap_size = floor(n_items / 5), N = 100, Time = nrow(data) / num_new_obs,
  mcmc_kernel_app = 5, cardinalities = cardinalities,
  alpha_prop_sd = 0.1, lambda = 0.001, alpha_max = 1e6,
  num_new_obs = num_new_obs, verbose = TRUE
)

# Studying the structure of the output
str(samples)
