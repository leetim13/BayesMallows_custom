% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/RcppExports.R
\name{smc_mallows_new_users}
\alias{smc_mallows_new_users}
\title{SMC-Mallows New Users}
\usage{
smc_mallows_new_users(
  R_obs,
  type,
  n_items,
  N,
  Time,
  mcmc_kernel_app,
  num_new_obs,
  alpha_prop_sd = 0.5,
  lambda = 0.1,
  alpha_max = 1e+06,
  alpha = 0,
  aug_method = "random",
  logz_estimate = NULL,
  cardinalities = NULL,
  verbose = FALSE,
  metric = "footnote",
  leap_size = 1L
)
}
\arguments{
\item{R_obs}{Matrix containing the full set of observed rankings of size
n_assessors by n_items}

\item{type}{One of \code{"complete"}, \code{"partial"}, or
\code{"partial_alpha_fixed"}.}

\item{n_items}{Integer is the number of items in a ranking}

\item{N}{Integer specifying the number of particles}

\item{Time}{Integer specifying the number of time steps in the SMC algorithm}

\item{mcmc_kernel_app}{Integer value for the number of applications we
apply the MCMC move kernel}

\item{num_new_obs}{Integer value for the number of new observations
(complete rankings) for each time step}

\item{alpha_prop_sd}{Numeric value specifying the standard deviation of the
lognormal proposal distribution used for \eqn{\alpha} in the
Metropolis-Hastings algorithm. Defaults to \code{0.1}.}

\item{lambda}{Strictly positive numeric value specifying the rate parameter
of the truncated exponential prior distribution of \eqn{\alpha}. Defaults
to \code{0.1}. When \code{n_cluster > 1}, each mixture component
\eqn{\alpha_{c}} has the same prior distribution.}

\item{alpha_max}{Maximum value of \code{alpha} in the truncated exponential
prior distribution.}

\item{alpha}{A numeric value of the scale parameter which is known and fixed.}

\item{aug_method}{A character string specifying the approach for filling
in the missing data, options are "pseudolikelihood" or "random".}

\item{logz_estimate}{Estimate of the partition function, computed with
\code{\link{estimate_partition_function}}.}

\item{cardinalities}{Cardinalities for exact evaluation of partition function,
returned from \code{\link{prepare_partition_function}}.}

\item{verbose}{Logical specifying whether to print out the progress of the
SMC-Mallows algorithm. Defaults to \code{FALSE}.}

\item{metric}{A character string specifying the distance metric to use
in the Bayesian Mallows Model. Available options are \code{"footrule"},
\code{"spearman"}, \code{"cayley"}, \code{"hamming"}, \code{"kendall"}, and
\code{"ulam"}.}

\item{leap_size}{leap_size Integer specifying the step size of the
leap-and-shift proposal distribution}
}
\value{
a set of particles each containing a value of rho and alpha
}
\description{
Function to perform resample-move SMC algorithm where we
receive new users with complete rankings at each time step. See Chapter 4
of \insertCite{steinSequentialInferenceMallows2023}{BayesMallows}
}
\examples{
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
}
\seealso{
Other modeling: 
\code{\link{compute_mallows_mixtures}()},
\code{\link{compute_mallows}()},
\code{\link{smc_mallows_new_item_rank}()}
}
\concept{modeling}
