//! kMkNN: exact search over a k-means partition, pruned by the triangle
//! inequality. No Manhattan.

use ann_search_rs::{build_kmknn_index, query_kmknn_index, query_kmknn_self};
use extendr_api::prelude::*;
use extendr_api::Result;

use crate::convert::opt_usize;
use crate::handle::{build_prec, query_prec, self_prec, AnnIndex};
use crate::utils::kmeans_params;

/// Build a kMkNN index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use [KmknnIndex] instead.
///
/// @param data Numeric matrix. Samples x features.
/// @param metric String. One of `c("euclidean", "cosine")`.
/// @param nlist Integer or `NULL`. Number of k-means clusters.
/// @param kmeans_iters Integer or `NULL`. Lloyd iterations.
/// @param kmeans_balanced Boolean. Reseed starved centroids.
/// @param seed Integer. Random seed.
/// @param precision String. `"float"` or `"double"`.
/// @param verbose Boolean. Print progress.
///
/// @returns External pointer to the index.
///
/// @keywords internal
#[extendr]
#[allow(clippy::too_many_arguments)]
fn rs_kmknn_build(
    data: RMatrix<f64>,
    metric: &str,
    nlist: Nullable<i32>,
    kmeans_iters: Nullable<i32>,
    kmeans_balanced: bool,
    seed: i32,
    precision: &str,
    verbose: bool,
) -> Result<ExternalPtr<AnnIndex>> {
    let nlist = opt_usize(nlist);
    let km = kmeans_params(opt_usize(kmeans_iters), kmeans_balanced);
    let seed = seed as usize;
    build_prec!(data, precision, Kmknn, |mat| build_kmknn_index(
        mat,
        metric,
        nlist,
        km,
        seed,
        verbose
    ))
}

/// Query a kMkNN index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use the `$predict()` method instead.
///
/// @param ptr External pointer to the index.
/// @param data Numeric matrix. Queries x features.
/// @param k Integer. Number of neighbours.
/// @param sqrt Boolean. Square root the distances (true Euclidean).
/// @param return_dist Boolean. Return the distances.
/// @param verbose Boolean. Print progress.
///
/// @returns A list with `idx` (1-based integer matrix) and `dist` (double
/// matrix or `NULL`).
///
/// @keywords internal
#[extendr]
fn rs_kmknn_query(
    ptr: ExternalPtr<AnnIndex>,
    data: RMatrix<f64>,
    k: i32,
    sqrt: bool,
    return_dist: bool,
    verbose: bool,
) -> Result<Robj> {
    let k = k as usize;
    query_prec!(ptr, Kmknn, "kmknn", data, k, sqrt, |idx, q| {
        query_kmknn_index(q, idx, k, return_dist, verbose)
    })
}

/// Self-query a kMkNN index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use the `$query_self()` method instead.
///
/// @param ptr External pointer to the index.
/// @param k Integer. Number of neighbours, including the point itself.
/// @param sqrt Boolean. Square root the distances (true Euclidean).
/// @param return_dist Boolean. Return the distances.
/// @param verbose Boolean. Print progress.
///
/// @returns A list with `idx` (1-based integer matrix) and `dist` (double
/// matrix or `NULL`).
///
/// @keywords internal
#[extendr]
fn rs_kmknn_self(
    ptr: ExternalPtr<AnnIndex>,
    k: i32,
    sqrt: bool,
    return_dist: bool,
    verbose: bool,
) -> Result<Robj> {
    let k = k as usize;
    self_prec!(ptr, Kmknn, "kmknn", k, sqrt, |idx| {
        query_kmknn_self(idx, k, return_dist, verbose)
    })
}

extendr_module! {
    mod kmknn;
    fn rs_kmknn_build;
    fn rs_kmknn_query;
    fn rs_kmknn_self;
}
