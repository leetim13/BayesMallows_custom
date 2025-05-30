% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/assign_cluster.R
\name{assign_cluster}
\alias{assign_cluster}
\title{Assign Assessors to Clusters}
\usage{
assign_cluster(
  model_fit,
  burnin = model_fit$burnin,
  soft = TRUE,
  expand = FALSE
)
}
\arguments{
\item{model_fit}{An object of type \code{BayesMallows}, returned from
\code{\link{compute_mallows}}.}

\item{burnin}{A numeric value specifying the number of iterations
to discard as burn-in. Defaults to \code{model_fit$burnin}, and must be
provided if \code{model_fit$burnin} does not exist. See \code{\link{assess_convergence}}.}

\item{soft}{A logical specifying whether to perform soft or
hard clustering. If \code{soft=TRUE}, all cluster probabilities
are returned, whereas if \code{soft=FALSE}, only the maximum a
posterior (MAP) cluster probability is returned, per assessor. In the
case of a tie between two or more cluster assignments, a random cluster
is taken as MAP estimate.}

\item{expand}{A logical specifying whether or not to expand the rowset
of each assessor to also include clusters for which the assessor has
0 a posterior assignment probability. Only used when \code{soft = TRUE}. Defaults
to \code{FALSE}.}
}
\value{
A dataframe. If \code{soft = FALSE}, it has one row per assessor, and columns \code{assessor},
\code{probability} and \code{map_cluster}. If \code{soft = TRUE}, it has \code{n_cluster}
rows per assessor, and the additional column \code{cluster}.
}
\description{
Assign assessors to clusters by finding the cluster with highest
posterior probability.
}
\seealso{
\code{\link{compute_mallows}} for an example where this function is used.

Other posterior quantities: 
\code{\link{compute_consensus.BayesMallows}()},
\code{\link{compute_consensus.SMCMallows}()},
\code{\link{compute_consensus}()},
\code{\link{compute_posterior_intervals.BayesMallows}()},
\code{\link{compute_posterior_intervals.SMCMallows}()},
\code{\link{compute_posterior_intervals}()},
\code{\link{heat_plot}()},
\code{\link{plot.BayesMallows}()},
\code{\link{plot.SMCMallows}()},
\code{\link{plot_elbow}()},
\code{\link{plot_top_k}()},
\code{\link{predict_top_k}()},
\code{\link{print.BayesMallowsMixtures}()},
\code{\link{print.BayesMallows}()}
}
\concept{posterior quantities}
