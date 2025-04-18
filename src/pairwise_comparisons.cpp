#include <RcppArmadillo.h>
#include "leapandshift.h"
#include "distances.h"

using namespace arma;

// [[Rcpp::depends(RcppArmadillo)]]

// Update shape parameters for the Bernoulli error model
void update_shape_bernoulli(
    double& shape_1,
    double& shape_2,
    const double& kappa_1,
    const double& kappa_2,
    const mat& rankings,
    const Rcpp::List& constraints
){
  int n_items = rankings.n_rows;
  int n_assessors = rankings.n_cols;
  int sum_1 = 0, sum_2 = 0;
  for(int i = 0; i < n_assessors; ++i){
    Rcpp::List assessor_constraints = Rcpp::as<Rcpp::List>(constraints[i]);
    for(int j = 0; j < n_items; ++j) {
      uvec items_above = Rcpp::as<uvec>(Rcpp::as<Rcpp::List>(assessor_constraints[1])[j]);
      uvec items_below = Rcpp::as<uvec>(Rcpp::as<Rcpp::List>(assessor_constraints[2])[j]);

      for(unsigned int k = 0; k < items_above.n_elem; ++k){
        int g = (as_scalar(rankings.col(i).row(j)) < as_scalar(rankings.col(i).row(items_above(k) - 1)));
        sum_1 += g;
        sum_2 += 1 - g;
      }
      for(unsigned int k = 0; k < items_below.n_elem; ++k){
        int g = (as_scalar(rankings.col(i).row(j)) > as_scalar(rankings.col(i).row(items_below(k) - 1)));
        sum_1 += g;
        sum_2 += 1 - g;
      }
    }
  }
  shape_1 = kappa_1 + sum_1;
  shape_2 = kappa_2 + sum_2;
}

void find_pairwise_limits(int& left_limit, int& right_limit, const int& item,
                          const Rcpp::List& assessor_constraints,
                          const vec& current_ranking) {
  // Find the items which are preferred to the given item
  // Items go from 1, ..., n_items, so must use [item - 1]
  uvec items_above = Rcpp::as<uvec>(Rcpp::as<Rcpp::List>(assessor_constraints[1])[item - 1]);
  uvec items_below = Rcpp::as<uvec>(Rcpp::as<Rcpp::List>(assessor_constraints[2])[item - 1]);

  // If there are any items above, we must find the possible rankings
  if(items_above.n_elem > 0) {
    // Again subtracting 1 because of zero-first indexing
    // Find all the rankings of the items that are preferred to *item*
    vec rankings_above = current_ranking.elem(items_above - 1);
    left_limit = max(rankings_above);
  }

  // If there are any items below, we must find the possible rankings
  if(items_below.n_elem > 0) {
    // Find all the rankings of the items that are disfavored to *item*
    vec rankings_below = current_ranking.elem(items_below - 1);
    right_limit = min(rankings_below);
  }

}

vec propose_pairwise_augmentation(const vec& ranking, const Rcpp::List& assessor_constraints) {
  int n_items = ranking.n_elem;

  // Extract the constraints for this particular assessor
  uvec constrained_items = Rcpp::as<uvec>(assessor_constraints[0]);

  // Sample an integer between 1 and n_items
  int item = randi<int>(distr_param(0, n_items - 1));

  // Left and right limits of the interval we draw ranks from
  // Correspond to l_j and r_j, respectively, in Vitelli et al. (2018), JMLR, Sec. 4.2.
  int left_limit = 0, right_limit = n_items + 1;
  find_pairwise_limits(left_limit, right_limit, item + 1, assessor_constraints, ranking);

  // Now complete the leap step by sampling a new proposal uniformly between
  // left_limit + 1 and right_limit - 1
  int proposed_rank = randi<int>(distr_param(left_limit + 1, right_limit - 1));

  // Assign the proposal to the (item-1)th item
  vec proposal = ranking;
  proposal(item) = proposed_rank;

  uvec indices;

  // Do the shift step
  shift_step(proposal, ranking, item, indices);

  return proposal;
}

