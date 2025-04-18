#' BayesMallows: Bayesian Preference Learning with the Mallows Rank Model.
#'
#' @description The BayesMallows package provides functionality for fully
#'   Bayesian analysis of preference or rank data. The package implements the
#'   Bayesian Mallows model described in
#'   \insertCite{vitelli2018;textual}{BayesMallows}, which handles complete
#'   rankings, top-k rankings, ranks missing at random, and consistent pairwise
#'   preference data, as well as mixtures of rank models. Modeling of pairwise
#'   preferences containing inconsistencies, as described in
#'   \insertCite{crispino2019;textual}{BayesMallows}, is also supported. See
#'   also \insertCite{sorensen2020;textual}{BayesMallows} for an overview of the
#'   methods and a tutorial.
#'
#'   The documentation and examples for the following functions are likely most
#'   useful to get you started:
#' \itemize{
#'  \item For analysis of rank or preference data, see \code{\link{compute_mallows}}.
#'  \item For computation of multiple models with varying numbers of mixture components,
#'  see \code{\link{compute_mallows_mixtures}}.
#'  \item For estimation of the partition function (normalizing constant) using either
#'  the importance sampling algorithm of \insertCite{vitelli2018;textual}{BayesMallows} or
#'  the asymptotic algorithm of \insertCite{mukherjee2016;textual}{BayesMallows}, see
#'  \code{\link{estimate_partition_function}}.
#'  \item For sequential Monte Carlo algorithms developed in
#'  \insertCite{steinSequentialInferenceMallows2023;textual}{BayesMallows}, see
#'  \code{\link{smc_mallows_new_users}} and \code{\link{smc_mallows_new_item_rank}}.
#' }
#'
#'
#'
#' @docType package
#' @name BayesMallows
#' @aliases BayesMallows-package
#'
#' @references \insertAllCited{}
NULL
