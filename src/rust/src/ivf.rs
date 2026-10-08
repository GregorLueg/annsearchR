//! IVF: inverted file over k-means Voronoi cells. `nlist` sets how finely the
//! space is cut, `nprobe` how many cells a query visits. No Manhattan.

use ann_search_rs::{build_ivf_index, query_ivf_index, query_ivf_self};
use extendr_api::prelude::*;
use extendr_api::Result;

use crate::convert::opt_usize;
use crate::handle::{build_prec, query_prec, self_prec, AnnIndex};
use crate::utils::kmeans_params;

/// Build an IVF index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use [IvfIndex] instead.
///
/// @param data Numeric matrix. Samples x features.
/// @param metric String. One of `c("euclidean", "cosine")`.
/// @param nlist Integer or `NULL`. Number of Voronoi cells.
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
fn rs_ivf_build(
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
    build_prec!(data, precision, Ivf, |mat| build_ivf_index(
        mat,
        nlist,
        km,
        metric,
        seed,
        verbose
    ))
}

/// Query an IVF index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use the `$predict()` method instead.
///
/// @param ptr External pointer to the index.
/// @param data Numeric matrix. Queries x features.
/// @param k Integer. Number of neighbours.
/// @param nprobe Integer or `NULL`. Cells visited per query.
/// @param sqrt Boolean. Square root the distances (true Euclidean).
/// @param return_dist Boolean. Return the distances.
/// @param verbose Boolean. Print progress.
///
/// @returns A list with `idx` (1-based integer matrix) and `dist` (double
/// matrix or `NULL`).
///
/// @keywords internal
#[extendr]
fn rs_ivf_query(
    ptr: ExternalPtr<AnnIndex>,
    data: RMatrix<f64>,
    k: i32,
    nprobe: Nullable<i32>,
    sqrt: bool,
    return_dist: bool,
    verbose: bool,
) -> Result<Robj> {
    let (k, nprobe) = (k as usize, opt_usize(nprobe));
    query_prec!(ptr, Ivf, "ivf", data, k, sqrt, |idx, q| {
        query_ivf_index(q, idx, k, nprobe, return_dist, verbose)
    })
}

/// Self-query an IVF index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use the `$query_self()` method instead.
///
/// @param ptr External pointer to the index.
/// @param k Integer. Number of neighbours, including the point itself.
/// @param nprobe Integer or `NULL`. Cells visited per query.
/// @param sqrt Boolean. Square root the distances (true Euclidean).
/// @param return_dist Boolean. Return the distances.
/// @param verbose Boolean. Print progress.
///
/// @returns A list with `idx` (1-based integer matrix) and `dist` (double
/// matrix or `NULL`).
///
/// @keywords internal
#[extendr]
fn rs_ivf_self(
    ptr: ExternalPtr<AnnIndex>,
    k: i32,
    nprobe: Nullable<i32>,
    sqrt: bool,
    return_dist: bool,
    verbose: bool,
) -> Result<Robj> {
    let (k, nprobe) = (k as usize, opt_usize(nprobe));
    self_prec!(ptr, Ivf, "ivf", k, sqrt, |idx| {
        query_ivf_self(idx, k, nprobe, return_dist, verbose)
    })
}

extendr_module! {
    mod ivf;
    fn rs_ivf_build;
    fn rs_ivf_query;
    fn rs_ivf_self;
}
