#' Observation frequencies in the Bayesian Mallows model
#'
#' When more than one assessor have given the exact same rankings or preferences,
#' considerable speed-up can be obtained by providing only the unique set of
#' rankings/preferences to \code{\link{compute_mallows}}, and instead providing
#' the number of assessors in the \code{obs_freq} argument. This topic is illustrated
#' here. See also the function \code{\link{rank_freq_distr}} for how to easily compute
#' the observation frequencies.
#'
#' @name obs_freq
#' @example /inst/examples/obs_freq_example.R
#' @family preprocessing
NULL
