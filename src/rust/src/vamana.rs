//! Vamana: the flat graph from DiskANN, pruned in two passes with the
//! relaxed-neighbour rule.

use ann_search_rs::{build_vamana_index, query_vamana_index, query_vamana_self};
use extendr_api::prelude::*;
use extendr_api::Result;

use crate::convert::opt_usize;
use crate::handle::{build_prec, query_prec, self_prec, AnnIndex};

/// Build a Vamana index
///
/// @description
/// `r lifecycle::badge("experimental")`
/// Use [VamanaIndex] instead.
///
/// @param data Numeric matrix. Samples x features.
/// @param metric String. One of `c("euclidean", "cosine", "manhattan")`.
/// @param r Integer. Maximum out-degree.
/// @param l_build Integer. Candidate list width during the build.
/// @param alpha_pass1 Numeric. Relaxation factor on the first pass.
/// @param alpha_pass2 Numeric. Relaxation factor on the second pass.
/// @param seed Integer. Random seed.
/// @param precision String. `"float"` or `"double"`.
///
/// @returns External pointer to the index.
///
/// @keywords internal
#[extendr]
#[allow(clippy::too_many_arguments)]
fn rs_vamana_build(
    data: RMatrix<f64>,
    metric: &str,
    r: i32,
    l_build: i32,
    alpha_pass1: f64,
    alpha_pass2: f64,
    seed: i32,
    precision: &str,
) -> Result<ExternalPtr<AnnIndex>> {
    let (r, l_build, seed) = (r as usize, l_build as usize, seed as usize);
    let (alpha_pass1, alpha_pass2) = (alpha_pass1 as f32, alpha_pass2 as f32);
    build_prec!(data, precision, Vamana, |mat| Ok(build_vamana_index(
        mat,
        r,
        l_build,
        None,
        alpha_pass1,
        alpha_pass2,
        metric,
        seed
    )))
}

/// Query a Vamana index
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
fn rs_vamana_query(
    ptr: ExternalPtr<AnnIndex>,
    data: RMatrix<f64>,
    k: i32,
    ef_search: Nullable<i32>,
    sqrt: bool,
    return_dist: bool,
    verbose: bool,
) -> Result<Robj> {
    let (k, ef_search) = (k as usize, opt_usize(ef_search));
    query_prec!(ptr, Vamana, "vamana", data, k, sqrt, |idx, q| {
        query_vamana_index(q, idx, k, ef_search, return_dist, verbose)
    })
}

/// Self-query a Vamana index
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
fn rs_vamana_self(
    ptr: ExternalPtr<AnnIndex>,
    k: i32,
    ef_search: Nullable<i32>,
    sqrt: bool,
    return_dist: bool,
    verbose: bool,
) -> Result<Robj> {
    let (k, ef_search) = (k as usize, opt_usize(ef_search));
    self_prec!(ptr, Vamana, "vamana", k, sqrt, |idx| {
        query_vamana_self(idx, k, ef_search, return_dist, verbose)
    })
}

extendr_module! {
    mod vamana;
    fn rs_vamana_build;
    fn rs_vamana_query;
    fn rs_vamana_self;
}
