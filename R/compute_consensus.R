#' @title Compute Consensus Ranking
#' @description Compute the consensus ranking using either cumulative
#' probability (CP) or maximum a posteriori (MAP) consensus
#' \insertCite{vitelli2018}{BayesMallows}. For mixture models, the
#' consensus is given for each mixture. Consensus of augmented ranks
#' can also be computed
#' for each assessor, by setting \code{parameter = "Rtilde"}.
#' @param model_fit A model fit.
#' @param ... other arguments passed to methods.
#' @references \insertAllCited{}
#' @export
#' @example /inst/examples/compute_consensus_example.R
#'
#' @family posterior quantities
#'
compute_consensus <- function(model_fit, ...) {
  UseMethod("compute_consensus")
}

#' @title Compute Consensus Ranking
#'
#' @param model_fit Object of type \code{BayesMallows} returned from
#'   \code{\link{compute_mallows}}.
#' @param type Character string specifying which consensus to compute. Either
#'   \code{"CP"} or \code{"MAP"}. Defaults to \code{"CP"}.
#' @param burnin A numeric value specifying the number of iterations to discard
#'   as burn-in. Defaults to \code{model_fit$burnin}, and must be provided if
#'   \code{model_fit$burnin} does not exist. See
#'   \code{\link{assess_convergence}}.
#' @param parameter Character string defining the parameter for which to compute
#'   the consensus. Defaults to \code{"rho"}. Available options are \code{"rho"}
#'   and \code{"Rtilde"}, with the latter giving consensus rankings for
#'   augmented ranks.
#' @param assessors When \code{parameter = "rho"}, this integer vector is used
#'   to define the assessors for which to compute the augmented ranking.
#' @param ... Other arguments passed on to other methods. Currently not used.
#'   Defaults to \code{1L}, which yields augmented rankings for assessor 1.
#' @export
#' @family posterior quantities
compute_consensus.BayesMallows <- function(
    model_fit, type = "CP", burnin = model_fit$burnin, parameter = "rho",
    assessors = 1L, ...) {
  if (is.null(burnin)) {
    stop("Please specify the burnin.")
  }
  stopifnot(burnin < model_fit$nmc)

  type <- match.arg(type, c("CP", "MAP"))

  stopifnot(inherits(model_fit, "BayesMallows"))

  if (parameter == "Rtilde" &&
    !inherits(model_fit$augmented_data, "data.frame")) {
    stop("For augmented ranks, please refit model with option 'save_aug = TRUE'.")
  }

  if (parameter == "rho") {
    # Filter out the pre-burnin iterations
    df <- model_fit$rho[model_fit$rho$iteration > burnin, , drop = FALSE]

    # Find the problem dimensions
    n_rows <- length(unique(paste(df$item, df$cluster)))

    # Check that there are rows.
    stopifnot(n_rows > 0)

    # Check that the number of rows are consistent with the information in
    # the model object
    stopifnot(model_fit$n_clusters * model_fit$n_items == n_rows)

    if (type == "CP") {
      df <- cpc_bm(df)
    } else if (type == "MAP") {
      df <- cpm_bm(df)
    }
  } else if (parameter == "Rtilde") {
    # Filter out the pre-burnin iterations and get the right assessors
    df <- model_fit$augmented_data[model_fit$augmented_data$iteration > burnin &
      model_fit$augmented_data$assessor %in% assessors, , drop = FALSE]

    # Find the problem dimensions
    n_rows <- length(unique(paste(df$assessor, df$item)))

    # Check that there are rows.
    stopifnot(n_rows > 0)

    # Check that the number of rows are consistent with the information in
    # the model object
    stopifnot(length(assessors) * model_fit$n_items == n_rows)

    # Treat assessors as clusters
    names(df)[names(df) == "assessor"] <- "cluster"
    class(df) <- c("consensus_BayesMallows", "tbl_df", "tbl", "data.frame")

    df <- if (type == "CP") {
      df <- cpc_bm(df)
    } else if (type == "MAP") {
      df <- cpm_bm(df)
    }

    if ("cluster" %in% names(df)) {
      names(df)[names(df) == "cluster"] <- "assessor"
    }
  }

  # If there is only one cluster, we drop the cluster column
  if (length(unique(df$cluster)) == 1) {
    df$cluster <- NULL
  }

  row.names(df) <- NULL
  as.data.frame(df)
}