vec propose_swap(const vec& ranking, const Rcpp::List& assessor_constraints,
                       int& g_diff, const int& Lswap) {
  int n_items = ranking.n_elem;

  // Draw a random number, representing an item
  int u = randi<int>(distr_param(1, n_items - Lswap));

  int ind1 = as_scalar(find(ranking == u));
  int ind2 = as_scalar(find(ranking == (u + Lswap)));

  vec proposal = ranking;
  proposal(ind1) = ranking(ind2);
  proposal(ind2) = ranking(ind1);

  // First consider the first item that was switched
  uvec items_above = Rcpp::as<uvec>(Rcpp::as<Rcpp::List>(assessor_constraints[1])[ind1]);
  uvec items_below = Rcpp::as<uvec>(Rcpp::as<Rcpp::List>(assessor_constraints[2])[ind1]);

  for(unsigned int j = 0; j < items_above.n_elem; ++j){
    g_diff += (proposal(items_above[j] - 1) > proposal(ind1)) - (ranking(items_above[j] - 1) > ranking(ind1));
  }
  for(unsigned int j = 0; j < items_below.n_elem; ++j){
    g_diff += (proposal(items_below[j] - 1) < proposal(ind1)) - (ranking(items_below[j] - 1) < ranking(ind1));
  }

  // Now consider the second item
  items_above = Rcpp::as<uvec>(Rcpp::as<Rcpp::List>(assessor_constraints[1])[ind2]);
  items_below = Rcpp::as<uvec>(Rcpp::as<Rcpp::List>(assessor_constraints[2])[ind2]);

  for(unsigned int j = 0; j < items_above.n_elem; ++j){
    g_diff += (proposal(items_above[j] - 1) > proposal(ind1)) - (ranking(items_above[j] - 1) > ranking(ind1));
  }
  for(unsigned int j = 0; j < items_below.n_elem; ++j){
    g_diff += (proposal(items_below[j] - 1) < proposal(ind1)) - (ranking(items_below[j] - 1) < ranking(ind1));
  }
  return proposal;
}


void augment_pairwise(
    mat& rankings,
    const uvec& current_cluster_assignment,
    const vec& alpha,
    const double& theta,
    const mat& rho,
    const std::string& metric,
    const Rcpp::List& constraints,
    vec& aug_acceptance,
    const std::string& error_model,
    const int& Lswap
){
  int n_assessors = rankings.n_cols;
  int n_items = rankings.n_rows;

  for(int i = 0; i < n_assessors; ++i) {
    vec proposal;
    // Summed difference over error function before and after proposal
    int g_diff = 0;

    // Sample a proposal, depending on the error model
    if(error_model == "none"){
      proposal = propose_pairwise_augmentation(rankings.col(i), Rcpp::as<Rcpp::List>(constraints[i]));
    } else if(error_model == "bernoulli"){
      proposal = propose_swap(rankings.col(i), Rcpp::as<Rcpp::List>(constraints[i]), g_diff, Lswap);
    } else {
      Rcpp::stop("error_model must be 'none' or 'bernoulli'");
    }

    // Finally, decide whether to accept the proposal or not
    // Draw a uniform random number
    double u = std::log(randu<double>());

    // Find which cluster the assessor belongs to
    int cluster = current_cluster_assignment(i);

    double ratio = -alpha(cluster) / n_items *
      (get_rank_distance(proposal, rho.col(cluster), metric) -
      get_rank_distance(rankings.col(i), rho.col(cluster), metric));

    if((theta > 0) & (g_diff != 0)) {
      ratio += g_diff * std::log(theta / (1 - theta));
    }

    if(ratio > u){
      rankings.col(i) = proposal;
      ++aug_acceptance(i);
    }
  }
}
