#' Plot Posterior Distributions
#'
#' Plot posterior distributions of the parameters of the Mallows Rank model.
#'
#' @param x An object of type \code{BayesMallows}, returned from
#'   \code{\link{compute_mallows}}.
#'
#' @param burnin A numeric value specifying the number of iterations
#' to discard as burn-in. Defaults to \code{x$burnin}, and must be
#' provided if \code{x$burnin} does not exist. See \code{\link{assess_convergence}}.
#'
#' @param parameter Character string defining the parameter to plot. Available
#' options are \code{"alpha"}, \code{"rho"}, \code{"cluster_probs"},
#' \code{"cluster_assignment"}, and \code{"theta"}.
#'
#' @param items The items to study in the diagnostic plot for \code{rho}. Either
#'   a vector of item names, corresponding to \code{x$items} or a
#'   vector of indices. If NULL, five items are selected randomly.
#'   Only used when \code{parameter = "rho"}.
#'
#' @param ... Other arguments passed to \code{plot} (not used).
#'
#' @export
#' @importFrom stats density
#'
#' @example /inst/examples/plot.BayesMallows_example.R
#' @family posterior quantities
plot.BayesMallows <- function(x, burnin = x$burnin, parameter = "alpha", items = NULL, ...) {
  if (is.null(burnin)) {
    stop("Please specify the burnin.")
  }
  if (x$nmc <= burnin) stop("burnin must be <= nmc")

  stopifnot(parameter %in% c("alpha", "rho", "cluster_probs", "cluster_assignment", "theta"))

  if (parameter == "alpha") {
    df <- x$alpha[x$alpha$iteration > burnin, , drop = FALSE]

    p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$value)) +
      ggplot2::geom_density() +
      ggplot2::xlab(expression(alpha)) +
      ggplot2::ylab("Posterior density")

    if (x$n_clusters > 1) {
      p <- p + ggplot2::facet_wrap(~ .data$cluster, scales = "free_x")
    }

    return(p)
  } else if (parameter == "rho") {
    if (is.null(items) && x$n_items > 5) {
      message("Items not provided by user. Picking 5 at random.")
      items <- sample.int(x$n_items, 5)
    } else if (is.null(items) && x$n_items > 0) {
      items <- seq.int(from = 1, to = x$n_items)
    }

    if (!is.character(items)) {
      items <- x$items[items]
    }

    df <- x$rho[x$rho$iteration > burnin & x$rho$item %in% items, , drop = FALSE]

    # Finally create the plot
    p <- ggplot2::ggplot(df, ggplot2::aes(.data$value)) +
      ggplot2::geom_histogram(
        bins = x$n_items, ggplot2::aes(y = ggplot2::after_stat(density)),
        fill = "black", col = "gray") +
      ggplot2::xlab("rank") +
      ggplot2::ylab("Posterior probability")

    if (x$n_clusters == 1) {
      p <- p + ggplot2::facet_wrap(~ .data$item)
    } else {
      p <- p + ggplot2::facet_wrap(~ .data$cluster + .data$item)
    }

    return(p)
  } else if (parameter == "cluster_probs") {
    df <- x$cluster_probs[x$cluster_probs$iteration > burnin, , drop = FALSE]

    ggplot2::ggplot(df, ggplot2::aes(x = .data$value)) +
      ggplot2::geom_density() +
      ggplot2::xlab(expression(tau[c])) +
      ggplot2::ylab("Posterior density") +
      ggplot2::facet_wrap(~ .data$cluster)
  } else if (parameter == "cluster_assignment") {
    if (is.null(x$cluster_assignment)) {
      stop("No cluster assignments.")
    }

    # First get one cluster per assessor, and sort these
    df <- assign_cluster(x, burnin = burnin, soft = FALSE, expand = FALSE)
    df <- df[order(df$map_cluster), ]
    assessor_order <- df$assessor

    # Next, rerun with soft=TRUE to get the probability of all clusters
    df <- assign_cluster(x, burnin = burnin, soft = TRUE, expand = TRUE)
    # Then order the assessors according to assessor_order
    df$assessor <- factor(df$assessor, levels = assessor_order)

    # Now make a plot
    ggplot2::ggplot(df, ggplot2::aes(.data$assessor, .data$cluster)) +
      ggplot2::geom_tile(ggplot2::aes(fill = .data$probability)) +
      ggplot2::theme(
        legend.title = ggplot2::element_blank(),
        axis.title.y = ggplot2::element_blank(),
        axis.ticks.x = ggplot2::element_blank(),
        axis.text.x = ggplot2::element_blank()
      ) +
      ggplot2::xlab(paste0("Assessors (", min(assessor_order), " - ", max(assessor_order), ")"))
  } else if (parameter == "theta") {
    if (is.null(x$theta)) {
      stop("Please run compute_mallows with error_model = 'bernoulli'.")
    }

    df <- x$theta[x$theta$iteration > burnin, , drop = FALSE]

    p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$value)) +
      ggplot2::geom_density() +
      ggplot2::xlab(expression(theta)) +
      ggplot2::ylab("Posterior density")


    return(p)
  }
}
