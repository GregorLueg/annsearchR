//! Ball tree: nested hyperspheres, pruned by the triangle inequality. The
//! search budget makes it approximate. No Manhattan.

use ann_search_rs::{build_balltree_index, query_balltree_index, query_balltree_self};
use extendr_api::prelude::*;
use extendr_api::Result;

use crate::convert::opt_usize;
use crate::handle::{build_prec, query_prec, self_prec, AnnIndex};

/// Build a ball tree index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use [BallTreeIndex] instead.
///
/// @param data Numeric matrix. Samples x features.
/// @param metric String. One of `c("euclidean", "cosine")`.
/// @param seed Integer. Random seed.
/// @param precision String. `"float"` or `"double"`.
///
/// @returns External pointer to the index.
///
/// @keywords internal
#[extendr]
fn rs_balltree_build(
    data: RMatrix<f64>,
    metric: &str,
    seed: i32,
    precision: &str,
) -> Result<ExternalPtr<AnnIndex>> {
    let seed = seed as usize;
    build_prec!(data, precision, BallTree, |mat| build_balltree_index(
        mat, metric, seed
    ))
}

/// Query a ball tree index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use the `$predict()` method instead.
///
/// @param ptr External pointer to the index.
/// @param data Numeric matrix. Queries x features.
/// @param k Integer. Number of neighbours.
/// @param search_budget Integer or `NULL`. Points inspected per query.
/// @param sqrt Boolean. Square root the distances (true Euclidean).
/// @param return_dist Boolean. Return the distances.
/// @param verbose Boolean. Print progress.
///
/// @returns A list with `idx` (1-based integer matrix) and `dist` (double
/// matrix or `NULL`).
///
/// @keywords internal
#[extendr]
fn rs_balltree_query(
    ptr: ExternalPtr<AnnIndex>,
    data: RMatrix<f64>,
    k: i32,
    search_budget: Nullable<i32>,
    sqrt: bool,
    return_dist: bool,
    verbose: bool,
) -> Result<Robj> {
    let (k, search_budget) = (k as usize, opt_usize(search_budget));
    query_prec!(ptr, BallTree, "balltree", data, k, sqrt, |idx, q| {
        query_balltree_index(q, idx, k, search_budget, return_dist, verbose)
    })
}

/// Self-query a ball tree index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use the `$query_self()` method instead.
///
/// @param ptr External pointer to the index.
/// @param k Integer. Number of neighbours, including the point itself.
/// @param search_budget Integer or `NULL`. Points inspected per query.
/// @param sqrt Boolean. Square root the distances (true Euclidean).
/// @param return_dist Boolean. Return the distances.
/// @param verbose Boolean. Print progress.
///
/// @returns A list with `idx` (1-based integer matrix) and `dist` (double
/// matrix or `NULL`).
///
/// @keywords internal
#[extendr]
fn rs_balltree_self(
    ptr: ExternalPtr<AnnIndex>,
    k: i32,
    search_budget: Nullable<i32>,
    sqrt: bool,
    return_dist: bool,
    verbose: bool,
) -> Result<Robj> {
    let (k, search_budget) = (k as usize, opt_usize(search_budget));
    self_prec!(ptr, BallTree, "balltree", k, sqrt, |idx| {
        query_balltree_self(idx, k, search_budget, return_dist, verbose)
    })
}

extendr_module! {
    mod ball_tree;
    fn rs_balltree_build;
    fn rs_balltree_query;
    fn rs_balltree_self;
}