#' Compute Consensus Ranking
#'
#' Compute the consensus ranking using either cumulative probability (CP) or
#' maximum a posteriori (MAP) consensus \insertCite{vitelli2018}{BayesMallows}.
#' For mixture models, the consensus is given for each mixture.
#'
#' @param model_fit An object of class \code{SMCMallows}, returned from
#'   \code{\link{smc_mallows_new_item_rank}} or
#'   \code{\link{smc_mallows_new_users}}.
#'
#' @param type Character string specifying which consensus to compute. Either
#'   \code{"CP"} or \code{"MAP"}. Defaults to \code{"CP"}.
#'
#'
#' @param ... Other optional arguments passed to methods. Currently not used.
#'
#' @export
#' @family posterior quantities
#'
#' @example inst/examples/smc_post_processing_functions_example.R
compute_consensus.SMCMallows <- function(model_fit, type = "CP", ...) {
  type <- match.arg(type, c("CP", "MAP"))

  if (type == "CP") {
    df <- smc_processing(model_fit$rho_samples[, , dim(model_fit$rho_samples)[[3]]])
    df$cluster <- "Cluster 1"
    n_rows <- length(unique(interaction(df$item, df$cluster)))
    df$iteration <- seq_len(nrow(df))

    # Check that there are rows.
    stopifnot(n_rows > 0)

    df <- aggregate_cp_consensus(df)
    df <- find_cpc(df)
    df$cluster <- NULL
  } else if (type == "MAP") {
    df <-
      as.data.frame(model_fit$rho_samples[, , dim(model_fit$rho_samples)[[3]]])
    colnames(df) <- paste("Item", seq_len(ncol(df)))
    n_items <- ncol(df)
    iterations <- seq_len(nrow(df))
    df <- smc_processing(df)
    df$iteration <- rep(iterations, n_items)

    df$cluster <- "Cluster 1"
    n_rows <- length(unique(interaction(df$item, df$cluster)))

    # Check that there are rows.
    stopifnot(n_rows > 0)

    # Spread to get items along columns
    df <- stats::reshape(
      data = as.data.frame(df),
      direction = "wide",
      idvar = c("iteration", "cluster"),
      timevar = "item",
      varying = list(unique(df$item))
    )
    attr(df, "reshapeWide") <- NULL # maintain identity to spread() output

    df <- aggregate_map_consensus(df, max(iterations))

    # Now collect one set of ranks per cluster
    df <- stats::reshape(
      as.data.frame(df),
      direction = "long",
      varying = setdiff(names(df), c("cluster", "probability")),
      new.row.names = seq_len(prod(dim(df))),
      v.names = "map_ranking",
      timevar = "item",
      times = setdiff(names(df), c("cluster", "probability"))
    )
    df$id <- NULL

    attr(x = df, "reshapeLong") <- NULL # preserves identity to gather() output

    # Sort according to cluster and ranking
    df <- df[order(df$cluster, df$map_ranking), , drop = FALSE]
    df$cluster <- NULL
  }
  rownames(df) <- NULL
  df
}


# Internal function for finding CP consensus.
find_cpc <- function(group_df, group_var = "cluster") {
  # Declare the result dataframe before adding rows to it
  result <- data.frame(
    cluster = character(),
    ranking = numeric(),
    item = character(),
    cumprob = numeric()
  )
  n_items <- max(group_df$value)
  group_df$cumprob[is.na(group_df$cumprob)] <- 0

  for (i in seq(from = 1, to = n_items, by = 1)) {
    # Filter out the relevant rows
    tmp_df <- group_df[group_df$value == i, , drop = FALSE]

    # Remove items in result
    tmp_df <- tmp_df[!interaction(tmp_df[c("cluster", "item")]) %in%
      interaction(result[c("cluster", "item")]), ]

    if (nrow(tmp_df) >= 1) {
      # Keep the max only. This filtering must be done after the first filter,
      # since we take the maximum among the filtered values
      tmp_df <- do.call(
        rbind,
        lapply(split(tmp_df, f = tmp_df[group_var]), function(x) {
          x[x$cumprob == max(x$cumprob), ]
        })
      )
      # Add the ranking
      tmp_df$ranking <- i

      # Select the columns we want to keep, and put them in result
      result <- rbind(
        result,
        tmp_df[, c("cluster", "ranking", "item", "cumprob"), drop = FALSE]
      )
    }
  }
  return(result)
}

aggregate_cp_consensus <- function(df) {
  # Convert items and cluster to character, since factor levels are not needed in this case
  df$item <- as.character(df$item)
  df$cluster <- as.character(df$cluster)

  df <- aggregate(
    list(n = df$iteration),
    by = list(
      item = as.character(df$item),
      cluster = as.character(df$cluster), value = df$value
    ),
    FUN = length
  )

  # Arrange according to value, per item and cluster
  do.call(rbind, lapply(split(df, f = ~ item + cluster), function(x) {
    x <- x[order(x$value), ]
    x$cumprob <- cumsum(x$n) / sum(x$n)
    x
  }))
}

aggregate_map_consensus <- function(df, n_samples) {
  # Group by everything except iteration, and count the unique combinations
  df <- aggregate(list(n = df$iteration), df[, setdiff(names(df), "iteration")],
    FUN = length
  )
  # Keep only the maximum per cluster
  df <- do.call(rbind, lapply(split(df, f = df$cluster), function(x) {
    x$n_max <- max(x$n)
    x[x$n == x$n_max, , drop = FALSE]
  }))

  # Compute the probability
  df$probability <- df$n / n_samples
  df$n_max <- df$n <- NULL
  df
}

cpc_bm <- function(df) {
  # Count per item, cluster, and value
  df <- aggregate_cp_consensus(df)
  # Find the CP consensus per cluster, using the find_cpc function
  df <- find_cpc(df)

  df <- df[order(df$cluster, df$ranking), ]
  df
}

cpm_bm <- function(df) {
  # Store the total number of iterations after burnin
  n_samples <- length(unique(df$iteration))

  # Reshape to get items along columns
  df <- stats::reshape(as.data.frame(df),
    direction = "wide",
    idvar = c("chain", "cluster", "iteration"),
    timevar = "item"
  )
  df$chain <- NULL
  names(df) <- gsub("^value\\.", "", names(df))

  df <- aggregate_map_consensus(df, n_samples)

  # Now collect one set of ranks per cluster
  df$id <- seq_len(nrow(df))
  df <- stats::reshape(as.data.frame(df),
    direction = "long",
    varying = setdiff(names(df), c("cluster", "probability", "id")),
    v.names = "map_ranking",
    timevar = "item",
    idvar = c("cluster", "probability", "id"),
    times = setdiff(names(df), c("cluster", "probability", "id"))
  )
  rownames(df) <- NULL
  df$id <- NULL

  # Sort according to cluster and ranking
  df <- df[order(df$cluster, df$map_ranking),
    c("cluster", "map_ranking", "item", "probability"),
    drop = FALSE
  ]
}
