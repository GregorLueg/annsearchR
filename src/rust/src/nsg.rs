//! NSG: refines an NN-Descent kNN graph into a sparse monotonic one.

use ann_search_rs::{build_nsg_index, query_nsg_index, query_nsg_self};
use extendr_api::prelude::*;
use extendr_api::Result;

use crate::convert::opt_usize;
use crate::handle::{build_prec, query_prec, self_prec, AnnIndex};

/// Build an NSG index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use [NsgIndex] instead.
///
/// @param data Numeric matrix. Samples x features.
/// @param metric String. One of `c("euclidean", "cosine", "manhattan")`.
/// @param r Integer. Maximum out-degree of the refined graph.
/// @param l_build Integer. Candidate list width while refining.
/// @param c Integer. Candidate pool size per node before pruning.
/// @param knn_k Integer. Degree of the NN-Descent graph built first.
/// @param seed Integer. Random seed.
/// @param precision String. `"float"` or `"double"`.
/// @param verbose Boolean. Print progress.
///
/// @returns External pointer to the index.
///
/// @keywords internal
#[extendr]
#[allow(clippy::too_many_arguments)]
fn rs_nsg_build(
    data: RMatrix<f64>,
    metric: &str,
    r: i32,
    l_build: i32,
    c: i32,
    knn_k: i32,
    seed: i32,
    precision: &str,
    verbose: bool,
) -> Result<ExternalPtr<AnnIndex>> {
    let (r, l_build, c) = (r as usize, l_build as usize, c as usize);
    let (knn_k, seed) = (knn_k as usize, seed as usize);
    build_prec!(data, precision, Nsg, |mat| build_nsg_index(
        mat, r, l_build, c, knn_k, metric, seed, verbose
    ))
}

/// Query an NSG index
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
fn rs_nsg_query(
    ptr: ExternalPtr<AnnIndex>,
    data: RMatrix<f64>,
    k: i32,
    ef_search: Nullable<i32>,
    sqrt: bool,
    return_dist: bool,
    verbose: bool,
) -> Result<Robj> {
    let (k, ef_search) = (k as usize, opt_usize(ef_search));
    query_prec!(ptr, Nsg, "nsg", data, k, sqrt, |idx, q| {
        query_nsg_index(q, idx, k, ef_search, return_dist, verbose)
    })
}

/// Self-query an NSG index
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
fn rs_nsg_self(
    ptr: ExternalPtr<AnnIndex>,
    k: i32,
    ef_search: Nullable<i32>,
    sqrt: bool,
    return_dist: bool,
    verbose: bool,
) -> Result<Robj> {
    let (k, ef_search) = (k as usize, opt_usize(ef_search));
    self_prec!(ptr, Nsg, "nsg", k, sqrt, |idx| {
        query_nsg_self(idx, k, ef_search, return_dist, verbose)
    })
}

extendr_module! {
    mod nsg;
    fn rs_nsg_build;
    fn rs_nsg_query;
    fn rs_nsg_self;
}
