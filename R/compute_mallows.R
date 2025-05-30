#' Preference Learning with the Mallows Rank Model
#'
#' @description Compute the posterior distributions of the parameters of the
#'   Bayesian Mallows Rank Model, given rankings or preferences stated by a set
#'   of assessors.
#'
#'   The \code{BayesMallows} package uses the following parametrization of the
#'   Mallows rank model \insertCite{mallows1957}{BayesMallows}:
#'   \deqn{p(r|\alpha,\rho) = (1/Z_{n}(\alpha)) \exp{-\alpha/n d(r,\rho)}} where
#'   \eqn{r} is a ranking, \eqn{\alpha} is a scale parameter, \eqn{\rho} is the
#'   latent consensus ranking, \eqn{Z_{n}(\alpha)} is the partition function
#'   (normalizing constant), and \eqn{d(r,\rho)} is a distance function
#'   measuring the distance between \eqn{r} and \eqn{\rho}. Note that some
#'   authors use a Mallows model without division by \eqn{n} in the exponent;
#'   this includes the \code{PerMallows} package, whose scale parameter
#'   \eqn{\theta} corresponds to \eqn{\alpha/n} in the \code{BayesMallows}
#'   package. We refer to \insertCite{vitelli2018}{BayesMallows} for further
#'   details of the Bayesian Mallows model.
#'
#'   \code{compute_mallows} always returns posterior distributions of the latent
#'   consensus ranking \eqn{\rho} and the scale parameter \eqn{\alpha}. Several
#'   distance measures are supported, and the preferences can take the form of
#'   complete or incomplete rankings, as well as pairwise preferences.
#'   \code{compute_mallows} can also compute mixtures of Mallows models, for
#'   clustering of assessors with similar preferences.
#'
#' @param rankings A matrix of ranked items, of size \code{n_assessors x
#'   n_items}. See \code{\link{create_ranking}} if you have an ordered set of
#'   items that need to be converted to rankings. If \code{preferences} is
#'   provided, \code{rankings} is an optional initial value of the rankings,
#'   generated by \code{\link{generate_initial_ranking}}. If \code{rankings} has
#'   column names, these are assumed to be the names of the items. \code{NA}
#'   values in rankings are treated as missing data and automatically augmented;
#'   to change this behavior, see the \code{na_action} argument.
#'
#' @param preferences A dataframe with pairwise comparisons, with 3 columns,
#'   named \code{assessor}, \code{bottom_item}, and \code{top_item}, and one row
#'   for each stated preference. Given a set of pairwise preferences, generate a
#'   transitive closure using \code{\link{generate_transitive_closure}}. This
#'   will give \code{preferences} the class \code{"BayesMallowsTC"}. If
#'   \code{preferences} is not of class \code{"BayesMallowsTC"},
#'   \code{compute_mallows} will call \code{\link{generate_transitive_closure}}
#'   on \code{preferences} before computations are done. In the current version,
#'   the pairwise preferences are assumed to be mutually compatible.
#'
#' @param obs_freq A vector of observation frequencies (weights) to apply do
#'   each row in \code{rankings}. This can speed up computation if a large
#'   number of assessors share the same rank pattern. Defaults to \code{NULL},
#'   which means that each row of \code{rankings} is multiplied by 1. If
#'   provided, \code{obs_freq} must have the same number of elements as there
#'   are rows in \code{rankings}, and \code{rankings} cannot be \code{NULL}. See
#'   \code{\link{obs_freq}} for more information and
#'   \code{\link{rank_freq_distr}} for a convenience function for computing it.
#'
#' @param metric A character string specifying the distance metric to use in the
#'   Bayesian Mallows Model. Available options are \code{"footrule"},
#'   \code{"spearman"}, \code{"cayley"}, \code{"hamming"}, \code{"kendall"}, and
#'   \code{"ulam"}. The distance given by \code{metric} is also used to compute
#'   within-cluster distances, when \code{include_wcd = TRUE}.
#'
#' @param error_model Character string specifying which model to use for
#'   inconsistent rankings. Defaults to \code{NULL}, which means that
#'   inconsistent rankings are not allowed. At the moment, the only available
#'   other option is \code{"bernoulli"}, which means that the Bernoulli error
#'   model is used. See \insertCite{crispino2019;textual}{BayesMallows} for a
#'   definition of the Bernoulli model.
#'
#' @param n_clusters Integer specifying the number of clusters, i.e., the number
#'   of mixture components to use. Defaults to \code{1L}, which means no
#'   clustering is performed. See \code{\link{compute_mallows_mixtures}} for a
#'   convenience function for computing several models with varying numbers of
#'   mixtures.
#'
#'
#'
#' @param clus_thin Integer specifying the thinning to be applied to cluster
#'   assignments and cluster probabilities. Defaults to \code{1L}.
#'
#' @param nmc Integer specifying the number of iteration of the
#'   Metropolis-Hastings algorithm to run. Defaults to \code{2000L}. See
#'   \code{\link{assess_convergence}} for tools to check convergence of the
#'   Markov chain.
#'
#' @param leap_size Integer specifying the step size of the leap-and-shift
#'   proposal distribution. Defaults \code{floor(n_items / 5)}.
#'
#' @param swap_leap Integer specifying the step size of the Swap proposal. Only
#'   used when \code{error_model} is not \code{NULL}.
#'
#'
#' @param rho_init Numeric vector specifying the initial value of the latent
#'   consensus ranking \eqn{\rho}. Defaults to NULL, which means that the
#'   initial value is set randomly. If \code{rho_init} is provided when
#'   \code{n_clusters > 1}, each mixture component \eqn{\rho_{c}} gets the same
#'   initial value.
#'
#' @param rho_thinning Integer specifying the thinning of \code{rho} to be
#'   performed in the Metropolis- Hastings algorithm. Defaults to \code{1L}.
#'   \code{compute_mallows} save every \code{rho_thinning}th value of
#'   \eqn{\rho}.
#'
#' @param alpha_prop_sd Numeric value specifying the standard deviation of the
#'   lognormal proposal distribution used for \eqn{\alpha} in the
#'   Metropolis-Hastings algorithm. Defaults to \code{0.1}.
#'
#' @param alpha_init Numeric value specifying the initial value of the scale
#'   parameter \eqn{\alpha}. Defaults to \code{1}. When \code{n_clusters > 1},
#'   each mixture component \eqn{\alpha_{c}} gets the same initial value. When
#'   chains are run in parallel, by providing an argument \code{cl = cl}, then
#'   \code{alpha_init} can be a vector of of length \code{length(cl)}, each
#'   element of which becomes an initial value for the given chain.
#'
#' @param alpha_jump Integer specifying how many times to sample \eqn{\rho}
#'   between each sampling of \eqn{\alpha}. In other words, how many times to
#'   jump over \eqn{\alpha} while sampling \eqn{\rho}, and possibly other
#'   parameters like augmented ranks \eqn{\tilde{R}} or cluster assignments
#'   \eqn{z}. Setting \code{alpha_jump} to a high number can speed up
#'   computation time, by reducing the number of times the partition function
#'   for the Mallows model needs to be computed. Defaults to \code{1L}.
#'
#' @param lambda Strictly positive numeric value specifying the rate parameter
#'   of the truncated exponential prior distribution of \eqn{\alpha}. Defaults
#'   to \code{0.1}. When \code{n_cluster > 1}, each mixture component
#'   \eqn{\alpha_{c}} has the same prior distribution.
#'
#' @param alpha_max Maximum value of \code{alpha} in the truncated exponential
#'   prior distribution.
#'
#' @param psi Integer specifying the concentration parameter \eqn{\psi} of the
#'   Dirichlet prior distribution used for the cluster probabilities
#'   \eqn{\tau_{1}, \tau_{2}, \dots, \tau_{C}}, where \eqn{C} is the value of
#'   \code{n_clusters}. Defaults to \code{10L}. When \code{n_clusters = 1}, this
#'   argument is not used.
#'
#' @param include_wcd Logical indicating whether to store the within-cluster
#'   distances computed during the Metropolis-Hastings algorithm. Defaults to
#'   \code{TRUE} if \code{n_clusters > 1} and otherwise \code{FALSE}. Setting
#'   \code{include_wcd = TRUE} is useful when deciding the number of mixture
#'   components to include, and is required by \code{\link{plot_elbow}}.
#'
#' @param save_aug Logical specifying whether or not to save the augmented
#'   rankings every \code{aug_thinning}th iteration, for the case of missing
#'   data or pairwise preferences. Defaults to \code{FALSE}. Saving augmented
#'   data is useful for predicting the rankings each assessor would give to the
#'   items not yet ranked, and is required by \code{\link{plot_top_k}}.
#'
#' @param aug_thinning Integer specifying the thinning for saving augmented
#'   data. Only used when \code{save_aug = TRUE}. Defaults to \code{1L}.
#'
#' @param logz_estimate Estimate of the partition function, computed with
#'   \code{\link{estimate_partition_function}}. Be aware that when using an
#'   estimated partition function when \code{n_clusters > 1}, the partition
#'   function should be estimated over the whole range of \eqn{\alpha} values
#'   covered by the prior distribution for \eqn{\alpha} with high probability.
#'   In the case that a cluster \eqn{\alpha_c} becomes empty during the
#'   Metropolis-Hastings algorithm, the posterior of \eqn{\alpha_c} equals its
#'   prior. For example, if the rate parameter of the exponential prior equals,
#'   say \eqn{\lambda = 0.001}, there is about 37 \% (or exactly: \code{1 -
#'   pexp(1000, 0.001)}) prior probability that \eqn{\alpha_c > 1000}. Hence
#'   when \code{n_clusters > 1}, the estimated partition function should cover
#'   this range, or \eqn{\lambda} should be increased.
#'
#' @param verbose Logical specifying whether to print out the progress of the
#'   Metropolis-Hastings algorithm. If \code{TRUE}, a notification is printed
#'   every 1000th iteration. Defaults to \code{FALSE}.
#'
#' @param validate_rankings Logical specifying whether the rankings provided (or
#'   generated from \code{preferences}) should be validated. Defaults to
#'   \code{TRUE}. Turning off this check will reduce computing time with a large
#'   number of items or assessors.
#'
#' @param na_action Character specifying how to deal with \code{NA} values in
#'   the \code{rankings} matrix, if provided. Defaults to \code{"augment"},
#'   which means that missing values are automatically filled in using the
#'   Bayesian data augmentation scheme described in
#'   \insertCite{vitelli2018;textual}{BayesMallows}. The other options for this
#'   argument are \code{"fail"}, which means that an error message is printed
#'   and the algorithm stops if there are \code{NA}s in \code{rankings}, and
#'   \code{"omit"} which simply deletes rows with \code{NA}s in them.
#'
#' @param constraints Optional constraint set returned from
#'   \code{\link{generate_constraints}}. Defaults to \code{NULL}, which means
#'   the the constraint set is computed internally. In repeated calls to
#'   \code{compute_mallows}, with very large datasets, computing the constraint
#'   set may be time consuming. In this case it can be beneficial to precompute
#'   it and provide it as a separate argument.
#'
#' @param save_ind_clus Whether or not to save the individual cluster
#'   probabilities in each step. This results in csv files
#'   \code{cluster_probs1.csv}, \code{cluster_probs2.csv}, ..., being saved in
#'   the calling directory. This option may slow down the code considerably, but
#'   is necessary for detecting label switching using Stephen's algorithm. See
#'   \code{\link{label_switching}} for more information.
#'
#' @param seed Optional integer to be used as random number seed.
#'
#' @param cl Optional cluster.
#'
#'
#' @return A list of class BayesMallows.
#'
#' @seealso \code{\link{compute_mallows_mixtures}} for a function that computes
#'   separate Mallows models for varying numbers of clusters.
#'
#'
#'
#' @references \insertAllCited{}
#'
#' @export
#' @importFrom rlang .data
#'
#' @family modeling
#'
#' @example /inst/examples/compute_mallows_example.R
#'
compute_mallows <- function(rankings = NULL,
                            preferences = NULL,
                            obs_freq = NULL,
                            metric = "footrule",
                            error_model = NULL,
                            n_clusters = 1L,
                            clus_thin = 1L,
                            nmc = 2000L,
                            leap_size = max(1L, floor(n_items / 5)),
                            swap_leap = 1L,
                            rho_init = NULL,
                            rho_thinning = 1L,
                            alpha_prop_sd = 0.1,
                            alpha_init = 1,
                            alpha_jump = 1L,
                            lambda = 0.001,
                            alpha_max = 1e6,
                            psi = 10L,
                            include_wcd = (n_clusters > 1),
                            save_aug = FALSE,
                            aug_thinning = 1L,
                            logz_estimate = NULL,
                            verbose = FALSE,
                            validate_rankings = TRUE,
                            na_action = "augment",
                            constraints = NULL,
                            save_ind_clus = FALSE,
                            seed = NULL,
                            cl = NULL) {
  if (!is.null(seed)) set.seed(seed)

  # Check if there are NAs in rankings, if it is provided
  if (!is.null(rankings)) {
    if (na_action == "fail" && any(is.na(rankings))) {
      stop("rankings matrix contains NA values")
    }

    if (na_action == "omit" && any(is.na(rankings))) {
      keeps <- apply(rankings, 1, function(x) !any(is.na(x)))
      print(paste("Omitting", sum(keeps), "rows from rankings due to NA values"))
      rankings <- rankings[keeps, , drop = FALSE]
    }
  }

  # Check that at most one of rankings and preferences is set
  if (is.null(rankings) && is.null(preferences)) {
    stop("Either rankings or preferences (or both) must be provided.")
  }

  if (is.null(preferences) && !is.null(error_model)) {
    stop("Error model requires preferences to be set.")
  }

  # Check if obs_freq are provided
  if (!is.null(obs_freq)) {
    if (is.null(rankings)) {
      stop("rankings matrix must be provided when obs_freq are provided")
    }
    if (nrow(rankings) != length(obs_freq)) {
      stop("obs_freq must be of same length as the number of rows in rankings")
    }
  }

  if (!swap_leap > 0) stop("swap_leap must be strictly positive")
  if (nmc <= 0) stop("nmc must be strictly positive")

  # Check that we do not jump over all alphas
  if (alpha_jump >= nmc) stop("alpha_jump must be strictly smaller than nmc")

  # Check that we do not jump over all rhos
  if (rho_thinning >= nmc) stop("rho_thinning must be strictly smaller than nmc")
  if (aug_thinning >= nmc) stop("aug_thinning must be strictly smaller than nmc")

  if (lambda <= 0) stop("exponential rate parameter lambda must be strictly positive")

  # Check that all rows of rankings are proper permutations
  if (!is.null(rankings) && validate_rankings && !all(apply(rankings, 1, validate_permutation))) {
    stop("invalid permutations provided in rankings matrix")
  }


  # Deal with pairwise comparisons. Generate rankings compatible with them.
  if (!is.null(preferences) && is.null(error_model)) {
    if (!inherits(preferences, "BayesMallowsTC")) {
      message("Generating transitive closure of preferences.")
      # Make sure the preference columns are double
      preferences$bottom_item <- as.numeric(preferences$bottom_item)
      preferences$top_item <- as.numeric(preferences$top_item)
      preferences <- generate_transitive_closure(preferences)
    }
    if (is.null(rankings)) {
      message("Generating initial ranking.")
      rankings <- generate_initial_ranking(preferences)
    }
  } else if (!is.null(error_model)) {
    stopifnot(error_model == "bernoulli")
    n_items <- max(c(preferences$bottom_item, preferences$top_item))
    n_assessors <- length(unique(preferences$assessor))
    if (is.null(rankings)) {
      rankings <- replicate(n_assessors, sample(x = n_items, size = n_items), simplify = "numeric")
      rankings <- matrix(rankings, ncol = n_items, nrow = n_assessors, byrow = TRUE)
    }
  }

  # Find the number of items
  n_items <- ncol(rankings)

  # If any row of rankings has only one missing value, replace it with the implied ranking
  if (any(is.na(rankings))) {
    dn <- dimnames(rankings)
    rankings <- lapply(
      split(rankings, f = seq_len(nrow(rankings))),
      function(x) {
        if (sum(is.na(x)) == 1) x[is.na(x)] <- setdiff(seq_along(x), x)
        return(x)
      }
    )
    rankings <- do.call(rbind, rankings)
    dimnames(rankings) <- dn
  }

  if (!is.null(rho_init)) {
    if (!validate_permutation(rho_init)) stop("rho_init must be a proper permutation")
    if (!(sum(is.na(rho_init)) == 0)) stop("rho_init cannot have missing values")
    if (length(rho_init) != n_items) stop("rho_init must have the same number of items as implied by rankings or preferences")
    rho_init <- matrix(rho_init, ncol = 1)
  }

  # Generate the constraint set
  if (!is.null(preferences) && is.null(constraints)) {
    constraints <- generate_constraints(preferences, n_items)
  } else if (is.null(constraints)) {
    constraints <- list()
  }

  if (is.null(obs_freq)) obs_freq <- rep(1, nrow(rankings))

  logz_list <- prepare_partition_function(logz_estimate, metric, n_items)

  if (save_ind_clus) {
    abort <- readline(
      prompt = paste(
        nmc, "csv files will be saved in your current working directory.",
        "Proceed? (yes/no): "
      )
    )
    if (tolower(abort) %in% c("n", "no")) stop()
  }

  if (is.null(cl)) {
    lapplyfun <- lapply
    chain_seq <- 1
  } else {
    parallel::clusterExport(
      cl = cl,
      varlist = c(
        "rankings", "obs_freq", "nmc", "constraints", "logz_list",
        "rho_init", "metric", "swap_leap", "error_model",
        "n_clusters", "include_wcd", "leap_size", "alpha_prop_sd", "alpha_init",
        "alpha_jump", "lambda", "alpha_max", "psi", "rho_thinning", "aug_thinning",
        "clus_thin", "save_aug", "verbose", "save_ind_clus"
      ),
      envir = environment()
    )
    if (!is.null(seed)) parallel::clusterSetRNGStream(cl, seed)
    lapplyfun <- function(X, FUN, ...) {
      parallel::parLapply(cl = cl, X = X, fun = FUN, ...)
    }
    chain_seq <- seq_along(cl)
  }
  # to extract one sample at a time. armadillo is column major, just like rankings
  fits <- lapplyfun(X = chain_seq, FUN = function(i) {
    if (length(alpha_init) > 1) {
      alpha_init <- alpha_init[i]
    }
    run_mcmc(
      rankings = t(rankings),
      obs_freq = obs_freq,
      nmc = nmc,
      constraints = constraints,
      cardinalities = logz_list$cardinalities,
      logz_estimate = logz_list$logz_estimate,
      rho_init = rho_init,
      metric = metric,
      error_model = ifelse(is.null(error_model), "none", error_model),
      Lswap = swap_leap,
      n_clusters = n_clusters,
      include_wcd = include_wcd,
      lambda = lambda,
      alpha_max = alpha_max,
      psi = psi,
      leap_size = leap_size,
      alpha_prop_sd = alpha_prop_sd,
      alpha_init = alpha_init,
      alpha_jump = alpha_jump,
      rho_thinning = rho_thinning,
      aug_thinning = aug_thinning,
      clus_thin = clus_thin,
      save_aug = save_aug,
      verbose = verbose,
      kappa_1 = 1.0,
      kappa_2 = 1.0,
      save_ind_clus = save_ind_clus
    )
  })


  if (verbose) {
    print("Metropolis-Hastings algorithm completed. Post-processing data.")
  }

  fit <- tidy_mcmc(
    fits, rho_thinning, rankings, alpha_jump,
    n_clusters, nmc, aug_thinning, n_items, clus_thin
  )

  fit$save_aug <- save_aug

  # Add class attribute
  class(fit) <- "BayesMallows"

  return(fit)
}
