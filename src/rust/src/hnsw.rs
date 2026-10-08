//! HNSW: hierarchical navigable small world graph. `ef_search` is required;
//! HNSW has no internal default to fall back on.

use ann_search_rs::{build_hnsw_index, query_hnsw_index, query_hnsw_self};
use extendr_api::prelude::*;
use extendr_api::Result;

use crate::handle::{build_prec, query_prec, self_prec, AnnIndex};

/// Build an HNSW index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use [HnswIndex] instead.
///
/// @param data Numeric matrix. Samples x features.
/// @param metric String. One of `c("euclidean", "cosine", "manhattan")`.
/// @param m Integer. Edges per node on the upper layers.
/// @param ef_construction Integer. Candidate list width during the build.
/// @param seed Integer. Random seed.
/// @param precision String. `"float"` or `"double"`.
/// @param verbose Boolean. Print progress.
///
/// @returns External pointer to the index.
///
/// @keywords internal
#[extendr]
fn rs_hnsw_build(
    data: RMatrix<f64>,
    metric: &str,
    m: i32,
    ef_construction: i32,
    seed: i32,
    precision: &str,
    verbose: bool,
) -> Result<ExternalPtr<AnnIndex>> {
    let (m, ef_construction, seed) = (m as usize, ef_construction as usize, seed as usize);
    build_prec!(data, precision, Hnsw, |mat| Ok(build_hnsw_index(
        mat,
        m,
        ef_construction,
        metric,
        seed,
        verbose
    )))
}

/// Query an HNSW index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use the `$predict()` method instead.
///
/// @param ptr External pointer to the index.
/// @param data Numeric matrix. Queries x features.
/// @param k Integer. Number of neighbours.
/// @param ef_search Integer. Beam width at query time.
/// @param sqrt Boolean. Square root the distances (true Euclidean).
/// @param return_dist Boolean. Return the distances.
/// @param verbose Boolean. Print progress.
///
/// @returns A list with `idx` (1-based integer matrix) and `dist` (double
/// matrix or `NULL`).
///
/// @keywords internal
#[extendr]
fn rs_hnsw_query(
    ptr: ExternalPtr<AnnIndex>,
    data: RMatrix<f64>,
    k: i32,
    ef_search: i32,
    sqrt: bool,
    return_dist: bool,
    verbose: bool,
) -> Result<Robj> {
    let (k, ef_search) = (k as usize, ef_search as usize);
    query_prec!(ptr, Hnsw, "hnsw", data, k, sqrt, |idx, q| {
        query_hnsw_index(q, idx, k, ef_search, return_dist, verbose)
    })
}

/// Self-query an HNSW index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use the `$query_self()` method instead.
///
/// @param ptr External pointer to the index.
/// @param k Integer. Number of neighbours, including the point itself.
/// @param ef_search Integer. Beam width at query time.
/// @param sqrt Boolean. Square root the distances (true Euclidean).
/// @param return_dist Boolean. Return the distances.
/// @param verbose Boolean. Print progress.
///
/// @returns A list with `idx` (1-based integer matrix) and `dist` (double
/// matrix or `NULL`).
///
/// @keywords internal
#[extendr]
fn rs_hnsw_self(
    ptr: ExternalPtr<AnnIndex>,
    k: i32,
    ef_search: i32,
    sqrt: bool,
    return_dist: bool,
    verbose: bool,
) -> Result<Robj> {
    let (k, ef_search) = (k as usize, ef_search as usize);
    self_prec!(ptr, Hnsw, "hnsw", k, sqrt, |idx| {
        query_hnsw_self(idx, k, ef_search, return_dist, verbose)
    })
}

extendr_module! {
    mod hnsw;
    fn rs_hnsw_build;
    fn rs_hnsw_query;
    fn rs_hnsw_self;
}
