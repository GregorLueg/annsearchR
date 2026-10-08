//! Forest of randomised kd spill-trees. Same trade as Annoy, with axis-aligned
//! splits. Supports Manhattan.

use ann_search_rs::{build_kd_tree_index, query_kd_tree_index, query_kd_tree_self};
use extendr_api::prelude::*;
use extendr_api::Result;

use crate::convert::opt_usize;
use crate::handle::{build_prec, query_prec, self_prec, AnnIndex};

/// Build a kd forest index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use [KdTreeIndex] instead.
///
/// @param data Numeric matrix. Samples x features.
/// @param metric String. One of `c("euclidean", "cosine", "manhattan")`.
/// @param n_trees Integer. Number of trees.
/// @param seed Integer. Random seed.
/// @param precision String. `"float"` or `"double"`.
///
/// @returns External pointer to the index.
///
/// @keywords internal
#[extendr]
fn rs_kdtree_build(
    data: RMatrix<f64>,
    metric: &str,
    n_trees: i32,
    seed: i32,
    precision: &str,
) -> Result<ExternalPtr<AnnIndex>> {
    let (n_trees, seed) = (n_trees as usize, seed as usize);
    build_prec!(data, precision, KdTree, |mat| Ok(build_kd_tree_index(
        mat, metric, n_trees, seed
    )))
}

/// Query a kd forest index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use the `$predict()` method instead.
///
/// @param ptr External pointer to the index.
/// @param data Numeric matrix. Queries x features.
/// @param k Integer. Number of neighbours.
/// @param search_budget Integer or `NULL`. Candidates inspected per query.
/// @param sqrt Boolean. Square root the distances (true Euclidean).
/// @param return_dist Boolean. Return the distances.
/// @param verbose Boolean. Print progress.
///
/// @returns A list with `idx` (1-based integer matrix) and `dist` (double
/// matrix or `NULL`).
///
/// @keywords internal
#[extendr]
fn rs_kdtree_query(
    ptr: ExternalPtr<AnnIndex>,
    data: RMatrix<f64>,
    k: i32,
    search_budget: Nullable<i32>,
    sqrt: bool,
    return_dist: bool,
    verbose: bool,
) -> Result<Robj> {
    let (k, search_budget) = (k as usize, opt_usize(search_budget));
    query_prec!(ptr, KdTree, "kdtree", data, k, sqrt, |idx, q| {
        query_kd_tree_index(q, idx, k, search_budget, return_dist, verbose)
    })
}

/// Self-query a kd forest index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use the `$query_self()` method instead.
///
/// @param ptr External pointer to the index.
/// @param k Integer. Number of neighbours, including the point itself.
/// @param search_budget Integer or `NULL`. Candidates inspected per query.
/// @param sqrt Boolean. Square root the distances (true Euclidean).
/// @param return_dist Boolean. Return the distances.
/// @param verbose Boolean. Print progress.
///
/// @returns A list with `idx` (1-based integer matrix) and `dist` (double
/// matrix or `NULL`).
///
/// @keywords internal
#[extendr]
fn rs_kdtree_self(
    ptr: ExternalPtr<AnnIndex>,
    k: i32,
    search_budget: Nullable<i32>,
    sqrt: bool,
    return_dist: bool,
    verbose: bool,
) -> Result<Robj> {
    let (k, search_budget) = (k as usize, opt_usize(search_budget));
    self_prec!(ptr, KdTree, "kdtree", k, sqrt, |idx| {
        query_kd_tree_self(idx, k, search_budget, return_dist, verbose)
    })
}

extendr_module! {
    mod kd_tree;
    fn rs_kdtree_build;
    fn rs_kdtree_query;
    fn rs_kdtree_self;
}
