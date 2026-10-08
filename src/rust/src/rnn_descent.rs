//! Relative NN-Descent: builds and prunes a navigable graph in one pass.

use ann_search_rs::{build_rnn_descent_index, query_rnn_descent_index, query_rnn_descent_self};
use extendr_api::prelude::*;
use extendr_api::Result;

use crate::convert::opt_usize;
use crate::handle::{build_prec, query_prec, self_prec, AnnIndex};

/// Build a relative NN-Descent index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use [RnnDescentIndex] instead.
///
/// @param data Numeric matrix. Samples x features.
/// @param metric String. One of `c("euclidean", "cosine", "manhattan")`.
/// @param s Integer. Neighbours sampled per node per local join.
/// @param r Integer. Maximum out-degree after pruning.
/// @param t1 Integer. Outer iterations.
/// @param t2 Integer. Inner iterations per outer one.
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
fn rs_rnndescent_build(
    data: RMatrix<f64>,
    metric: &str,
    s: i32,
    r: i32,
    t1: i32,
    t2: i32,
    n_trees: Nullable<i32>,
    seed: i32,
    precision: &str,
    verbose: bool,
) -> Result<ExternalPtr<AnnIndex>> {
    let (s, r, t1, t2) = (s as usize, r as usize, t1 as usize, t2 as usize);
    let (n_trees, seed) = (opt_usize(n_trees), seed as usize);
    build_prec!(data, precision, RnnDescent, |mat| build_rnn_descent_index(
        mat, s, r, t1, t2, metric, n_trees, seed, verbose
    ))
}

/// Query a relative NN-Descent index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use the `$predict()` method instead.
///
/// @param ptr External pointer to the index.
/// @param data Numeric matrix. Queries x features.
/// @param k Integer. Number of neighbours.
/// @param ef_search Integer or `NULL`. Beam width at query time.
/// @param k_search Integer or `NULL`. Neighbours expanded per hop.
/// @param sqrt Boolean. Square root the distances (true Euclidean).
/// @param return_dist Boolean. Return the distances.
/// @param verbose Boolean. Print progress.
///
/// @returns A list with `idx` (1-based integer matrix) and `dist` (double
/// matrix or `NULL`).
///
/// @keywords internal
#[extendr]
#[allow(clippy::too_many_arguments)]
fn rs_rnndescent_query(
    ptr: ExternalPtr<AnnIndex>,
    data: RMatrix<f64>,
    k: i32,
    ef_search: Nullable<i32>,
    k_search: Nullable<i32>,
    sqrt: bool,
    return_dist: bool,
    verbose: bool,
) -> Result<Robj> {
    let k = k as usize;
    let (ef_search, k_search) = (opt_usize(ef_search), opt_usize(k_search));
    query_prec!(ptr, RnnDescent, "rnndescent", data, k, sqrt, |idx, q| {
        query_rnn_descent_index(q, idx, k, ef_search, k_search, return_dist, verbose)
    })
}

/// Self-query a relative NN-Descent index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use the `$query_self()` method instead.
///
/// @param ptr External pointer to the index.
/// @param k Integer. Number of neighbours, including the point itself.
/// @param ef_search Integer or `NULL`. Beam width at query time.
/// @param k_search Integer or `NULL`. Neighbours expanded per hop.
/// @param sqrt Boolean. Square root the distances (true Euclidean).
/// @param return_dist Boolean. Return the distances.
/// @param verbose Boolean. Print progress.
///
/// @returns A list with `idx` (1-based integer matrix) and `dist` (double
/// matrix or `NULL`).
///
/// @keywords internal
#[extendr]
fn rs_rnndescent_self(
    ptr: ExternalPtr<AnnIndex>,
    k: i32,
    ef_search: Nullable<i32>,
    k_search: Nullable<i32>,
    sqrt: bool,
    return_dist: bool,
    verbose: bool,
) -> Result<Robj> {
    let k = k as usize;
    let (ef_search, k_search) = (opt_usize(ef_search), opt_usize(k_search));
    self_prec!(ptr, RnnDescent, "rnndescent", k, sqrt, |idx| {
        query_rnn_descent_self(idx, k, ef_search, k_search, return_dist, verbose)
    })
}

extendr_module! {
    mod rnn_descent;
    fn rs_rnndescent_build;
    fn rs_rnndescent_query;
    fn rs_rnndescent_self;
}
