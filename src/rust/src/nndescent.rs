//! NN-Descent: builds the kNN graph directly by iterative local join. The
//! converged graph can be extracted without any search.

use ann_search_rs::{
    build_nndescent_index, extract_nndescent_knn, query_nndescent_index, query_nndescent_self,
};
use extendr_api::prelude::*;
use extendr_api::Result;

use crate::convert::opt_usize;
use crate::handle::{build_prec, query_prec, self_prec, AnnIndex};

/// Build an NN-Descent index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use [NNDescentIndex] instead.
///
/// @param data Numeric matrix. Samples x features.
/// @param metric String. One of `c("euclidean", "cosine", "manhattan")`.
/// @param k_graph Integer. Neighbours per node in the graph.
/// @param delta Numeric. Convergence threshold.
/// @param diversify_prob Numeric. Edge pruning probability after descent.
/// @param max_iter Integer or `NULL`. Iteration cap.
/// @param max_candidates Integer or `NULL`. Candidates sampled per local join.
/// @param n_trees Integer or `NULL`. Random projection trees for the seed
/// graph.
/// @param seed Integer. Random seed.
/// @param precision String. `"float"` or `"double"`.
/// @param verbose Boolean. Print progress.
///
/// @returns External pointer to the index.
///
/// @keywords internal
#[extendr]
#[allow(clippy::too_many_arguments)]
fn rs_nndescent_build(
    data: RMatrix<f64>,
    metric: &str,
    k_graph: i32,
    delta: f64,
    diversify_prob: f64,
    max_iter: Nullable<i32>,
    max_candidates: Nullable<i32>,
    n_trees: Nullable<i32>,
    seed: i32,
    precision: &str,
    verbose: bool,
) -> Result<ExternalPtr<AnnIndex>> {
    let k_graph = Some(k_graph as usize);
    let (max_iter, max_candidates) = (opt_usize(max_iter), opt_usize(max_candidates));
    let (n_trees, seed) = (opt_usize(n_trees), seed as usize);
    build_prec!(data, precision, NNDescent, |mat| build_nndescent_index(
        mat,
        metric,
        num_traits::cast(delta).expect("finite f64 casts into the index float"),
        num_traits::cast(diversify_prob).expect("finite f64 casts into the index float"),
        k_graph,
        max_iter,
        max_candidates,
        n_trees,
        seed,
        verbose
    ))
}

/// Query an NN-Descent index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use the `$predict()` method instead.
///
/// @param ptr External pointer to the index.
/// @param data Numeric matrix. Queries x features.
/// @param k Integer. Number of neighbours.
/// @param ef_search Integer or `NULL`. Beam width at query time.
/// @param sqrt Boolean. Square root the distances (true Euclidean).
/// @param return_dist Boolean. Return the distances.
/// @param verbose Boolean. Print progress.
///
/// @returns A list with `idx` (1-based integer matrix) and `dist` (double
/// matrix or `NULL`).
///
/// @keywords internal
#[extendr]
fn rs_nndescent_query(
    ptr: ExternalPtr<AnnIndex>,
    data: RMatrix<f64>,
    k: i32,
    ef_search: Nullable<i32>,
    sqrt: bool,
    return_dist: bool,
    verbose: bool,
) -> Result<Robj> {
    let (k, ef_search) = (k as usize, opt_usize(ef_search));
    query_prec!(ptr, NNDescent, "nndescent", data, k, sqrt, |idx, q| {
        query_nndescent_index(q, idx, k, ef_search, return_dist, verbose)
    })
}

/// Self-query an NN-Descent index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use the `$query_self()` method instead.
///
/// @param ptr External pointer to the index.
/// @param k Integer. Number of neighbours, including the point itself.
/// @param ef_search Integer or `NULL`. Beam width at query time.
/// @param sqrt Boolean. Square root the distances (true Euclidean).
/// @param return_dist Boolean. Return the distances.
/// @param verbose Boolean. Print progress.
///
/// @returns A list with `idx` (1-based integer matrix) and `dist` (double
/// matrix or `NULL`).
///
/// @keywords internal
#[extendr]
fn rs_nndescent_self(
    ptr: ExternalPtr<AnnIndex>,
    k: i32,
    ef_search: Nullable<i32>,
    sqrt: bool,
    return_dist: bool,
    verbose: bool,
) -> Result<Robj> {
    let (k, ef_search) = (k as usize, opt_usize(ef_search));
    self_prec!(ptr, NNDescent, "nndescent", k, sqrt, |idx| {
        query_nndescent_self(idx, k, ef_search, return_dist, verbose)
    })
}

/// Extract the converged NN-Descent graph
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use the `$extract_knn()` method instead.
///
/// @param ptr External pointer to the index.
/// @param k Integer. Row length, including the point itself when
/// `include_self = TRUE`. At most the graph degree (plus one with self).
/// @param include_self Boolean. Prepend each point at distance 0.
/// @param sqrt Boolean. Square root the distances (true Euclidean).
/// @param return_dist Boolean. Return the distances.
///
/// @returns A list with `idx` (1-based integer matrix) and `dist` (double
/// matrix or `NULL`).
///
/// @keywords internal
#[extendr]
fn rs_nndescent_extract(
    ptr: ExternalPtr<AnnIndex>,
    k: i32,
    include_self: bool,
    sqrt: bool,
    return_dist: bool,
) -> Result<Robj> {
    let k = k as usize;
    self_prec!(ptr, NNDescent, "nndescent", k, sqrt, |idx| {
        extract_nndescent_knn(idx, Some(k), include_self, return_dist)
    })
}

extendr_module! {
    mod nndescent;
    fn rs_nndescent_build;
    fn rs_nndescent_query;
    fn rs_nndescent_self;
    fn rs_nndescent_extract;
}
