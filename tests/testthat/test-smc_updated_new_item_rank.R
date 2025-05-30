# set-up

# new item rank for each user (fewer things)
example_dataset <- sushi_rankings[1:100, ]
n_users <- dim(example_dataset)[1]
n_items <- dim(example_dataset)[2]
test_dataset <- array(0, c(n_users, n_items, (n_items / 2 + 1)))
test_dataset[, , (n_items / 2 + 1)] <- example_dataset
tt <- 0
for (ii in (n_items - 1):(n_items / 2)) {
  tt <- tt + 1

  # set n_users line with one more NA
  example_dataset[example_dataset > ii] <- NA

  # set as new time stamp
  test_dataset[, , ((n_items / 2 + 1) - tt)] <- example_dataset
}


metric <- "footrule"
leap_size <- floor(n_items / 5)

cardinalities <- prepare_partition_function(metric = metric, n_items = n_items)$cardinalities

# test with random sampler
N <- 2
mcmc_kernel_app <- 5
num_new_obs <- 10
Time <- n_users / num_new_obs
Time2 <- dim(test_dataset)[3]
sample_dataset <- example_dataset

# run smc new user with uniform
set.seed(994)
smc_test_new_user_unif <- smc_mallows_new_users(
  R_obs = sample_dataset,
  type = "partial",
  n_items = n_items,
  metric = metric,
  leap_size = leap_size,
  N = N,
  Time = Time,
  mcmc_kernel_app = mcmc_kernel_app,
  num_new_obs = num_new_obs,
  alpha_prop_sd = 0.5,
  lambda = 0.1,
  alpha_max = 20,
  aug_method = "random",
  logz_estimate = NULL,
  cardinalities = cardinalities
)

# run smc updated rankings with alpha unknown
smc_test_partial_unif1 <- smc_mallows_new_item_rank(
  alpha = 2, n_items = n_items,
  R_obs = test_dataset, metric = metric, leap_size = leap_size,
  N = N, Time = Time2, logz_estimate = NULL,
  cardinalities = cardinalities,
  mcmc_kernel_app = mcmc_kernel_app, aug_method = "random",
  rho_samples_init = smc_test_new_user_unif$rho_samples[, , Time + 1],
  aug_rankings_init = smc_test_new_user_unif$augmented_rankings,
  alpha_fixed = TRUE
)
test_that("Updated item rank output is OK", {
  expect_is(smc_test_partial_unif1, "SMCMallows")
  expect_length(smc_test_partial_unif1, 3)
  expect_equal(dim(smc_test_partial_unif1$rho_samples), c(N, n_items, 6))
  expect_length(smc_test_partial_unif1$ESS, Time2)
  expect_equal(dim(smc_test_partial_unif1$augmented_rankings), c(n_users, n_items, N))
})

# run smc updated rankings with alpha unknown
smc_test_partial_unif2 <- smc_mallows_new_item_rank(
  n_items = n_items,
  R_obs = test_dataset, metric = metric, leap_size = leap_size,
  N = N, Time = Time2, logz_estimate = NULL,
  cardinalities = cardinalities,
  mcmc_kernel_app = mcmc_kernel_app, alpha_prop_sd = 0.5,
  lambda = 0.1, alpha_max = 20, aug_method = "random",
  alpha_samples_init = smc_test_new_user_unif$alpha_samples[, Time + 1],
  rho_samples_init = smc_test_new_user_unif$rho_samples[, , Time + 1],
  aug_rankings_init = smc_test_new_user_unif$augmented_rankings
)
test_that("Updated item rank output (alpha variable) is OK", {
  expect_is(smc_test_partial_unif2, "SMCMallows")
  expect_length(smc_test_partial_unif2, 4)
  expect_equal(dim(smc_test_partial_unif2$rho_samples), c(N, n_items, 6))
  expect_length(smc_test_partial_unif2$ESS, Time2)
  expect_equal(dim(smc_test_partial_unif2$augmented_rankings), c(n_users, n_items, N))
  expect_equal(dim(smc_test_partial_unif2$alpha_samples), c(N, 6))
})

# test with pseudolikelihood

smc_test_new_user_pseudo <- smc_mallows_new_users(
  R_obs = example_dataset, n_items = n_items, metric = metric,
  leap_size = leap_size,
  N = N, Time = Time, logz_estimate = NULL,
  cardinalities = cardinalities,
  mcmc_kernel_app = mcmc_kernel_app, num_new_obs = num_new_obs,
  alpha_prop_sd = 0.5, lambda = 0.1,
  alpha_max = 20, type = "partial", aug_method = "pseudolikelihood"
)

smc_test_partial_pseudo1 <- smc_mallows_new_item_rank(
  alpha = 2, n_items = n_items,
  R_obs = test_dataset, metric = metric, leap_size = leap_size,
  N = N, Time = Time2, logz_estimate = NULL,
  cardinalities = cardinalities,
  mcmc_kernel_app = mcmc_kernel_app, aug_method = "pseudolikelihood",
  rho_samples_init = smc_test_new_user_pseudo$rho_samples[, , Time + 1],
  aug_rankings_init = smc_test_new_user_pseudo$augmented_rankings,
  alpha_fixed = TRUE
)
test_that("Updated item rank output is OK", {
  expect_is(smc_test_partial_pseudo1, "SMCMallows")
  expect_length(smc_test_partial_pseudo1, 3)
  expect_equal(dim(smc_test_partial_pseudo1$rho_samples), c(N, n_items, 6))
  expect_length(smc_test_partial_pseudo1$ESS, Time2)
  expect_equal(dim(smc_test_partial_pseudo1$augmented_rankings), c(n_users, n_items, N))
})

smc_test_partial_pseudo2 <- smc_mallows_new_item_rank(
  n_items = n_items,
  R_obs = test_dataset, metric = metric, leap_size = leap_size,
  N = N, Time = Time2, logz_estimate = NULL,
  cardinalities = cardinalities,
  mcmc_kernel_app = mcmc_kernel_app, alpha_prop_sd = 0.5,
  lambda = 0.1, alpha_max = 20, aug_method = "pseudolikelihood",
  alpha_samples_init = smc_test_new_user_unif$alpha_samples[, Time + 1],
  rho_samples_init = smc_test_new_user_unif$rho_samples[, , Time + 1],
  aug_rankings_init = smc_test_new_user_unif$augmented_rankings
)
test_that("Updated item rank output (variable alpha) is OK", {
  expect_is(smc_test_partial_pseudo2, "SMCMallows")
  expect_length(smc_test_partial_pseudo2, 4)
  expect_equal(dim(smc_test_partial_pseudo2$rho_samples), c(N, n_items, 6))
  expect_length(smc_test_partial_pseudo2$ESS, Time2)
  expect_equal(dim(smc_test_partial_pseudo2$augmented_rankings), c(n_users, n_items, N))
  expect_equal(dim(smc_test_partial_pseudo2$alpha_samples), c(N, 6))
})

# check metric and aug_method error
test_that("metric and aug_method must match", {
  expect_error(
    smc_mallows_new_item_rank(
      alpha = 2, n_items = n_items,
      R_obs = test_dataset, metric = "cayley", leap_size = leap_size,
      N = N, Time = Time2, logz_estimate = NULL,
      cardinalities = cardinalities,
      mcmc_kernel_app = mcmc_kernel_app, aug_method = "pseudolikelihood",
      alpha_fixed = TRUE
    ),
    "Pseudolikelihood only supports footrule and spearman metrics"
  )
})
