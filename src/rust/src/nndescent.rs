//! NN-Descent: builds the kNN graph directly by iterative local join. The
//! converged graph can be extracted without any search.

use ann_search_rs::prelude::{parse_annsearch_verbosity, NNDescentKnnParams};
use ann_search_rs::{
    build_knn_graph_nndescent, build_nndescent_index, extract_nndescent_knn,
    query_nndescent_index, query_nndescent_self,
};
use extendr_api::prelude::*;
use extendr_api::Result;

use crate::convert::{opt_usize, pack_knn_graph, r_err, r_to_flat};
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
/// @param verbose Integer. 0 silent, 1 progress, 2 detailed.
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
    verbose: i32,
) -> Result<ExternalPtr<AnnIndex>> {
    let verbosity = parse_annsearch_verbosity(verbose as usize);
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
        verbosity
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
/// @param verbose Integer. 0 silent, 1 progress, 2 detailed.
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
    verbose: i32,
) -> Result<Robj> {
    let verbosity = parse_annsearch_verbosity(verbose as usize);
    let (k, ef_search) = (k as usize, opt_usize(ef_search));
    query_prec!(ptr, NNDescent, "nndescent", data, k, sqrt, |idx, q| {
        query_nndescent_index(q, idx, k, ef_search, return_dist, verbosity)
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
/// @param verbose Integer. 0 silent, 1 progress, 2 detailed.
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
    verbose: i32,
) -> Result<Robj> {
    let verbosity = parse_annsearch_verbosity(verbose as usize);
    let (k, ef_search) = (k as usize, opt_usize(ef_search));
    self_prec!(ptr, NNDescent, "nndescent", k, sqrt, |idx| {
        query_nndescent_self(idx, k, ef_search, return_dist, verbosity)
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

/// Build the NN-Descent kNN graph without an index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use [knn_graph_nndescent()] instead.
///
/// @param data Numeric matrix. Samples x features.
/// @param metric String. One of `c("euclidean", "cosine", "manhattan")`.
/// @param k_graph Integer. Neighbours per node found by the descent, the
/// sample itself not counted.
/// @param delta Numeric. Convergence threshold.
/// @param max_iter Integer or `NULL`. Iteration cap.
/// @param max_candidates Integer or `NULL`. Candidates sampled per local join.
/// @param n_trees Integer or `NULL`. Random projection trees for the seed
/// graph.
/// @param include_self Boolean. Prepend each point at distance 0.
/// @param sqrt Boolean. Square root the distances (true Euclidean).
/// @param return_dist Boolean. Return the distances.
/// @param seed Integer. Random seed.
/// @param precision String. `"float"` or `"double"`.
/// @param verbose Integer. 0 silent, 1 progress, 2 detailed.
///
/// @returns A list with `idx` (1-based integer matrix, `k_graph` columns plus
/// one with `include_self`) and `dist` (double matrix or `NULL`).
///
/// @keywords internal
#[extendr]
#[allow(clippy::too_many_arguments)]
fn rs_nndescent_knn_graph(
    data: RMatrix<f64>,
    metric: &str,
    k_graph: i32,
    delta: f64,
    max_iter: Nullable<i32>,
    max_candidates: Nullable<i32>,
    n_trees: Nullable<i32>,
    include_self: bool,
    sqrt: bool,
    return_dist: bool,
    seed: i32,
    precision: &str,
    verbose: i32,
) -> Result<Robj> {
    let verbosity = parse_annsearch_verbosity(verbose as usize);
    let params = NNDescentKnnParams::new(
        k_graph as usize,
        opt_usize(max_iter),
        opt_usize(max_candidates),
        opt_usize(n_trees),
        delta,
        include_self,
        return_dist,
    );
    let seed = seed as usize;
    // The flat copy moves into the builder, which drops it before returning.
    match precision {
        "double" => {
            let mat = r_to_flat::<f64>(&data);
            let g = crate::pool::run(move || {
                build_knn_graph_nndescent(mat, metric, Some(params), seed, verbosity)
            })
            .map_err(r_err)?;
            Ok(pack_knn_graph(&g, sqrt))
        }
        _ => {
            let mat = r_to_flat::<f32>(&data);
            let g = crate::pool::run(move || {
                build_knn_graph_nndescent(mat, metric, Some(params), seed, verbosity)
            })
            .map_err(r_err)?;
            Ok(pack_knn_graph(&g, sqrt))
        }
    }
}

extendr_module! {
    mod nndescent;
    fn rs_nndescent_build;
    fn rs_nndescent_query;
    fn rs_nndescent_self;
    fn rs_nndescent_extract;
    fn rs_nndescent_knn_graph;
}
