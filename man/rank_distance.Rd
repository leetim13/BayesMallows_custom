% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/rank_distance.R
\name{rank_distance}
\alias{rank_distance}
\title{Distance between a set of rankings and a given rank sequence}
\usage{
rank_distance(rankings, rho, metric, obs_freq = 1)
}
\arguments{
\item{rankings}{A matrix of size \eqn{N }\eqn{\times}{x}\eqn{ n_items} of
rankings in each row. Alternatively, if \eqn{N} equals 1, \code{rankings}
can be a vector.}

\item{rho}{A ranking sequence.}

\item{metric}{Character string specifying the distance measure to use.
Available options are \code{"kendall"}, \code{"cayley"}, \code{"hamming"},
\code{"ulam"}, \code{"footrule"} and \code{"spearman"}.}

\item{obs_freq}{Vector of observation frequencies of length \eqn{N}, or of length 1,
which means that all ranks are given the same weight. Defaults to 1.}
}
\value{
A vector of distances according to the given \code{metric}.
}
\description{
Compute the distance between a matrix of rankings and a rank
  sequence.
}
\details{
The implementation of Cayley distance is based on a \code{C++}
translation of \code{Rankcluster::distCayley} \insertCite{Grimonprez2016}{BayesMallows}.
}
\examples{

# Distance between two vectors of rankings:
rank_distance(1:5, 5:1, metric = "kendall")
rank_distance(c(2, 4, 3, 6, 1, 7, 5), c(3, 5, 4, 7, 6, 2, 1), metric = "cayley")
rank_distance(c(4, 2, 3, 1), c(3, 4, 1, 2), metric = "hamming")
rank_distance(c(1, 3, 5, 7, 9, 8, 6, 4, 2), c(1, 2, 3, 4, 9, 8, 7, 6, 5), "ulam")
rank_distance(c(8, 7, 1, 2, 6, 5, 3, 4), c(1, 2, 8, 7, 3, 4, 6, 5), "footrule")
rank_distance(c(1, 6, 2, 5, 3, 4), c(4, 3, 5, 2, 6, 1), "spearman")

# Difference between a metric and a vector
# We set the burn-in and thinning too low for the example to run fast
data0 <- sample_mallows(rho0 = 1:10, alpha = 20, n_samples = 1000,
                        burnin = 10, thinning = 1)

rank_distance(rankings = data0, rho = 1:10, metric = "kendall")
}
\references{
\insertAllCited
}
\seealso{
Other rank functions: 
\code{\link{expected_dist}()},
\code{\link{get_mallows_loglik}()},
\code{\link{rank_conversion}},
\code{\link{rank_freq_distr}()},
\code{\link{sample_mallows}()}
}
\concept{rank functions}
